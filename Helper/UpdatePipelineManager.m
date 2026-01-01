//
//  UpdatePipelineManager.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 1/1/26.
//

//
//  UpdatePipelineManager.m
//  SparkleUpdateTool
//
//  Created by Refactoring Bot.
//

#import "UpdatePipelineManager.h"
#import "BinaryDeltaManager.h"
#import "FileHelper.h"

@implementation UpdatePipelineManager

+ (instancetype)sharedManager {
    static UpdatePipelineManager *shared;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[UpdatePipelineManager alloc] init];
    });
    return shared;
}

- (void)runPipelineWithConfig:(UpdateGenerationConfig *)config
                     logBlock:(PipelineLogBlock)logBlock
                   completion:(PipelineCompletionBlock)completion {
    
    // 0. 基础校验
    NSError *validError = nil;
    if (![config validate:&validError]) {
        completion(NO, nil, validError);
        return;
    }
    
    // 准备路径
    NSString *finalDeltaPath = [config.outputDirectory stringByAppendingPathComponent:config.deltaFilename];
    
    // ---------------------------------------------------------
    // STEP 1: 生成 Delta Patch (异步)
    // ---------------------------------------------------------
    logBlock(@"⏳ Generating Delta Patch...", NO);
    
    [BinaryDeltaManager createDeltaFromOldPath:config.oldAppPath
                                     toNewPath:config.latestAppPath // [使用新属性名]
                                    outputPath:finalDeltaPath
                                      logBlock:^(NSString *msg){ logBlock(msg, NO); }
                                    completion:^(BOOL success, NSError *error) {
        
        if (!success) {
            completion(NO, nil, error);
            return;
        }
        
        logBlock(@"✅ Delta Generated. Preparing files...", NO);
        
        // ---------------------------------------------------------
        // STEP 2: 复制文件到输出目录
        // ---------------------------------------------------------
        // 注意：FileHelper 操作通常是同步的，这里为了安全起见，继续在当前后台线程执行
        [FileHelper copyFileAtPath:config.oldAppPath toDirectory:config.outputDirectory];
        [FileHelper copyFileAtPath:config.latestAppPath toDirectory:config.outputDirectory];
        // BinaryDeltaManager 应该已经把 delta 生成到了 finalDeltaPath，无需再次复制
        
        // ---------------------------------------------------------
        // STEP 3: 压缩 New App (异步)
        // ---------------------------------------------------------
        logBlock(@"📦 Zipping application...", NO);
        
        // 我们压缩的是输出目录里的那个新 App
        NSString *appFileName = [config.latestAppPath lastPathComponent];
        NSString *targetAppPath = [config.outputDirectory stringByAppendingPathComponent:appFileName];
        
        [FileHelper zipAppAtPath:targetAppPath logBlock:^(NSString *msg){ logBlock(msg, NO); } completion:^(NSString *zipFilePath) {
            
            // ---------------------------------------------------------
            // STEP 4: 生成 JSON
            // ---------------------------------------------------------
            logBlock(@"📝 Generating JSON...", NO);
            
            NSString *deltaSize = [FileHelper strfileSizeAtPath:finalDeltaPath];
            NSString *zipSize = [NSString stringWithFormat:@"%llu", [FileHelper fileSizeAtPath:zipFilePath]];
            
            // 构造 JSON 输出路径
            NSString *jsonFilename = [NSString stringWithFormat:@"%@.json", config.appName ?: @"update"];
            NSString *jsonPath = [config.outputDirectory stringByAppendingPathComponent:jsonFilename];
            
            NSError *jsonError = nil;
            BOOL jsonSuccess = [self generateJSONWithConfig:config
                                                  deltaSize:deltaSize
                                                    zipSize:zipSize
                                                   jsonPath:jsonPath
                                                      error:&jsonError];
            
            if (jsonSuccess) {
                completion(YES, jsonPath, nil);
            } else {
                completion(NO, nil, jsonError);
            }
        }];
    }];
}

// 私有：JSON 生成逻辑 (从旧 VC 迁移过来)
- (BOOL)generateJSONWithConfig:(UpdateGenerationConfig *)config
                     deltaSize:(NSString *)deltaSize
                       zipSize:(NSString *)zipSize
                      jsonPath:(NSString *)jsonPath
                         error:(NSError **)error {
    
    NSString *baseURL = @"https://unigo.ai/uploads/";
    
    // 使用 URL 编码防止文件名空格导致链接失效
    NSString *deltaName = [config.deltaFilename lastPathComponent];
    NSString *safeDeltaName = [deltaName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    
    NSString *zipName = [NSString stringWithFormat:@"%@-%@.zip", config.appName, config.latestVersion];
    NSString *safeZipName = [zipName stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLPathAllowedCharacterSet]];
    
    NSDictionary *jsonDict = @{
        @"appName": config.appName ?: @"",
        @"lastVersion": config.oldVersion ?: @"",
        @"latestVersion": config.latestVersion ?: @"", // [使用新属性名]
        @"deltaFileName": deltaName,
        @"deltaSize": deltaSize ?: @"0",
        @"fileSize": zipSize ?: @"0",
        @"deltaURL": [baseURL stringByAppendingString:safeDeltaName],
        @"downloadURL": [baseURL stringByAppendingString:safeZipName],
        @"releaseDate": [[NSDate date] description],
        @"minimumSystemVersion": @"13.5",
        @"description": [NSString stringWithFormat:@"%@ client update", config.appName],
        @"wineConfig": @{
            @"bottleName": config.appName ?: @"",
            @"wineVersion": @"10.0",
            @"preservePaths": @{@"0": @"steamapps", @"1": @"userdata", @"2": @"config"}
        }
    };
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:error];
    if (!data) return NO;
    
    return [data writeToFile:jsonPath atomically:YES];
}

@end
