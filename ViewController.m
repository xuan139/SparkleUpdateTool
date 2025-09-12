//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//
#import <Cocoa/Cocoa.h>
#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "BinaryDeltaManager.h"
#import "FileHelper.h"
#import "AppcastGenerator.h"
#import "AppUpdateViewController.h"
#import "UIHelper.h"

@implementation ViewController

- (void)loadView {
    // 创建根视图
    [self setupRootViewWithWidthRatio:0.8 heightRatio:0.9];
}


// 创建一个动态大小的根视图，宽高为屏幕比例
- (void)setupRootViewWithWidthRatio:(CGFloat)widthRatio heightRatio:(CGFloat)heightRatio {
    NSScreen *screen = [NSScreen mainScreen];
    NSRect screenFrame = [screen visibleFrame];

    CGFloat width = screenFrame.size.width * widthRatio;
    CGFloat height = screenFrame.size.height * heightRatio;

    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, width, height)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupDir];
//    [self checkAndHandleBinaryDelta];
    
    // 初始化字典
    self.jsonFieldMap = [NSMutableDictionary dictionary];

    // 加载 JSON 文件
    [self loadJSONFromFile:@"sample.json"];
    
}

#pragma mark - setupUI
- (void)setupUI {
    // 起始位置
    CGFloat startX = 10;
    CGFloat startY = 660;  // 顶部向下起始
    CGFloat verticalSpacing = 40;

    // 各控件宽度
    CGFloat labelWidth = 100;
    CGFloat fieldWidth = 360;
    CGFloat buttonWidth = 80;

    // --- Old App ---
    NSDictionary *oldAppControls = [self setupAppSelectorWithLabel:@"Old App"
                                                             action:@selector(selectOldApp)
                                                               x:startX
                                                               y:startY
                                                        labelWidth:labelWidth
                                                        fieldWidth:fieldWidth
                                                       buttonWidth:buttonWidth];
    self.oldAppLabel = oldAppControls[@"label"];
    self.oldAppPathField = oldAppControls[@"field"];
    self.oldAppSelectButton = oldAppControls[@"button"];

    // --- New App ---
    NSDictionary *newAppControls = [self setupAppSelectorWithLabel:@"New App"
                                                             action:@selector(selectUpdatedApp)
                                                               x:startX
                                                               y:startY - verticalSpacing
                                                        labelWidth:labelWidth
                                                        fieldWidth:fieldWidth
                                                       buttonWidth:buttonWidth];
    self.updatedAppLabel = newAppControls[@"label"];
    self.updatedAppPathField = newAppControls[@"field"];
    self.updatedAppSelectButton = newAppControls[@"button"];

    // --- Generate & Apply Buttons ---
    [self setupGenerateButtonAtX:startX
                               y:startY - verticalSpacing * 2
                             width:160
                           spacing:20];

    CGFloat logHeight = 500;
    CGFloat logWidth = 550;
    CGFloat logY = startY - verticalSpacing * 2 - 50 - logHeight;

    NSTextView *logTextView = [[NSTextView alloc] initWithFrame:NSMakeRect(0, 0, logWidth, logHeight)];
    logTextView.editable = NO;
    logTextView.font = [NSFont systemFontOfSize:16];  // 字体大小，可调，比如 14 或 16

    NSScrollView *logScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(startX, logY, logWidth, logHeight)];
    logScrollView.documentView = logTextView;
    logScrollView.hasVerticalScroller = YES;
    logScrollView.hasHorizontalScroller = YES;
    logScrollView.autohidesScrollers = YES;

    [self.view addSubview:logScrollView];
    self.logTextView = logTextView;

//    [self.view addSubview:logScrollView];

    [self logMessage:@"Begin logging"];
    
    
    // 假设 self.currentJSON 已经加载了 NSDictionary
