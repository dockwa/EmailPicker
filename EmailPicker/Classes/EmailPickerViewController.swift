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


open class EmailPickerViewController: UIViewController {
    ///A typealias for an email.
    public typealias Email = String
    
    /**
     An enum representing the result of the EmailPicker
     
     - Selected:  Some contacts were selected. Has an array of the emails that were selected, and the EmailPickerViewController to dismiss it.
     - Cancelled: The EmailPicker was cancelled, so no contacts were selected. Has the EmailPickerViewController to dismiss it.
     */
    public enum Result {
        case selected(EmailPickerViewController, [Email])
        case cancelled(EmailPickerViewController)
    }
    
    /// The completion closure for EmailPicker
    public typealias CompletionHandler = (Result) -> Void

    
    
    fileprivate lazy var tokenInputView: CLTokenInputView = {
        let view = CLTokenInputView()
        view.delegate = self
        view.placeholderText = "Enter an email address"
        view.drawBottomBorder = true
        view.tokenizationCharacters = [" ", ","]
        view.backgroundColor = .white
        return view
    }()
    fileprivate lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "EmailPickerCell", bundle: Bundle(for: type(of: self))), forCellReuseIdentifier: "EmailPickerCell")
        table.delegate = self
        table.dataSource = self
        table.rowHeight = EmailPickerCell.height
        table.keyboardDismissMode = .onDrag
        return table
    }()
    fileprivate var loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .whiteLarge)
        spinner.color = .darkGray
        spinner.hidesWhenStopped = true
        return spinner
    }()
    fileprivate lazy var infoLabel: InsetLabel = {
        let label = InsetLabel()
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        return label
    }()
    fileprivate var tokenHeightConstraint: NSLayoutConstraint?

    fileprivate lazy var addressBook: APAddressBook = {
        let book = APAddressBook()
        book.fieldsMask = [.name, .thumbnail, .emailsOnly]
        book.sortDescriptors = [NSSortDescriptor(key: "name.firstName", ascending: true),
                                NSSortDescriptor(key: "name.lastName", ascending: true)]
        book.filterBlock = {(contact: APContact!) -> Bool in
            guard let emails = contact.emails , emails.count > 0 else { return false }
            return true
        }
        return book
    }()
    
    fileprivate var contacts: [APContact] = []
    fileprivate var filteredContacts: [APContact] = []
    fileprivate var selectedContacts: [APContact] = []
    fileprivate var completion: CompletionHandler?
    fileprivate var infoText: String?
    
    
    //init
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    public init(infoText: String? = nil, completion: @escaping CompletionHandler) {
        super.init(nibName: nil, bundle: nil)
        self.completion = completion
        self.infoText = infoText
        
        navigationItem.title = "Select Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(EmailPickerViewController.cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(EmailPickerViewController.done))
    }
    
    
    /**
     This is the prefered method to create a new EmailPicker. Use this method and present modally.
     
     - parameter infoText:   This is the text that will appear at the top of the EmailPicker. Use this to provide additional instructions or context for your users.
     - parameter completion: The completion closure to handle the selected emails.
     
     - returns: Returns an EmailPicker wrapped in a UINavigationController.
     */
    open class func emailPickerModal(_ infoText: String? = nil, completion: @escaping CompletionHandler) -> UINavigationController {
        let picker = EmailPickerViewController(infoText: infoText, completion: completion)
        let nav = UINavigationController(rootViewController: picker)
        return nav
    }
}

public extension EmailPickerViewController {
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
        func setupView() {
            //view
            view.backgroundColor = .white
            
            if let text = infoText , text.isEmpty == false {
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
    
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if tokenInputView.isEditing == false {
            tokenInputView.beginEditing()
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tokenInputView.endEditing()
    }
    

    func cancel() {
        completion?(.cancelled(self))
    }
    
    func done() {
        tokenInputView.tokenizeTextfieldText()
        completion?(.selected(self, selectedContacts.flatMap{$0.userSelectedEmail}))
    }
    
}


//MARK: - ClTokenInputView Delegate

extension EmailPickerViewController: CLTokenInputViewDelegate {
    
    public func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        if text == "" {
            filteredContacts = contacts
        }
        else {
            filterContactsWithSearchText(text!)
        }
        tableView.reloadData()
    }
    
    public func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        if let contact = token.context as? APContact {
            selectedContacts.append(contact)
        }
    }
    
