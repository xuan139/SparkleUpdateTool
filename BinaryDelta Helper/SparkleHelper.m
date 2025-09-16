//
//  SparkleHelper.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//


#import "SparkleHelper.h"

@implementation SparkleHelper

+ (BOOL)checkAndDownloadBinaryDeltaFromURL:(NSURL *)downloadURL {
    NSString *binaryDeltaPath = @"/usr/local/bin/BinaryDelta";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 如果已存在
    if ([fileManager fileExistsAtPath:binaryDeltaPath]) {
        NSLog(@"✅ BinaryDelta exists: %@", binaryDeltaPath);
        return YES;
    }
    
    // 确保目标目录存在
    NSString *directory = [binaryDeltaPath stringByDeletingLastPathComponent];
    NSError *dirError;
    [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&dirError];
    if (dirError) {
        NSLog(@"❌ Failed to create directory: %@", dirError.localizedDescription);
        return NO;
    }
    
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success = NO;
    
    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession]
        downloadTaskWithURL:downloadURL
          completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"❌ Download failed: %@", error.localizedDescription);
            dispatch_semaphore_signal(semaphore);
            return;
        }

        NSError *moveError;
        [fileManager moveItemAtURL:location
                             toURL:[NSURL fileURLWithPath:binaryDeltaPath]
                             error:&moveError];
        if (moveError) {
            NSLog(@"❌ Move failed: %@", moveError.localizedDescription);
            dispatch_semaphore_signal(semaphore);
            return;
        }

        // 设置可执行权限
        NSError *permError;
        [fileManager setAttributes:@{NSFilePosixPermissions: @(0755)}
                     ofItemAtPath:binaryDeltaPath
                            error:&permError];
        if (permError) {
            NSLog(@"❌ Set permission failed: %@", permError.localizedDescription);
            dispatch_semaphore_signal(semaphore);
            return;
        }

        // 移除 Gatekeeper 限制
        NSTask *xattrTask = [[NSTask alloc] init];
        xattrTask.launchPath = @"/usr/bin/xattr";
        xattrTask.arguments = @[@"-cr", binaryDeltaPath];
        [xattrTask launch];
        [xattrTask waitUntilExit];

        NSTask *spctlTask = [[NSTask alloc] init];
        spctlTask.launchPath = @"/usr/sbin/spctl";
        spctlTask.arguments = @[@"--add", binaryDeltaPath];
        [spctlTask launch];
        [spctlTask waitUntilExit];

        NSLog(@"✅ BinaryDelta installed at: %@", binaryDeltaPath);
        success = YES;
        dispatch_semaphore_signal(semaphore);
    }];
    
    [task resume];
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    
    return success;
}
+ (void)generateKeys {
    NSString *generateKeysPath = @"/usr/local/bin/generate_keys";
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:generateKeysPath]) {
        NSLog(@"❌ generate_keys not found at %@", generateKeysPath);
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = generateKeysPath;

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;
    NSFileHandle *readHandle = pipe.fileHandleForReading;

    [task setTerminationHandler:^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            NSLog(@"✅ generate_keys output:\n%@", output);

            // 提取 SUPublicEDKey 字符串
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<string>(.*?)</string>" options:0 error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];

            if (match && match.numberOfRanges >= 2) {
                NSString *pubKey = [output substringWithRange:[match rangeAtIndex:1]];
                NSLog(@"🔑 SUPublicEDKey: %@", pubKey);
            } else {
                NSLog(@"⚠️ Failed to extract SUPublicEDKey");
            }
        });
    }];

    [task launch];
}

+ (NSString *)getPublicKey {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/generate_keys";

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        NSLog(@"❌ Failed to launch generate_keys: %@", exception.reason);
        return nil;
    }

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    // 查找 <string>...</string> 中的内容
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<string>([^<]+)</string>" options:0 error:nil];
    NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];

    if (match && match.numberOfRanges >= 2) {
        NSString *publicKey = [output substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"🔑 SUPublicEDKey: %@", publicKey);
        return publicKey;
    } else {
        NSLog(@"❌ Failed to extract public key from output:\n%@", output);
        return nil;
    }
}

+ (BOOL)createDeltaFromOldPath:(NSString *)oldPath
                     toNewPath:(NSString *)newPath
                    outputPath:(NSString *)outputPath
                      logBlock:(void (^)(NSString *log))logBlock {

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/binarydelta";
    task.arguments = @[@"create", @"--verbose", oldPath, newPath, outputPath];

//    task.arguments = @[@"apply", @"--verbose", oldDir, newDir, deltaPath];
    
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        logBlock([NSString stringWithFormat:@"❌ Failed to launch binarydelta: %@", exception.reason]);
        return NO;
    }

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    if (task.terminationStatus == 0) {
        logBlock([NSString stringWithFormat:@"✅ Delta created successfully at: %@", outputPath]);
        return YES;
    } else {
        logBlock([NSString stringWithFormat:@"❌ Failed to create delta.\n%@", output]);
        return NO;
    }
}


+ (BOOL)applyDelta:(NSString *)deltaPath
         toOldDir:(NSString *)oldDir
         toNewDir:(NSString *)newDir
         logBlock:(void (^)(NSString *log))logBlock {

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/binarydelta";
    task.arguments = @[@"apply", @"--verbose", oldDir, newDir, deltaPath];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        NSString *errorMsg = [NSString stringWithFormat:@"❌ Failed to launch binarydelta apply: %@", exception.reason];
        if (logBlock) logBlock(errorMsg);
        return NO;
    }

    NSData *outputData = [readHandle readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    if (logBlock) logBlock(output);

    if (task.terminationStatus == 0) {
        if (logBlock) logBlock([NSString stringWithFormat:@"✅ 应用 delta 成功: %@", newDir]);
        return YES;
    } else {
        if (logBlock) logBlock([NSString stringWithFormat:@"❌ 应用 delta 失败\n%@", output]);
        return NO;
    }
}


+ (NSString *)signFileAtPath:(NSString *)path
                     withKey:(NSString *)privateKeyPath
                    logBlock:(void (^)(NSString *log))logBlock {

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/sign_update";
    task.arguments = @[ @"sign", path, privateKeyPath ];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        logBlock([NSString stringWithFormat:@"❌ Failed to launch sign_update: %@", exception.reason]);
        return nil;
    }

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    // 使用正则提取签名，格式如：Signature: AbcdEf123==
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Signature: ([^\\s]+)" options:0 error:&error];
    if (error) {
        logBlock([NSString stringWithFormat:@"❌ Regex error: %@", error.localizedDescription]);
        return nil;
    }

    NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];
    if (match && [match numberOfRanges] > 1) {
        NSString *signature = [output substringWithRange:[match rangeAtIndex:1]];
        logBlock([NSString stringWithFormat:@"🔐 Signature: %@", signature]);
        return signature;
    } else {
        logBlock([NSString stringWithFormat:@"❌ Signature not found in output:\n%@", output]);
        return nil;
    }
}

+ (BOOL)verifyFileAtPath:(NSString *)path signature:(NSString *)sig publicKey:(NSString *)pubKeyPath {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/sign_update";
    task.arguments = @[ @"verify", path, sig, pubKeyPath ];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        NSLog(@"❌ Failed to launch sign_update verify: %@", exception.reason);
        return NO;
    }

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    if ([task terminationStatus] == 0) {
        NSLog(@"✅ Verify success: %@", output);
        return YES;
    } else {
        NSLog(@"❌ Verify failed: %@", output);
        return NO;
    }
}



@end
