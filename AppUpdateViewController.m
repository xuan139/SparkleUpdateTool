//
//  AppUpdateViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/26/25.
//


#import <Foundation/Foundation.h>
#import "AppUpdateViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "UIHelper.h"
#import "BinaryDeltaManager.h"

@implementation AppUpdateViewController

- (void)loadView {
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 700, 500)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
    [self setupDir];
}

#pragma mark - setupUI
- (void)setupUI {
    CGFloat baseY = 440;
    CGFloat spacingY = 50;
    //  App 选择
    [self setupFileSelectorWithLabel:@"App:" action:@selector(selectOldApp) yPosition:baseY isOldApp:YES];
    // Delta 文件选择
    [self setupFileSelectorWithLabel:@"Delta:" action:@selector(selectDeltaFile) yPosition:baseY - spacingY isOldApp:NO];
    // 新版 App 文件名输入
    [self setupNewAppNameFieldAtY:baseY - spacingY * 2];
    // OK 和 Cancel 按钮
    [self setupButtonsAtY:baseY - spacingY * 3];
    // 日志视图
    NSTextView *logTextView;
    NSScrollView *logScrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(20, 20, 600, 250)];
    logTextView = [[NSTextView alloc] initWithFrame:logScrollView.bounds];
    logScrollView.documentView = logTextView;
    logScrollView.hasVerticalScroller = YES;
    logTextView.editable = NO;
    logTextView.font = [NSFont systemFontOfSize:14];
    self.logTextView = logTextView;
    [self.view addSubview:logScrollView];
    
    [self logMessage:@"logging ..."];
}

#pragma mark - setupDir
- (void)setupDir {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    self.logFileDir = [documentsPath stringByAppendingPathComponent:@"sparkleLogDir/sparkle_log.txt"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *logDir = [self.logFileDir stringByDeletingLastPathComponent];
    if (![fileManager fileExistsAtPath:logDir]) {
        [fileManager createDirectoryAtPath:logDir withIntermediateDirectories:YES attributes:nil error:nil];
    }
    if (![fileManager fileExistsAtPath:self.logFileDir]) {
        [fileManager createFileAtPath:self.logFileDir contents:nil attributes:nil];
    }
    
    [self logMessage:[NSString stringWithFormat:@"log : %@", self.logFileDir]];
}

- (void)setupFileSelectorWithLabel:(NSString *)labelText action:(SEL)selector yPosition:(CGFloat)y isOldApp:(BOOL)isOldApp {
    CGFloat padding = 20;
    CGFloat labelWidth = 100;
    CGFloat fieldWidth = 400;
    CGFloat buttonWidth = 130;
    CGFloat height = 24;

    NSTextField *label = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, labelWidth, height)];
    label.stringValue = labelText;
    label.editable = NO;
    label.bordered = NO;
    label.backgroundColor = [NSColor clearColor];
    [self.view addSubview:label];

    NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(padding + labelWidth, y, fieldWidth, height)];
    field.editable = NO;
    [self.view addSubview:field];

    NSString *buttonTitle = [NSString stringWithFormat:@"Choose %@", labelText];
    NSButton *button = [[NSButton alloc] initWithFrame:NSMakeRect(padding + labelWidth + fieldWidth + 10, y - 5, buttonWidth, 30)];
    button.title = buttonTitle;
    button.target = self;
    button.action = selector;
    button.bezelStyle = NSBezelStyleRounded;
    [self.view addSubview:button];

    if (isOldApp) {
        self.oldAppLabel = label;
        self.oldAppPathField = field;
        self.oldAppSelectButton = button;
    } else {
        self.deltaLabel = label;
        self.deltaPathField = field;
        self.deltaSelectButton = button;
    }
}

- (void)setupNewAppNameFieldAtY:(CGFloat)y {
    CGFloat padding = 20;
    CGFloat labelWidth = 100;
    CGFloat fieldWidth = 400;
    CGFloat height = 24;

    self.NewAppNameLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, y, labelWidth, height)];
    self.NewAppNameLabel.stringValue = @"New App Name:";
    self.NewAppNameLabel.editable = NO;
    self.NewAppNameLabel.bordered = NO;
    self.NewAppNameLabel.backgroundColor = [NSColor clearColor];
    [self.view addSubview:self.NewAppNameLabel];

    self.NewAppNameField = [[NSTextField alloc] initWithFrame:NSMakeRect(padding + labelWidth, y, fieldWidth, height)];
    self.NewAppNameField.placeholderString = @"Input New App name(ex: MyApp_V12.app)";
    [self.view addSubview:self.NewAppNameField];
}

- (void)setupButtonsAtY:(CGFloat)y {
    CGFloat padding = 20;
    self.okButton = [[NSButton alloc] initWithFrame:NSMakeRect(padding, y, 100, 30)];
    self.okButton.title = @"OK";
    self.okButton.bezelStyle = NSBezelStyleRounded;
    self.okButton.target = self;
    self.okButton.action = @selector(okButtonPressed);
    [self.view addSubview:self.okButton];

    self.cancelButton = [[NSButton alloc] initWithFrame:NSMakeRect(padding + 120, y, 100, 30)];
    self.cancelButton.title = @"Cancel";
    self.cancelButton.bezelStyle = NSBezelStyleRounded;
    self.cancelButton.target = self;
    self.cancelButton.action = @selector(cancelButtonPressed);
    [self.view addSubview:self.cancelButton];
}

