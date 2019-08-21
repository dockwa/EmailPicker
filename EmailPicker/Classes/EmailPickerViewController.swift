//
//  EmailPickerViewController.swift
//  EmailPicker
//
//  Created by Christian Hatch on 7/23/15.
//  Copyright (c) 2016 Dockwa. All rights reserved.
//

import UIKit
import CLTokenInputView
import Contacts

open class EmailPickerViewController: UIViewController {

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
    
    public typealias Completion = (Result) -> Void

    
    private lazy var tokenInputView: CLTokenInputView = {
        let view = CLTokenInputView()
        view.delegate = self
        view.placeholderText = "Enter an email address"
        view.drawBottomBorder = true
        view.tokenizationCharacters = [" ", ","]
        view.backgroundColor = .white
        return view
    }()
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(UINib(nibName: "EmailPickerCell", bundle: Bundle(for: type(of: self))), forCellReuseIdentifier: "EmailPickerCell")
        table.delegate = self
        table.dataSource = self
        table.rowHeight = EmailPickerCell.height
        table.keyboardDismissMode = .onDrag
        return table
    }()
    private var loadingSpinner: UIActivityIndicatorView = {
        let spinner = UIActivityIndicatorView(style: .whiteLarge)
        spinner.color = .darkGray
        spinner.hidesWhenStopped = true
        return spinner
    }()
    private lazy var infoLabel: InsetLabel = {
        let label = InsetLabel()
        label.numberOfLines = 0
        label.adjustsFontSizeToFitWidth = true
        label.minimumScaleFactor = 0.5
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 18)
        return label
    }()
    private var tokenHeightConstraint: NSLayoutConstraint?
    
    private var contacts: [CNContact] = []
    private var filteredContacts: [CNContact] = []
    private var selectedContacts: [CNContact] = []
    private var completion: Completion?
    private var infoText: String?
    
    
    // MARK: - Init
    
    /**
     This is the prefered method to create a new EmailPicker. Use this method and present modally.
     
     - parameter infoText:   This is the text that will appear at the top of the EmailPicker. Use this to provide additional instructions or context for your users.
     - parameter doneButtonTitle: This is the title of the right bar button item, used to finish selecting emails.
     - parameter completion: The completion closure to handle the selected emails.
     
     - returns: Returns an EmailPicker.
     */
    public init(infoText: String? = nil, doneButtonTitle: String = "Done", completion: @escaping Completion) {
        super.init(nibName: nil, bundle: nil)
        self.completion = completion
        self.infoText = infoText
        
        navigationItem.title = "Select Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: doneButtonTitle, style: .done, target: self, action: #selector(done))
        view.backgroundColor = .white
        
        if let text = infoText, !text.isEmpty {
            view.addSubview(infoLabel)
            infoLabel.text = text
        }
        
        view.addSubview(tokenInputView)
        view.addSubview(tableView)
        view.insertSubview(loadingSpinner, aboveSubview: tableView)
        
        addLayoutConstraints()
    }
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
}

// MARK: - UIKit

extension EmailPickerViewController {
    
    override open func viewDidLoad() {
        super.viewDidLoad()
        
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

    @objc func cancel() {
        completion?(.cancelled(self))
    }
    
    @objc func done() {
        tokenInputView.tokenizeTextfieldText()
        completion?(.selected(self, selectedContacts.compactMap { $0.userSelectedEmail }))
    }
}


// MARK: - ClTokenInputView Delegate

extension EmailPickerViewController: CLTokenInputViewDelegate {
    
    public func tokenInputView(_ view: CLTokenInputView, didChangeText text: String?) {
        guard let text = text else { return }
        
        if text == "" {
            filteredContacts = contacts
        } else {
            filterContacts(withSearchText: text)
        }
        
        tableView.reloadData()
    }
    
    public func tokenInputView(_ view: CLTokenInputView, didAdd token: CLToken) {
        if let contact = token.context as? CNContact {
            selectedContacts.append(contact)
        }
    }
    
    public func tokenInputView(_ view: CLTokenInputView, didRemove token: CLToken) {
        if let contact = token.context as? CNContact {
            if let idx = selectedContacts.firstIndex(of: contact) {
                selectedContacts.remove(at: idx)
            }
            tableView.reloadData()
        }
    }
    
