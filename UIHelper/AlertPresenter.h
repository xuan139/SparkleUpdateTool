//
//  AlertPresenter.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//


// AlertPresenter.h
#import <Cocoa/Cocoa.h>

@interface AlertPresenter : NSObject

/// 显示成功提示 (优先 Sheet)
+ (void)showSuccess:(NSString *)message inWindow:(NSWindow *)window;

/// 显示错误提示 (优先 Sheet)
+ (void)showError:(NSString *)errorMsg inWindow:(NSWindow *)window;

/// 通用提示
+ (void)showAlertWithTitle:(NSString *)title
                   message:(NSString *)message
                     style:(NSAlertStyle)style
                  inWindow:(NSWindow *)window;

@end

