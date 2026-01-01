//
//  BinaryDeltaManager.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 8/30/25.
//
//  Production Refactoring
//


//改进详解（Why is this better?）
//真正的实时性 (readabilityHandler)：
//旧代码：readDataToEndOfFile 会等到任务彻底跑完，缓冲区关闭后才一次性吐出几万行日志。如果生成补丁需要 1 分钟，用户这 1 分钟内看到的是界面静止。
//新代码：操作系统内核缓冲区只要有数据，Block 就会被调用。你可以看到 bsdiff 的实时进度百分比（如果有输出的话）。
//优雅的线程模型 (terminationHandler)：
//旧代码：dispatch_async 里套 [task waitUntilExit]。这意味着你必须占用一个 GCD 线程一直傻等着任务结束。如果并发任务多，线程池会枯竭。
//新代码：terminationHandler 是基于系统内核信号（SIGCHLD）的机制。任务运行时不占用任何应用的后台线程，只有结束那一瞬间才会回调。这是最高效的进程管理方式。
//支持取消 (return NSTask *)：
//我在接口返回了 NSTask *。如果在 UI 上加一个 "Cancel" 按钮，你只需要调用 [task interrupt]，进程就会优雅退出。旧代码是“发射后不管”，无法中途停止。
//更合理的文件策略 (Library/Caches)：
//使用 NSTemporaryDirectory() 的风险是 macOS 可能会在磁盘空间不足或重启时清理它。
//使用 Library/Caches/com.sparkletool.bin 是标准的 macOS 缓存做法，既持久又不会污染用户文档。

#import "BinaryDeltaManager.h"

NSErrorDomain const BinaryDeltaErrorDomain = @"com.sparkletool.binarydelta";

@implementation BinaryDeltaManager

#pragma mark - Public Methods

+ (nullable NSTask *)createDeltaFromOldPath:(NSString *)oldPath
                                  toNewPath:(NSString *)newPath
                                 outputPath:(NSString *)outputPath
                                   logBlock:(void (^)(NSString *log))logBlock
                                 completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    // 参数校验
    if (!oldPath || !newPath || !outputPath) {
        if (completion) completion(NO, [NSError errorWithDomain:BinaryDeltaErrorDomain code:BinaryDeltaErrorTaskFailed userInfo:@{NSLocalizedDescriptionKey: @"Invalid arguments."}]);
        return nil;
    }

    // BinaryDelta create <old> <new> <output> --verbose
    // 注意：我们将 verbose 放在最后，或者根据工具习惯。通常放在前面比较安全，但你之前测试放在参数里是对的。
    // 根据你上次成功的经验：create --verbose <old> <new> <output>
    NSArray *args = @[@"create", @"--verbose", oldPath, newPath, outputPath];
    
    return [self runCommandWithArgs:args logBlock:logBlock completion:completion];
}

+ (nullable NSTask *)applyDelta:(NSString *)deltaPath
                       toOldDir:(NSString *)oldDir
                       toNewDir:(NSString *)newDir
                       logBlock:(void (^)(NSString *log))logBlock
                     completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    NSArray *args = @[@"apply", @"--verbose", oldDir, newDir, deltaPath];
    return [self runCommandWithArgs:args logBlock:logBlock completion:completion];
}

#pragma mark - Core Execution Engine

