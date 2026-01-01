//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//
//  Refactored Final: UI Components + Service Layer Pattern
//

#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// 引入工具
#import "FileHelper.h"
#import "UIFactory.h"
#import "AlertPresenter.h"
#import "SmartLogView.h"

// 引入业务模块
#import "AppUpdateViewController.h"
#import "DynamicJSONEditorView.h"
#import "UpdateGenerationConfig.h"   // [新增]
#import "UpdatePipelineManager.h"    // [新增]

@interface ViewController ()

@property (nonatomic, strong) DynamicJSONEditorView *jsonEditorView;

@end

@implementation ViewController

#pragma mark - Lifecycle & View Setup

- (void)loadView {
    NSView *view = [[NSView alloc] init];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupLayout];
    [self setupDir];
}

- (void)setupLayout {
    // --- 主容器 ---
    NSStackView *mainStack = [[NSStackView alloc] init];
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.alignment = NSLayoutAttributeLeading;
    mainStack.spacing = 16;
    mainStack.edgeInsets = NSEdgeInsetsMake(20, 20, 20, 20);
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mainStack];
    
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [mainStack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    // --- 1. 顶部：文件选择区 ---
    NSTextField *tempOldPathField = nil;
    [mainStack addArrangedSubview:[self createSelectionRowWithLabel:@"Old App:" pathField:&tempOldPathField action:@selector(selectOldApp)]];
    self.oldAppPathField = tempOldPathField;
    
    NSTextField *tempNewPathField = nil;
    [mainStack addArrangedSubview:[self createSelectionRowWithLabel:@"New App:" pathField:&tempNewPathField action:@selector(selectUpdatedApp)]];
    self.updatedAppPathField = tempNewPathField;
    
    // --- 2. 顶部：操作按钮区 ---
    NSStackView *actionRow = [[NSStackView alloc] init];
    actionRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    actionRow.spacing = 20;
    
    self.generateUpdateButton = [UIFactory primaryButtonWithTitle:@"Generate Update" target:self action:@selector(generateUpdate)];
    self.applyUpdateButton = [UIFactory buttonWithTitle:@"Test Apply" target:self action:@selector(setUpApplyUpdateWindow)];
    
    [actionRow addArrangedSubview:self.generateUpdateButton];
    [actionRow addArrangedSubview:self.applyUpdateButton];
    [actionRow addArrangedSubview:[NSView new]]; // Spacer
    [mainStack addArrangedSubview:actionRow];
    
    // --- 3. 底部：内容区 (日志 + JSON 编辑器) ---
    NSStackView *contentStack = [[NSStackView alloc] init];
    contentStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    contentStack.distribution = NSStackViewDistributionFillEqually;
    contentStack.spacing = 20;
    
    [contentStack addArrangedSubview:[self createLogSection]];
    [contentStack addArrangedSubview:[self createJSONEditorSection]];
    
    [mainStack addArrangedSubview:contentStack];
    
    // 布局约束
    [actionRow.widthAnchor constraintEqualToAnchor:mainStack.widthAnchor].active = YES;
    [contentStack.widthAnchor constraintEqualToAnchor:mainStack.widthAnchor].active = YES;
    
    [self logToScreen:@"System initialized. Ready." type:LogLevelInfo];
}

#pragma mark - UI Factory Helpers

