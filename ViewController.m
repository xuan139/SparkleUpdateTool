//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//
#import <Cocoa/Cocoa.h>
#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

#import "SparkleHelper.h"
#import "FileHelper.h"
#import "AppcastGenerator.h"
#import "AppUpdateViewController.h"
#import "UIHelper.h"

@implementation ViewController

- (void)loadView {
    // 创建根视图
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 700, 500)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupDir];
    [self checkAndHandleBinaryDelta];
}

#pragma mark - setupUI
- (void)setupUI {
    CGFloat baseY = 440;
    CGFloat spacingY = 50;

    NSDictionary *oldAppControls = [self setupAppSelectorWithLabel:@"Old App"
                                                            action:@selector(selectOldApp)
                                                         yPosition:baseY];
    self.oldAppLabel = oldAppControls[@"label"];
    self.oldAppPathField = oldAppControls[@"field"];
    self.oldAppSelectButton = oldAppControls[@"button"];

    NSDictionary *newAppControls = [self setupAppSelectorWithLabel:@"New App"
                                                            action:@selector(selectUpdatedApp)
                                                         yPosition:baseY - spacingY];
    self.updatedAppLabel = newAppControls[@"label"];
    self.updatedAppPathField = newAppControls[@"field"];
    self.updatedAppSelectButton = newAppControls[@"button"];
    
    [self setupGenerateButtonAtY:baseY - spacingY * 2];
    NSTextView *logTextView;
    NSScrollView *logScrollView = [UIHelper createLogTextViewWithFrame:NSMakeRect(20, 20, 600, 300)
                                                              textView:&logTextView];
    self.logTextView = logTextView;
    [self.view addSubview:logScrollView];
    [self logMessage:@"Begin logging"];
}



#pragma mark - setupDir

- (void)setupDir{
    _outputDir  = [FileHelper generateSubdirectory:@"sparkle_output"];
    _deltaDir   = [FileHelper fullPathInDocuments:@"sparkle_patch/update.delta"];
    _logFileDir = [FileHelper fullPathInDocuments:@"sparkleLogDir/sparkle_log.txt"];
    
    [FileHelper prepareEmptyFileAtPath:_deltaDir];
    [FileHelper prepareEmptyFileAtPath:_logFileDir];
     
    [self logAllImportantPaths];
}


- (NSDictionary *)setupAppSelectorWithLabel:(NSString *)labelText
                                     action:(SEL)selector
                                  yPosition:(CGFloat)y {
    CGFloat padding = 20;
    CGFloat labelWidth = 100;
    CGFloat fieldWidth = 400;
    CGFloat buttonWidth = 130;
    CGFloat height = 24;

    NSTextField *label = [UIHelper createLabelWithText:labelText
                                                 frame:NSMakeRect(padding, y, labelWidth, height)];
    [self.view addSubview:label];

    NSTextField *field = [UIHelper createPathFieldWithFrame:NSMakeRect(padding + labelWidth, y, fieldWidth, height)];
    [self.view addSubview:field];

    NSString *buttonTitle = [NSString stringWithFormat:@"Choose %@", labelText];
    NSButton *button = [UIHelper createButtonWithTitle:buttonTitle
                                                target:self
                                                action:selector
                                                 frame:NSMakeRect(padding + labelWidth + fieldWidth + 10, y - 5, buttonWidth, 30)];
    [self.view addSubview:button];

    return @{
        @"label": label,
        @"field": field,
        @"button": button
    };
}


- (void)setupGenerateButtonAtY:(CGFloat)y {
    CGFloat padding = 20;
    self.generateUpdateButton = [UIHelper createButtonWithTitle:@"generate delta"
                                                         target:self
                                                         action:@selector(generateUpdate)
                                                          frame:NSMakeRect(padding, y, 160, 30)];
    [self.view addSubview:self.generateUpdateButton];
    
    
    self.applyUpdateButton = [UIHelper createButtonWithTitle:@"test apply delta"
                                                      target:self
                                                      action:@selector(setUpApplyUpdateWindow)
                                                       frame:NSMakeRect(padding*12, y, 160, 30)];
    [self.view addSubview:self.applyUpdateButton];
}
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
            [self logMessage:[NSString stringWithFormat:@"📦 OLD App Build Version: %@ (Build: %@)", _oldVersion, _oldBuildVersion]];
        }
        [self logMessage:[NSString stringWithFormat:@"✅ App Name: %@", _appName]];
        
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
            _appName = [_NewAppDir lastPathComponent];
            _NewVersion = versionInfo[@"version"];
            _NewBuildVersion = versionInfo[@"build"];
            [self logMessage:[NSString stringWithFormat:@"📦 NEW App Build Version: %@ (Build: %@)", _NewVersion, _NewBuildVersion]];
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


