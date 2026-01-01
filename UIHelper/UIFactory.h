//
//  UIFactory.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//


// UIFactory.h
#import <Cocoa/Cocoa.h>

@interface UIFactory : NSObject

/// 标准标签
+ (NSTextField *)labelWithText:(NSString *)text;

/// 路径显示框 (可选中、中间截断、Tooltip)
+ (NSTextField *)pathDisplayFieldWithPlaceholder:(NSString *)placeholder;

/// 动作按钮
+ (NSButton *)buttonWithTitle:(NSString *)title target:(id)target action:(SEL)action;

/// 主动作按钮 (蓝色高亮，回车默认)
+ (NSButton *)primaryButtonWithTitle:(NSString *)title target:(id)target action:(SEL)action;

@end