    public func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        if let contact = token.context as? APContact {
            if let idx = selectedContacts.index(of: contact) {
                selectedContacts.remove(at: idx)
            }
            tableView.reloadData()
        }
    }
    
    public func tokenInputView(_ view: CLTokenInputView, tokenForText text: String) -> CLToken? {
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
    
    public func tokenInputViewDidEndEditing(_ view: CLTokenInputView) {
        
    }
    
    public func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) {
        
    }
    
    public func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        tokenHeightConstraint?.constant = height
    }
}


//MARK: - TableView DataSource

extension EmailPickerViewController: UITableViewDataSource {
    
    @objc(tableView:heightForRowAtIndexPath:) public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return EmailPickerCell.height
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContacts.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmailPickerCell") as! EmailPickerCell
        
        let contact = filteredContacts[(indexPath as NSIndexPath).row]
        if let img = contact.thumbnail {
            cell.thumbnailImageView.image = img
        }
        else {
            cell.thumbnailImageView.image = nil
        }
        cell.label.text = contact.name?.compositeName
        
        let isSelected = selectedContacts.contains(contact)
        cell.accessoryType = isSelected ? .checkmark : .none
        
        return cell
    }
}

//MARK: - TableView Delegate

extension EmailPickerViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let contact = filteredContacts[(indexPath as NSIndexPath).row]
        
        if selectedContacts.contains(contact) { //we already have it, lets deselect it
            if let idx = selectedContacts.index(of: contact) {
                selectedContacts.remove(at: idx)
            }
            tableView.reloadData()
            
            let token = tokenForContact(contact)
            tokenInputView.remove(token)
        }
        else { //we don't have it, lets select it
            selectPreferedEmailForContact(contact, fromView: tableView.cellForRow(at: indexPath)?.contentView, completion: { (contact) -> Void in
                let token = self.tokenForContact(contact)
                self.tokenInputView.add(token)
            })
        }
    }
}



//MARK: - Helpers

extension EmailPickerViewController {
    
    typealias SelectedEmailCompletion = (_ contact: APContact) -> Void
   
    fileprivate func selectPreferedEmailForContact(_ contact: APContact, fromView: UIView?, completion: @escaping SelectedEmailCompletion) {
        
        guard let mails = contact.emails else { return }
        
        if mails.count > 1 {
            let alert = UIAlertController(title: "Choose Email", message: "Which email would you like to use?", preferredStyle: .actionSheet)
            
            var actions = mails.map({ (email) -> UIAlertAction in
                let action = UIAlertAction(title: email.address, style: .default, handler: { (action) -> Void in
                    contact.userSelectedEmail = action.title
                    completion(contact)
                })
                return action
            })
            
            actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            for act in actions {
                alert.addAction(act)
            }
            
            if let fromView = fromView {
                alert.popoverPresentationController?.sourceView = fromView
                alert.popoverPresentationController?.permittedArrowDirections = [.up, .down]
            }
            else {
                alert.popoverPresentationController?.sourceView = self.view
            }
            
            present(alert, animated: true, completion: nil)
        }
        else {
            contact.userSelectedEmail = mails.first?.address!
            completion(contact)
        }
        
    }
    
    
    fileprivate func tokenForContact(_ contact: APContact) -> CLToken {
        let token = CLToken(displayText: contact.userSelectedEmail!, context: contact)
        return token
    }
    

    fileprivate func filterContactsWithSearchText(_ text: String) {
        let array = NSArray(array: self.contacts)
        
        let predicate = NSPredicate(format: "self.name.firstName contains[cd] %@ OR self.name.lastName contains[cd] %@", text, text)
        self.filteredContacts = array.filtered(using: predicate) as! [APContact]
    }
    
