//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//
//  Refactored Phase 1: Integrated DynamicJSONEditorView
//

#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// 引入业务逻辑类
#import "BinaryDeltaManager.h"
#import "FileHelper.h"
#import "AppUpdateViewController.h"

// 引入 UI Toolkit
#import "UIFactory.h"
#import "UITheme.h"
#import "AlertPresenter.h"
#import "SmartLogView.h"

// [新增] 引入新剥离的组件
#import "DynamicJSONEditorView.h"

// [删除] FlippedStackView 类的定义已移除 (移入了 DynamicJSONEditorView.m)

@interface ViewController ()

// [新增] 私有属性持有新的编辑器组件
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
    
    // [删除] self.jsonFieldMap = [NSMutableDictionary dictionary]; // 不再需要
    
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

    // --- 1. 顶部：文件选择区 (代码保持不变) ---
    NSTextField *tempOldPathField = nil;
    NSButton *tempOldButton = nil;
    NSView *oldAppRow = [self createSelectionRowWithLabel:@"Old App:" pathField:&tempOldPathField button:&tempOldButton action:@selector(selectOldApp)];
    [mainStack addArrangedSubview:oldAppRow];
    self.oldAppPathField = tempOldPathField;
    self.oldAppSelectButton = tempOldButton;
    
    NSTextField *tempNewPathField = nil;
    NSButton *tempNewButton = nil;
    NSView *newAppRow = [self createSelectionRowWithLabel:@"New App:" pathField:&tempNewPathField button:&tempNewButton action:@selector(selectUpdatedApp)];
    [mainStack addArrangedSubview:newAppRow];
    self.updatedAppPathField = tempNewPathField;
    self.updatedAppSelectButton = tempNewButton;
    
    // --- 2. 顶部：操作按钮区 (代码保持不变) ---
    NSStackView *actionRow = [[NSStackView alloc] init];
    actionRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    actionRow.spacing = 20;
    [actionRow setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    self.generateUpdateButton = [UIFactory primaryButtonWithTitle:@"Generate Delta" target:self action:@selector(generateUpdate)];
    self.applyUpdateButton = [UIFactory buttonWithTitle:@"Test Apply Delta" target:self action:@selector(setUpApplyUpdateWindow)];
    
    [actionRow addArrangedSubview:self.generateUpdateButton];
    [actionRow addArrangedSubview:self.applyUpdateButton];
    [actionRow addArrangedSubview:[NSView new]];
    [mainStack addArrangedSubview:actionRow];
    [actionRow.widthAnchor constraintEqualToAnchor:mainStack.widthAnchor].active = YES;
    
    // --- 3. 底部：内容区 (日志 + JSON 编辑器) ---
    NSStackView *contentStack = [[NSStackView alloc] init];
    contentStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    contentStack.distribution = NSStackViewDistributionFillEqually;
    contentStack.spacing = 20;
    
    // 左侧：日志视图
    [contentStack addArrangedSubview:[self createLogSection]];
    
    // [修改] 右侧：JSON 编辑器 (调用更新后的方法)
    [contentStack addArrangedSubview:[self createJSONEditorSection]];
    
    [mainStack addArrangedSubview:contentStack];
    [contentStack.widthAnchor constraintEqualToAnchor:mainStack.widthAnchor].active = YES;
    
    [self logMessage:@"System initialized. Ready."];
}

// 辅助：创建文件选择行 (保持不变)
- (NSView *)createSelectionRowWithLabel:(NSString *)text pathField:(NSTextField **)fieldPtr button:(NSButton **)btnPtr action:(SEL)action {
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
    
    NSButton *btn = [UIFactory buttonWithTitle:@"Choose..." target:self action:action];
    [row addArrangedSubview:btn];
    if (btnPtr) *btnPtr = btn;
    
    NSLayoutConstraint *widthConstraint = [row.widthAnchor constraintEqualToConstant:0];
    widthConstraint.priority = NSLayoutPriorityFittingSizeCompression;
    widthConstraint.active = YES;
    return row;
}

