//
//  BinaryDeltaManager.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 8/30/25.
//

#import <Foundation/Foundation.h>

@interface BinaryDeltaManager : NSObject

/// 返回 BinaryDelta 可执行路径
+ (NSString *)binaryDeltaPath;
+ (BOOL)createDeltaFromOldPath:(NSString *)oldPath
                     toNewPath:(NSString *)newPath
                    outputPath:(NSString *)outputPath
                      logBlock:(void (^)(NSString *log))logBlock;

+ (BOOL)applyDelta:(NSString *)deltaPath
         toOldDir:(NSString *)oldDir
         toNewDir:(NSString *)newDir
          logBlock:(void (^)(NSString *log))logBlock;

@end