    fileprivate func showNoAccessAlert(_ withError: NSError? = nil) {
        let msg = "This app might not have permission to show your contacts.\nTo allow this app to show your contacts, tap Settings and make sure Contacts is switched on. (\(withError?.localizedDescription ?? ""))."
        
        let alert = UIAlertController(title: "Error Loading Contacts", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
            UIApplication.shared.openURL(URL(string: UIApplicationOpenSettingsURLString)!)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(action)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    fileprivate func loadContacts() {
        
        func showLoading() {
            tableView.isHidden = true
            tokenInputView.isUserInteractionEnabled = false
            loadingSpinner.startAnimating()
        }
        
        func finishLoading() {
            tableView.isHidden = false
            loadingSpinner.stopAnimating()
            tokenInputView.isUserInteractionEnabled = true
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
                self.showNoAccessAlert(error as NSError?)
            }
        }

    }
    
}


//MARK: - Layout

extension EmailPickerViewController {
    
    fileprivate func addLayoutConstraints() {
        
        func addConstraintsForInfoLabel() {
            infoLabel.translatesAutoresizingMaskIntoConstraints = false
            let top = NSLayoutConstraint(item: infoLabel, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
            let left = NSLayoutConstraint(item: infoLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: infoLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
            let height = NSLayoutConstraint(item: infoLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 60)
            infoLabel.addConstraint(height)
            view.addConstraints([top, left, right])
        }
        
        func addConstraintsForTokenInputView() {
            tokenInputView.translatesAutoresizingMaskIntoConstraints = false
            
            
            if let text = infoText , text.isEmpty == false {
                let top = NSLayoutConstraint(item: tokenInputView, attribute: .top, relatedBy: .equal, toItem: infoLabel, attribute: .bottom, multiplier: 1, constant: 0)
                let left = NSLayoutConstraint(item: tokenInputView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: tokenInputView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
                
                let heightConstant = tokenHeightConstraint?.constant ?? 45
                let height = NSLayoutConstraint(item: tokenInputView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: heightConstant)
                tokenHeightConstraint = height
                
                tokenInputView.addConstraint(height)
                view.addConstraints([top, left, right])
            }
            else {
                let top = NSLayoutConstraint(item: tokenInputView, attribute: .top, relatedBy: .equal, toItem: topLayoutGuide, attribute: .bottom, multiplier: 1, constant: 0)
                let left = NSLayoutConstraint(item: tokenInputView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: tokenInputView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
               
                let heightConstant = tokenHeightConstraint?.constant ?? 45
                let height = NSLayoutConstraint(item: tokenInputView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: heightConstant)
                tokenHeightConstraint = height
                
                tokenInputView.addConstraint(height)
                view.addConstraints([top, left, right])
            }
        }
        
        func addConstraintsForTableView() {
            tableView.translatesAutoresizingMaskIntoConstraints = false
            let top = NSLayoutConstraint(item: tableView, attribute: .top, relatedBy: .equal, toItem: tokenInputView, attribute: .bottom, multiplier: 1, constant: 0)
            let left = NSLayoutConstraint(item: tableView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: tableView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
            let bottom = NSLayoutConstraint(item: tableView, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
            view.addConstraints([top, left, right, bottom])
        }
        
        func addConstraintsForLoadingSpinner() {
            loadingSpinner.translatesAutoresizingMaskIntoConstraints = false
            let alignVertical = NSLayoutConstraint(item: loadingSpinner, attribute: .centerX, relatedBy: .equal, toItem: view, attribute: .centerX, multiplier: 1, constant: 0)
            let alignHorizontal = NSLayoutConstraint(item: loadingSpinner, attribute: .centerY, relatedBy: .equal, toItem: view, attribute: .centerY, multiplier: 1, constant: 0)
            view.addConstraints([alignVertical, alignHorizontal])
        }
        
        if let text = infoText , text.isEmpty == false {
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
        return NSPredicate(format: "SELF MATCHES %@", emailRegex).evaluate(with: self)
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
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        super.drawText(in: UIEdgeInsetsInsetRect(rect, insets))
    }
}


















