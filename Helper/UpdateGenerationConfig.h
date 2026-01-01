//
//  UpdateGenerationConfig.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 1/1/26.
//


//
//  UpdateGenerationConfig.h
//  SparkleUpdateTool
//
//  Created by Refactoring Bot.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface UpdateGenerationConfig : NSObject

// --- 核心输入参数 ---
@property (nonatomic, copy) NSString *oldAppPath;

// [修正] 改名为 latestAppPath，避免 Cocoa "new" 命名规范冲突
@property (nonatomic, copy) NSString *latestAppPath;

@property (nonatomic, copy) NSString *outputDirectory;
@property (nonatomic, copy) NSString *deltaFilename; // 例如: "update.delta"

// --- 自动解析的元数据 (只读) ---
@property (nonatomic, copy, readonly) NSString *appName;
@property (nonatomic, copy, readonly) NSString *oldVersion;
@property (nonatomic, copy, readonly) NSString *latestVersion; // 对应 latestAppPath 的版本

/**
 * 校验必要参数 (路径是否为空)
 */
- (BOOL)validate:(NSError **)error;

/**
 * 根据路径自动解析 App 的 info.plist 获取版本号和名称
 * 建议在设置完 Path 后调用此方法
 */
- (void)parseAppMetadata;

@end

NS_ASSUME_NONNULL_END
