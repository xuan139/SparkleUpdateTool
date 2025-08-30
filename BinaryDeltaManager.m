//
//  BinaryDeltaManager.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 8/30/25.
//

#import "BinaryDeltaManager.h"

@implementation BinaryDeltaManager

+ (NSString *)binaryDeltaPath {
    NSString *appSupportDir = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) firstObject];
    NSString *yourAppDir = [appSupportDir stringByAppendingPathComponent:@"OStation"];
    NSString *destPath = [yourAppDir stringByAppendingPathComponent:@"BinaryDelta"];

    if ([[NSFileManager defaultManager] fileExistsAtPath:destPath]) return destPath;

    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:@"BinaryDelta" ofType:nil];
    if (!bundlePath) return nil;

    NSError *error = nil;
    if (![[NSFileManager defaultManager] fileExistsAtPath:yourAppDir]) {
        [[NSFileManager defaultManager] createDirectoryAtPath:yourAppDir
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        if (error) return nil;
    }

    [[NSFileManager defaultManager] copyItemAtPath:bundlePath toPath:destPath error:&error];
    if (error) return nil;

    [[NSFileManager defaultManager] setAttributes:@{NSFilePosixPermissions: @0755} ofItemAtPath:destPath error:&error];
    if (error) return nil;

    return destPath;
}

+ (BOOL)createDeltaFromOldPath:(NSString *)oldPath
                     toNewPath:(NSString *)newPath
                    outputPath:(NSString *)outputPath
                      logBlock:(void (^)(NSString *log))logBlock {

    NSTask *task = [[NSTask alloc] init];
    NSString *path = [self binaryDeltaPath];
    if (path == nil){
        return NO;
    }
    task.launchPath = path;
    task.arguments = @[@"create", @"--verbose", oldPath, newPath, outputPath];
   
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
    NSString *path = [self binaryDeltaPath];
    if (path == nil){
        return NO;
    }
    task.launchPath = path;
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


@end
