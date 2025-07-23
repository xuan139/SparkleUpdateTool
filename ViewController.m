//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import "SparkleHelper.h"
#import "FileHelper.h"
#import "AppcastGenerator.h"
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
}

#pragma mark - setupUI
- (void)setupUI {
    CGFloat baseY = 440;
    CGFloat spacingY = 50;
    CGFloat padding = 20;
    [self setupAppSelectorWithLabel:@"old App:"
                              action:@selector(selectOldApp)
                          yPosition:baseY
                              isOld:YES];
    [self setupAppSelectorWithLabel:@"new App:"
                              action:@selector(selectUpdatedApp)
                          yPosition:baseY - spacingY
                              isOld:NO];
    [self setupGenerateButtonAtY:baseY - spacingY * 2];
    NSTextView *logTextView;
    NSScrollView *logScrollView = [UIHelper createLogTextViewWithFrame:NSMakeRect(20, 20, 600, 300)
                                                              textView:&logTextView];
    self.logTextView = logTextView;
    [self.view addSubview:logScrollView];
    self.logTextView.font = [NSFont systemFontOfSize:14];
    [self logMessage:@"logging"];
}



#pragma mark - setupDir

- (void)setupDir{
    _outputDir  = [FileHelper generateSubdirectory:@"sparkle_output"];
    _deltaDir   = [FileHelper fullPathInDocuments:@"sparkle_patch/update.delta"];
    _logFileDir = [FileHelper fullPathInDocuments:@"sparkleLogDir/sparkle_log.txt"];
    _appcastDir = [FileHelper fullPathInDocuments:@"sparkleAppcastDir/appcast.xml"];

    [FileHelper prepareEmptyFileAtPath:_deltaDir];
    [FileHelper prepareEmptyFileAtPath:_logFileDir];
    [FileHelper prepareEmptyFileAtPath:_appcastDir];
    
    [self logAllImportantPaths];
}


- (void)setupAppSelectorWithLabel:(NSString *)labelText
                           action:(SEL)selector
                         yPosition:(CGFloat)y
                            isOld:(BOOL)isOld {
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

    NSString *buttonTitle = [NSString stringWithFormat:@"choose %@", labelText];
    NSButton *button = [UIHelper createButtonWithTitle:buttonTitle
                                                 target:self
                                                 action:selector
                                                  frame:NSMakeRect(padding + labelWidth + fieldWidth + 10, y - 5, buttonWidth, 30)];
    [self.view addSubview:button];

    if (isOld) {
        self.oldAppLabel = label;
        self.oldAppPathField = field;
        self.oldAppSelectButton = button;
    } else {
        self.updatedAppLabel = label;
        self.updatedAppPathField = field;
        self.updatedAppSelectButton = button;
    }
}

- (void)setupGenerateButtonAtY:(CGFloat)y {
    CGFloat padding = 20;
    self.generateUpdateButton = [UIHelper createButtonWithTitle:@"generate delta"
                                                         target:self
                                                         action:@selector(generateUpdate)
                                                          frame:NSMakeRect(padding, y, 160, 30)];
    [self.view addSubview:self.generateUpdateButton];
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

    // 如果目录不存在则创建
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:fullPath]) {
        NSError *error = nil;
        [fileManager createDirectoryAtPath:fullPath
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&error];
        if (error) {
            NSLog(@"❌ 创建目录失败: %@", error.localizedDescription);
            return nil;
        }
    }

    // 打开 NSOpenPanel
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    panel.allowedContentTypes = @[ UTTypeApplicationBundle ];
    panel.directoryURL = [NSURL fileURLWithPath:fullPath];

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
    // Step 1: Generate Patch
    BOOL success = [SparkleHelper createDeltaFromOldPath:_oldAppDir
                                                 toNewPath:_NewAppDir
                                                 outputPath:_deltaDir
                                                 logBlock:^(NSString *log) {
        [self logMessage:[NSString stringWithFormat:@"📄createDeltaLogs: %@", log]];

    }];
    
    if (success) {
        NSString *baseURL = @"https://unigo.com/updates/";
        NSString *fullURL = [baseURL stringByAppendingPathComponent:_appName];
        
        [AppcastGenerator generateAppcastXMLWithAppName: _appName
                                                version:_NewVersion
                                           shortVersion:_NewBuildVersion
                                                pubDate:[NSDate date]
                                           fullAppPath:_NewAppDir
                                          fullSignature:@"full_sig"
                                         deltaFilePath:_deltaDir
                                      deltaFromVersion:@"1.5"
                                       deltaSignature:@"delta_sig"
                                               baseURL:fullURL
                                           outputPath:_appcastDir];

        
        NSDictionary *result = [AppcastGenerator parseAppcastXMLFromPath:_appcastDir];
    //    NSLog(@"%@", result);
        
        [self logMessage:[NSString stringWithFormat:@" result of  %@", result]];
        
        
        [self logMessage:@"✅ success create delta.update copy to _outputDir"];
        [FileHelper copyFileAtPath:_oldAppDir toDirectory:_outputDir];
        [FileHelper copyFileAtPath:_NewAppDir toDirectory:_outputDir];
        [FileHelper copyFileAtPath:_deltaDir toDirectory:_outputDir];
    } else {
        [self logMessage:@"❌ failed create delta.update"];
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

- (void)uploadPatchToServer:(NSString *)localPath remoteURL:(NSString *)remoteURL {
    // 你可以换成 curl / rsync / scp
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/scp";
    task.arguments = @[localPath, remoteURL];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];
    task.terminationHandler = ^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self logMessage:@"🚀 upload done"];
            [self logMessage:output];
        });
    };

    [task launch];
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


@end
