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
        case selected([Email])
        case cancelled
    }
    
    public typealias Completion = (Result, EmailPickerViewController) -> Void

    // MARK: - Properties
    
    private lazy var tokenInputView: CLTokenInputView = {
        let view = CLTokenInputView()
        view.delegate = self
        view.placeholderText = "Enter an email address"
        view.drawBottomBorder = true
        view.tokenizationCharacters = [" ", ","]
        return view
    }()
    private lazy var tableView: UITableView = {
        let table = UITableView()
        table.register(EmailPickerCell.self, forCellReuseIdentifier: EmailPickerCell.reuseIdentifier)
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
    private var selectedContacts: [CNContact] = [] {
        didSet {
            if #available(iOS 13.0, *) {
                isModalInPresentation = !selectedContacts.isEmpty
            }
        }
    }
    private let completion: Completion
    private let infoText: String?
    private let showPermissionAlertAutomatically: Bool
    
    
    // MARK: - Init
    
    /**
     This is the prefered method to create a new EmailPicker. Use this method and present modally.
     
     - parameter infoText:   This is the text that will appear at the top of the EmailPicker. Use this to provide additional instructions or context for your users.
     - parameter doneButtonTitle: This is the title of the right bar button item, used to finish selecting emails.
     - parameter showPermissionAlert: This is the title of the right bar button item, used to finish selecting emails.
     - parameter completion: The completion closure to handle the selected emails.
     
     - returns: Returns an EmailPicker.
     */
    public init(infoText: String? = nil, doneButtonTitle: String = "Done", showPermissionAlert: Bool = true, completion: @escaping Completion) {
        self.completion = completion
        self.infoText = infoText
        self.showPermissionAlertAutomatically = showPermissionAlert
        super.init(nibName: nil, bundle: nil)
        navigationItem.title = "Select Contacts"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: doneButtonTitle, style: .done, target: self, action: #selector(done))
        if #available(iOS 13.0, *) {
            view.backgroundColor = .systemBackground
            tokenInputView.backgroundColor = .systemBackground
        } else {
            view.backgroundColor = .white
            tokenInputView.backgroundColor = .white
        }
        
        if let text = infoText, !text.isEmpty {
            view.addSubview(infoLabel)
            infoLabel.text = text
        }
        
        view.addSubview(tokenInputView)
        view.addSubview(tableView)
        view.insertSubview(loadingSpinner, aboveSubview: tableView)
        
        addLayoutConstraints()
    }
    public required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - UIKit

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        loadContacts()
    }
    
    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        if !tokenInputView.isEditing {
            tokenInputView.beginEditing()
        }
        
        if #available(iOS 13.0, *) {
            view.backgroundColor = UIColor.systemBackground
            infoLabel.textColor = UIColor.label
        }
    }
    
    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        tokenInputView.endEditing()
    }

    @objc private func cancel() {
        completion(.cancelled, self)
    }
    
    @objc private func done() {
        tokenInputView.tokenizeTextfieldText()
        completion(.selected(selectedContacts.compactMap { $0.userSelectedEmail }), self)
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
        } else {
            if text.isEmail {
                let contact = CNContact()
                contact.userSelectedEmail = text
                let token = CLToken(displayText: contact.userSelectedEmail!, context: contact)
                return token
            }
        }
        return nil
    }

    public func tokenInputView(_ view: CLTokenInputView, didChangeHeightTo height: CGFloat) {
        tokenHeightConstraint?.constant = height
    }

    public func tokenInputViewDidEndEditing(_ view: CLTokenInputView) { }
    
    public func tokenInputViewDidBeginEditing(_ view: CLTokenInputView) { }
}

// MARK: - TableView DataSource

extension EmailPickerViewController: UITableViewDataSource {
    
    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return EmailPickerCell.height
    }
    
    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return filteredContacts.count
    }
    
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "EmailPickerCell") as! EmailPickerCell
        let contact = filteredContacts[indexPath.row]
        let isSelected = selectedContacts.contains(contact)
        cell.thumbnailImageView.image = contact.thumbnailImage
        cell.label.text = contact.displayString
        cell.accessoryType = isSelected ? .checkmark : .none
        if #available(iOS 13.0, *) {
            cell.label.textColor = UIColor.label
        }
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
            guard let token = CLToken(contact: contact) else { return }
            tokenInputView.remove(token)
        } else { //we don't have it, lets select it
            selectPreferedEmail(for: contact, fromView: tableView.cellForRow(at: indexPath)?.contentView, completion: { contact in
                guard let token = CLToken(contact: contact) else { return }
                self.tokenInputView.add(token)
            })
        }
    }
}

