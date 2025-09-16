//
//  AppcastGenerator.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/22/25.
//

#import <Foundation/Foundation.h>
#import "FileHelper.h"
#import "AppcastGenerator.h"

@implementation AppcastGenerator

+ (NSString *)rfc822DateStringFromDate:(NSDate *)date {
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE, dd MMM yyyy HH:mm:ss Z"];
    [formatter setLocale:[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"]];
    return [formatter stringFromDate:date];
}


+ (NSDictionary *)parseAppcastXMLFromPath:(NSString *)xmlPath {
    NSError *error;
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath options:0 error:&error];
    if (!xmlData) return nil;

    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    if (!doc) return nil;

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"appName"] = [[[doc nodesForXPath:@"//channel/title" error:nil].firstObject stringValue] stringByReplacingOccurrencesOfString:@" Updates" withString:@""];
    result[@"baseURL"] = [[[doc nodesForXPath:@"//channel/link" error:nil].firstObject stringValue] stringByReplacingOccurrencesOfString:@"appcast.xml" withString:@""];
    
    NSXMLElement *item = [doc nodesForXPath:@"//item" error:nil].firstObject;
    if (item) {
        result[@"version"] = [[[item nodesForXPath:@"title" error:nil].firstObject stringValue] stringByReplacingOccurrencesOfString:@"Version " withString:@""];
        result[@"releaseNotesLink"] = [[item nodesForXPath:@"sparkle:releaseNotesLink" error:nil].firstObject stringValue];
        result[@"pubDate"] = [[item nodesForXPath:@"pubDate" error:nil].firstObject stringValue];

        NSXMLElement *enclosure = [item nodesForXPath:@"enclosure" error:nil].firstObject;
        if (enclosure) {
            result[@"fullAppURL"] = [enclosure attributeForName:@"url"].stringValue;
            result[@"shortVersion"] = [enclosure attributeForName:@"sparkle:shortVersionString"].stringValue;
            result[@"fullSize"] = [enclosure attributeForName:@"length"].stringValue;
            result[@"fullSignature"] = [enclosure attributeForName:@"sparkle:edSignature"].stringValue;
        }

        NSXMLElement *deltaEnclosure = [item nodesForXPath:@"sparkle:delta/enclosure" error:nil].firstObject;
        if (deltaEnclosure) {
            result[@"deltaURL"] = [deltaEnclosure attributeForName:@"url"].stringValue;
            result[@"deltaFromVersion"] = [deltaEnclosure attributeForName:@"sparkle:deltaFrom"].stringValue;
            result[@"deltaSize"] = [deltaEnclosure attributeForName:@"length"].stringValue;
            result[@"deltaSignature"] = [deltaEnclosure attributeForName:@"sparkle:edSignature"].stringValue;
        }
    }

    return result;
}

//+ (void)writeAppcastXML:(NSString *)xml toPath:(NSString *)path {
//    NSError *error;
//    [xml writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
//    if (error) {
//        NSLog(@"写入 XML 失败: %@ - %@", path, error.localizedDescription);
//    } else {
//        NSLog(@"成功写入 XML 到: %@", path);
//    }
//}


