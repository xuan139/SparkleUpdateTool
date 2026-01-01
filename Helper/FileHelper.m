//
//  FileHelper.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//

#import "FileHelper.h"

@implementation FileHelper

#pragma mark - Path & Name Utilities

+ (NSString *)replaceFileNameInPath:(NSString *)originalPath withNewName:(NSString *)newBaseName {
    if (!originalPath.length || !newBaseName.length) return nil;
    
    NSString *directory = [originalPath stringByDeletingLastPathComponent];
    NSString *ext = [originalPath pathExtension];
    NSString *newFileName = [NSString stringWithFormat:@"%@.%@", newBaseName, ext];
    return [directory stringByAppendingPathComponent:newFileName];
}

+ (NSString *)stripVersionFromAppName:(NSString *)appName {
    if (!appName.length) return nil;
    
    NSError *error = nil;
    // 匹配结尾的 "-数字.数字..."
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"-\\d+(\\.\\d+)*$" options:0 error:&error];
    if (error) {
        NSLog(@"[FileHelper] Regex Error: %@", error.localizedDescription);
        return appName;
    }
    return [regex stringByReplacingMatchesInString:appName options:0 range:NSMakeRange(0, appName.length) withTemplate:@""];
}

+ (NSString *)firstAppFileNameInPath:(NSString *)directoryPath {
    return [directoryPath lastPathComponent];
}

+ (NSString *)fullPathInDocuments:(NSString *)relativePath {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    return [docsDir stringByAppendingPathComponent:relativePath];
}

#pragma mark - Directory Management

+ (NSString *)generateSubdirectory:(NSString *)subDirName {
    NSString *fullPath = [self fullPathInDocuments:subDirName];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:fullPath]) {
        NSError *error = nil;
        if (![fm createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:&error]) {
            NSLog(@"[FileHelper] ❌ Failed to create dir: %@", error.localizedDescription);
            return nil;
        }
    }
    return fullPath;
}

+ (NSString *)createDirectoryIfNeededAtPath:(NSString *)directoryPath
                                      error:(NSError **)error
                                   logBlock:(void (^)(NSString *))logBlock {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if ([fm fileExistsAtPath:directoryPath isDirectory:&isDir]) {
        if (!isDir) {
            // 存在同名文件，删除
            if (![fm removeItemAtPath:directoryPath error:error]) {
                if (logBlock) logBlock([NSString stringWithFormat:@"❌ Failed to remove existing file: %@", (*error).localizedDescription]);
                return nil;
            }
            if (logBlock) logBlock(@"⚠️ Removed existing file with same name.");
        } else {
            if (logBlock) logBlock([NSString stringWithFormat:@"✅ Directory already exists: %@", directoryPath]);
            return directoryPath;
        }
    }

    if ([fm createDirectoryAtPath:directoryPath withIntermediateDirectories:YES attributes:nil error:error]) {
        if (logBlock) logBlock([NSString stringWithFormat:@"✅ Created directory: %@", directoryPath]);
        return directoryPath;
    } else {
        if (logBlock) logBlock([NSString stringWithFormat:@"❌ Failed to create directory: %@", (*error).localizedDescription]);
        return nil;
    }
}

#pragma mark - File Operations

+ (void)copyFileAtPath:(NSString *)sourceFilePath toDirectory:(NSString *)targetDir {
    if (!sourceFilePath || !targetDir) return;

    NSFileManager *fm = [NSFileManager defaultManager];
    NSString *fileName = [sourceFilePath lastPathComponent];
    NSString *targetPath = [targetDir stringByAppendingPathComponent:fileName];
    
    // 如果存在先删除
    if ([fm fileExistsAtPath:targetPath]) {
        [fm removeItemAtPath:targetPath error:nil];
    }
    
    NSError *error = nil;
    if ([fm copyItemAtPath:sourceFilePath toPath:targetPath error:&error]) {
        NSLog(@"[FileHelper] ✅ Copied %@ to %@", fileName, targetDir);
    } else {
        NSLog(@"[FileHelper] ❌ Copy failed: %@", error.localizedDescription);
    }
}

+ (BOOL)prepareEmptyFileAtPath:(NSString *)filePath {
    if (!filePath.length) return NO;
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 确保父目录存在
    NSString *directory = [filePath stringByDeletingLastPathComponent];
    if (![fm fileExistsAtPath:directory]) {
        [fm createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:nil];
    }
    
    // 删除旧文件
    if ([fm fileExistsAtPath:filePath]) {
        [fm removeItemAtPath:filePath error:nil];
    }

    // 创建空文件
    return [fm createFileAtPath:filePath contents:[NSData data] attributes:nil];
}

