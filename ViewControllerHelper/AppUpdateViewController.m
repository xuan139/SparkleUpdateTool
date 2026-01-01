//
//  AppUpdateViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/26/25.
//  Refactored: Fixed naming conventions, selector mismatches, and implemented Auto Layout.
//

#import "AppUpdateViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// 引入工具类
#import "FileHelper.h"
#import "UIFactory.h"
#import "AlertPresenter.h"
#import "SmartLogView.h"
#import "BinaryDeltaManager.h"

@interface AppUpdateViewController ()

// --- UI 属性 (私有) ---
@property (nonatomic, strong) NSTextField *oldAppPathField;
@property (nonatomic, strong) NSTextField *deltaPathField;

// [修复] 重命名 newAppNameField -> outputAppNameField 以避免 "new" 命名冲突
@property (nonatomic, strong) NSTextField *outputAppNameField;

@property (nonatomic, strong) NSButton *okButton;
@property (nonatomic, strong) SmartLogView *logView;

// --- 数据属性 ---
@property (nonatomic, strong) NSString *oldAppDir;
@property (nonatomic, strong) NSString *deltaDir;
@property (nonatomic, strong) NSString *logFilePath;

@end

@implementation AppUpdateViewController

#pragma mark - Lifecycle

- (void)loadView {
    // 设置初始视图大小
    NSView *view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 600, 550)];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupPaths];
    [self setupLayout];
}

#pragma mark - Setup

- (void)setupPaths {
    // 设置日志路径
    self.logFilePath = [FileHelper fullPathInDocuments:@"sparkleLogDir/sparkle_apply_log.txt"];
    [FileHelper prepareEmptyFileAtPath:self.logFilePath];
}

- (void)setupLayout {
    // 1. 主容器 (Vertical StackView)
    NSStackView *mainStack = [[NSStackView alloc] init];
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.alignment = NSLayoutAttributeLeading;
    mainStack.spacing = 20;
    mainStack.edgeInsets = NSEdgeInsetsMake(30, 30, 30, 30);
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mainStack];

    // Auto Layout 约束：撑满窗口
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [mainStack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    // 2. 组装 UI 组件
    
    // Row 1: 旧 App 选择
    // [修复] 使用临时变量 tempOldField 解决 "non-local object" 错误
    NSTextField *tempOldField = nil;
    [mainStack addArrangedSubview:[self createPathSelectionRow:@"Old App:"
                                                 placeholder:@"Select old .app..."
                                                   targetPtr:&tempOldField
                                                      action:@selector(selectOldApp)]];
    self.oldAppPathField = tempOldField; // 赋值给属性

    // Row 2: Delta 文件选择
    // [修复] 使用临时变量 tempDeltaField
    NSTextField *tempDeltaField = nil;
    [mainStack addArrangedSubview:[self createPathSelectionRow:@"Delta File:"
                                                 placeholder:@"Select .delta file..."
                                                   targetPtr:&tempDeltaField
                                                      action:@selector(selectDeltaFile)]];
    self.deltaPathField = tempDeltaField; // 赋值给属性

    // Row 3: 新文件名输入
    // [修复] 使用临时变量 tempNameField
    NSTextField *tempNameField = nil;
    [mainStack addArrangedSubview:[self createInputFieldRow:@"New Name:"
                                              placeholder:@"e.g. MyApp_v2.0.app"
                                                targetPtr:&tempNameField]];
    self.outputAppNameField = tempNameField; // 赋值给属性

    // Row 4: 按钮区域
    NSStackView *buttonStack = [[NSStackView alloc] init];
    buttonStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    buttonStack.spacing = 12;
    
    self.okButton = [UIFactory primaryButtonWithTitle:@"Apply Update" target:self action:@selector(okButtonPressed)];
    NSButton *cancelBtn = [UIFactory buttonWithTitle:@"Cancel" target:self action:@selector(cancelButtonPressed)];
    
    [buttonStack addArrangedSubview:self.okButton];
    [buttonStack addArrangedSubview:cancelBtn];
    [mainStack addArrangedSubview:buttonStack];

    // Row 5: 日志区域
    [mainStack addArrangedSubview:[UIFactory labelWithText:@"Execution Log:"]];
    
    self.logView = [[SmartLogView alloc] init];
    [mainStack addArrangedSubview:self.logView];
    
    // 约束日志视图
    [self.logView.widthAnchor constraintEqualToAnchor:mainStack.widthAnchor].active = YES;
    [self.logView.heightAnchor constraintGreaterThanOrEqualToConstant:200].active = YES;
    
    [self log:@"Ready to apply delta." level:LogLevelInfo];
}

#pragma mark - UI Helpers

