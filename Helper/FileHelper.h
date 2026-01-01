
//
//  FileHelper.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//  Optimized: Removed legacy methods, unified file operations.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN // 开启非空检查，更安全

@interface FileHelper : NSObject

// --- 路径与名称处理 ---
+ (nullable NSString *)replaceFileNameInPath:(NSString *)originalPath withNewName:(NSString *)newBaseName;
+ (nullable NSString *)stripVersionFromAppName:(NSString *)appName;
+ (NSString *)firstAppFileNameInPath:(NSString *)directoryPath;

// --- 目录管理 ---
+ (nullable NSString *)generateSubdirectory:(NSString *)subDirName;
+ (NSString *)fullPathInDocuments:(NSString *)relativePath;
+ (nullable NSString *)createDirectoryIfNeededAtPath:(NSString *)directoryPath
                                               error:(NSError **)error
                                            logBlock:(void (^_Nullable)(NSString *log))logBlock;

// --- 文件操作 ---
+ (void)copyFileAtPath:(NSString *)sourceFilePath toDirectory:(NSString *)targetDir;
+ (BOOL)prepareEmptyFileAtPath:(NSString *)filePath;
+ (BOOL)copyAllFilesFromDirectory:(NSString *)sourceDir toDirectory:(NSString *)destDir error:(NSError **)error;

// --- 信息获取 ---
+ (nullable NSDictionary *)getAppVersionInfoFromPath:(NSString *)appPath
                                            logBlock:(void (^_Nullable)(NSString *msg))logBlock;

// 获取文件大小 (返回数字)
+ (unsigned long long)fileSizeAtPath:(NSString *)filePath;
// 获取文件大小 (返回字符串)
+ (NSString *)strfileSizeAtPath:(NSString *)filePath;

// --- 压缩操作 ---
/**
 * 压缩 App 为 Zip 文件
 * @param appPath .app 文件的完整路径
 * @param logBlock 日志回调 (可能在后台线程)
 * @param completion 完成回调，返回 zip 文件路径
 */
+ (void)zipAppAtPath:(NSString *)appPath
            logBlock:(void (^_Nullable)(NSString *message))logBlock
          completion:(void (^_Nullable)(NSString *zipFilePath))completion;

@end

NS_ASSUME_NONNULL_END