+ (BOOL)copyAllFilesFromDirectory:(NSString *)sourceDir toDirectory:(NSString *)destDir error:(NSError **)error {
    NSFileManager *fm = [NSFileManager defaultManager];
    
    if (![fm fileExistsAtPath:destDir]) {
        if (![fm createDirectoryAtPath:destDir withIntermediateDirectories:YES attributes:nil error:error]) return NO;
    }
    
    NSArray *files = [fm contentsOfDirectoryAtPath:sourceDir error:error];
    if (!files) return NO;
    
    for (NSString *fileName in files) {
        // 跳过 .DS_Store
        if ([fileName isEqualToString:@".DS_Store"]) continue;

        NSString *src = [sourceDir stringByAppendingPathComponent:fileName];
        NSString *dst = [destDir stringByAppendingPathComponent:fileName];
        
        if ([fm fileExistsAtPath:dst]) {
            [fm removeItemAtPath:dst error:nil];
        }
        
        if (![fm copyItemAtPath:src toPath:dst error:error]) return NO;
    }
    return YES;
}

#pragma mark - App Info & Size

+ (NSDictionary *)getAppVersionInfoFromPath:(NSString *)appPath
                                   logBlock:(void (^)(NSString *))logBlock {
    if (!appPath) return nil;

    NSString *plistPath = [appPath stringByAppendingPathComponent:@"Contents/Info.plist"];
    NSDictionary *info = [NSDictionary dictionaryWithContentsOfFile:plistPath];

    if (!info) {
        if (logBlock) logBlock([NSString stringWithFormat:@"❌ Cannot read Info.plist at %@", plistPath]);
        return nil;
    }

    if (logBlock) logBlock([NSString stringWithFormat:@"✅ Read Info.plist: %@", plistPath]);

    return @{
        @"appName": info[@"CFBundleName"] ?: info[@"CFBundleExecutable"] ?: @"Unknown",
        @"version": info[@"CFBundleShortVersionString"] ?: @"",
        @"build": info[@"CFBundleVersion"] ?: @""
    };
}

+ (NSString *)strfileSizeAtPath:(NSString *)filePath {
    // 复用逻辑
    return [NSString stringWithFormat:@"%llu", [self fileSizeAtPath:filePath]];
}

+ (unsigned long long)fileSizeAtPath:(NSString *)filePath {
    NSFileManager *fm = [NSFileManager defaultManager];
    BOOL isDir = NO;
    if (![fm fileExistsAtPath:filePath isDirectory:&isDir]) return 0;
    
    if (!isDir) {
        return [[fm attributesOfItemAtPath:filePath error:nil] fileSize];
    }
    
    // 文件夹递归计算
    unsigned long long total = 0;
    NSDirectoryEnumerator *enumerator = [fm enumeratorAtURL:[NSURL fileURLWithPath:filePath]
                                 includingPropertiesForKeys:@[NSURLTotalFileSizeKey]
                                                    options:NSDirectoryEnumerationSkipsHiddenFiles
                                               errorHandler:nil];
    for (NSURL *url in enumerator) {
        NSNumber *size = nil;
        [url getResourceValue:&size forKey:NSURLTotalFileSizeKey error:nil];
        total += size.unsignedLongLongValue;
    }
    return total;
}

#pragma mark - Compression

+ (void)zipAppAtPath:(NSString *)appPath
            logBlock:(void (^)(NSString *))logBlock
          completion:(void (^)(NSString *))completion {
    
    if (!appPath.length) {
        if (logBlock) logBlock(@"❌ Zip failed: Path is empty.");
        if (completion) completion(nil);
        return;
    }
    
    NSString *dir = [appPath stringByDeletingLastPathComponent];
    NSString *name = [appPath lastPathComponent];
    NSString *zipPath = [dir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", name]];
    
    // 使用全局队列异步执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/zip";
        // -r 递归, -y 保留符号链接 (对 .app 很重要), -q 静默模式
        task.arguments = @[@"-r", @"-y", @"-q", zipPath, name];
        task.currentDirectoryPath = dir;
        
        @try {
            [task launch];
            [task waitUntilExit];
            
            if (task.terminationStatus == 0) {
                if (logBlock) logBlock([NSString stringWithFormat:@"📦 Zip created: %@", zipPath]);
                if (completion) completion(zipPath);
            } else {
                if (logBlock) logBlock([NSString stringWithFormat:@"❌ Zip command failed with code: %d", task.terminationStatus]);
                if (completion) completion(nil);
            }
        } @catch (NSException *e) {
            if (logBlock) logBlock([NSString stringWithFormat:@"❌ Zip exception: %@", e]);
            if (completion) completion(nil);
        }
    });
}

@end