// MARK: - Helpers

extension EmailPickerViewController {
    
    public func showPermissionAlert(error: NSError? = nil) {
        let msg = "\(Bundle.name ?? "This app") does not have permission to show your contacts.\nTo allow \(Bundle.name ?? "this app") to show your contacts, tap Settings and make sure Contacts is switched on. (\(error?.localizedDescription ?? ""))."
        let alert = UIAlertController(title: "Error Loading Contacts", message: msg, preferredStyle: .alert)
        let action = UIAlertAction(title: "Settings", style: .default, handler: { (action) in
            UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!, options: [:], completionHandler: nil)
        })
        let cancel = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(action)
        alert.addAction(cancel)
        present(alert, animated: true, completion: nil)
    }

    private func selectPreferedEmail(for contact: CNContact, fromView: UIView?, completion: ((CNContact) -> Void)?) {
        let mails = contact.emailAddresses
        guard mails.count > 1 else {
            if let email = mails.first?.value {
                contact.userSelectedEmail = email as String
                completion?(contact)
            }
            return
        }

        var actions = mails.compactMap{$0.value as String}.map({ (email) -> UIAlertAction in
            let action = UIAlertAction(title: email, style: .default, handler: { action in
                contact.userSelectedEmail = action.title
                completion?(contact)
            })
            return action
        })
        actions.append(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))

        let alert = UIAlertController(title: "Choose Email", message: "Which email would you like to use?", preferredStyle: .actionSheet)
        actions.forEach { alert.addAction($0) } 

        if let fromView = fromView {
            alert.popoverPresentationController?.sourceView = fromView
            alert.popoverPresentationController?.permittedArrowDirections = [.up, .down]
        } else {
            alert.popoverPresentationController?.sourceView = view
        }
        present(alert, animated: true, completion: nil)
        alert.view.tintColor = view.tintColor
    }
    
    private func filterContacts(withSearchText text: String) {
        let array = NSArray(array: contacts)
        let predicate = NSPredicate(format: "self.givenName contains[cd] %@ OR self.familyName contains[cd] %@", text, text)
        let filtered = array.filtered(using: predicate) as! [CNContact]
        filteredContacts = filtered.sorted(by: { (lhs, rhs) -> Bool in
            return lhs.givenName < rhs.givenName
        })
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
        
        let keysToFetch: [CNKeyDescriptor] = [
            CNContactGivenNameKey as CNKeyDescriptor,
            CNContactFamilyNameKey as CNKeyDescriptor,
            CNContactEmailAddressesKey as CNKeyDescriptor,
            CNContactThumbnailImageDataKey as CNKeyDescriptor]

        showLoading()
        CNContactStore.fetchAllContacts(keysToFetch: keysToFetch, filter: { !$0.emailAddresses.isEmpty }) { (results, error) in
            finishLoading()
            if let error = error {
                if self.showPermissionAlertAutomatically {
                    self.showPermissionAlert(error: error)
                }
            } else if let results = results {
                self.contacts = results.sorted(by: { (lhs, rhs) -> Bool in
                    return lhs.givenName < rhs.givenName
                })
                self.filteredContacts = self.contacts
                self.tableView.reloadData()
            }
        }
    }
}

// MARK: - Layout

