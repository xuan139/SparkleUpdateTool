//
//  SparkleHelper.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/20/25.
//


// SparkleHelper.h
#import <Foundation/Foundation.h>

@interface SparkleHelper : NSObject

+ (void)generateKeys;

+ (NSString *)getPublicKey;

+ (BOOL)createDeltaFromOldPath:(NSString *)oldPath toNewPath:(NSString *)newPath outputPath:(NSString *)outputPath logBlock:(void (^)(NSString *log))logBlock;

+ (NSString *)signFileAtPath:(NSString *)path
                     withKey:(NSString *)privateKeyPath
                     logBlock:(void (^)(NSString *log))logBlock;


+ (BOOL)applyDelta:(NSString *)deltaPath
         toOldDir:(NSString *)oldDir
         toNewDir:(NSString *)newDir
         logBlock:(void (^)(NSString *log))logBlock;

+ (BOOL)verifyFileAtPath:(NSString *)path signature:(NSString *)sig publicKey:(NSString *)pubKeyPath;


//+ (NSString *)generateAppcastXMLWithVersion:(NSString *)version
//                         shortVersion:(NSString *)shortVersion
//                                zipURL:(NSString *)zipURL
//                              deltaURL:(NSString *)deltaURL
//                            zipSignature:(NSString *)zipSig
//                          deltaSignature:(NSString *)deltaSig
//                                 pubDate:(NSDate *)pubDate;
//+ (BOOL)writeXML:(NSString *)xml toPath:(NSString *)outputPath;

@end
