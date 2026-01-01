//
//  UIFactory.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//


// UIFactory.m
#import "UIFactory.h"
#import "UITheme.h"

@implementation UIFactory

+ (NSTextField *)labelWithText:(NSString *)text {
    NSTextField *label = [NSTextField labelWithString:NSLocalizedString(text, nil)];
    label.font = [UITheme labelFont];
    label.textColor = [UITheme primaryColor];
    label.translatesAutoresizingMaskIntoConstraints = NO;
    
    // A11y
    label.accessibilityLabel = text;
    label.accessibilityRole = NSAccessibilityStaticTextRole;
    
    return label;
}

+ (NSTextField *)pathDisplayFieldWithPlaceholder:(NSString *)placeholder {
    NSTextField *field = [[NSTextField alloc] init];
    field.font = [UITheme codeFont];
    field.placeholderString = NSLocalizedString(placeholder ?: @"", nil);
    field.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 产品细节优化：
    field.editable = NO;
    field.selectable = YES; // ✅ 允许用户复制路径
    field.bezeled = YES;
    field.bezelStyle = NSTextFieldSquareBezel;
    field.drawsBackground = YES;
    field.lineBreakMode = NSLineBreakByTruncatingMiddle; // ✅ 长路径中间省略: /Users/.../App.app
    field.toolTip = placeholder; // ✅ 鼠标悬停显示完整路径
    
    // 布局优先级：水平方向易拉伸，垂直固定
    [field setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    return field;
}

+ (NSButton *)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    NSButton *btn = [NSButton buttonWithTitle:NSLocalizedString(title, nil) target:target action:action];
    btn.bezelStyle = NSBezelStyleRounded;
    btn.font = [UITheme labelFont];
    btn.translatesAutoresizingMaskIntoConstraints = NO;
    return btn;
}

+ (NSButton *)primaryButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action {
    NSButton *btn = [self buttonWithTitle:title target:target action:action];
    btn.keyEquivalent = @"\r"; // ✅ 支持回车键触发
    return btn;
}

@end
