//
//  ViewController.h
//  SparkleUpdateTool
//
//  Refactored Phase 2: Fully Decoupled Service Layer
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController

// --- UI Components ---
@property (nonatomic, strong) NSTextField *oldAppPathField;
@property (nonatomic, strong) NSButton *oldAppSelectButton;
@property (nonatomic, strong) NSTextField *updatedAppPathField;
@property (nonatomic, strong) NSButton *updatedAppSelectButton;

@property (nonatomic, strong) NSButton *generateUpdateButton;
@property (nonatomic, strong) NSButton *applyUpdateButton;

// 日志视图 (使用 id 或父类引用，保持解耦)
@property (nonatomic, strong) NSView *logView;

// --- 状态与配置 ---
// 我们不再需要在 VC 里存几十个版本号变量，只存路径即可
@property (nonatomic, strong) NSString *oldAppDir;
@property (nonatomic, strong) NSString *latestAppDir; // [改名] NewAppDir -> latestAppDir

// 基础目录配置
@property (nonatomic, strong) NSString *outputDir;
@property (nonatomic, strong) NSString *deltaDir;     // 默认 Delta 存放目录
@property (nonatomic, strong) NSString *logFileDir;
@property (nonatomic, strong) NSString *jsonPath;     // 最终 JSON 路径

// 子窗口控制器
@property (nonatomic, strong) NSWindowController *updateWindowController;

@end