// 辅助：创建日志区域 (保持不变)
- (NSView *)createLogSection {
    NSStackView *container = [[NSStackView alloc] init];
    container.orientation = NSUserInterfaceLayoutOrientationVertical;
    container.alignment = NSLayoutAttributeLeading;
    container.spacing = 8;
    
    [container addArrangedSubview:[UIFactory labelWithText:@"Process Log:"]];
    
    // 强转以匹配属性类型（如果.h用了NSView）
    SmartLogView *logV = [[SmartLogView alloc] init];
    self.logView = logV;
    
    [container addArrangedSubview:self.logView];
    [self.logView.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;
    [self.logView.heightAnchor constraintGreaterThanOrEqualToConstant:300].active = YES;
    
    return container;
}

// ----------------------------------------------------------------
// [修改] 辅助：创建 JSON 编辑区域 (大幅简化)
// ----------------------------------------------------------------
- (NSView *)createJSONEditorSection {
    NSStackView *container = [[NSStackView alloc] init];
    container.orientation = NSUserInterfaceLayoutOrientationVertical;
    container.alignment = NSLayoutAttributeLeading;
    container.spacing = 8;
    
    [container addArrangedSubview:[UIFactory labelWithText:@"Appcast JSON Editor:"]];
    
    // [新增] 实例化 DynamicJSONEditorView
    self.jsonEditorView = [[DynamicJSONEditorView alloc] init];
    
    // 约束高度，确保有足够空间
    [self.jsonEditorView.heightAnchor constraintGreaterThanOrEqualToConstant:300].active = YES;
    
    [container addArrangedSubview:self.jsonEditorView];
    
    // 底部按钮栏
    NSStackView *btnRow = [[NSStackView alloc] init];
    btnRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    [btnRow addArrangedSubview:[UIFactory buttonWithTitle:@"Save JSON" target:self action:@selector(saveJSONToFile)]];
    [btnRow addArrangedSubview:[UIFactory buttonWithTitle:@"Load JSON" target:self action:@selector(loadJSONFromFile)]];
    [btnRow addArrangedSubview:[NSView new]]; // Spacer
    
    [container addArrangedSubview:btnRow];
    
    // 宽度约束
    [self.jsonEditorView.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;
    [btnRow.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;

    return container;
}

#pragma mark - 核心业务逻辑 (Log & Alert)

- (void)logMessage:(NSString *)message {
    if ([self.logView isKindOfClass:[SmartLogView class]]) {
        [(SmartLogView *)self.logView appendLog:message level:LogLevelInfo];
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        NSString *timestampedMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];
        
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFileDir];
        if (!fileHandle) {
            [[NSFileManager defaultManager] createFileAtPath:self.logFileDir contents:nil attributes:nil];
            fileHandle = [NSFileHandle fileHandleForWritingAtPath:self.logFileDir];
        }
        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            [fileHandle writeData:[timestampedMessage dataUsingEncoding:NSUTF8StringEncoding]];
            [fileHandle closeFile];
        }
    });
}

// 目录设置 (保持不变)
- (void)setupDir {
    _outputDir  = [FileHelper generateSubdirectory:@"sparkle_output"];
    _deltaDir   = [FileHelper fullPathInDocuments:@"sparkle_patch/update.delta"];
    _logFileDir = [FileHelper fullPathInDocuments:@"sparkleLogDir/sparkle_log.txt"];
    _jsonPath = [FileHelper fullPathInDocuments:@"sparkle_output/appVersion.json"];
    
    [FileHelper prepareEmptyFileAtPath:_deltaDir];
    [FileHelper prepareEmptyFileAtPath:_logFileDir];
    [FileHelper prepareEmptyFileAtPath:_jsonPath];
     
    [self logAllImportantPaths];
}

- (void)logAllImportantPaths {
    if ([self.logView isKindOfClass:[SmartLogView class]]) {
        SmartLogView *v = (SmartLogView *)self.logView;
        [v appendLog:[NSString stringWithFormat:@"📂 Output: %@", _outputDir] level:LogLevelWarning];
        [v appendLog:[NSString stringWithFormat:@"📂 Delta: %@", _deltaDir] level:LogLevelWarning];
        [v appendLog:[NSString stringWithFormat:@"📂 Logs: %@", _logFileDir] level:LogLevelWarning];
        [v appendLog:[NSString stringWithFormat:@"📂 JSON: %@", _jsonPath] level:LogLevelWarning];
    }
}

