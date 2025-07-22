//
//  FileHelper.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//


#import "FileHelper.h"

@implementation FileHelper


+ (NSString *)firstAppFileNameInPath:(NSString *)directoryPath {
    // 获取文件管理器

    // 提取并返回文件名
    return [directoryPath lastPathComponent];
}



+ (void)copyFileAtPath:(NSString *)sourceFilePath toDirectory:(NSString *)targetDir {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 获取文件名（不含路径）
    NSString *fileName = [sourceFilePath lastPathComponent];
    NSString *targetPath = [targetDir stringByAppendingPathComponent:fileName];
    
    // 如果目标文件存在，先删除
    if ([fileManager fileExistsAtPath:targetPath]) {
        [fileManager removeItemAtPath:targetPath error:nil];
    }
    
    NSError *copyError = nil;
    [fileManager copyItemAtPath:sourceFilePath toPath:targetPath error:&copyError];
    if (copyError) {
        NSLog(@"❌ 复制文件失败 %@ -> %@ 错误: %@", sourceFilePath, targetPath, copyError.localizedDescription);
    } else {
        NSLog(@"✅ 复制文件 %@ 到 %@", sourceFilePath, targetPath);
    }
}

+ (NSString *)generateSubdirectory:(NSString *)subDirName {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fullPath = [documentsPath stringByAppendingPathComponent:subDirName];

    // 如果目录不存在则创建
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:fullPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"❌ 创建目录失败: %@", error.localizedDescription);
            return nil;
        }
    }
    return fullPath;
}

+ (NSString *)fullPathInDocuments:(NSString *)relativePath {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docsDir stringByAppendingPathComponent:relativePath];
}


+ (NSString *)createDirectoryIfNeededAtPath:(NSString *)directoryPath
                                      error:(NSError **)error
                                   logBlock:(void (^)(NSString *log))logBlock {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;

    BOOL exists = [fm fileExistsAtPath:directoryPath isDirectory:&isDir];

    if (exists) {
        if (!isDir) {
            // 已存在同名文件，删除它
            if (![fm removeItemAtPath:directoryPath error:error]) {
                if (logBlock) logBlock([NSString stringWithFormat:@"❌ 删除已有同名文件失败: %@", (*error).localizedDescription]);
                return nil;
            }
            if (logBlock) logBlock(@"⚠️ 已存在同名文件，已删除");
        } else {
            if (logBlock) logBlock([NSString stringWithFormat:@"✅ 目录已存在: %@", directoryPath]);
            return directoryPath;
        }
    }

    // 创建目录
    BOOL success = [fm createDirectoryAtPath:directoryPath
                  withIntermediateDirectories:YES
                                   attributes:nil
                                        error:error];
    if (success) {
        if (logBlock) logBlock([NSString stringWithFormat:@"✅ 创建目录成功: %@", directoryPath]);
        return directoryPath;
    } else {
        if (logBlock) logBlock([NSString stringWithFormat:@"❌ 创建目录失败: %@", (*error).localizedDescription]);
        return nil;
    }
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

+ (NSString *)zipAppAtPath:(NSString *)appPath logBlock:(void (^)(NSString *message))logBlock {
    if (![[NSFileManager defaultManager] fileExistsAtPath:appPath]) {
        logBlock(@"❌ 要压缩的 .app 文件不存在");
        return nil;
    }

    NSString *appName = [[appPath lastPathComponent] stringByDeletingPathExtension];
    NSString *appDirectory = [appPath stringByDeletingLastPathComponent];
    NSString *zipPath = [appDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", appName]];

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/zip";
    task.currentDirectoryPath = appDirectory;
    task.arguments = @[@"-r", zipPath, [appPath lastPathComponent]];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    NSFileHandle *readHandle = [pipe fileHandleForReading];

    logBlock([NSString stringWithFormat:@"📦 开始压缩 %@ → %@", appPath, zipPath]);

    task.terminationHandler = ^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            // 可选：打印 zip 命令输出
            // logBlock(output);

            if (finishedTask.terminationStatus == 0) {
                logBlock(@"✅ 压缩完成");
            } else {
                logBlock(@"❌ 压缩失败");
            }
        });
    };

    [task launch];

    return zipPath;
}

@end