- (NSView *)createSelectionRowWithLabel:(NSString *)text pathField:(NSTextField **)fieldPtr action:(SEL)action {
    NSStackView *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing = 10;
    
    NSTextField *label = [UIFactory labelWithText:text];
    [label.widthAnchor constraintEqualToConstant:80].active = YES;
    [row addArrangedSubview:label];
    
    NSTextField *field = [UIFactory pathDisplayFieldWithPlaceholder:@"Path not selected..."];
    [field setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [row addArrangedSubview:field];
    if (fieldPtr) *fieldPtr = field;
    
    [row addArrangedSubview:[UIFactory buttonWithTitle:@"Choose..." target:self action:action]];
    return row;
}

- (NSView *)createLogSection {
    NSStackView *container = [[NSStackView alloc] init];
    container.orientation = NSUserInterfaceLayoutOrientationVertical;
    container.alignment = NSLayoutAttributeLeading;
    container.spacing = 8;
    [container addArrangedSubview:[UIFactory labelWithText:@"Process Log:"]];
    
    self.logView = [[SmartLogView alloc] init];
    [container addArrangedSubview:self.logView];
    
    [self.logView.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;
    [self.logView.heightAnchor constraintGreaterThanOrEqualToConstant:300].active = YES;
    return container;
}

- (NSView *)createJSONEditorSection {
    NSStackView *container = [[NSStackView alloc] init];
    container.orientation = NSUserInterfaceLayoutOrientationVertical;
    container.alignment = NSLayoutAttributeLeading;
    container.spacing = 8;
    [container addArrangedSubview:[UIFactory labelWithText:@"Appcast JSON Editor:"]];
    
    self.jsonEditorView = [[DynamicJSONEditorView alloc] init];
    [self.jsonEditorView.heightAnchor constraintGreaterThanOrEqualToConstant:300].active = YES;
    [container addArrangedSubview:self.jsonEditorView];
    
    NSStackView *btnRow = [[NSStackView alloc] init];
    btnRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    [btnRow addArrangedSubview:[UIFactory buttonWithTitle:@"Save JSON" target:self action:@selector(saveJSONToFile)]];
    [btnRow addArrangedSubview:[UIFactory buttonWithTitle:@"Load JSON" target:self action:@selector(loadJSONFromFile)]];
    [container addArrangedSubview:btnRow];
    
    [self.jsonEditorView.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;
    [btnRow.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;
    return container;
}

#pragma mark - Setup & Logging

- (void)setupDir {
    _outputDir  = [FileHelper generateSubdirectory:@"sparkle_output"];
    _deltaDir   = [FileHelper fullPathInDocuments:@"sparkle_patch/update.delta"];
    _logFileDir = [FileHelper fullPathInDocuments:@"sparkleLogDir/sparkle_log.txt"];
    _jsonPath   = [FileHelper fullPathInDocuments:@"sparkle_output/appVersion.json"];
    
    [FileHelper prepareEmptyFileAtPath:_deltaDir];
    [FileHelper prepareEmptyFileAtPath:_logFileDir];
    [FileHelper prepareEmptyFileAtPath:_jsonPath];
    
    [self logToScreen:[NSString stringWithFormat:@"📂 Output: %@", _outputDir] type:LogLevelWarning];
}

- (void)logToScreen:(NSString *)message type:(LogLevel)level {
    // UI Log
    if ([self.logView isKindOfClass:[SmartLogView class]]) {
        [(SmartLogView *)self.logView appendLog:message level:level];
    }
    
    // File Log (Async)
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSString *timestamp = [[NSDate date] description]; // 简单时间戳
        NSString *logEntry = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        
        NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:self.logFileDir];
        if (fh) {
            [fh seekToEndOfFile];
            [fh writeData:[logEntry dataUsingEncoding:NSUTF8StringEncoding]];
            [fh closeFile];
        }
    });
}

#pragma mark - Actions: Select App

- (void)selectOldApp {
    NSString *path = [self openAppFromSubdirectory:@"sparkleOldApp"];
    if (path) {
        _oldAppDir = path;
        self.oldAppPathField.stringValue = path;
        [self logToScreen:[NSString stringWithFormat:@"✅ Selected Old App: %@", path] type:LogLevelSuccess];
        // 简单打印一下版本供确认，不再存入 VC 属性
        NSDictionary *info = [FileHelper getAppVersionInfoFromPath:path logBlock:nil];
        if (info) [self logToScreen:[NSString stringWithFormat:@"Version: %@", info[@"version"]] type:LogLevelInfo];
    }
}

- (void)selectUpdatedApp {
    NSString *path = [self openAppFromSubdirectory:@"sparkleNewApp"];
    if (path) {
        _latestAppDir = path; // [改名]
        self.updatedAppPathField.stringValue = path;
        [self logToScreen:[NSString stringWithFormat:@"✅ Selected New App: %@", path] type:LogLevelSuccess];
        NSDictionary *info = [FileHelper getAppVersionInfoFromPath:path logBlock:nil];
        if (info) [self logToScreen:[NSString stringWithFormat:@"Version: %@", info[@"version"]] type:LogLevelInfo];
    }
}

- (NSString *)openAppFromSubdirectory:(NSString *)subDirName {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fullPath = [documentsPath stringByAppendingPathComponent:subDirName];
    [[NSFileManager defaultManager] createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:nil];

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedContentTypes = @[ UTTypeApplicationBundle ];
    panel.directoryURL = [NSURL fileURLWithPath:fullPath];
    return ([panel runModal] == NSModalResponseOK) ? panel.URL.path : nil;
}

#pragma mark - Actions: Generate (Refactored)

// ----------------------------------------------------------------
// [核心重构点] 使用 UpdatePipelineManager 替代原有的数百行逻辑
// ----------------------------------------------------------------
- (void)generateUpdate {
    // 1. 准备配置对象
    UpdateGenerationConfig *config = [[UpdateGenerationConfig alloc] init];
    config.oldAppPath = self.oldAppDir;
    config.latestAppPath = self.latestAppDir; // [改名]
    config.outputDirectory = self.outputDir;
    
    // 2. 校验基本参数
    NSError *error = nil;
    if (![config validate:&error]) {
        [AlertPresenter showError:error.localizedDescription inWindow:self.view.window];
        return;
    }
    
    // 3. 获取 Delta 文件名 (用户交互)
    NSString *deltaName = [self promptForDeltaFileName:config.latestAppPath];
    if (!deltaName) return; // 用户取消
    config.deltaFilename = deltaName;
    
    // 4. 解析元数据 (自动获取 Version, AppName 等)
    [config parseAppMetadata];
    [self logToScreen:[NSString stringWithFormat:@"🚀 Preparing update for: %@ (%@ -> %@)", config.appName, config.oldVersion, config.latestVersion] type:LogLevelInfo];
    
    // 5. 调用业务管家 (Pipeline)
    self.generateUpdateButton.enabled = NO;
    
    __weak typeof(self) weakSelf = self;
    [[UpdatePipelineManager sharedManager] runPipelineWithConfig:config
                                                        logBlock:^(NSString *message, BOOL isError) {
        // [线程安全] 确保 UI 更新在主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            [weakSelf logToScreen:message type:isError ? LogLevelError : LogLevelInfo];
        });
    } completion:^(BOOL success, NSString *jsonPath, NSError *error) {
        
        // [线程安全] 回调回主线程
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.generateUpdateButton.enabled = YES;
            
            if (success) {
                [weakSelf logToScreen:@"✅ Pipeline Completed Successfully!" type:LogLevelSuccess];
                [AlertPresenter showSuccess:@"Update Generation Complete!" inWindow:weakSelf.view.window];
                
                // 自动加载生成的 JSON 到编辑器
                if (jsonPath) {
                    [weakSelf loadJSONFromFileAtPath:jsonPath];
                }
            } else {
                [weakSelf logToScreen:[NSString stringWithFormat:@"❌ Pipeline Failed: %@", error.localizedDescription] type:LogLevelError];
                [AlertPresenter showError:error.localizedDescription inWindow:weakSelf.view.window];
            }
        });
    }];
}