#pragma mark - Actions: Select App (保持不变)

- (void)selectOldApp {
    NSString *path = [self openAppFromSubdirectory:@"sparkleOldApp"];
    if (path) {
        _oldAppDir = path;
        self.oldAppPathField.stringValue = path;
        [(SmartLogView *)self.logView appendLog:[NSString stringWithFormat:@"✅ Selected Old App: %@", path] level:LogLevelSuccess];
        
        NSDictionary *versionInfo = [FileHelper getAppVersionInfoFromPath:path logBlock:^(NSString *msg) {
            [(SmartLogView *)self.logView appendLog:msg level:LogLevelInfo];
        }];
        
        if (versionInfo) {
            _oldVersion = versionInfo[@"version"];
            _oldBuildVersion = versionInfo[@"build"];
            _appNameOld = versionInfo[@"appName"];
            _appName = [FileHelper stripVersionFromAppName:_appNameOld];
            [self logMessage:[NSString stringWithFormat:@"Version Info: %@ (%@)", _oldVersion, _oldBuildVersion]];
        }
    }
}

- (void)selectUpdatedApp {
    NSString *path = [self openAppFromSubdirectory:@"sparkleNewApp"];
    if (path) {
        _NewAppDir = path;
        self.updatedAppPathField.stringValue = path;
        [(SmartLogView *)self.logView appendLog:[NSString stringWithFormat:@"✅ Selected New App: %@", path] level:LogLevelSuccess];
        
        NSDictionary *versionInfo = [FileHelper getAppVersionInfoFromPath:path logBlock:^(NSString *msg) {
            [(SmartLogView *)self.logView appendLog:msg level:LogLevelInfo];
        }];
        
        if (versionInfo) {
            _NewVersion = versionInfo[@"version"];
            _NewBuildVersion = versionInfo[@"build"];
            _appNameNew = versionInfo[@"appName"];
            [self logMessage:[NSString stringWithFormat:@"Version Info: %@ (%@)", _NewVersion, _NewBuildVersion]];
        }
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

#pragma mark - Actions: Generate (保持不变)

- (void)generateUpdate {
    [(SmartLogView *)self.logView appendLog:@"🚀 Starting Generation Process..." level:LogLevelInfo];
    
    if (_oldAppDir.length == 0 || _NewAppDir.length == 0) {
        [AlertPresenter showError:@"Please select both Old and New Apps first." inWindow:self.view.window];
        return;
    }
    
    _deltaPath = [self promptForDeltaFilePathWithBaseDir:_deltaDir];
    if (!_deltaPath) return;
    
    self.generateUpdateButton.enabled = NO;
    [(SmartLogView *)self.logView appendLog:@"⏳ Generating Delta Patch (Async)..." level:LogLevelWarning];

    __weak typeof(self) weakSelf = self;

    [BinaryDeltaManager createDeltaFromOldPath:self.oldAppDir
                                     toNewPath:self.NewAppDir
                                    outputPath:self.deltaPath
                                      logBlock:^(NSString *log) {
        [(SmartLogView *)weakSelf.logView appendLog:log level:LogLevelInfo];
    } completion:^(BOOL success, NSError *error) {
        
        if (success) {
            [(SmartLogView *)weakSelf.logView appendLog:@"✅ Delta Patch Generated Successfully!" level:LogLevelSuccess];
            
            [FileHelper copyFileAtPath:weakSelf.oldAppDir toDirectory:weakSelf.outputDir];
            [FileHelper copyFileAtPath:weakSelf.NewAppDir toDirectory:weakSelf.outputDir];
            [FileHelper copyFileAtPath:weakSelf.deltaPath toDirectory:weakSelf.outputDir];
            
            [AlertPresenter showSuccess:[NSString stringWithFormat:@"Delta created at: %@", weakSelf.deltaPath] inWindow:weakSelf.view.window];

            // ... (保持原有的 URL 拼接逻辑) ...
            NSString *baseURL = @"https://unigo.ai/uploads/";
            NSString *appName = weakSelf.appName;
            NSString *lastVersion = weakSelf.oldVersion;
            NSString *latestVersion = weakSelf.NewVersion;
            
            NSString *jsonPath = [FileHelper replaceFileNameInPath:weakSelf.jsonPath withNewName:appName];
            NSString *deltaFileName = [NSString stringWithFormat:@"%@-%@-%@.delta", appName, lastVersion, latestVersion];
            NSString *deltaURL = [baseURL stringByAppendingString:deltaFileName];
            NSString *downloadURL = [baseURL stringByAppendingString:[NSString stringWithFormat:@"%@-%@.zip", appName, latestVersion]];
            
            NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
            NSString *outputDir = [documentsPath stringByAppendingPathComponent:@"sparkle_output"];
            NSString *deltaFilePath = [outputDir stringByAppendingPathComponent:deltaFileName];
            NSString *appFilePath = [outputDir stringByAppendingPathComponent:[NSString stringWithFormat:@"%@-%@.app", appName, latestVersion]];
            
            NSString *deltaSize = [FileHelper strfileSizeAtPath:deltaFilePath];
            
            [(SmartLogView *)weakSelf.logView appendLog:@"📦 Zipping application..." level:LogLevelInfo];
            
            [FileHelper zipAppAtPath:appFilePath logBlock:^(NSString *message) {
                 [(SmartLogView *)weakSelf.logView appendLog:message level:LogLevelInfo];
            } completion:^(NSString *zipFilePath) {
                
                NSString *zipfileSize = [NSString stringWithFormat:@"%llu", [FileHelper fileSizeAtPath:zipFilePath]];
                NSError *jsonError = nil;
                
                // 调用下方的辅助方法生成 JSON
                BOOL jsonSuccess = [weakSelf generateFullVersionJSONWithAppName:appName
                                                                    lastVersion:lastVersion
                                                                  latestVersion:latestVersion
                                                                  deltaFileName:deltaFileName
                                                                      deltaSize:deltaSize
                                                                    zipfileSize:zipfileSize
                                                                       deltaURL:deltaURL
                                                                    downloadURL:downloadURL
                                                                    wineVersion:@"10.0"
                                                                  preservePaths:@[@"steamapps", @"userdata", @"config"]
                                                                       jsonPath:jsonPath
                                                                          error:&jsonError];
                
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (jsonSuccess) {
                        [(SmartLogView *)weakSelf.logView appendLog:@"✅ JSON Created!" level:LogLevelSuccess];
                        [AlertPresenter showSuccess:@"JSON file generated successfully." inWindow:weakSelf.view.window];
                        // [修改] 调用新方法加载 JSON
                        [weakSelf loadJSONFromFileAtPath:jsonPath];
                    } else {
                        [(SmartLogView *)weakSelf.logView appendLog:[NSString stringWithFormat:@"❌ JSON Generation Failed: %@", jsonError] level:LogLevelError];
                    }
                    weakSelf.generateUpdateButton.enabled = YES;
                });
            }];
            
        } else {
            NSString *err = error.localizedDescription;
            [(SmartLogView *)weakSelf.logView appendLog:[NSString stringWithFormat:@"❌ Generation Failed: %@", err] level:LogLevelError];
            [AlertPresenter showError:err inWindow:weakSelf.view.window];
            weakSelf.generateUpdateButton.enabled = YES;
        }
    }];
}

