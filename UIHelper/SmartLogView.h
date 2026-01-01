//
//  SmartLogView.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 12/31/25.
//


// SmartLogView.h
#import <Cocoa/Cocoa.h>

typedef NS_ENUM(NSInteger, LogLevel) {
    LogLevelInfo,
    LogLevelSuccess,
    LogLevelError,
    LogLevelWarning
};

@interface SmartLogView : NSScrollView

/// 追加日志（自动处理颜色、时间戳、自动滚动）
- (void)appendLog:(NSString *)message level:(LogLevel)level;

/// 清空日志
- (void)clearLog;

@end

