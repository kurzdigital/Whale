//
//  SIPKeyboardManager.h
//  KeyboardManager
//
//  Created by Hendrik von Prince on 07/03/16.
//  Copyright © 2016 Sipeso GmbH. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SIPKeyboardManager;

@protocol SIPKeyboardManagerDelegate <NSObject>
-(void)keyboardManager:(nonnull SIPKeyboardManager *)keyboardManager updatingKeyboardFrameTo:(CGRect)keyboardFrame withAnimationDuration:(NSTimeInterval)animationDuration;
@end

/**
 Notifies its delegate when the keyboard-frame changes. It is not able to catch all cases (like, when the keyboard is undocked and the
 layout changes from English (US) to Chinese Simplified Handwriting, the frame changes but the delegate won't fire because of 
 http://www.openradar.me/25056255 ), but most of them.
 */
@interface SIPKeyboardManager : NSObject
@property(nonatomic, weak) id<SIPKeyboardManagerDelegate> delegate;

@end