BOOL checkAndDownloadBinaryDelta(NSURL *downloadURL) {
    NSString *binaryDeltaPath = @"/usr/local/bin/BinaryDelta";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 检查文件是否存在
    if ([fileManager fileExistsAtPath:binaryDeltaPath]) {
        NSLog(@"BinaryDelta 已存在: %@", binaryDeltaPath);
        return YES;
    }
    
    // 确保目标目录存在
    NSString *directory = [binaryDeltaPath stringByDeletingLastPathComponent];
    NSError *dirError;
    [fileManager createDirectoryAtPath:directory withIntermediateDirectories:YES attributes:nil error:&dirError];
    if (dirError) {
        NSLog(@"创建目录失败: %@", dirError.localizedDescription);
        return NO;
    }
    
    // 信号量以等待异步下载
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);
    __block BOOL success = NO;
    
    // 下载 BinaryDelta
    NSURLSessionDownloadTask *task = [[NSURLSession sharedSession] downloadTaskWithURL:downloadURL completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
        if (error) {
            NSLog(@"下载失败: %@", error.localizedDescription);
            success = NO;
            dispatch_semaphore_signal(semaphore);
            return;
        }
        
        // 移动到目标路径
        NSError *moveError;
        [fileManager moveItemAtURL:location toURL:[NSURL fileURLWithPath:binaryDeltaPath] error:&moveError];
        if (moveError) {
            NSLog(@"移动文件失败: %@", moveError.localizedDescription);
            success = NO;
            dispatch_semaphore_signal(semaphore);
            return;
        }
        
        // 设置可执行权限
        NSError *permError;
        [fileManager setAttributes:@{NSFilePosixPermissions: @(0755)} ofItemAtPath:binaryDeltaPath error:&permError];
        if (permError) {
            NSLog(@"设置权限失败: %@", permError.localizedDescription);
            success = NO;
            dispatch_semaphore_signal(semaphore);
            return;
        }
        
        // 移除 Gatekeeper 限制
        NSTask *xattrTask = [[NSTask alloc] init];
        xattrTask.launchPath = @"/usr/bin/xattr";
        xattrTask.arguments = @[@"-cr", binaryDeltaPath];
        [xattrTask launch];
        [xattrTask waitUntilExit];
        
        NSTask *spctlTask = [[NSTask alloc] init];
        spctlTask.launchPath = @"/usr/sbin/spctl";
        spctlTask.arguments = @[@"--add", binaryDeltaPath];
        [spctlTask launch];
        [spctlTask waitUntilExit];
        
        NSLog(@"BinaryDelta 下载并保存到: %@", binaryDeltaPath);
        success = YES;
        dispatch_semaphore_signal(semaphore);
    }];
    
    [task resume];
    
    // 等待下载完成
    dispatch_semaphore_wait(semaphore, DISPATCH_TIME_FOREVER);
    return success;
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
    if (!_deltaPath) return;
    [self logMessage:[NSString stringWithFormat:@"📄deltaPath: %@", _deltaPath]];
    
    
    // Step 1: Generate Patch
    BOOL success = [SparkleHelper createDeltaFromOldPath:_oldAppDir
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
    [inputField setStringValue:@"appName_Version_update.delta"]; // 默认值
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
    [self logMessage:[NSString stringWithFormat:@"appcastDir: %@", _appcastDir]];
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

- (void)checkAndHandleBinaryDelta {
    NSURL *downloadURL = [NSURL URLWithString:@"http://localhost:5000/static/uploads/BinaryDelta"];
    
    BOOL result = checkAndDownloadBinaryDelta(downloadURL);
    
    if (result) {
        [self logMessage:@"✅ Found BinaryDelta."];
        // 如果还想继续做其它事情可以放这里
    } else {
        [self logMessage:@"❌ BinaryDelta not found. Closing app..."];
        [self showErrorAndExit];
    }
}

- (void)showErrorAndExit {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = @"❌ Required file missing";
    alert.informativeText = @"BinaryDelta was not found. The application will now close.";
    [alert addButtonWithTitle:@"Exit"];
    [alert runModal];
    
    [NSApp terminate:nil];
}


@end
