# EmailPicker
![Powered by Dockwa](https://raw.githubusercontent.com/dockwa/openpixel/dockwa/by-dockwa.png)

[![Version](https://img.shields.io/cocoapods/v/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![License](https://img.shields.io/cocoapods/l/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)
[![Platform](https://img.shields.io/cocoapods/p/EmailPicker.svg?style=flat)](http://cocoapods.org/pods/EmailPicker)


## Example
![Sample](https://github.com/dockwa/EmailPicker/blob/master/Sample.gif)

To run the example project, clone the repo, and run `pod install` from the Example directory first.

## Usage
Create a new instance using the class method 
``` 
emailPickerModal(infoText: String?, completion: EmailPickerCompletion)
```
which returns a new EmailPicker instance wrapped in a UINavigationController to present modally. 

## Requirements
This is a Swift project and uses Swift specific features such as associated values on enums, so you cannot use this pod in an Objective-C project.

## Installation

EmailPicker is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'EmailPicker'
```

## Author

Christian Hatch, christianhatch@gmail.com

## License

EmailPicker is available under the MIT license. See the LICENSE file for more info.
