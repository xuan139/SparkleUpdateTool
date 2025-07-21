//
//  SparkleHelper.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//


#import "SparkleHelper.h"

@implementation SparkleHelper

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
                    outputPath:(NSString *)outputPath {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/binarydelta";
    task.arguments = @[@"create", oldPath, newPath, outputPath];

    // 捕获输出
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        NSLog(@"❌ Failed to launch binarydelta create: %@", exception.reason);
        return NO;
    }

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    if (task.terminationStatus == 0) {
        NSLog(@"✅ Delta created successfully at: %@", outputPath);
        return YES;
    } else {
        NSLog(@"❌ Failed to create delta.\n%@", output);
        return NO;
    }
}


+ (BOOL)applyDelta:(NSString *)deltaPath toOldZip:(NSString *)oldZip outputPath:(NSString *)newAppPath {
    // 创建 NSTask
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/local/bin/binarydelta";
    task.arguments = @[@"apply", oldZip, deltaPath, newAppPath];

    // 捕获输出
    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    @try {
        [task launch];
        [task waitUntilExit];
    } @catch (NSException *exception) {
        NSLog(@"❌ Failed to launch binarydelta apply: %@", exception.reason);
        return NO;
    }

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    if (task.terminationStatus == 0) {
        NSLog(@"✅ Applied delta successfully. Output at: %@", newAppPath);
        return YES;
    } else {
        NSLog(@"❌ Failed to apply delta.\n%@", output);
        return NO;
    }
}

+ (NSString *)signFileAtPath:(NSString *)path withKey:(NSString *)privateKeyPath {
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
        NSLog(@"❌ Failed to launch sign_update: %@", exception.reason);
        return nil;
    }

    NSData *outputData = [[pipe fileHandleForReading] readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    // 使用正则提取签名，格式如：Signature: AbcdEf123==
    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"Signature: ([^\\s]+)" options:0 error:&error];
    if (error) {
        NSLog(@"❌ Regex error: %@", error.localizedDescription);
        return nil;
    }

    NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];
    if (match && [match numberOfRanges] > 1) {
        NSString *signature = [output substringWithRange:[match rangeAtIndex:1]];
        NSLog(@"🔐 Signature: %@", signature);
        return signature;
    } else {
        NSLog(@"❌ Signature not found in output:\n%@", output);
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
