# EmailPicker
[![Powered by Dockwa](https://raw.githubusercontent.com/dockwa/openpixel/dockwa/by-dockwa.png)](https://engineering.dockwa.com/)

[![Version](https://img.shields.io/cocoapods/v/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![License](https://img.shields.io/cocoapods/l/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![Platform](https://img.shields.io/cocoapods/p/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)

## What It Is

EmailPicker is a simple Swift 3 viewcontroller to easily select emails from a user's contacts and/or enter them manually. Great for sharing content or inviting users.

## Example
![Sample](https://github.com/dockwa/EmailPicker/blob/master/Sample.gif)

To test out EmailPicker, just run `pod try EmailPicker` from your terminal, or clone the repo, and run `pod install` from the Example directory. 

## Usage
Check out the example project for a usage example, like this: 

```swift
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
present(UINavigationController(rootViewController: picker), animated: true, completion: nil)
```

## Requirements
Swift 4.0

This is a Swift project and uses Swift specific features such as associated values on enums, so you cannot use this pod in Objective-C.

## Installation

EmailPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EmailPicker'
```

## Author

Christian Hatch, [@commodoreftp](https://twitter.com/Commodoreftp)

## License

EmailPicker is available under the MIT license. See the LICENSE file for more info.