- (NSString *)promptForDeltaFilePathWithBaseDir:(NSString *)baseDir {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Enter Delta Filename"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    input.stringValue = [NSString stringWithFormat:@"%@-%@.delta", _appNameOld ?: @"App", _NewVersion ?: @"vNew"];
    [alert setAccessoryView:input];
    if ([alert runModal] == NSAlertFirstButtonReturn) {
        NSString *name = input.stringValue;
        if (name.length == 0) name = @"update.delta";
        return [[baseDir stringByDeletingLastPathComponent] stringByAppendingPathComponent:name];
    }
    return nil;
}

#pragma mark - Actions: Test Apply & JSON Logic

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

// ----------------------------------------------------------------
// [修改] JSON 核心逻辑：全部委托给 jsonEditorView
// ----------------------------------------------------------------

- (void)loadJSONFromFileAtPath:(NSString *)filePath {
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    [self loadJSONFromData:data];
}

- (void)loadJSONFromFile {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"json"];
    if ([panel runModal] == NSModalResponseOK) {
        [self loadJSONFromFileAtPath:panel.URL.path];
    }
}

- (void)loadJSONFromData:(NSData *)data {
    if (!data) return;
    NSError *error = nil;
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    
    if (dict) {
        // [修改] 直接调用组件方法
        [self.jsonEditorView reloadDataWithJSON:dict];
        
        [(SmartLogView *)self.logView appendLog:@"JSON Loaded into UI." level:LogLevelSuccess];
    } else {
        [(SmartLogView *)self.logView appendLog:@"❌ Failed to parse JSON data." level:LogLevelError];
    }
}

