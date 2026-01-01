//
//  UpdateGenerationConfig.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 1/1/26.
//

//
//  UpdateGenerationConfig.m
//  SparkleUpdateTool
//
//  Created by Refactoring Bot.
//

#import "UpdateGenerationConfig.h"
#import "FileHelper.h" // 依赖现有的工具类

@interface UpdateGenerationConfig ()
@property (nonatomic, copy, readwrite) NSString *appName;
@property (nonatomic, copy, readwrite) NSString *oldVersion;
@property (nonatomic, copy, readwrite) NSString *latestVersion;
@end

@implementation UpdateGenerationConfig

- (void)parseAppMetadata {
    // 解析旧版信息
    if (self.oldAppPath) {
        NSDictionary *info = [FileHelper getAppVersionInfoFromPath:self.oldAppPath logBlock:nil];
        if (info) {
            self.oldVersion = info[@"version"];
        }
    }
    
    // 解析新版信息
    if (self.latestAppPath) {
        NSDictionary *info = [FileHelper getAppVersionInfoFromPath:self.latestAppPath logBlock:nil];
        if (info) {
            self.latestVersion = info[@"version"];
            self.appName = info[@"appName"]; // 通常使用最新版的名称
        }
    }
}

- (BOOL)validate:(NSError **)error {
    if (!self.oldAppPath || self.oldAppPath.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"ConfigError" code:101 userInfo:@{NSLocalizedDescriptionKey: @"Old App path is missing"}];
        return NO;
    }
    
    if (!self.latestAppPath || self.latestAppPath.length == 0) {
        if (error) *error = [NSError errorWithDomain:@"ConfigError" code:102 userInfo:@{NSLocalizedDescriptionKey: @"New App path is missing"}];
        return NO;
    }
    
    if (!self.outputDirectory) {
        if (error) *error = [NSError errorWithDomain:@"ConfigError" code:103 userInfo:@{NSLocalizedDescriptionKey: @"Output directory is missing"}];
        return NO;
    }
    
    return YES;
}

@end