extension EmailPickerViewController {
    private func addLayoutConstraints() {
        func addConstraintsForInfoLabel() {
            infoLabel.translatesAutoresizingMaskIntoConstraints = false
            let top = NSLayoutConstraint(item: infoLabel, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0)
            let left = NSLayoutConstraint(item: infoLabel, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
            let right = NSLayoutConstraint(item: infoLabel, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
            let height = NSLayoutConstraint(item: infoLabel, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: 60)
            infoLabel.addConstraint(height)
            view.addConstraints([top, left, right])
        }
        
        func addConstraintsForTokenInputView() {
            tokenInputView.translatesAutoresizingMaskIntoConstraints = false
            
            if let text = infoText , !text.isEmpty {
                let top = NSLayoutConstraint(item: tokenInputView, attribute: .top, relatedBy: .equal, toItem: infoLabel, attribute: .bottom, multiplier: 1, constant: 0)
                let left = NSLayoutConstraint(item: tokenInputView, attribute: .leading, relatedBy: .equal, toItem: view, attribute: .leading, multiplier: 1, constant: 0)
                let right = NSLayoutConstraint(item: tokenInputView, attribute: .trailing, relatedBy: .equal, toItem: view, attribute: .trailing, multiplier: 1, constant: 0)
                
                let heightConstant = tokenHeightConstraint?.constant ?? 45
                let height = NSLayoutConstraint(item: tokenInputView, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .height, multiplier: 1, constant: heightConstant)
                tokenHeightConstraint = height
                
                tokenInputView.addConstraint(height)
                view.addConstraints([top, left, right])
            } else {
                let top = NSLayoutConstraint(item: tokenInputView, attribute: .top, relatedBy: .equal, toItem: view.safeAreaLayoutGuide, attribute: .top, multiplier: 1, constant: 0)
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
        
        if let text = infoText , !text.isEmpty {
            addConstraintsForInfoLabel()
        }
        addConstraintsForTokenInputView()
        addConstraintsForTableView()
        addConstraintsForLoadingSpinner()
    }
}

// MARK: - UILabel Inset Subclass

class InsetLabel: UILabel {
    override func drawText(in rect: CGRect) {
        let insets = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        super.drawText(in: rect.inset(by: insets))
    }
}

// MARK: - Extensions

private var selectedEmailKey: UInt8 = 0
private extension CNContact {
    var userSelectedEmail: String? {
        get { return objc_getAssociatedObject(self, &selectedEmailKey) as? String }
        set { objc_setAssociatedObject(self, &selectedEmailKey, newValue, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN) }
    }

    var displayString: String {
        guard !givenName.isEmpty || !familyName.isEmpty else {
            if let email = emailAddresses.first?.value {
                return email as String
            }
            return ""
        }
        return "\(givenName) \(familyName)"
    }
    
    var thumbnailImage: UIImage? {
        guard let data = thumbnailImageData else { return nil }
        return UIImage(data: data)
    }
}

private extension CNContactStore {
    static func fetchAllContacts(keysToFetch: [CNKeyDescriptor], filter: ((CNContact) -> Bool)? = nil, completion: @escaping (([CNContact]?, NSError?) -> Void)) {
        DispatchQueue.global(qos: .utility).async {
            let contactStore = CNContactStore()
            var allContainers: [CNContainer] = []
            do {
                allContainers = try contactStore.containers(matching: nil)
            } catch {
                DispatchQueue.main.async {
                    completion(nil, error as NSError)
                }
            }
            var results: [CNContact] = []
            for container in allContainers {
                let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
                do {
                    let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch)
                    results += containerResults
                } catch {
                    DispatchQueue.main.async {
                        completion(nil, error as NSError)
                    }
                }
            }
            if let filter = filter {
                results = results.filter(filter)
            }
            DispatchQueue.main.async {
                completion(results, nil)
            }
        }
    }
}

private extension CLToken {
    convenience init?(contact: CNContact) {
        guard let email = contact.userSelectedEmail else { return nil }
        self.init(displayText: email, context: contact)
    }
}

private extension String {
    var isEmail: Bool {
        emailAddresses().count == 1
    }
    
    func emailAddresses() -> [String] {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue) else { return [] }
        let matches = detector.matches(in: self, options: [], range: NSRange(location: 0, length: count))
        return matches.compactMap { (match) -> String? in
            guard let matchURL = match.url,
                  let matchURLComponents = URLComponents(url: matchURL, resolvingAgainstBaseURL: false),
                  matchURLComponents.scheme == "mailto"
            else { return nil }
            return matchURLComponents.path
        }
    }
}

private extension Bundle {
    static var name: String? {
        if let display = Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String {
            return display
        } else if let name = Bundle.main.object(forInfoDictionaryKey: "CFBundleName") as? String {
            return name
        }
        return nil
    }
}