    public func tokenInputView(_ view: CLTokenInputView, tokenForText text: String) -> CLToken? {
        if filteredContacts.count > 0 {
            guard let contact = filteredContacts.first else { return nil }
            selectPreferedEmail(for: contact, fromView: view, completion: nil)
        } else { //lets create a token
            if text.isEmail {
                let contact = CNContact()
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

// MARK: - TableView DataSource

extension EmailPickerViewController: UITableViewDataSource {
    
    @objc(tableView:heightForRowAtIndexPath:) public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return EmailPickerCell.height
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContacts.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmailPickerCell") as! EmailPickerCell
        
        let contact = filteredContacts[indexPath.row]
        let isSelected = selectedContacts.contains(contact)

        cell.thumbnailImageView.image = contact.thumbnail
        cell.label.text = "\(contact.givenName) \(contact.familyName)"
        cell.accessoryType = isSelected ? .checkmark : .none
        return cell
    }
}

// MARK: - TableView Delegate

extension EmailPickerViewController: UITableViewDelegate {

    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let contact = filteredContacts[indexPath.row]
        
        if selectedContacts.contains(contact) { //we already have it, lets deselect it
            if let idx = selectedContacts.firstIndex(of: contact) {
                selectedContacts.remove(at: idx)
            }
            tableView.reloadData()
            
            guard let token = makeToken(contact: contact) else { return }
            tokenInputView.remove(token)
        } else { //we don't have it, lets select it
            selectPreferedEmail(for: contact, fromView: tableView.cellForRow(at: indexPath)?.contentView, completion: { (contact) -> Void in
                guard let token = self.makeToken(contact: contact) else { return }
                self.tokenInputView.add(token)
            })
        }
    }
}

// MARK: - Contact Helpers

extension EmailPickerViewController {
    
    typealias SelectedEmailCompletion = (CNContact) -> Void
   
    private func selectPreferedEmail(for contact: CNContact, fromView: UIView?, completion: SelectedEmailCompletion?) {
        guard let mails = contact.emails else { return }
        
        guard mails.count > 1 else {
            contact.userSelectedEmail = mails.first?.address!
            completion?(contact)
            return
        }
    
        var actions = mails.map({ (email) -> UIAlertAction in
            let action = UIAlertAction(title: email.address, style: .default, handler: { (action) -> Void in
                contact.userSelectedEmail = action.title
                completion?(contact)
            })
            return action
        })
        actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        let alert = UIAlertController(title: "Choose Email", message: "Which email would you like to use?", preferredStyle: .actionSheet)
        for act in actions {
            alert.addAction(act)
        }
        
        //show alert
        if let fromView = fromView {
            alert.popoverPresentationController?.sourceView = fromView
            alert.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        }
        else {
            alert.popoverPresentationController?.sourceView = self.view
        }
        
        present(alert, animated: true, completion: nil)
        alert.view.tintColor = view.tintColor
    }
    
    private func makeToken(contact: CNContact) -> CLToken? {
        guard let email = contact.userSelectedEmail else { return nil }
        let token = CLToken(displayText: email, context: contact)
        return token
    }
    
    private func filterContacts(withSearchText text: String) {
        let array = NSArray(array: self.contacts)
        
        let predicate = NSPredicate(format: "self.name.firstName contains[cd] %@ OR self.name.lastName contains[cd] %@", text, text)
        self.filteredContacts = array.filtered(using: predicate) as! [CNContact]
    }
    
    private func showNoAccessAlert(withError: NSError? = nil) {
        let msg = "This app might not have permission to show your contacts.\nTo allow this app to show your contacts, tap Settings and make sure Contacts is switched on. (\(withError?.localizedDescription ?? ""))."
        
        let alert = UIAlertController(title: "Error Loading Contacts", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(action)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    private func loadContacts() {
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
        
        
        
        let contactStore = CNContactStore()
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactPhoneNumbersKey as CNKeyDescriptor,
            CNContactImageDataAvailableKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor]
        
        // Get all the containers
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        // Iterate all containers and append their contacts to our results array
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                results += containerResults
            } catch {
                print("Error fetching results for container")
            }
        }
    }
}

// MARK: - Layout

extension EmailPickerViewController {
    private func addLayoutConstraints() {
        
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

// MARK: - Extensions



private extension String {
    var isEmail: Bool {
        return emailAddresses().count == 1
    }
    
    func emailAddresses() -> [String] {
        var addresses = [String]()
        if let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) {
            let matches = detector.matches(in: self, options: [], range: NSMakeRange(0, self.count))
            for match in matches {
                if let matchURL = match.url,
                    let matchURLComponents = URLComponents(url: matchURL, resolvingAgainstBaseURL: false),
                    matchURLComponents.scheme == "mailto" {
                    let address = matchURLComponents.path
                    addresses.append(String(address))
                }
            }
        }
        return addresses
    }
}

private var selectedEmailKey: UInt8 = 0
private extension CNContact {
    var userSelectedEmail: String? {
        get {
            return objc_getAssociatedObject(self, &selectedEmailKey) as? String
        }
        set(newValue) {
            objc_setAssociatedObject(self, &selectedEmailKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
        }
    }
}

// MARK: - Cell

class EmailPickerCell: UITableViewCell {
    @objc static let height: CGFloat = 60
    
    @IBOutlet weak var thumbnailImageView: UIImageView! {
        didSet {
            thumbnailImageView.layer.cornerRadius = 20
        }
    }
    @IBOutlet weak var label: UILabel!
}

// MARK: - UILabel Inset Subclass

class InsetLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        super.drawText(in: rect.inset(by: insets))
    }
}


