//    NSDictionary *jsonDict = self.currentJSON; // 或者通过 loadJSONFromFile:@"sample.json" 读取
    // 加载 JSON
    NSString *jsonPath = [[NSBundle mainBundle] pathForResource:@"sample" ofType:@"json"];
    NSData *jsonData = [NSData dataWithContentsOfFile:jsonPath];
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:&error];
    if (!jsonDict) {
        NSLog(@"Failed to load JSON: %@", error);
        return;
    }

    self.currentJSON = [jsonDict mutableCopy];
    self.jsonFieldMap = [NSMutableDictionary dictionary];

    
    // JSON 编辑区域
    CGFloat jsonStartX = startX + labelWidth + fieldWidth + 150;
    CGFloat jsonStartY = startY+20;
    CGFloat jsonWidth = 500;
    CGFloat jsonHeight = 650;

    self.jsonScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(jsonStartX, jsonStartY - jsonHeight, jsonWidth, jsonHeight)];
    self.jsonScrollView.hasVerticalScroller = YES;
    self.jsonScrollView.autohidesScrollers = YES;
    [self.view addSubview:self.jsonScrollView];

    // Container
    NSView *jsonContainer = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, jsonWidth, jsonHeight)];
    self.jsonScrollView.documentView = jsonContainer;

    // 控件尺寸
    CGFloat padding = 10;
    CGFloat labelWidthJSON = 120;
    CGFloat fieldWidthJSON = jsonWidth - labelWidthJSON - padding*2;
    CGFloat fieldHeight = 24;
    verticalSpacing = 40;

    // 坐标从顶部向下
    __block CGFloat currentY = jsonHeight - fieldHeight - padding;

    [self.currentJSON enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        NSTextField *keyLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, currentY, labelWidthJSON, fieldHeight)];
        keyLabel.stringValue = key;
        keyLabel.bezeled = NO;
        keyLabel.drawsBackground = NO;
        keyLabel.editable = NO;
        keyLabel.selectable = NO;
        [jsonContainer addSubview:keyLabel];
        
        NSTextField *valueField = [[NSTextField alloc] initWithFrame:NSMakeRect(padding + labelWidthJSON, currentY, fieldWidthJSON, fieldHeight)];
        valueField.stringValue = [NSString stringWithFormat:@"%@", obj];
        [jsonContainer addSubview:valueField];
        
        self.jsonFieldMap[key] = valueField;
        
        currentY -= verticalSpacing;
    }];

    // Save 按钮
    NSButton *saveButton = [[NSButton alloc] initWithFrame:NSMakeRect(padding, currentY - 40, 80, 30)];
    [saveButton setTitle:@"Save"];
    [saveButton setTarget:self];
    [saveButton setAction:@selector(saveJSONToFile)];
    [jsonContainer addSubview:saveButton];


}

#pragma mark 加载 JSON
- (void)loadJSONFromFile:(NSString *)fileName {
    NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:fileName];
    NSData *data = [NSData dataWithContentsOfFile:filePath];
    if (!data) {
        NSLog(@"❌ Cannot load file: %@", filePath);
        return;
    }
    
    NSError *error;
    NSDictionary *jsonDict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
    if (error) {
        NSLog(@"❌ JSON parse error: %@", error);
        return;
    }
    self.currentJSON = jsonDict;
}


#pragma mark 保存修改json
- (void)saveJSONToFile {
    NSMutableDictionary *updatedJSON = [NSMutableDictionary dictionary];
    
    [self.jsonFieldMap enumerateKeysAndObjectsUsingBlock:^(NSString *key, NSTextField *field, BOOL *stop) {
        updatedJSON[key] = field.stringValue;
    }];
    
    NSData *data = [NSJSONSerialization dataWithJSONObject:updatedJSON options:NSJSONWritingPrettyPrinted error:nil];
    NSString *filePath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"sample.json"];
    [data writeToFile:filePath atomically:YES];
    
    NSLog(@"✅ JSON saved to %@", filePath);
}


#pragma mark - setupDir

- (void)setupDir{
    _outputDir  = [FileHelper generateSubdirectory:@"sparkle_output"];
    _deltaDir   = [FileHelper fullPathInDocuments:@"sparkle_patch/update.delta"];
    _logFileDir = [FileHelper fullPathInDocuments:@"sparkleLogDir/sparkle_log.txt"];
    _jsonPath = [FileHelper fullPathInDocuments:@"sparkle_output/appVersion.json"];
    
    [FileHelper prepareEmptyFileAtPath:_deltaDir];
    [FileHelper prepareEmptyFileAtPath:_logFileDir];
    [FileHelper prepareEmptyFileAtPath:_jsonPath];
     
    [self logAllImportantPaths];
    
}