// 辅助：弹窗询问 Delta 文件名
- (NSString *)promptForDeltaFileName:(NSString *)appNamePath {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Enter Delta Filename"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    // 简单的默认名
    input.stringValue = @"update.delta";
    [alert setAccessoryView:input];
    
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSString *val = input.stringValue;
        return (val.length > 0) ? val : @"update.delta";
    }
    return nil;
}

#pragma mark - Actions: JSON Editor (Delegated to View)

- (void)loadJSONFromFileAtPath:(NSString *)filePath {
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (data) {
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
        if (dict) {
            [self.jsonEditorView reloadDataWithJSON:dict];
            [self logToScreen:@"JSON Loaded into Editor." type:LogLevelSuccess];
            // 更新当前 jsonPath，方便点击 Save 时覆盖
            self.jsonPath = filePath;
        }
    }
}

- (void)loadJSONFromFile {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"json"];
    if ([panel runModal] == NSModalResponseOK) {
        [self loadJSONFromFileAtPath:panel.URL.path];
    }
}

- (void)saveJSONToFile {
    // 强制结束编辑
    [self.view.window makeFirstResponder:nil];
    
    // 从组件获取数据
    NSDictionary *finalJSON = [self.jsonEditorView exportJSON];
    
    NSError *err = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:finalJSON options:NSJSONWritingPrettyPrinted error:&err];
    
    if (err) {
        [AlertPresenter showError:err.localizedDescription inWindow:self.view.window];
        return;
    }
    
    // 如果没有加载过文件，使用默认路径
    NSString *targetPath = self.jsonPath;
    
    // 尝试根据 appName 改名 (可选逻辑)
    NSString *appName = finalJSON[@"appName"];
    if (appName && [appName isKindOfClass:[NSString class]] && appName.length > 0) {
        NSString *dir = [targetPath stringByDeletingLastPathComponent];
        targetPath = [dir stringByAppendingPathComponent:[appName stringByAppendingPathExtension:@"json"]];
    }
    
    if ([data writeToFile:targetPath atomically:YES]) {
        [AlertPresenter showSuccess:[NSString stringWithFormat:@"Saved to %@", targetPath] inWindow:self.view.window];
        [self logToScreen:[NSString stringWithFormat:@"Saved JSON to %@", targetPath] type:LogLevelSuccess];
        // 重新加载以确认
        [self loadJSONFromFileAtPath:targetPath];
    } else {
        [AlertPresenter showError:@"Failed to write file" inWindow:self.view.window];
    }
}

#pragma mark - Actions: Test Apply

- (void)setUpApplyUpdateWindow {
    AppUpdateViewController *vc = [[AppUpdateViewController alloc] init];
    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 450)
                                                   styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable
                                                     backing:NSBackingStoreBuffered defer:NO];
    [window setTitle:@"Test Apply Update"];
    [window setContentViewController:vc];
    [window center];
    self.updateWindowController = [[NSWindowController alloc] initWithWindow:window];
    [self.updateWindowController showWindow:self];
}

@end
