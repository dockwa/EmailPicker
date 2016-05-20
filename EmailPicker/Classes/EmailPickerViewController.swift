//
//  EmailPickerViewController.swift
//  EmailPicker
//
//  Created by Christian Hatch on 7/23/15.
//  Copyright (c) 2016 Dockwa. All rights reserved.
//

import UIKit
import CLTokenInputView
import APAddressBook

public typealias Email = String

public enum EmailPickerResult {
    case Selected(EmailPickerViewController, [Email])
    case Cancelled(EmailPickerViewController)
}

public typealias EmailPickerCompletion = (EmailPickerResult) -> Void

public class EmailPickerViewController: UIViewController {
   
    private lazy var tokenInputView: CLTokenInputView = {
        let view = CLTokenInputView()
        view.delegate = self
        view.placeholderText = "Enter an email address"
        view.drawBottomBorder = true
        view.tokenizationCharacters = [" ", ","]
        view.backgroundColor = .whiteColor()
        return view
    }()
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.registerNib(UINib(nibName: "EmailPickerCell", bundle: NSBundle(forClass: self.dynamicType)), forCellReuseIdentifier: "EmailPickerCell")
        table.delegate = self
        table.dataSource = self
        table.rowHeight = EmailPickerCell.height
        table.keyboardDismissMode = .OnDrag
        return table
    }()
    private var loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .WhiteLarge)
        spinner.color = .darkGrayColor()
        spinner.hidesWhenStopped = true
        return spinner
    }()
    private lazy var infoLabel: InsetLabel = {
        let label = InsetLabel()
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .Center
        return label
    }()
    private var tokenHeightConstraint: NSLayoutConstraint?

    private lazy var addressBook: APAddressBook = {
        let book = APAddressBook()
        book.fieldsMask = [.Name, .Thumbnail, .EmailsOnly]
        book.sortDescriptors = [NSSortDescriptor(key: "name.firstName", ascending: true),
                                NSSortDescriptor(key: "name.lastName", ascending: true)]
        book.filterBlock = {(contact: APContact!) -> Bool in
            guard let emails = contact.emails where emails.count > 0 else { return false }
            return true
        }
        return book
    }()
    
    private var contacts: [APContact] = []
    private var filteredContacts: [APContact] = []
    private var selectedContacts: [APContact] = []
    private var completion: EmailPickerCompletion?
    private var infoText: String?
    
    
    //init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: NSBundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    public init(infoText: String? = nil, completion: EmailPickerCompletion) {
        super.init(nibName: nil, bundle: nil)
        self.completion = completion
        self.infoText = infoText
        
        navigationItem.title = "Select Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Cancel, target: self, action: #selector(EmailPickerViewController.cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .Plain, target: self, action: #selector(EmailPickerViewController.done))
    }
    
    
    public class func emailPickerModal(infoText: String? = nil, completion: EmailPickerCompletion) -> UINavigationController {
        let picker = EmailPickerViewController(infoText: infoText, completion: completion)
        let nav = UINavigationController(rootViewController: picker)
        return nav
    }
}

public extension EmailPickerViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func setupView() {
            //view
            view.backgroundColor = .whiteColor()
            
            if let text = infoText where text.isEmpty == false {
                view.addSubview(infoLabel)
                infoLabel.text = text
            }
            
            view.addSubview(tokenInputView)
            view.addSubview(tableView)
            view.insertSubview(loadingSpinner, aboveSubview: tableView)
            
            addLayoutConstraints()
        }
        
        setupView()
        loadContacts()
    }
    
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        if tokenInputView.editing == false {
            tokenInputView.beginEditing()
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        tokenInputView.endEditing()
    }
    

    func cancel() {
        completion?(.Cancelled(self))
    }
    
    func done() {
        tokenInputView.tokenizeTextfieldText()
        completion?(.Selected(self, selectedContacts.flatMap{$0.userSelectedEmail}))
    }
    
}


//MARK: - ClTokenInputView Delegate

extension EmailPickerViewController: CLTokenInputViewDelegate {
    
    public func tokenInputView(view: CLTokenInputView, didChangeText text: String?) {
        if text == "" {
            filteredContacts = contacts
        }
        else {
            filterContactsWithSearchText(text!)
        }
        tableView.reloadData()
    }
    
    public func tokenInputView(view: CLTokenInputView, didAddToken token: CLToken) {
        if let contact = token.context as? APContact {
            selectedContacts.append(contact)
        }
    }
    
    public func tokenInputView(view: CLTokenInputView, didRemoveToken token: CLToken) {
        if let contact = token.context as? APContact {
            if let idx = selectedContacts.indexOf(contact) {
                selectedContacts.removeAtIndex(idx)
            }
            tableView.reloadData()
        }
    }
    