- (NSDictionary *)setupAppSelectorWithLabel:(NSString *)labelText
                                     action:(SEL)selector
                                       x:(CGFloat)x
                                       y:(CGFloat)y
                                  labelWidth:(CGFloat)labelWidth
                                  fieldWidth:(CGFloat)fieldWidth
                                 buttonWidth:(CGFloat)buttonWidth {
    
    CGFloat height = 24;

    // Label
    NSTextField *label = [UIHelper createLabelWithText:labelText
                                                 frame:NSMakeRect(x, y, labelWidth, height)];
    [self.view addSubview:label];

    // Path Field
    NSTextField *field = [UIHelper createPathFieldWithFrame:NSMakeRect(x + labelWidth, y, fieldWidth, height)];
    [self.view addSubview:field];

    // Button
    NSString *buttonTitle = [NSString stringWithFormat:@"Choose %@", labelText];
    NSButton *button = [UIHelper createButtonWithTitle:buttonTitle
                                                target:self
                                                action:selector
                                                 frame:NSMakeRect(x + labelWidth + fieldWidth + 10, y - 3, buttonWidth, 30)];
    [self.view addSubview:button];

    return @{
        @"label": label,
        @"field": field,
        @"button": button
    };
}

- (void)setupGenerateButtonAtX:(CGFloat)x y:(CGFloat)y width:(CGFloat)width spacing:(CGFloat)spacing {
    // Generate Delta Button
    self.generateUpdateButton = [UIHelper createButtonWithTitle:@"generate delta"
                                                         target:self
                                                         action:@selector(generateUpdate)
                                                          frame:NSMakeRect(x, y, width, 30)];
    [self.view addSubview:self.generateUpdateButton];

    // Test Apply Delta Button
    self.applyUpdateButton = [UIHelper createButtonWithTitle:@"test apply delta"
                                                      target:self
                                                      action:@selector(setUpApplyUpdateWindow)
                                                       frame:NSMakeRect(x + width + spacing, y, width, 30)];
    [self.view addSubview:self.applyUpdateButton];
}


//- (NSDictionary *)setupAppSelectorWithLabel:(NSString *)labelText
//                                     action:(SEL)selector
//                                  yPosition:(CGFloat)y {
//    CGFloat padding = 20;
//    CGFloat labelWidth = 100;
//    CGFloat fieldWidth = 400;
//    CGFloat buttonWidth = 130;
//    CGFloat height = 24;
//
//    NSTextField *label = [UIHelper createLabelWithText:labelText
//                                                 frame:NSMakeRect(padding, y, labelWidth, height)];
//    [self.view addSubview:label];
//
//    NSTextField *field = [UIHelper createPathFieldWithFrame:NSMakeRect(padding + labelWidth, y, fieldWidth, height)];
//    [self.view addSubview:field];
//
//    NSString *buttonTitle = [NSString stringWithFormat:@"Choose %@", labelText];
//    NSButton *button = [UIHelper createButtonWithTitle:buttonTitle
//                                                target:self
//                                                action:selector
//                                                 frame:NSMakeRect(padding + labelWidth + fieldWidth + 10, y - 5, buttonWidth, 30)];
//    [self.view addSubview:button];
//
//    return @{
//        @"label": label,
//        @"field": field,
//        @"button": button
//    };
//}
//
//
//- (void)setupGenerateButtonAtY:(CGFloat)y {
//    CGFloat padding = 20;
//    self.generateUpdateButton = [UIHelper createButtonWithTitle:@"generate delta"
//                                                         target:self
//                                                         action:@selector(generateUpdate)
//                                                          frame:NSMakeRect(padding, y, 160, 30)];
//    [self.view addSubview:self.generateUpdateButton];
//    
//    self.applyUpdateButton = [UIHelper createButtonWithTitle:@"test apply delta"
//                                                      target:self
//                                                      action:@selector(setUpApplyUpdateWindow)
//                                                       frame:NSMakeRect(padding*12, y, 160, 30)];
//    [self.view addSubview:self.applyUpdateButton];
//}
#pragma mark - Button Actions
- (void)selectOldApp {
    
    _oldAppDir = [self openAppFromSubdirectory:@"sparkleOldApp"];
    
    if (_oldAppDir) {
        [self.oldAppPathField setStringValue:_oldAppDir];
        [self logMessage:[NSString stringWithFormat:@"✅ choose old App: %@", _oldAppDir]];
        NSDictionary *versionInfo = [FileHelper getAppVersionInfoFromPath:_oldAppDir logBlock:^(NSString *msg) {
            [self logMessage:msg]; // self 是 ViewController 实例
        }];
        if (versionInfo) {
            _oldVersion = versionInfo[@"version"];
            _oldBuildVersion = versionInfo[@"build"];
            _appNameOld = versionInfo[@"appName"];
            _appName = [FileHelper stripVersionFromAppName:_appNameOld];
            [self logMessage:[NSString stringWithFormat:@"Old App:%@ Version: %@ (Build: %@)", _appNameOld, _oldVersion, _oldBuildVersion]];
        }

        
    }
}