// [修复] 方法签名中第二个参数名为 placeholder，解决了 Selector Mismatch 错误
- (NSView *)createPathSelectionRow:(NSString *)label placeholder:(NSString *)placeholder targetPtr:(NSTextField **)fieldPtr action:(SEL)sel {
    NSStackView *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing = 10;
    
    NSTextField *lbl = [UIFactory labelWithText:label];
    [lbl.widthAnchor constraintEqualToConstant:80].active = YES; // 固定 Label 宽度
    
    NSTextField *field = [UIFactory pathDisplayFieldWithPlaceholder:placeholder];
    [field setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    NSButton *btn = [UIFactory buttonWithTitle:@"Choose..." target:self action:sel];
    
    [row addArrangedSubview:lbl];
    [row addArrangedSubview:field];
    [row addArrangedSubview:btn];
    
    if (fieldPtr) *fieldPtr = field;
    
    // 确保 Row 宽度能够被拉伸
    NSLayoutConstraint *widthCon = [row.widthAnchor constraintEqualToConstant:0];
    widthCon.priority = NSLayoutPriorityFittingSizeCompression;
    widthCon.active = YES;
    
    return row;
}

- (NSView *)createInputFieldRow:(NSString *)label placeholder:(NSString *)placeholder targetPtr:(NSTextField **)fieldPtr {
    NSStackView *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing = 10;
    
    NSTextField *lbl = [UIFactory labelWithText:label];
    [lbl.widthAnchor constraintEqualToConstant:80].active = YES;
    
    NSTextField *field = [[NSTextField alloc] init];
    field.placeholderString = placeholder;
    [field setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    [row addArrangedSubview:lbl];
    [row addArrangedSubview:field];
    
    if (fieldPtr) *fieldPtr = field;
    return row;
}

#pragma mark - Actions

- (void)selectOldApp {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedContentTypes = @[UTTypeApplicationBundle];
    panel.directoryURL = [NSURL fileURLWithPath:[FileHelper fullPathInDocuments:@"sparkle_output"]];
    
    if ([panel runModal] == NSModalResponseOK) {
        self.oldAppDir = panel.URL.path;
        self.oldAppPathField.stringValue = self.oldAppDir;
        [self log:[NSString stringWithFormat:@"Selected App: %@", self.oldAppDir.lastPathComponent] level:LogLevelSuccess];
    }
}

- (void)selectDeltaFile {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"delta"];
    panel.directoryURL = [NSURL fileURLWithPath:[FileHelper fullPathInDocuments:@"sparkle_output"]];
    
    if ([panel runModal] == NSModalResponseOK) {
        self.deltaDir = panel.URL.path;
        self.deltaPathField.stringValue = self.deltaDir;
        [self log:[NSString stringWithFormat:@"Selected Delta: %@", self.deltaDir.lastPathComponent] level:LogLevelSuccess];
    }
}

- (void)okButtonPressed {
    // 获取用户输入的新文件名
    NSString *outputAppName = self.outputAppNameField.stringValue;
    
    // 基础校验
    if (!self.oldAppDir || !self.deltaDir || outputAppName.length == 0) {
        [AlertPresenter showError:@"Please fill all fields (Old App, Delta, New Name)." inWindow:self.view.window];
        return;
    }
    
    // 构造输出路径：在旧 App 同级目录下生成
    NSString *outputDir = [self.oldAppDir stringByDeletingLastPathComponent];
    NSString *newAppPath = [outputDir stringByAppendingPathComponent:outputAppName];
    
    self.okButton.enabled = NO;
    [self log:@"⏳ Applying delta... Please wait." level:LogLevelWarning];
    
    // 使用 weakSelf 避免 Retain Cycle
    __weak typeof(self) weakSelf = self;
    
    [BinaryDeltaManager applyDelta:self.deltaDir
                          toOldDir:self.oldAppDir
                          toNewDir:newAppPath
                          logBlock:^(NSString *log) {
        // 确保日志更新在主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf log:log level:LogLevelInfo];
        });
    } completion:^(BOOL success, NSError *error) {
        
        // 确保 UI 更新在主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.okButton.enabled = YES;
            
            if (success) {
                [weakSelf log:[NSString stringWithFormat:@"✅ Success! New App created at: %@", newAppPath] level:LogLevelSuccess];
                [AlertPresenter showSuccess:@"Delta Applied Successfully!" inWindow:weakSelf.view.window];
                
                // 在 Finder 中显示结果
                [[NSWorkspace sharedWorkspace] selectFile:newAppPath inFileViewerRootedAtPath:@""];
            } else {
                [weakSelf log:[NSString stringWithFormat:@"❌ Failed: %@", error.localizedDescription] level:LogLevelError];
                [AlertPresenter showError:error.localizedDescription inWindow:weakSelf.view.window];
            }
        });
    }];
}

- (void)cancelButtonPressed {
    [self.view.window close];
}

#pragma mark - Logging System

- (void)log:(NSString *)message level:(LogLevel)level {
    // 1. UI Log (SmartLogView)
    [self.logView appendLog:message level:level];
    
    // 2. File Log (后台写入，防止阻塞 UI)
    NSString *filePath = self.logFilePath;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *ts = [[NSDate date] description];
        NSString *entry = [NSString stringWithFormat:@"[%@] %@\n", ts, message];
        
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:filePath];
        if (fh) {
            [fh seekToEndOfFile];
            [fh writeData:[entry dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
        }
    });
}

@end
