//
//  FileHelper.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//


#import <Foundation/Foundation.h>

@interface FileHelper : NSObject

+ (NSString *)replaceFileNameInPath:(NSString *)originalPath withNewName:(NSString *)newBaseName;
+ (NSString *)stripVersionFromAppName:(NSString *)appName;
+ (NSDictionary *)getAppVersionInfoFromPath:(NSString *)appPath
                                   logBlock:(void (^)(NSString *msg))logBlock;

+ (unsigned long long)fileSizeAtPath:(NSString *)filePath;
+ (NSString *)strfileSizeAtPath:(NSString *)filePath;
+ (NSString *)firstAppFileNameInPath:(NSString *)directoryPath;
+ (void)copyFileAtPath:(NSString *)sourceFilePath toDirectory:(NSString *)targetDir;
+ (NSString *)generateSubdirectory:(NSString *)subDirName;
+ (NSString *)fullPathInDocuments:(NSString *)relativePath;
+ (NSString *)createDirectoryIfNeededAtPath:(NSString *)directoryPath
                                      error:(NSError **)error
                                   logBlock:(void (^)(NSString *log))logBlock;
+ (BOOL)prepareEmptyFileAtPath:(NSString *)filePath;
+ (BOOL)copyAllFilesFromDirectory:(NSString *)sourceDir toDirectory:(NSString *)destDir error:(NSError **)error;

+ (NSString *)zipAppAtPath:(NSString *)appPath logBlock:(void (^)(NSString *message))logBlock;
@end