- (void)selectUpdatedApp {
    _NewAppDir = [self openAppFromSubdirectory:@"sparkleNewApp"];
    
    if (_NewAppDir) {
        [self.updatedAppPathField setStringValue:_NewAppDir];
        [self logMessage:[NSString stringWithFormat:@"✅ choose new App: %@", _NewAppDir]];
        NSDictionary *versionInfo = [FileHelper getAppVersionInfoFromPath:_NewAppDir logBlock:^(NSString *msg) {
            [self logMessage:msg]; // self 是 ViewController 实例
        }];
        if (versionInfo) {
//            _appName = [_NewAppDir lastPathComponent];
            _NewVersion = versionInfo[@"version"];
            _NewBuildVersion = versionInfo[@"build"];
            _appNameNew = versionInfo[@"appName"];
            [self logMessage:[NSString stringWithFormat:@"New App:%@ Version: %@ (Build: %@)", _appNameNew, _NewVersion, _NewBuildVersion]];
        }
    }
}

- (NSString *)openAppFromSubdirectory:(NSString *)subDirName {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fullPath = [documentsPath stringByAppendingPathComponent:subDirName];

    // 创建目录（如不存在）
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:fullPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"❌ Failed to create directory: %@", error.localizedDescription);
            return nil;
        }
    }

    // 使用封装的方法弹出文件选择面板
    return [self selectAppFromDirectory:fullPath];
}

- (NSString *)selectAppFromDirectory:(NSString *)directoryPath {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedContentTypes = @[ UTTypeApplicationBundle ];
    panel.directoryURL = [NSURL fileURLWithPath:directoryPath];

    if ([panel runModal] == NSModalResponseOK) {
        return panel.URL.path;
    }
    return nil;
}