    public func tokenInputView(view: CLTokenInputView, tokenForText text: String) -> CLToken? {
        if filteredContacts.count > 0 {
            let contact = filteredContacts.first
            selectPreferedEmailForContact(contact!, fromView: view, completion: { (contact) -> Void in
                return self.tokenForContact(contact)
            })
        }
        else { //lets create a token
            if text.isEmail() {
                let contact = APContact()
                contact.userSelectedEmail = text
                
                let token = CLToken(displayText: contact.userSelectedEmail!, context: contact)
                return token
            }
        }
        
        return nil
    }
    
    public func tokenInputViewDidEndEditing(view: CLTokenInputView) {
        
    }
    
    public func tokenInputViewDidBeginEditing(view: CLTokenInputView) {
        
    }
    
    public func tokenInputView(view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        tokenHeightConstraint?.constant = height
    }
}


//MARK: - TableView DataSource

extension EmailPickerViewController: UITableViewDataSource {
    
    public func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return EmailPickerCell.height
    }
    
    public func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContacts.count
    }
    
    public func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("EmailPickerCell") as! EmailPickerCell
        
        let contact = filteredContacts[indexPath.row]
        if let img = contact.thumbnail {
            cell.thumbnailImageView.image = img
        }
        else {
            cell.thumbnailImageView.image = nil
        }
        cell.label.text = contact.name?.compositeName
        
        let isSelected = selectedContacts.contains(contact)
        cell.accessoryType = isSelected ? .Checkmark : .None
        
        return cell
    }
}

//MARK: - TableView Delegate

extension EmailPickerViewController: UITableViewDelegate {

    public func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let contact = filteredContacts[indexPath.row]
        
        if selectedContacts.contains(contact) { //we already have it, lets deselect it
            if let idx = selectedContacts.indexOf(contact) {
                selectedContacts.removeAtIndex(idx)
            }
            tableView.reloadData()
            
            let token = tokenForContact(contact)
            tokenInputView.removeToken(token)
        }
        else { //we don't have it, lets select it
            selectPreferedEmailForContact(contact, fromView: tableView.cellForRowAtIndexPath(indexPath)?.contentView, completion: { (contact) -> Void in
                let token = self.tokenForContact(contact)
                self.tokenInputView.addToken(token)
            })
        }
    }
}



//MARK: - Helpers

extension EmailPickerViewController {
    
    typealias SelectedEmailCompletion = (contact: APContact) -> Void
   
