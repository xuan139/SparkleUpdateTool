//
//  BinaryDeltaManager.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 8/30/25.
//
//  Production Refactoring
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

// 定义错误域
FOUNDATION_EXPORT NSErrorDomain const BinaryDeltaErrorDomain;

// 定义错误码
typedef NS_ERROR_ENUM(BinaryDeltaErrorDomain, BinaryDeltaErrorCode) {
    BinaryDeltaErrorToolNotFound     = 1001,
    BinaryDeltaErrorPermissionDenied = 1002,
    BinaryDeltaErrorTaskFailed       = 1003,
    BinaryDeltaErrorCancelled        = 1004
};

@interface BinaryDeltaManager : NSObject

/**
 * 异步执行 BinaryDelta 操作（支持实时日志和健壮的错误处理）
 *
 * @param args       命令行参数数组（不包含可执行文件路径）
 * @param logBlock   实时日志回调（保证在主线程执行）
 * @param completion 完成回调（success: 是否成功, error: 详细错误信息）
 * @return           返回 NSTask 对象，以便外部可以调用 [task interrupt] 取消任务
 */
+ (nullable NSTask *)runCommandWithArgs:(NSArray<NSString *> *)args
                               logBlock:(void (^)(NSString *log))logBlock
                             completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

// 快捷方法：生成补丁
+ (nullable NSTask *)createDeltaFromOldPath:(NSString *)oldPath
                                  toNewPath:(NSString *)newPath
                                 outputPath:(NSString *)outputPath
                                   logBlock:(void (^)(NSString *log))logBlock
                                 completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

// 快捷方法：应用补丁
+ (nullable NSTask *)applyDelta:(NSString *)deltaPath
                       toOldDir:(NSString *)oldDir
                       toNewDir:(NSString *)newDir
                       logBlock:(void (^)(NSString *log))logBlock
                     completion:(void (^)(BOOL success, NSError * _Nullable error))completion;

@end

NS_ASSUME_NONNULL_END
