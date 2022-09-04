# EmailPicker
[![Powered by Dockwa](https://raw.githubusercontent.com/dockwa/openpixel/dockwa/by-dockwa.png)](https://engineering.dockwa.com/)

[![Version](https://img.shields.io/cocoapods/v/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![License](https://img.shields.io/cocoapods/l/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![Platform](https://img.shields.io/cocoapods/p/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)

## What It Is

EmailPicker is a simple Swift viewcontroller to easily select emails from a user's contacts and/or enter them manually. Great for sharing content or inviting users.

## Example
![Sample](https://github.com/dockwa/EmailPicker/blob/main/Example/Sample.gif)

To test out EmailPicker, just run `pod try EmailPicker` from your terminal, or clone the repo, and run `pod install` from the Example directory. 

## Usage
Check out the example project for a usage example, like this: 

```swift
let textToShow = "To share your fun results with some friends, please type their emails or select their names from the list. Enjoy!"
let picker = EmailPickerViewController(infoText: textToShow, doneButtonTitle: "Send", completion: {(result, vc) in
    vc.dismiss(animated: true) {
        switch result {
        case .selected(let emails):
            self.contactsLabel.text = "Selected Emails: \(emails)"
        case .cancelled:
            self.contactsLabel.text = "Cancelled!"
        }
    }
})
present(UINavigationController(rootViewController: picker), animated: true, completion: nil)
```

## Requirements
Swift 5.1
iOS 11.4

This is a Swift project and uses Swift specific features such as associated values on enums, so you cannot use this pod in Objective-C.

If you need backwards compatibility to iOS 8.0, use version 1.5.0 of this library.  

## Installation

### Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler.

Once you have your Swift package set up, adding SimpleImageSlider as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/dockwa/EmailPicker", .upToNextMajor(from: "4.0.0"))
]
```

### CocoaPods

EmailPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EmailPicker'
```

## Author

Christian Hatch, [@commodoreftp](https://twitter.com/Commodoreftp)

## License

EmailPicker is available under the MIT license. See the LICENSE file for more info.
