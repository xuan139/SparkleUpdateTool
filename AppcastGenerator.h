//
//  AppcastGenerator.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/22/25.
//

#ifndef AppcastGenerator_h
#define AppcastGenerator_h


#endif /* AppcastGenerator_h */

#import <Foundation/Foundation.h>


@interface AppcastGenerator : NSObject

+ (NSString *)rfc822DateStringFromDate:(NSDate *)date;
+ (NSDictionary *)parseAppcastXMLFromPath:(NSString *)xmlPath ;
+ (void)writeAppcastXML:(NSString *)xml toPath:(NSString *)path;
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
                           outputPath:(NSString *)xmlOutputPath ;

@end

