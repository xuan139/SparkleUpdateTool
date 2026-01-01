//
//  UITheme.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//


// UITheme.m
#import "UITheme.h"

@implementation UITheme

+ (NSFont *)labelFont { return [NSFont systemFontOfSize:13 weight:NSFontWeightRegular]; }
+ (NSFont *)boldLabelFont { return [NSFont systemFontOfSize:13 weight:NSFontWeightBold]; }
+ (NSFont *)codeFont { return [NSFont monospacedSystemFontOfSize:12 weight:NSFontWeightRegular]; }

+ (NSColor *)primaryColor { return [NSColor labelColor]; }
+ (NSColor *)successColor { return [NSColor systemGreenColor]; }
+ (NSColor *)errorColor { return [NSColor systemRedColor]; }
+ (NSColor *)warningColor { return [NSColor systemOrangeColor]; }

@end