- (void)generateUpdate {
    
    [self logMessage:@"Begin generate delte.update"];
    [self logAllImportantPaths];
    if (_oldAppDir.length == 0 || _NewAppDir.length == 0) {
        [self logMessage:@"❌ Choose old and new App Paths"];
        return;
    }
    if (_deltaDir.length == 0) {
        [self logMessage:@"❌ create ~/Documents/sparkle_patch first"];
        return;
    }
    
    
    _deltaPath = [self promptForDeltaFilePathWithBaseDir:_deltaDir];
    _appNameDeltaFileName = [_deltaPath lastPathComponent];  // 结果是 "OStation-1.6-1.7.delta"

    
    if (!_deltaPath) return;
    [self logMessage:[NSString stringWithFormat:@"📄deltaPath: %@", _deltaPath]];
    
    
    // Step 1: Generate Patch
    BOOL success = [BinaryDeltaManager createDeltaFromOldPath:_oldAppDir
                                               toNewPath:_NewAppDir
                                              outputPath:_deltaPath
                                                logBlock:^(NSString *log) {
        [self logMessage:[NSString stringWithFormat:@"📄createDeltaLogs: %@", log]];
    }];
    
    if (success) {
        [self logMessage:@"✅ success create delta.update copy to _outputDir"];
        
        [FileHelper copyFileAtPath:_oldAppDir toDirectory:_outputDir];
        [FileHelper copyFileAtPath:_deltaPath toDirectory:_outputDir];
        [UIHelper showSuccessAlertWithTitle:@"✅ Successful!"
                                    message:@"success create delta.update copy to _outputDir."];

        
        NSString *appName = _appName;
        NSString *lastVersion = _oldVersion;
        NSString *latestVersion = _NewVersion;
        NSString *deltaFileName = _appNameDeltaFileName;
        
        NSString *jsonPath = [FileHelper replaceFileNameInPath:_jsonPath withNewName:appName];
        NSLog(@"✅ New Path: %@", jsonPath);

        BOOL success = [self generateVersionJSONWithAppName:appName
                                               lastVersion:lastVersion
                                             latestVersion:latestVersion
                                              deltaFileName:deltaFileName
                                                  jsonPath:jsonPath];

        if (success) {
            NSLog(@"✅ Version JSON generated successfully!");
        } else {
            NSLog(@"❌ Failed to generate Version JSON.");
        }

    } else {
        [UIHelper showSuccessAlertWithTitle:@"✅ failed!"
                                    message:@"failed to create delta.update"];
        [self logMessage:@"❌ failed to create delta.update"];
    }
}


- (void)setUpApplyUpdateWindow {
    // 用纯代码初始化控制器
    AppUpdateViewController *vc = [[AppUpdateViewController alloc] init];

    NSWindow *window = [[NSWindow alloc] initWithContentRect:NSMakeRect(0, 0, 600, 400)
                                                   styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable)
                                                     backing:NSBackingStoreBuffered
                                                       defer:NO];
    [window setTitle:@"Update"];
    [window setContentViewController:vc];

    NSWindowController *windowController = [[NSWindowController alloc] initWithWindow:window];

    // 显示窗口
    [windowController showWindow:self];
    // ✅ 居中窗口
    [window center];

    // 保存引用防止释放
    self.updateWindowController = windowController;

}

- (BOOL)generateVersionJSONWithAppName:(NSString *)appName
                           lastVersion:(NSString *)lastVersion
                         latestVersion:(NSString *)latestVersion
                         deltaFileName:(NSString *)deltaFileName
                              jsonPath:(NSString *)jsonPath{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss";
    NSString *releaseDate = [formatter stringFromDate:[NSDate date]];

    NSDictionary *jsonDict = @{
        @"appName": appName ?: @"UnknownApp",
        @"lastVersion": lastVersion ?: @"0.0.0",
        @"latestVersion": latestVersion ?: @"0.0.0",
        @"releaseDate": releaseDate,
        @"deltaFileName": deltaFileName ?: @"",
        @"jsonPath": jsonPath ?: @""
    };

    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:jsonDict
                                                       options:NSJSONWritingPrettyPrinted
                                                         error:&error];
    if (error) {
        NSLog(@"❌ Failed to serialize JSON: %@", error.localizedDescription);
        return NO;
    }
    
//    NSLog(@"JSON dict: %@", jsonDict);
//    NSLog(@"outputPath: %@", jsonPath);
//    NSLog(@"jsonData length: %lu", (unsigned long)jsonData.length);

    BOOL success = [jsonData writeToFile:jsonPath atomically:YES];
    if (!success) {
        NSLog(@"❌ Failed to write JSON to path: %@", jsonPath);
        [self logMessage:[NSString stringWithFormat:@"❌ Failed to write JSON to path: %@", jsonPath]];
        
        return NO;
    }

    NSLog(@"✅ JSON saved to: %@", jsonPath);
    [self logMessage:[NSString stringWithFormat:@"✅ JSON saved to: %@", jsonPath]];
    return YES;
}

//  a user interaction function . Its purpose is to display a prompt dialog that allows the user to input a delta file name and returns the full file path.

