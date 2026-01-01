//
//  AlertPresenter.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//


// AlertPresenter.m
#import "AlertPresenter.h"

@implementation AlertPresenter

+ (void)showSuccess:(NSString *)message inWindow:(NSWindow *)window {
    [self showAlertWithTitle:NSLocalizedString(@"Success", nil)
                     message:message
                       style:NSAlertStyleInformational
                    inWindow:window];
}

+ (void)showError:(NSString *)errorMsg inWindow:(NSWindow *)window {
    [self showAlertWithTitle:NSLocalizedString(@"Error", nil)
                     message:errorMsg
                       style:NSAlertStyleCritical
                    inWindow:window];
}

+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                     style:(NSAlertStyle)style
                  inWindow:(NSWindow *)window {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = title;
        alert.informativeText = message;
        alert.alertStyle = style;
        [alert addButtonWithTitle:NSLocalizedString(@"OK", nil)];
        
        // ✅ 现代交互：如果有窗口，使用 Sheet 下滑；没有则回退到 Modal
        if (window) {
            [alert beginSheetModalForWindow:window completionHandler:nil];
        } else {
            [alert runModal];
        }
    });
}

@end
