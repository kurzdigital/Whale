//
//  SIPKeyboardManager.m
//  KeyboardManager
//
//  Created by Hendrik von Prince on 07/03/16.
//  Copyright © 2016 Sipeso GmbH. All rights reserved.
//

#import "SIPKeyboardManager.h"

@interface UIView (RecursiveSubviews)
-(void)sip_callBlockRecursively:(void(^)(UIView *))block;
@end

@implementation UIView (RecursiveSubviews)
-(void)sip_callBlockRecursively:(void (^)(UIView *))block {
    for(UIView *subview in self.subviews) {
        block(subview);
        [subview sip_callBlockRecursively:block];
    }
}
@end

@interface SIPKeyboardTransitionInformation : NSObject
@property(nonatomic, strong) NSDate *timeStamp;
@property(nonatomic) CGRect keyboardFrame;

-(instancetype)initWithTimeStamp:(NSDate *)timeStamp keyboardFrame:(CGRect)keyboardFrame;
+(instancetype)informationWithTimeStamp:(NSDate *)timeStamp keyboardFrame:(CGRect)keyboardFrame;

@end

@implementation SIPKeyboardTransitionInformation
-(instancetype)initWithTimeStamp:(NSDate *)timeStamp keyboardFrame:(CGRect)keyboardFrame {
    self = [super init];
    if(self) {
        self.timeStamp = timeStamp;
        self.keyboardFrame = keyboardFrame;
    }

    return self;
}

+(instancetype)informationWithTimeStamp:(NSDate *)timeStamp keyboardFrame:(CGRect)keyboardFrame {
    return [[self alloc] initWithTimeStamp:timeStamp keyboardFrame:keyboardFrame];
}

@end

@interface SIPKeyboardManager()
@property(nonatomic, strong) SIPKeyboardTransitionInformation *transition;
@property(strong, nonatomic) NSTimer *timerToCheckKeyboardBounds;
@end

@implementation SIPKeyboardManager


- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardWillChangeFrameNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardFrameChange:) name:UIKeyboardDidChangeFrameNotification object:nil];
   }
    return self;
}

-(void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Keyboard callbacks

-(void)keyboardFrameChange:(NSNotification *)notification {
    NSDate *timeStamp = [NSDate date];
    
    // Ignore changes that are received within 10ms.
    // An analysis of the notifications showed that, when the keyboard fires multiple notifications in a row, the first contains the correct endFrame and the correct
    // animationDuration. The following notifications may either have a wrong endFrame or wrong animationDuration.
    if(self.transition.timeStamp && ([timeStamp timeIntervalSince1970] - [self.transition.timeStamp timeIntervalSince1970]) < 0.01) {
        return;
    }

    NSValue *boundsInfoValue = notification.userInfo[@"UIKeyboardBoundsUserInfoKey"];
    CGRect boundsInfo = [boundsInfoValue CGRectValue];
    if(boundsInfoValue && CGRectEqualToRect(boundsInfo, CGRectZero)) {
        // most probably: this notification is sent while an undocked keyboard is getting moved and contains no useful informations
        return;
    }
    
    NSDictionary *transitionInformationFromNotification = notification.userInfo;
    const NSTimeInterval duration = [transitionInformationFromNotification[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGRect endFrame = [transitionInformationFromNotification[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    
    // As we only use a heuristic to guess which notification might be the right one,
    // we set up a timer that will call -[SIPKeyboardManager checkKeyboardBounds] which gets the current
    // keyboardframe (when it is visible) and fire an update in case that the new keyboardframe differs
    // from the last known frame.
    if(duration > 0 || self.timerToCheckKeyboardBounds == nil) {
        NSDate *animationFinishedDate = [NSDate dateWithTimeIntervalSinceNow:duration];
        if(self.timerToCheckKeyboardBounds == nil ||
           self.timerToCheckKeyboardBounds.valid == NO ||
           [animationFinishedDate compare:self.timerToCheckKeyboardBounds.fireDate] == NSOrderedDescending) {
            [self.timerToCheckKeyboardBounds invalidate];
            self.timerToCheckKeyboardBounds = [NSTimer scheduledTimerWithTimeInterval:duration target:self selector:@selector(checkKeyboardBounds) userInfo:nil repeats:NO];
        }
    }

    // radar 25032907
    // When a custom keyboard is being used, the keyboard-frame reported in the notifications are just wrong.
    // This code tries to find the keyboard-view by traversing the windows and views.
    // To find the view, we use the class-names of private-API which may change and break this mechanism.
    // The worst case that can happen when this mechanism breaks is, that the keyboard-frame is not correctly detected.
    if([notification.name isEqualToString:UIKeyboardDidChangeFrameNotification]) {
        const CGRect keyboardFrame = [SIPKeyboardManager tryToFindFrameOfKeyboard];
        if(CGRectIsNull(keyboardFrame) == NO) {
            endFrame = keyboardFrame;
        }
    }

    SIPKeyboardTransitionInformation *transitionInformation = [SIPKeyboardTransitionInformation informationWithTimeStamp:timeStamp
                                                                                                           keyboardFrame:endFrame];

    // only send an update when the previous position is different
    if(self.transition == nil || CGRectEqualToRect(self.transition.keyboardFrame, transitionInformation.keyboardFrame) == NO) {
        [self.delegate keyboardManager:self updatingKeyboardFrameTo:endFrame withAnimationDuration:duration];
    }

    self.transition = transitionInformation;
}

/**
 *  Should only be called from the timer self.tiemrToCheckKeyboardBounds.
 *  Gets the current keyboard-frame (when it is visible) and fires an update to the delegate
 *  when it is different to the last fired delegate-call.
 */
-(void)checkKeyboardBounds {
    self.timerToCheckKeyboardBounds = nil;
    const CGRect currentKeyboardFrame = [SIPKeyboardManager tryToFindFrameOfKeyboard];
    if(CGRectIsNull(currentKeyboardFrame)) {
        return;
    }
    
    if(self.transition == nil || CGRectEqualToRect(self.transition.keyboardFrame, currentKeyboardFrame) == NO) {
        [self.delegate keyboardManager:self updatingKeyboardFrameTo:currentKeyboardFrame withAnimationDuration:0];
    }
}

/**
 *  Traverses the windows to find the keyboard-window and searches for the actual keyboard-view.
 *  @return     The frame of the keyboard when it is found, otherwise CGRectNull.
 */
+(CGRect)tryToFindFrameOfKeyboard {
    __block CGRect result = CGRectNull;
    for(UIWindow *window in [UIApplication sharedApplication].windows.reverseObjectEnumerator) {
        // When the keyboard is used while the iPad gets rotated, it may leak an UIRemoteKeyboardWindow that remains open but is hidden. (FEEDTOGO-6522)
        // So, there may be multiple UIRemoteKeyboardWindows, while the invalid ones are hopefully invisible and we will ignore them.
        if(window.hidden == false && [NSStringFromClass([window class]) isEqualToString:@"UIRemoteKeyboardWindow"]) {
            [window sip_callBlockRecursively:^(UIView *view) {
                // If there are multiple UIRemoteKeyboardWindows
                if([NSStringFromClass([view class]) isEqualToString:@"UIInputSetHostView"] && view.bounds.size.width > 0 && view.bounds.size.height > 0) {
                    result = view.frame;
                }
            }];
            break;
        }
    }
    
    return result;
}

@end