+ (void)writeAppcastXML:(NSString *)xml toPath:(NSString *)appcastPath {
    NSError *writeError = nil;
    BOOL success = [xml writeToFile:appcastPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    if (!success || writeError) {
        NSLog(@"写入 XML 失败: %@ - %@", appcastPath, writeError.localizedDescription);
    } else {
        NSLog(@"成功写入 XML 到: %@", appcastPath);
    }
}

+ (void)generateAppcastXMLWithAppName:(NSString *)appName
                              version:(NSString *)version
                         shortVersion:(NSString *)shortVersion
                              pubDate:(NSDate *)pubDate
                         fullAppPath:(NSString *)fullAppPath
                        fullSignature:(NSString *)fullSignature
                        deltaFilePath:(NSString *)deltaFilePath
                     deltaFromVersion:(NSString *)deltaFromVersion
                      deltaSignature:(NSString *)deltaSignature
                              baseURL:(NSString *)baseURL
                          outputPath:(NSString *)xmlOutputPath {
    // 验证输入
    if (!appName || !version || !shortVersion || !pubDate || !fullAppPath || !fullSignature || !xmlOutputPath) {
        NSLog(@"缺少必要参数: appName=%@, version=%@, shortVersion=%@, pubDate=%@, fullAppPath=%@, fullSignature=%@, xmlOutputPath=%@",
              appName, version, shortVersion, pubDate, fullAppPath, fullSignature, xmlOutputPath);
        return;
    }

    // 动态拼接 baseURL
//    NSString *appBaseURL = baseURL ?: @"https://unigo.com";
//    appBaseURL = [appBaseURL stringByAppendingString:@"/"];
    
    NSString *validBaseURL = baseURL ?: @"https://unigo.com";
        if ([validBaseURL hasPrefix:@"https:/"] && ![validBaseURL hasPrefix:@"https://"]) {
            validBaseURL = [@"https://" stringByAppendingString:[validBaseURL substringFromIndex:7]];
        }
    NSString *appBaseURL = validBaseURL;
    
        if (![appBaseURL hasSuffix:@"/"]) {
            appBaseURL = [appBaseURL stringByAppendingString:@"/"];
        }
    
//
    // 获取文件大小
    unsigned long long fullSize  = fullAppPath ? [FileHelper fileSizeAtPath:fullAppPath] : 0 ;
    unsigned long long deltaSize = deltaFilePath ? [FileHelper fileSizeAtPath:deltaFilePath] : 0;

    // 构建 XML
    NSMutableString *xml = [NSMutableString string];
    [xml appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
    [xml appendString:@"<rss version=\"2.0\" xmlns:sparkle=\"http://www.andymatuschak.org/xml-namespaces/sparkle\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n"];
    [xml appendString:@"  <channel>\n"];
    [xml appendFormat:@"    <title>%@ Updates</title>\n", appName];
    [xml appendFormat:@"    <link>%@appcast.xml</link>\n", appBaseURL];
    [xml appendFormat:@"    <description>Latest updates for %@</description>\n", appName];
    [xml appendString:@"    <language>en</language>\n"];
    [xml appendString:@"    <item>\n"];
    [xml appendFormat:@"      <title>Version %@</title>\n", version];
    [xml appendFormat:@"      <sparkle:releaseNotesLink>%@release_notes_%@.html</sparkle:releaseNotesLink>\n", appBaseURL, version];
    [xml appendFormat:@"      <pubDate>%@</pubDate>\n", [self rfc822DateStringFromDate:pubDate]];

     
     [xml appendFormat:@"      <enclosure url=\"%@%@\" sparkle:version=\"%@\" sparkle:shortVersionString=\"%@\" length=\"%llu\" type=\"application/octet-stream\" sparkle:edSignature=\"%@\" />\n",
      appBaseURL, appName, version, shortVersion, fullSize, fullSignature];
     

    if (deltaFilePath && deltaFromVersion && deltaSignature && deltaSize > 0) {
        [xml appendString:@"      <sparkle:delta>\n"];
        [xml appendFormat:@"        <enclosure url=\"%@upadte.delta\" sparkle:version=\"%@\" sparkle:deltaFrom=\"%@\" length=\"%llu\" type=\"application/octet-stream\" sparkle:edSignature=\"%@\" />\n",
         appBaseURL, version, deltaFromVersion, deltaSize, deltaSignature];
        [xml appendString:@"      </sparkle:delta>\n"];
    }
    [xml appendString:@"    </item>\n"];
    [xml appendString:@"  </channel>\n"];
    [xml appendString:@"</rss>\n"];
    
    // 写入文件
    [self writeAppcastXML:xml toPath:xmlOutputPath];
    
}


@end