- (void)saveJSONToFile {
    [self.view.window makeFirstResponder:nil]; // 确保当前输入框失去焦点，完成提交
    
    // [修改] 从组件获取最终数据
    NSDictionary *finalJSON = [self.jsonEditorView exportJSON];
    
    // 获取文件名逻辑
    NSString *fileName = finalJSON[@"appName"] ?: @"update";
    if ([fileName isKindOfClass:[NSNull class]]) fileName = @"update";
    
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:finalJSON options:NSJSONWritingPrettyPrinted error:&error];
    
    if (error) {
        [AlertPresenter showError:[NSString stringWithFormat:@"Serialization Failed: %@", error.localizedDescription] inWindow:self.view.window];
        return;
    }
    
    NSString *path = [self.jsonPath stringByDeletingLastPathComponent];
    NSString *fullPath = [path stringByAppendingPathComponent:[fileName stringByAppendingPathExtension:@"json"]];
    
    if ([data writeToFile:fullPath atomically:YES]) {
        [AlertPresenter showSuccess:[NSString stringWithFormat:@"Saved to %@", fullPath] inWindow:self.view.window];
        [self loadJSONFromFileAtPath:fullPath];
    } else {
        [AlertPresenter showError:@"Save to Disk Failed" inWindow:self.view.window];
    }
}

// [删除] reconstructNestedDictionaryFromFlat 方法已删除
// [删除] createFieldsForJSON 方法已删除

// 辅助方法：生成 JSON (暂时保留在 VC，下一阶段重构业务逻辑时移除)
- (BOOL)generateFullVersionJSONWithAppName:(NSString *)appName
                                lastVersion:(NSString *)lastVersion
                               latestVersion:(NSString *)latestVersion
                               deltaFileName:(NSString *)deltaFileName
                                   deltaSize:(NSString *)deltaSize
                                    zipfileSize:(NSString *)zipfileSize
                                     deltaURL:(NSString *)deltaURL
                                     downloadURL:(NSString *)downloadURL
                                     wineVersion:(NSString *)wineVersion
                                     preservePaths:(NSArray<NSString *> *)preservePaths
                                        jsonPath:(NSString *)jsonPath
                                           error:(NSError **)error {
    
    NSMutableDictionary *preserveDict = [NSMutableDictionary dictionary];
    for (NSInteger i = 0; i < preservePaths.count; i++) {
        preserveDict[@(i).stringValue] = preservePaths[i];
    }

    NSDictionary *jsonDict = @{
        @"appName": appName ?: @"",
        @"lastVersion": lastVersion ?: @"",
        @"latestVersion": latestVersion ?: @"",
        @"deltaFileName": deltaFileName ?: @"",
        @"deltaSize": deltaSize ?: @"0",
        @"fileSize": zipfileSize ?: @"0",
        @"deltaURL": deltaURL ?: @"",
        @"downloadURL": downloadURL ?: @"",
        @"releaseDate": [[NSDate date] description],
        @"minimumSystemVersion": @"13.5",
        @"description": [NSString stringWithFormat:@"%@ client update", appName],
        @"signature": @"base64_encoded_signature",
        @"wineConfig": @{
            @"bottleName": appName ?: @"",
            @"wineVersion": wineVersion ?: @"",
            @"preservePaths": preserveDict
        }
    };
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonDict options:NSJSONWritingPrettyPrinted error:error];
    if (!data) return NO;
    
    return [data writeToFile:jsonPath atomically:YES];
}

@end
