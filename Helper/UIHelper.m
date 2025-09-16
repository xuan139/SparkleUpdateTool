//
//  UIHelper.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/22/25.
//


// UIHelper.m
#import "UIHelper.h"

@implementation UIHelper

+ (NSTextField *)createLabelWithText:(NSString *)text frame:(NSRect)frame {
    NSTextField *label = [[NSTextField alloc] initWithFrame:frame];
    label.stringValue = text;
    label.bezeled = NO;
    label.drawsBackground = NO;
    label.editable = NO;
    label.selectable = NO;
    return label;
}

+ (NSTextField *)createPathFieldWithFrame:(NSRect)frame {
    NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
    field.editable = NO;
    return field;
}

+ (NSButton *)createButtonWithTitle:(NSString *)title
                             target:(id)target
                             action:(SEL)action
                              frame:(NSRect)frame {
    NSButton *button = [[NSButton alloc] initWithFrame:frame];
    button.title = title;
    button.target = target;
    button.action = action;
    return button;
}

+ (NSScrollView *)createLogTextViewWithFrame:(NSRect)frame textView:(NSTextView **)textView {
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:frame];
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSBezelBorder;

    NSTextView *logView = [[NSTextView alloc] initWithFrame:scrollView.bounds];
    logView.editable = NO;
    logView.font = [NSFont fontWithName:@"Menlo" size:14];
    scrollView.documentView = logView;

    if (textView) {
        *textView = logView;
    }

    return scrollView;
}

//+ (void)showSuccessAlertWithTitle:(NSString *)title message:(NSString *)message {
//    NSAlert *alert = [[NSAlert alloc] init];
//    alert.messageText = title ?: @"✅ Success";
//    alert.informativeText = message ?: @"Operation completed successfully.";
//    [alert addButtonWithTitle:@"OK"];
//    [alert runModal];
//}


+ (void)showSuccessAlertWithTitle:(NSString *)title message:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = title.length > 0 ? title : @"✅ Success";
        alert.informativeText = message.length > 0 ? message : @"Operation completed successfully.";
        [alert addButtonWithTitle:@"OK"];
        [alert runModal];
    });
}

@end