+ (nullable NSTask *)runCommandWithArgs:(NSArray<NSString *> *)args
                               logBlock:(void (^)(NSString *log))logBlock
                             completion:(void (^)(BOOL success, NSError * _Nullable error))completion {
    
    // 1. 准备工具 (主线程快速检查，IO开销极小)
    NSError *toolError = nil;
    NSString *toolPath = [self prepareToolPathWithError:&toolError];
    
    if (!toolPath) {
        if (logBlock) logBlock([NSString stringWithFormat:@"❌ Tool Error: %@", toolError.localizedDescription]);
        if (completion) completion(NO, toolError);
        return nil;
    }

    // 2. 初始化 Task
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = toolPath;
    task.arguments = args;
    
    // 3. 配置管道和实时读取 (Real-time Logging)
    NSPipe *outputPipe = [NSPipe pipe];
    task.standardOutput = outputPipe;
    task.standardError = outputPipe; // 合并 stderr 到 stdout
    
    NSFileHandle *readHandle = [outputPipe fileHandleForReading];
    
    // 使用 readabilityHandler 进行异步流式读取
    // 优点：不阻塞任何线程，数据一来就处理，完美支持进度条
    readHandle.readabilityHandler = ^(NSFileHandle *handle) {
        NSData *data = [handle availableData];
        if (data.length == 0) return; // EOF
        
        NSString *logStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (logStr && logStr.length > 0) {
            // 回调主线程更新 UI
            dispatch_async(dispatch_get_main_queue(), ^{
                if (logBlock) logBlock([logStr stringByTrimmingCharactersInSet:[NSCharacterSet newlineCharacterSet]]);
            });
        }
    };

    // 4. 配置终止回调 (Process Termination)
    task.terminationHandler = ^(NSTask *completedTask) {
        // 清理 readabilityHandler，防止内存泄漏或野指针
        readHandle.readabilityHandler = nil;
        
        int status = completedTask.terminationStatus;
        BOOL success = (status == 0);
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success) {
                if (completion) completion(YES, nil);
            } else {
                NSString *errorMsg = [NSString stringWithFormat:@"Task exited with code %d", status];
                NSError *error = [NSError errorWithDomain:BinaryDeltaErrorDomain
                                                     code:BinaryDeltaErrorTaskFailed
                                                 userInfo:@{NSLocalizedDescriptionKey: errorMsg}];
                if (completion) completion(NO, error);
            }
        });
    };

    // 5. 启动任务
    NSError *launchError = nil;
    if (![task launchAndReturnError:&launchError]) {
        // 启动失败，手动触发清理和回调
        readHandle.readabilityHandler = nil;
        if (logBlock) logBlock([NSString stringWithFormat:@"❌ Launch Failed: %@", launchError.localizedDescription]);
        if (completion) completion(NO, launchError);
        return nil;
    }
    
    return task; // 返回 task 实例，以便支持取消操作
}

#pragma mark - Tool Management Strategy

+ (NSString *)prepareToolPathWithError:(NSError **)error {
    NSString *toolName = @"BinaryDelta";
    
    // 1. 查找缓存目录 (Library/Caches 比较稳定，不会像 tmp 那样重启即失)
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *cacheDir = [paths firstObject];
    NSString *toolDir = [cacheDir stringByAppendingPathComponent:@"com.sparkletool.bin"];
    NSString *executablePath = [toolDir stringByAppendingPathComponent:toolName];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    
    // 2. 检查缓存中是否已存在
    // 改进思路：生产环境应该校验 Hash 或 Bundle 版本，这里暂用简单的存在性校验
    if ([fm fileExistsAtPath:executablePath]) {
        return executablePath;
    }
    
    // 3. 不存在则从 Bundle 拷贝
    NSString *bundlePath = [[NSBundle mainBundle] pathForResource:toolName ofType:nil];
    if (!bundlePath) {
        if (error) *error = [NSError errorWithDomain:BinaryDeltaErrorDomain code:BinaryDeltaErrorToolNotFound userInfo:@{NSLocalizedDescriptionKey: @"BinaryDelta tool missing in Bundle."}];
        return nil;
    }
    
    // 4. 创建目录
    if (![fm createDirectoryAtPath:toolDir withIntermediateDirectories:YES attributes:nil error:error]) {
        return nil;
    }
    
    // 5. 拷贝文件
    if (![fm copyItemAtPath:bundlePath toPath:executablePath error:error]) {
        return nil;
    }
    
    // 6. 赋予执行权限 (chmod 755)
    NSDictionary *attr = @{NSFilePosixPermissions: @(0755)};
    if (![fm setAttributes:attr ofItemAtPath:executablePath error:error]) {
        return nil;
    }
    
    return executablePath;
}

@end
