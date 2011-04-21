//
//  AppDelegate.h
//  LocalPush
//

#import <UIKit/UIKit.h>

@interface AppDelegate : NSObject <UIApplicationDelegate> {
    UIWindow *window;
    UIBackgroundTaskIdentifier bgTask;
}

@property (nonatomic, retain) UIWindow *window;

- (void) _showAlert:(NSString*)pushmessage withTitle:(NSString*)title;
- (void)scheduleNotificationWithItem:(ToDoItem *)item interval:(int)minutesBefore;

@end
