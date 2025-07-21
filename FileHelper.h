//
//  FileHelper.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//


#import <Foundation/Foundation.h>

@interface FileHelper : NSObject
+ (NSString *)fullPathInDocuments:(NSString *)relativePath;
+ (NSString *)createDirectoryIfNeededAtPath:(NSString *)directoryPath
                                      error:(NSError **)error
                                   logBlock:(void (^)(NSString *log))logBlock;
+ (BOOL)prepareEmptyFileAtPath:(NSString *)filePath;
+ (BOOL)copyAllFilesFromDirectory:(NSString *)sourceDir toDirectory:(NSString *)destDir error:(NSError **)error;

+ (NSString *)zipAppAtPath:(NSString *)appPath logBlock:(void (^)(NSString *message))logBlock;
@end
