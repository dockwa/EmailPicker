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
    
    @IBOutlet weak var contactsLabel: UILabel!
    @IBOutlet weak var selectContactsButton: UIButton!
    
}


//MARK: - UIKit

extension ViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func setupView() {
            contactsLabel.text = nil
        }
        setupView()
    }
    
    
}


//MARK: - IBAction

extension ViewController {
    
    @IBAction func selectContactsButtonTapped(sender: UIButton) {
        
        let handler: EmailPickerCompletion = {(result) in
            switch result {
            case .Cancelled(let vc):
                vc.dismissViewControllerAnimated(true) {
                    self.contactsLabel.text = "Cancelled!"
                }
                break
            case .Selected(let vc, let emails):
                vc.dismissViewControllerAnimated(true) {
                    self.contactsLabel.text = "Selected Emails: \(emails)"
                }
                break
            }
        }
        
        let picker = EmailPickerViewController.emailPickerModal("To share your fun test results with some loved ones, please type their emails or select their names from the list. Enjoy!", completion: handler)
        
        presentViewController(picker, animated: true, completion: nil)
    }
    
}