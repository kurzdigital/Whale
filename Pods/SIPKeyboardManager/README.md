# SIPKeyboardManager

## Description
SIPKeyboardManager sends out informations about the current keyboard-frame via delegate

The notifications sent by iOS-keyboards can be misleading - willShow-notifications are sent out multiple times with different rects, it might miss sending a notification with the final keyboard-rect at all.
This class tries to handle all the cases and ensure that you will receive the correct keyboard-frame if possible.

## Requirements

## Installation

SIPKeyboardManager is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'SIPKeyboardManager'
```

## Author

Hendrik von Prince, raise.rescue@gmail.com

## License

SIPKeyboardManager is available under the MIT license. See the LICENSE file for more info.
