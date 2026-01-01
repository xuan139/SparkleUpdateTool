//
//  UpdatePipelineManager.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 1/1/26.
//


//
//  UpdatePipelineManager.h
//  SparkleUpdateTool
//
//  Created by Refactoring Bot.
//

#import <Foundation/Foundation.h>
#import "UpdateGenerationConfig.h"

NS_ASSUME_NONNULL_BEGIN


typedef void(^PipelineLogBlock)(NSString *message, BOOL isError);
typedef void(^PipelineCompletionBlock)(BOOL success, NSString * _Nullable jsonPath, NSError * _Nullable error);

@interface UpdatePipelineManager : NSObject

+ (instancetype)sharedManager;

/**
 * 执行完整的更新生成流水线：
 * 1. 校验配置
 * 2. 生成 Delta (Diff)
 * 3. 复制文件到输出目录
 * 4. 压缩 New App (Zip)
 * 5. 生成 Appcast JSON
 *
 * @param config 配置对象
 * @param logBlock 过程日志回调 (可能在后台线程)
 * @param completion 完成回调 (包含最终的 JSON 路径)
 */
- (void)runPipelineWithConfig:(UpdateGenerationConfig *)config
                     logBlock:(PipelineLogBlock)logBlock
                   completion:(PipelineCompletionBlock)completion;

@end

NS_ASSUME_NONNULL_END
