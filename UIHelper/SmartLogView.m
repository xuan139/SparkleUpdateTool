//
//  SmartLogView.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//

// SmartLogView.m
#import "SmartLogView.h"
#import "UITheme.h"

@interface SmartLogView ()
@property (nonatomic, strong) NSTextView *textView;
@end

@implementation SmartLogView

- (instancetype)init {
    self = [super initWithFrame:NSZeroRect];
    if (self) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.hasVerticalScroller = YES;
        self.borderType = NSBezelBorder;
        
        // 配置内部 TextView
        NSRect contentSize = NSMakeRect(0, 0, 100, 100);
        self.textView = [[NSTextView alloc] initWithFrame:contentSize];
        self.textView.minSize = NSMakeSize(0.0, contentSize.size.height);
        self.textView.maxSize = NSMakeSize(FLT_MAX, FLT_MAX);
        self.textView.verticallyResizable = YES;
        self.textView.horizontallyResizable = NO;
        self.textView.autoresizingMask = NSViewWidthSizable;
        self.textView.textContainer.containerSize = NSMakeSize(contentSize.size.width, FLT_MAX);
        self.textView.textContainer.widthTracksTextView = YES;
        
        self.textView.editable = NO;
        self.textView.font = [UITheme codeFont];
        self.textView.textColor = [NSColor labelColor];
        
        self.documentView = self.textView;
    }
    return self;
}

- (void)appendLog:(NSString *)message level:(LogLevel)level {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *fmt = [[NSDateFormatter alloc] init];
        fmt.dateFormat = @"HH:mm:ss";
        NSString *timestamp = [fmt stringFromDate:[NSDate date]];
        
        NSString *fullMsg = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        NSAttributedString *attrStr = [[NSAttributedString alloc] initWithString:fullMsg attributes:@{
            NSFontAttributeName: [UITheme codeFont],
            NSForegroundColorAttributeName: [self colorForLevel:level]
        }];
        
        [self.textView.textStorage appendAttributedString:attrStr];
        
        // ✅ 自动滚动到底部
        [self.textView scrollRangeToVisible:NSMakeRange(self.textView.string.length, 0)];
    });
}

- (void)clearLog {
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.textView setString:@""];
    });
}

- (NSColor *)colorForLevel:(LogLevel)level {
    switch (level) {
        case LogLevelSuccess: return [UITheme successColor];
        case LogLevelError:   return [UITheme errorColor];
        case LogLevelWarning: return [UITheme warningColor];
        default:              return [UITheme primaryColor];
    }
}

@end