    private func selectPreferedEmailForContact(contact: APContact, fromView: UIView?, completion: SelectedEmailCompletion) {
        
        guard let mails = contact.emails else { return }
        
        if mails.count > 1 {
            let alert = UIAlertController(title: "Choose Email", message: "Which email would you like to use?", preferredStyle: .ActionSheet)
            
            var actions = mails.map({ (email) -> UIAlertAction in
                let action = UIAlertAction(title: email.address, style: .Default, handler: { (action) -> Void in
                    contact.userSelectedEmail = action.title
                    completion(contact: contact)
                })
                return action
            })
            
            actions.append(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
            for act in actions {
                alert.addAction(act)
            }
            
            if let fromView = fromView {
                alert.popoverPresentationController?.sourceView = fromView
                alert.popoverPresentationController?.permittedArrowDirections = [.Up, .Down]
            }
            else {
                alert.popoverPresentationController?.sourceView = self.view
            }
            
            presentViewController(alert, animated: true, completion: nil)
        }
        else {
            contact.userSelectedEmail = mails.first?.address!
            completion(contact: contact)
        }
        
    }
    
    
    private func tokenForContact(contact: APContact) -> CLToken {
        let token = CLToken(displayText: contact.userSelectedEmail!, context: contact)
        return token
    }
    

    private func filterContactsWithSearchText(text: String) {
        let array = NSArray(array: self.contacts)
        
        let predicate = NSPredicate(format: "self.name.firstName contains[cd] %@ OR self.name.lastName contains[cd] %@", text, text)
        self.filteredContacts = array.filteredArrayUsingPredicate(predicate) as! [APContact]
    }
    
    private func showNoAccessAlert(withError: NSError? = nil) {
        let msg = "This app might not have permission to show your contacts.\nTo allow this app to show your contacts, tap Settings and make sure Contacts is switched on. (\(withError?.localizedDescription ?? ""))."
        
        let alert = UIAlertController(title: "Error Loading Contacts", message: msg, preferredStyle: .Alert)
        let action = UIAlertAction(title: "Settings", style: .Default, handler: { (action) in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        alert.addAction(action)
        alert.addAction(cancel)
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    private func loadContacts() {
        
        func showLoading() {
            tableView.hidden = true
            tokenInputView.userInteractionEnabled = false
            loadingSpinner.startAnimating()
        }
        
        func finishLoading() {
            tableView.hidden = false
            loadingSpinner.stopAnimating()
            tokenInputView.userInteractionEnabled = true
        }
        
        showLoading()
        addressBook.loadContacts { (contacts, error) -> Void in
            finishLoading()
            
            if let contacts = contacts {
                self.contacts = contacts
                self.filteredContacts = self.contacts
                self.tableView.reloadData()
            }
            else if let error = error {
                self.showNoAccessAlert(error)
            }
        }

    }
    
}


//MARK: - Layout

extension EmailPickerViewController {
    
    private func addLayoutConstraints() {
        
        func addConstraintsForInfoLabel() {
            infoLabel.translatesAutoresizingMaskIntoConstraints = false
            let top = NSLayoutConstraint(item: infoLabel, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0)
            let left = NSLayoutConstraint(item: infoLabel, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: infoLabel, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
            let height = NSLayoutConstraint(item: infoLabel, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: 60)
            infoLabel.addConstraint(height)
            view.addConstraints([top, left, right])
        }
        
        func addConstraintsForTokenInputView() {
            tokenInputView.translatesAutoresizingMaskIntoConstraints = false
            
            
            if let text = infoText where text.isEmpty == false {
                let top = NSLayoutConstraint(item: tokenInputView, attribute: .Top, relatedBy: .Equal, toItem: infoLabel, attribute: .Bottom, multiplier: 1, constant: 0)
                let left = NSLayoutConstraint(item: tokenInputView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: tokenInputView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
                
                let heightConstant = tokenHeightConstraint?.constant ?? 45
                let height = NSLayoutConstraint(item: tokenInputView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: heightConstant)
                tokenHeightConstraint = height
                
                tokenInputView.addConstraint(height)
                view.addConstraints([top, left, right])
            }
            else {
                let top = NSLayoutConstraint(item: tokenInputView, attribute: .Top, relatedBy: .Equal, toItem: topLayoutGuide, attribute: .Bottom, multiplier: 1, constant: 0)
                let left = NSLayoutConstraint(item: tokenInputView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: tokenInputView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
               
                let heightConstant = tokenHeightConstraint?.constant ?? 45
                let height = NSLayoutConstraint(item: tokenInputView, attribute: .Height, relatedBy: .Equal, toItem: nil, attribute: .Height, multiplier: 1, constant: heightConstant)
                tokenHeightConstraint = height
                
                tokenInputView.addConstraint(height)
                view.addConstraints([top, left, right])
            }
        }
        
        func addConstraintsForTableView() {
            tableView.translatesAutoresizingMaskIntoConstraints = false
            let top = NSLayoutConstraint(item: tableView, attribute: .Top, relatedBy: .Equal, toItem: tokenInputView, attribute: .Bottom, multiplier: 1, constant: 0)
            let left = NSLayoutConstraint(item: tableView, attribute: .Leading, relatedBy: .Equal, toItem: view, attribute: .Leading, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: tableView, attribute: .Trailing, relatedBy: .Equal, toItem: view, attribute: .Trailing, multiplier: 1, constant: 0)
            let bottom = NSLayoutConstraint(item: tableView, attribute: .Bottom, relatedBy: .Equal, toItem: view, attribute: .Bottom, multiplier: 1, constant: 0)
            view.addConstraints([top, left, right, bottom])
        }
        
        func addConstraintsForLoadingSpinner() {
            loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
            let alignVertical = NSLayoutConstraint(item: loadingSpinner, attribute: .CenterX, relatedBy: .Equal, toItem: view, attribute: .CenterX, multiplier: 1, constant: 0)
            let alignHorizontal = NSLayoutConstraint(item: loadingSpinner, attribute: .CenterY, relatedBy: .Equal, toItem: view, attribute: .CenterY, multiplier: 1, constant: 0)
            view.addConstraints([alignVertical, alignHorizontal])
        }
        
        if let text = infoText where text.isEmpty == false {
            addConstraintsForInfoLabel()
        }
        
        addConstraintsForTokenInputView()
        addConstraintsForTableView()
        addConstraintsForLoadingSpinner()
    }
    
}



//MARK: - Extensions

private extension String {
    func isEmail() -> Bool {
        let emailRegex = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,6}"
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluateWithObject(self)
    }
}

private var selectedEmailKey: UInt8 = 0
private extension APContact {
    var userSelectedEmail: String? {
        get {
            return objc_getAssociatedObject(self, &selectedEmailKey) as? String
        }
        set(newValue) {
            objc_setAssociatedObject(self, &selectedEmailKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}




//MARK: - Cell

class EmailPickerCell: UITableViewCell {
    static let height: CGFloat = 60
    
    @IBOutlet weak var thumbnailImageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        thumbnailImageView.layer.cornerRadius = thumbnailImageView.frame.size.height / 2
    }
}



//MARK: - UILabel Inset Subclass 

class InsetLabel: UILabel {
    override func drawTextInRect(rect: CGRect) {
        let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        super.drawTextInRect(UIEdgeInsetsInsetRect(rect, insets))
    }
}


















