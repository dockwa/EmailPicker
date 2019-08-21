//
//  ViewController.swift
//  EmailPicker
//
//  Created by Christian Hatch on 05/19/2016.
//  Copyright (c) 2016 Christian Hatch. All rights reserved.
//

import UIKit
import EmailPicker

class ViewController: UIViewController {
    
    @IBOutlet weak var contactsLabel: UILabel! {
        didSet {
            contactsLabel.text = nil
        }
    }
    @IBOutlet weak var selectContactsButton: UIButton!
    
    @IBAction func selectContactsButtonTapped(_ sender: UIButton) {
        let textToShow = "To share your fun results with some friends, please type their emails or select their names from the list. Enjoy!"
        let picker = EmailPickerViewController(infoText: textToShow, doneButtonTitle: "Send", completion: {(result) in
            switch result {
            case .cancelled(let vc):
                vc.dismiss(animated: true) {
                    self.contactsLabel.text = "Cancelled!"
                }
                
            case .selected(let vc, let emails):
                vc.dismiss(animated: true) {
                    self.contactsLabel.text = "Selected Emails: \(emails)"
                }
            }
        })
        picker.view.tintColor = .red
        present(UINavigationController(rootViewController: picker), animated: true, completion: nil)
    }
}