- (NSString *)promptForDeltaFilePathWithBaseDir:(NSString *)baseDir
{
    // 创建输入框提示框
    NSAlert *alert = [[NSAlert alloc] init];
    [alert setMessageText:@"Input appName of delta"];
    [alert addButtonWithTitle:@"OK"];
    [alert addButtonWithTitle:@"Cancel"];
    

    // 添加一个文本输入框作为 accessoryView
    NSTextField *inputField = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 240, 24)];
    
    NSString *deltaFileName = [NSString stringWithFormat:@"%@-%@.delta",
                               _appNameOld ?: @"UnknownApp",
                               _NewVersion ?: @"0.0.0"];
    
//    NSString *baseName = [deltaFileName stringByDeletingPathExtension];
//    NSArray *components = [baseName componentsSeparatedByString:@"-"];
//    // components = @[ @"OStation", @"1.6", @"1.7" ]
//    NSString *appName = components[0];
//    NSString *oldVersion = components[1];
//    NSString *newVersion = components[2];
    
    [inputField setStringValue:deltaFileName]; // 默认值
    [alert setAccessoryView:inputField];

    // 弹出窗口并获取响应
    NSModalResponse response = [alert runModal];
    if (response == NSAlertFirstButtonReturn) {
        NSString *fileName = inputField.stringValue;

        // 简单合法性检查
        if (fileName.length == 0) {
            fileName = @"update.delta";
        }
        // 取 baseDir 的父目录（去掉旧文件名）
        NSString *dir = [baseDir stringByDeletingLastPathComponent];
        return [dir stringByAppendingPathComponent:fileName];
        
    } else {
        // 用户取消输入，返回 nil
        return nil;
    }
}


- (void)logAllImportantPaths {
    [self logMessage:[NSString stringWithFormat:@"outputDir: %@",  _outputDir]];
    [self logMessage:[NSString stringWithFormat:@"deltaDir: %@",   _deltaDir]];
    [self logMessage:[NSString stringWithFormat:@"logFileDir: %@", _logFileDir]];
    [self logMessage:[NSString stringWithFormat:@"jsonPath: %@", _jsonPath]];
    [self logMessage:[NSString stringWithFormat:@"📄 oldAppPath: %@", _oldAppDir]];
    [self logMessage:[NSString stringWithFormat:@"🧩 newAppPath: %@", _NewAppDir]];
}


#pragma mark - 日志打印

- (void)logMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        // 1. 生成带时间戳的日志
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        NSString *timestampedMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

        // 2. 更新 UI 显示
        NSString *existingText = self.logTextView.string ?: @"";
        NSString *updatedText = [existingText stringByAppendingString:timestampedMessage];
        [self.logTextView setString:updatedText];

        NSRange bottom = NSMakeRange(updatedText.length, 0);
        [self.logTextView scrollRangeToVisible:bottom];


        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:self->_logFileDir];
        if (!fileHandle) {
            // 文件不存在则创建
            [[NSFileManager defaultManager] createFileAtPath:self->_logFileDir contents:nil attributes:nil];
            fileHandle = [NSFileHandle fileHandleForWritingAtPath:self->_logFileDir];
        }

        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            NSData *logData = [timestampedMessage dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandle writeData:logData];
            [fileHandle closeFile];
        }
    });
}

//- (void)checkAndHandleBinaryDelta {
//    NSURL *downloadURL = [NSURL URLWithString:@"http://localhost:5000/static/uploads/BinaryDelta"];
//    
//    BOOL result = [BinaryDeltaManager checkAndDownloadBinaryDeltaFromURL:downloadURL];
//
//    if (result) {
//        [self logMessage:@"✅ Found BinaryDelta."];
//        // 如果还想继续做其它事情可以放这里
//    } else {
//        [self logMessage:@"❌ BinaryDelta not found. Closing app..."];
//        [self showErrorAndExit];
//    }
//}

- (void)showErrorAndExit {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"❌ Required file missing";
    alert.informativeText = @"BinaryDelta was not found. The application will now close.";
    [alert addButtonWithTitle:@"Exit"];
    [alert runModal];
    
    [NSApp terminate:nil];
}


@end