#pragma mark - Button Actions
- (void)selectOldApp {
    self.oldAppDir = [self openFileWithSubdirectory:@"sparkle_output" contentType:UTTypeApplicationBundle];
    if (self.oldAppDir) {
        [self.oldAppPathField setStringValue:self.oldAppDir];
        [self logMessage:[NSString stringWithFormat:@"✅ choose new App: %@", self.oldAppDir]];
    }
}

- (void)selectDeltaFile {
    self.deltaDir = [self openFileWithSubdirectory:@"sparkle_output" contentType:UTTypeData];
    if (self.deltaDir) {
        [self.deltaPathField setStringValue:self.deltaDir];
        [self logMessage:[NSString stringWithFormat:@"✅ choose Delta file: %@", self.deltaDir]];
    }
}

- (void)okButtonPressed {
    NSString *NewAppName = self.NewAppNameField.stringValue;
    if (self.oldAppDir.length == 0 || self.deltaDir.length == 0 || NewAppName.length == 0) {
        [self logMessage:@"❌ choose App、Delta and new app filename"];
        return;
    }

    // 构造 newDir：用 newAppName 替换 oldAppDir 的文件名
    NSString *oldAppDirPath = self.oldAppDir;
    NSString *newDir = [[oldAppDirPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:NewAppName];

    // 调用 applyDelta
    BOOL success = [BinaryDeltaManager applyDelta:self.deltaDir
                          toOldDir:self.oldAppDir
                           toNewDir:newDir
                           logBlock:^(NSString *log) {
        [self logMessage:log];
    }];

    if (success) {
        [self logMessage:[NSString stringWithFormat:@"✅ updated App generated: %@", newDir]];
        [UIHelper showSuccessAlertWithTitle:@"✅ Successful!"
                                    message:@"success updated App and copy to _outputDir."];
     } else {
        [self logMessage:@"❌ update New App failed "];
        [UIHelper showSuccessAlertWithTitle:@"✅ failed!"
                                     message:@"update New App failed ."];
    }
}

//-(BOOL)applyDelta:(NSString *)deltaPath
//         toOldDir:(NSString *)oldDir
//         toNewDir:(NSString *)newDir
//         logBlock:(void (^)(NSString *log))logBlock {
//
//    NSTask *task = [[NSTask alloc] init];
//    task.launchPath = @"/usr/local/bin/binarydelta";
//    task.arguments = @[@"apply", @"--verbose", oldDir, newDir, deltaPath];
//
//    NSPipe *pipe = [NSPipe pipe];
//    task.standardOutput = pipe;
//    task.standardError = pipe;
//
//    NSFileHandle *readHandle = [pipe fileHandleForReading];
//
//    @try {
//        [task launch];
//        [task waitUntilExit];
//    } @catch (NSException *exception) {
//        NSString *errorMsg = [NSString stringWithFormat:@"❌ Failed to launch binarydelta apply: %@", exception.reason];
//        if (logBlock) logBlock(errorMsg);
//        return NO;
//    }
//
//    NSData *outputData = [readHandle readDataToEndOfFile];
//    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
//    
//    if (logBlock) logBlock(output);
//
//    if (task.terminationStatus == 0) {
//        if (logBlock) logBlock([NSString stringWithFormat:@"✅ apply delta success: %@", newDir]);
//        return YES;
//    } else {
//        if (logBlock) logBlock([NSString stringWithFormat:@"❌ apply delta failed\n%@", output]);
//        return NO;
//    }
//}

- (void)cancelButtonPressed {
    [self logMessage:@"🚫 Cancel"];
    self.oldAppPathField.stringValue = @"";
    self.deltaPathField.stringValue = @"";
    self.NewAppNameField.stringValue = @"";
    self.oldAppDir = nil;
    self.deltaDir = nil;
}

- (NSString *)openFileWithSubdirectory:(NSString *)subDirName contentType:(UTType *)contentType {
    NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *fullPath = [documentsPath stringByAppendingPathComponent:subDirName];

    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:fullPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            [self logMessage:[NSString stringWithFormat:@"❌ 创建目录失败: %@", error.localizedDescription]];
            return nil;
        }
    }

    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedContentTypes = @[contentType];
    panel.directoryURL = [NSURL fileURLWithPath:fullPath];

    if ([panel runModal] == NSModalResponseOK) {
        return panel.URL.path;
    }
    return nil;
}



#pragma mark - 日志打印
- (void)logMessage:(NSString *)message {
    dispatch_async(dispatch_get_main_queue(), ^{
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *timestamp = [formatter stringFromDate:[NSDate date]];
        NSString *timestampedMessage = [NSString stringWithFormat:@"[%@] %@\n", timestamp, message];

        NSString *existingText = self.logTextView.string ?: @"";
        NSString *updatedText = [existingText stringByAppendingString:timestampedMessage];
        [self.logTextView setString:updatedText];

        NSRange bottom = NSMakeRange(updatedText.length, 0);
        [self.logTextView scrollRangeToVisible:bottom];

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




@end
