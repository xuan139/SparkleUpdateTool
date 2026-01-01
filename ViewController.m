//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//
//  Refactored with Product-Level UI Toolkit
//  Fixed: JSON UI not showing, Thread 4 Crash, ARC Write-back, Layout Constraints
//

#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

// 引入业务逻辑类
#import "BinaryDeltaManager.h"
#import "FileHelper.h"
#import "AppUpdateViewController.h"

// 引入新的 UI Toolkit
#import "UIFactory.h"
#import "UITheme.h"
#import "AlertPresenter.h"

// --- 关键修复 1: 定义一个 FlippedStackView ---
// 解决 JSON 编辑器内容不显示或显示位置错误的问题
@interface FlippedStackView : NSStackView
@end

@implementation FlippedStackView
- (BOOL)isFlipped {
    return YES; // 让坐标系从顶部开始，内容从上往下排
}
@end
// ----------------------------------------

@implementation ViewController

#pragma mark - Lifecycle & View Setup

- (void)loadView {
    // 1. 创建主 View，不设置 Frame，由 Window 决定
    NSView *view = [[NSView alloc] init];
    self.view = view;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 初始化数据
    self.jsonFieldMap = [NSMutableDictionary dictionary];
    
    // 2. 搭建 UI (Auto Layout)
    [self setupLayout];
    
    // 3. 初始化目录
    [self setupDir];
}

