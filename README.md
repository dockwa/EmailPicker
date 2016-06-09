# EmailPicker
[![Powered by Dockwa](https://raw.githubusercontent.com/dockwa/openpixel/dockwa/by-dockwa.png)](https://engineering.dockwa.com/)

[![Version](https://img.shields.io/cocoapods/v/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![License](https://img.shields.io/cocoapods/l/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![Platform](https://img.shields.io/cocoapods/p/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)


## Example
![Sample](https://github.com/dockwa/EmailPicker/blob/master/Sample.gif)

To test out EmailPicker, just run `pod try EmailPicker` from your terminal, or clone the repo, and run `pod install` from the Example directory. 

## Usage
Create a new instance using the class method 
```swift
class func emailPickerModal(infoText: String? = nil, completion: EmailPickerCompletion) -> UINavigationController
```
which returns a new EmailPicker instance wrapped in a UINavigationController to present modally. 

Check out the example project for a usage example, like this: 

```swift
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

let picker = EmailPickerViewController.emailPickerModal("To share your fun results with some friends, please type their emails or select their names from the list. Enjoy!", completion: handler)
        
presentViewController(picker, animated: true, completion: nil)
```

## Requirements
This is a Swift project and uses Swift specific features such as associated values on enums, so you cannot use this pod in an Objective-C project.

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
