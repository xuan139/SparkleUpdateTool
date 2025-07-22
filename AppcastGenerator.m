//
//  AppcastGenerator.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/22/25.
//

#import <Foundation/Foundation.h>
#import "AppcastGenerator.h"

@implementation AppcastGenerator

+ (NSString *)rfc822DateStringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    return [formatter stringFromDate:date];
}

+ (unsigned long long)fileSizeAtPath:(NSString *)path {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSDictionary *attributes = [fileManager attributesOfItemAtPath:path error:&error];
    if (error) {
        NSLog(@"获取文件大小失败: %@ - %@", path, error.localizedDescription);
        return 0;
    }
    return [attributes[NSFileSize] unsignedLongLongValue];
}

+ (void)writeAppcastXML:(NSString *)xml toPath:(NSString *)path {
    NSError *error;
    [xml writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"写入 XML 失败: %@ - %@", path, error.localizedDescription);
    } else {
        NSLog(@"成功写入 XML 到: %@", path);
    }
}

@end
