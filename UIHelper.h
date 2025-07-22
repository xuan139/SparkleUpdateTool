//
//  UIHelper.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/22/25.
//


// UIHelper.h
#import <Cocoa/Cocoa.h>

@interface UIHelper : NSObject

+ (NSTextField *)createLabelWithText:(NSString *)text frame:(NSRect)frame;
+ (NSTextField *)createPathFieldWithFrame:(NSRect)frame;
+ (NSButton *)createButtonWithTitle:(NSString *)title
                             target:(id)target
                             action:(SEL)action
                              frame:(NSRect)frame;
+ (NSScrollView *)createLogTextViewWithFrame:(NSRect)frame textView:(NSTextView **)textView;


@end
