//
//  ViewController.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController
@property (nonatomic, strong) NSString *versionOld;
@property (nonatomic, strong) NSString *buildOld;
@property (nonatomic, strong) NSString *versionNew;
@property (nonatomic, strong) NSString *buildNew;

@property (nonatomic, strong) NSString *docsDir;
@property (nonatomic, strong) NSString *logFilePath;

@property (nonatomic, strong) NSString *oldAppPath;
@property (nonatomic, strong) NSString *updateAppPath;

// 关键文件路径
@property (nonatomic, strong) NSString *appcastPath;
@property (nonatomic, strong) NSString *fullZipPath;
@property (nonatomic, strong) NSString *deltaPath;
@property (nonatomic, strong) NSString *sourceDeltaPath;


@end