- (void)setupLayout {
    // --- 主容器 (垂直 Stack) ---
    NSStackView *mainStack = [[NSStackView alloc] init];
    mainStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    mainStack.alignment = NSLayoutAttributeLeading; // 使用 Leading 对齐
    mainStack.spacing = 16;
    mainStack.edgeInsets = NSEdgeInsetsMake(20, 20, 20, 20); // 内边距
    mainStack.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:mainStack];
    
    // 约束：撑满整个 View
    [NSLayoutConstraint activateConstraints:@[
        [mainStack.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [mainStack.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [mainStack.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor],
        [mainStack.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor]
    ]];

    // --- 1. 顶部：文件选择区 ---
    
    // 使用局部变量接收指针回写，解决 ARC Write-back 错误
    NSTextField *tempOldPathField = nil;
    NSButton *tempOldButton = nil;
    
    NSView *oldAppRow = [self createSelectionRowWithLabel:@"Old App:"
                                                pathField:&tempOldPathField
                                                   button:&tempOldButton
                                                   action:@selector(selectOldApp)];
    [mainStack addArrangedSubview:oldAppRow];
    
    self.oldAppPathField = tempOldPathField;
    self.oldAppSelectButton = tempOldButton;
    
    // New App Row
    NSTextField *tempNewPathField = nil;
    NSButton *tempNewButton = nil;
    
    NSView *newAppRow = [self createSelectionRowWithLabel:@"New App:"
                                                pathField:&tempNewPathField
                                                   button:&tempNewButton
                                                   action:@selector(selectUpdatedApp)];
    [mainStack addArrangedSubview:newAppRow];
    
    self.updatedAppPathField = tempNewPathField;
    self.updatedAppSelectButton = tempNewButton;
    
    // --- 2. 顶部：操作按钮区 ---
    NSStackView *actionRow = [[NSStackView alloc] init];
    actionRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    actionRow.spacing = 20;
    // 确保 actionRow 本身横向填满
    [actionRow setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    
    self.generateUpdateButton = [UIFactory primaryButtonWithTitle:@"Generate Delta"
                                                           target:self
                                                           action:@selector(generateUpdate)];
    
    self.applyUpdateButton = [UIFactory buttonWithTitle:@"Test Apply Delta"
                                                 target:self
                                                 action:@selector(setUpApplyUpdateWindow)];
    
    [actionRow addArrangedSubview:self.generateUpdateButton];
    [actionRow addArrangedSubview:self.applyUpdateButton];
    // 添加弹簧视图，把按钮顶到左边
    [actionRow addArrangedSubview:[NSView new]];
    
    [mainStack addArrangedSubview:actionRow];
    // 让 ActionRow 宽度填满 MainStack
    [actionRow.widthAnchor constraintEqualToAnchor:mainStack.widthAnchor].active = YES;
    
    // --- 3. 底部：内容区 (日志 + JSON 编辑器) ---
    NSStackView *contentStack = [[NSStackView alloc] init];
    contentStack.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    contentStack.distribution = NSStackViewDistributionFillEqually; // 左右等宽
    contentStack.spacing = 20;
    
    // 左侧：日志视图
    [contentStack addArrangedSubview:[self createLogSection]];
    
    // 右侧：JSON 编辑器
    [contentStack addArrangedSubview:[self createJSONEditorSection]];
    
    [mainStack addArrangedSubview:contentStack];
    // 让 ContentStack 宽度填满 MainStack
    [contentStack.widthAnchor constraintEqualToAnchor:mainStack.widthAnchor].active = YES;
    
    [self logMessage:@"System initialized. Ready."];
}

// 辅助：创建文件选择行
- (NSView *)createSelectionRowWithLabel:(NSString *)text
                              pathField:(NSTextField **)fieldPtr
                                 button:(NSButton **)btnPtr
                                 action:(SEL)action {
    NSStackView *row = [[NSStackView alloc] init];
    row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    row.spacing = 10;
    
    // Label (定宽)
    NSTextField *label = [UIFactory labelWithText:text];
    [label.widthAnchor constraintEqualToConstant:80].active = YES;
    [row addArrangedSubview:label];
    
    // Field (自动拉伸)
    NSTextField *field = [UIFactory pathDisplayFieldWithPlaceholder:@"Path not selected..."];
    [field setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
    [row addArrangedSubview:field];
    if (fieldPtr) *fieldPtr = field;
    
    // Button
    NSButton *btn = [UIFactory buttonWithTitle:@"Choose..." target:self action:action];
    [row addArrangedSubview:btn];
    if (btnPtr) *btnPtr = btn;
    
    // NSLayoutAnchor 没有 priority 参数，必须分步写
    NSLayoutConstraint *widthConstraint = [row.widthAnchor constraintEqualToConstant:0];
    widthConstraint.priority = NSLayoutPriorityFittingSizeCompression; // 允许被拉伸
    widthConstraint.active = YES;
    
    return row;
}

// 辅助：创建日志区域
- (NSView *)createLogSection {
    NSStackView *container = [[NSStackView alloc] init];
    container.orientation = NSUserInterfaceLayoutOrientationVertical;
    container.alignment = NSLayoutAttributeLeading;
    container.spacing = 8;
    
    [container addArrangedSubview:[UIFactory labelWithText:@"Process Log:"]];
    
    self.logView = [[SmartLogView alloc] init];
    [container addArrangedSubview:self.logView];
    
    // 约束日志视图宽高
    [self.logView.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;
    [self.logView.heightAnchor constraintGreaterThanOrEqualToConstant:300].active = YES;
    
    return container;
}

// 辅助：创建 JSON 编辑区域 (修复显示问题)
- (NSView *)createJSONEditorSection {
    NSStackView *container = [[NSStackView alloc] init];
    container.orientation = NSUserInterfaceLayoutOrientationVertical;
    container.alignment = NSLayoutAttributeLeading;
    container.spacing = 8;
    
    [container addArrangedSubview:[UIFactory labelWithText:@"Appcast JSON Editor:"]];
    
    // 滚动区域
    NSScrollView *scrollView = [[NSScrollView alloc] init];
    scrollView.hasVerticalScroller = YES;
    scrollView.autohidesScrollers = YES;
    scrollView.borderType = NSBezelBorder;
    scrollView.drawsBackground = NO; // 修复：透明背景
    
    // 内部 StackView (用于动态添加行)
    // 🛠 关键修复 1: 使用 FlippedStackView 确保从顶部开始排列
    self.jsonEditorStack = [[FlippedStackView alloc] init];
    self.jsonEditorStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.jsonEditorStack.alignment = NSLayoutAttributeLeading;
    self.jsonEditorStack.spacing = 10;
    self.jsonEditorStack.edgeInsets = NSEdgeInsetsMake(10, 10, 10, 10);
    self.jsonEditorStack.translatesAutoresizingMaskIntoConstraints = NO; // 🛠 关键修复 2: 开启 AutoLayout
    
    // 将 StackView 放入 ScrollView
    scrollView.documentView = self.jsonEditorStack;
    
    // 🛠 关键修复 3: 强制 StackView 宽度等于 ScrollView 内容区宽度
    [self.jsonEditorStack.widthAnchor constraintEqualToAnchor:scrollView.contentView.widthAnchor].active = YES;
    
    // 约束 ScrollView 撑开
    [scrollView.heightAnchor constraintGreaterThanOrEqualToConstant:300].active = YES;
    [container addArrangedSubview:scrollView];
    
    // 底部按钮栏
    NSStackView *btnRow = [[NSStackView alloc] init];
    btnRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
    [btnRow addArrangedSubview:[UIFactory buttonWithTitle:@"Save JSON" target:self action:@selector(saveJSONToFile)]];
    [btnRow addArrangedSubview:[UIFactory buttonWithTitle:@"Load JSON" target:self action:@selector(loadJSONFromFile)]];
    [btnRow addArrangedSubview:[NSView new]]; // Spacer
    
    [container addArrangedSubview:btnRow];
    
    // 约束 Container 宽度
    [scrollView.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;
    [btnRow.widthAnchor constraintEqualToAnchor:container.widthAnchor].active = YES;

    return container;
}

#pragma mark - 核心业务逻辑 (Refined Log & Alert)

- (void)logMessage:(NSString *)message {
    // 1. 使用 SmartLogView 显示 (SmartLogView 内部已经确保了主线程)
    [self.logView appendLog:message level:LogLevelInfo];
    
    // 2. 写入文件
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
    [self.logView appendLog:[NSString stringWithFormat:@"📂 Output: %@", _outputDir] level:LogLevelWarning];
    [self.logView appendLog:[NSString stringWithFormat:@"📂 Delta: %@", _deltaDir] level:LogLevelWarning];
    [self.logView appendLog:[NSString stringWithFormat:@"📂 Logs: %@", _logFileDir] level:LogLevelWarning];
    [self.logView appendLog:[NSString stringWithFormat:@"📂 JSON: %@", _jsonPath] level:LogLevelWarning];
}

#pragma mark - Actions: Select App

- (void)selectOldApp {
    NSString *path = [self openAppFromSubdirectory:@"sparkleOldApp"];
    if (path) {
        _oldAppDir = path;
        self.oldAppPathField.stringValue = path;
        [self.logView appendLog:[NSString stringWithFormat:@"✅ Selected Old App: %@", path] level:LogLevelSuccess];
        
        NSDictionary *versionInfo = [FileHelper getAppVersionInfoFromPath:path logBlock:^(NSString *msg) {
            [self.logView appendLog:msg level:LogLevelInfo];
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
        [self.logView appendLog:[NSString stringWithFormat:@"✅ Selected New App: %@", path] level:LogLevelSuccess];
        
        NSDictionary *versionInfo = [FileHelper getAppVersionInfoFromPath:path logBlock:^(NSString *msg) {
            [self.logView appendLog:msg level:LogLevelInfo];
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

#pragma mark - Actions: Generate

- (void)generateUpdate {
    [self.logView appendLog:@"🚀 Starting Generation Process..." level:LogLevelInfo];
    
    if (_oldAppDir.length == 0 || _NewAppDir.length == 0) {
        [AlertPresenter showError:@"Please select both Old and New Apps first." inWindow:self.view.window];
        return;
    }
    
    _deltaPath = [self promptForDeltaFilePathWithBaseDir:_deltaDir];
    if (!_deltaPath) return;
    
    self.generateUpdateButton.enabled = NO;
    [self.logView appendLog:@"⏳ Generating Delta Patch (Async)..." level:LogLevelWarning];

    __weak typeof(self) weakSelf = self;

    [BinaryDeltaManager createDeltaFromOldPath:self.oldAppDir
                                     toNewPath:self.NewAppDir
                                    outputPath:self.deltaPath
                                      logBlock:^(NSString *log) {
        [weakSelf.logView appendLog:log level:LogLevelInfo];
    } completion:^(BOOL success, NSError *error) {
        
        if (success) {
            [weakSelf.logView appendLog:@"✅ Delta Patch Generated Successfully!" level:LogLevelSuccess];
            
            [FileHelper copyFileAtPath:weakSelf.oldAppDir toDirectory:weakSelf.outputDir];
            [FileHelper copyFileAtPath:weakSelf.NewAppDir toDirectory:weakSelf.outputDir];
            [FileHelper copyFileAtPath:weakSelf.deltaPath toDirectory:weakSelf.outputDir];
            
            [AlertPresenter showSuccess:[NSString stringWithFormat:@"Delta created at: %@", weakSelf.deltaPath] inWindow:weakSelf.view.window];

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
            
            [weakSelf.logView appendLog:@"📦 Zipping application..." level:LogLevelInfo];
            
            // FileHelper 的 completion 是在后台线程执行的
            [FileHelper zipAppAtPath:appFilePath logBlock:^(NSString *message) {
                 [weakSelf.logView appendLog:message level:LogLevelInfo];
            } completion:^(NSString *zipFilePath) {
                
                // --- 这里是在后台线程 ---
                
                NSString *zipfileSize = [NSString stringWithFormat:@"%llu", [FileHelper fileSizeAtPath:zipFilePath]];
                
                NSError *jsonError = nil;
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
                
                // 🛠 关键修复: 切换回主线程进行 UI 更新 (修复 Thread 4 Crash)
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (jsonSuccess) {
                        [weakSelf.logView appendLog:@"✅ JSON Created!" level:LogLevelSuccess];
                        [AlertPresenter showSuccess:@"JSON file generated successfully." inWindow:weakSelf.view.window];
                        [weakSelf loadJSONFromFileAtPath:jsonPath];
                    } else {
                        [weakSelf.logView appendLog:[NSString stringWithFormat:@"❌ JSON Generation Failed: %@", jsonError] level:LogLevelError];
                    }
                    
                    weakSelf.generateUpdateButton.enabled = YES;
                });
            }];
            
        } else {
            NSString *err = error.localizedDescription;
            [weakSelf.logView appendLog:[NSString stringWithFormat:@"❌ Generation Failed: %@", err] level:LogLevelError];
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

// --- JSON 编辑器逻辑 (Auto Layout 适配版) ---

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
    NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];
    if (!dict) return;
    
    // 🛠 关键修复: 确保在主线程更新 UI
    dispatch_async(dispatch_get_main_queue(), ^{
        self.currentJSON = dict;
        
        // 1. 清空现有的 Field (使用 copy 防止遍历时修改数组崩溃)
        NSArray *existingViews = [self.jsonEditorStack.arrangedSubviews copy];
        for (NSView *view in existingViews) {
            [self.jsonEditorStack removeView:view];
            [view removeFromSuperview];
        }
        [self.jsonFieldMap removeAllObjects];
        
        // 2. 递归创建新 UI
        [self createFieldsForJSON:dict prefix:@"" indent:0];
        
        // 3. 强制刷新布局
        [self.jsonEditorStack layoutSubtreeIfNeeded];
        
        [self.logView appendLog:@"JSON Loaded into UI." level:LogLevelSuccess];
    });
}

- (void)createFieldsForJSON:(NSDictionary *)json prefix:(NSString *)prefix indent:(CGFloat)indent {
    [json enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        NSString *fullKey = prefix.length ? [NSString stringWithFormat:@"%@.%@", prefix, key] : key;
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            NSTextField *groupLabel = [UIFactory labelWithText:key];
            groupLabel.font = [NSFont boldSystemFontOfSize:12];
            
            NSStackView *groupRow = [[NSStackView alloc] init];
            groupRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
            [groupRow addArrangedSubview:[[NSView alloc] initWithFrame:NSMakeRect(0, 0, indent, 10)]];
            [groupRow addArrangedSubview:groupLabel];
            [self.jsonEditorStack addArrangedSubview:groupRow];
            
            [groupRow.widthAnchor constraintEqualToAnchor:self.jsonEditorStack.widthAnchor].active = NO;
            
            [self createFieldsForJSON:obj prefix:fullKey indent:indent + 20];
            
        } else {
            NSStackView *row = [[NSStackView alloc] init];
            row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
            
            if (indent > 0) {
                 [row addArrangedSubview:[[NSView alloc] initWithFrame:NSMakeRect(0, 0, indent, 10)]];
            }
            
            NSTextField *keyLabel = [UIFactory labelWithText:key];
            [keyLabel.widthAnchor constraintEqualToConstant:100].active = YES;
            [row addArrangedSubview:keyLabel];
            
            NSTextField *valField = [[NSTextField alloc] init];
            valField.stringValue = [NSString stringWithFormat:@"%@", obj];
            valField.toolTip = fullKey;
            [valField setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
            [row addArrangedSubview:valField];
            
            [self.jsonEditorStack addArrangedSubview:row];
            self.jsonFieldMap[fullKey] = valField;
            
             [row.widthAnchor constraintEqualToAnchor:self.jsonEditorStack.widthAnchor].active = YES;
        }
    }];
}

- (void)saveJSONToFile {
    [self.view.window makeFirstResponder:nil];
    
    NSString *fileName = self.jsonFieldMap[@"appName"].stringValue ?: @"update";
    
    NSMutableDictionary *flatJSON = [NSMutableDictionary dictionary];
    for (NSString *key in self.jsonFieldMap) {
        flatJSON[key] = self.jsonFieldMap[key].stringValue;
    }
    
    NSDictionary *nested = [self reconstructNestedDictionaryFromFlat:flatJSON];
    
    // 使用局部变量接收 error，解决 Write-back 错误
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:nested options:NSJSONWritingPrettyPrinted error:&error];
    
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

- (NSDictionary *)reconstructNestedDictionaryFromFlat:(NSDictionary *)flatDict {
    NSMutableDictionary *nested = [NSMutableDictionary dictionary];
    for (NSString *flatKey in flatDict) {
        NSArray *components = [flatKey componentsSeparatedByString:@"."];
        NSMutableDictionary *current = nested;
        for (NSInteger i = 0; i < components.count; i++) {
            NSString *part = components[i];
            if (i == components.count - 1) {
                current[part] = flatDict[flatKey];
            } else {
                if (!current[part]) current[part] = [NSMutableDictionary dictionary];
                current = current[part];
            }
        }
    }
    return nested;
}

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
