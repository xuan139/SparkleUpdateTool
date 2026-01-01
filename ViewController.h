//
//  ViewController.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

//
//  ViewController.h
//  SparkleUpdateTool
//
//  Refactored with Product-Level UI Toolkit
//

#import <Cocoa/Cocoa.h>
#import "AppUpdateViewController.h"
#import "SmartLogView.h" // 引入新组件

@interface ViewController : NSViewController

// --- UI Components (Auto Layout) ---

// 顶部输入区引用 (用于逻辑控制)
@property (nonatomic, strong) NSTextField *oldAppPathField;
@property (nonatomic, strong) NSButton *oldAppSelectButton;
@property (nonatomic, strong) NSTextField *updatedAppPathField;
@property (nonatomic, strong) NSButton *updatedAppSelectButton;

// 操作按钮
@property (nonatomic, strong) NSButton *generateUpdateButton;
@property (nonatomic, strong) NSButton *applyUpdateButton;

// 日志视图 (替换原有的 NSTextView)
@property (nonatomic, strong) SmartLogView *logView;

// JSON 编辑区容器 (用于动态添加 TextField)
@property (nonatomic, strong) NSStackView *jsonEditorStack;
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSTextField *> *jsonFieldMap;
@property (nonatomic, strong) NSDictionary *currentJSON;


// --- 业务数据属性 (保持不变) ---
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

@property (nonatomic, strong) NSString *deltaDir;
@property (nonatomic, strong) NSString *deltaPath;
@property (nonatomic, strong) NSString *outputDir;
@property (nonatomic, strong) NSString *logFileDir;
@property (nonatomic, strong) NSString *jsonPath;

@property (nonatomic, strong) NSWindowController *updateWindowController;

@end
