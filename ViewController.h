//
//  ViewController.h
//  SparkleUpdateTool
//
//  Refactored: Phase 1 (UI Component Extraction)
//

#import <Cocoa/Cocoa.h>
// [删除] #import "SmartLogView.h" (建议移到 .m 文件引入，保持头文件干净)

@interface ViewController : NSViewController

// --- UI Components ---
@property (nonatomic, strong) NSTextField *oldAppPathField;
@property (nonatomic, strong) NSButton *oldAppSelectButton;
@property (nonatomic, strong) NSTextField *updatedAppPathField;
@property (nonatomic, strong) NSButton *updatedAppSelectButton;

@property (nonatomic, strong) NSButton *generateUpdateButton;
@property (nonatomic, strong) NSButton *applyUpdateButton;

// [修改] 日志视图改为在该文件内部引入类，或者使用 id，这里保留原样
@property (nonatomic, strong) NSView *logView; // 类型可以是 SmartLogView，为了编译通过先写父类或在.m强转

// [删除] 以下属性已不再需要，被组件接管
// @property (nonatomic, strong) NSStackView *jsonEditorStack;
// @property (nonatomic, strong) NSMutableDictionary<NSString *, NSTextField *> *jsonFieldMap;
// @property (nonatomic, strong) NSDictionary *currentJSON;

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
