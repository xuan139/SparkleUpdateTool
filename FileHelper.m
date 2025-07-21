//
//  FileHelper.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//


#import "FileHelper.h"

@implementation FileHelper



+ (NSString *)fullPathInDocuments:(NSString *)relativePath {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docsDir stringByAppendingPathComponent:relativePath];
}


+ (NSString *)createDirectoryAtPath:(NSString *)directoryPath error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:directoryPath]) {
        BOOL success = [fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:error];
        if (!success) {
            return nil;
        }
    }
    return directoryPath; // 成功创建或已存在，返回路径
}

+ (BOOL)prepareEmptyFileAtPath:(NSString *)filePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 获取目录部分
    NSString *directory = [filePath stringByDeletingLastPathComponent];
    
    // 创建目录（如果不存在）
    if (![fm fileExistsAtPath:directory]) {
        NSError *dirError = nil;
        BOOL createdDir = [fm createDirectoryAtPath:directory
                         withIntermediateDirectories:YES
                                          attributes:nil
                                               error:&dirError];
        if (!createdDir) {
            NSLog(@"❌ Failed to create directory: %@", dirError);
            return NO;
        }
    }
    
    // 删除旧文件（如果存在）
    if ([fm fileExistsAtPath:filePath]) {
        NSError *removeError = nil;
        if (![fm removeItemAtPath:filePath error:&removeError]) {
            NSLog(@"❌ Failed to remove old file: %@", removeError);
            return NO;
        }
    }

    // 创建空文件
    BOOL created = [fm createFileAtPath:filePath contents:[NSData data] attributes:nil];
    if (!created) {
        NSLog(@"❌ Failed to create file at path: %@", filePath);
    }
    return created;
}


+ (BOOL)copyAllFilesFromDirectory:(NSString *)sourceDir toDirectory:(NSString *)destDir error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 确保目标目录存在
    if (![fm fileExistsAtPath:destDir]) {
        BOOL created = [fm createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:nil error:error];
        if (!created) return NO;
    }
    
    NSArray<NSString *> *files = [fm contentsOfDirectoryAtPath:sourceDir error:error];
    if (!files) return NO;
    
    for (NSString *fileName in files) {
        NSString *srcPath = [sourceDir stringByAppendingPathComponent:fileName];
        NSString *dstPath = [destDir stringByAppendingPathComponent:fileName];
        
        // 如果目标文件已存在，先删除
        if ([fm fileExistsAtPath:dstPath]) {
            BOOL removed = [fm removeItemAtPath:dstPath error:error];
            if (!removed) return NO;
        }
        
        BOOL copied = [fm copyItemAtPath:srcPath toPath:dstPath error:error];
        if (!copied) return NO;
    }
    
    return YES;
}


@end
