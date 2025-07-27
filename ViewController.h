//
//  ViewController.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

#import <Cocoa/Cocoa.h>
#import "AppUpdateViewController.h"

@interface ViewController : NSViewController


@property (nonatomic, strong) NSTextField *oldAppLabel;
@property (nonatomic, strong) NSTextField *oldAppPathField;
@property (nonatomic, strong) NSButton *oldAppSelectButton;

@property (nonatomic, strong) NSTextField *updatedAppLabel;
@property (nonatomic, strong) NSTextField *updatedAppPathField;
@property (nonatomic, strong) NSButton *updatedAppSelectButton;

@property (nonatomic, strong) NSButton *generateUpdateButton;
@property (nonatomic, strong) NSButton *applyUpdateButton;
@property (nonatomic, strong) NSTextView *logTextView;

// 关键文件路径
@property (nonatomic, strong) NSString *appName;
@property (nonatomic, strong) NSString *appNameOld;
@property (nonatomic, strong) NSString *appNameNew;
@property (nonatomic, strong) NSString *appNameDeltaFileName;

@property (nonatomic, strong) NSString *oldVersion;
@property (nonatomic, strong) NSString *oldBuildVersion;
@property (nonatomic, strong) NSString *NewVersion;
@property (nonatomic, strong) NSString *NewBuildVersion;

@property (nonatomic, strong) NSString *docsDir;
@property (nonatomic, strong) NSString *oldAppDir;
@property (nonatomic, strong) NSString *NewAppDir;


@property (nonatomic, strong) NSString *sourceDeltaDir;
@property (nonatomic, strong) NSString *oldfullZipPathFileName;
@property (nonatomic, strong) NSString *newfullZipPathFileName;

@property (nonatomic, strong) NSString *deltaDir;
@property (nonatomic, strong) NSString *deltaPath;

@property (nonatomic, strong) NSString *patchFilePath;
@property (nonatomic, strong) NSString *outputDir;
@property (nonatomic, strong) NSString *logFileDir;
@property (nonatomic, strong) NSString *appcastDir;

@property (nonatomic, strong) NSString *jsonPath;

@property (nonatomic, strong) NSWindowController *updateWindowController;


@end

