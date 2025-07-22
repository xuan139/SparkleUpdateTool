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
+ (unsigned long long)fileSizeAtPath:(NSString *)path;
+ (void)writeAppcastXML:(NSString *)xml toPath:(NSString *)path;

@end

