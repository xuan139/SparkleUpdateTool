//
//  UITheme.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//


// UITheme.h
#import <Cocoa/Cocoa.h>

@interface UITheme : NSObject

// 字体系统
+ (NSFont *)labelFont;
+ (NSFont *)boldLabelFont;
+ (NSFont *)codeFont; // 用于 Path 和 Log

// 颜色系统
+ (NSColor *)primaryColor;
+ (NSColor *)successColor;
+ (NSColor *)errorColor;
+ (NSColor *)warningColor;

@end


