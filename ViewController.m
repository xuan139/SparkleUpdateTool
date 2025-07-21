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
    CGFloat padding = 20;
    CGFloat labelWidth = 100;
    CGFloat fieldWidth = 400;
    CGFloat buttonWidth = 130;
    CGFloat height = 24;

    // 旧版 App 标签
    self.oldAppLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, 440, labelWidth, height)];
    [self.oldAppLabel setStringValue:@"old App:"];
    [self.oldAppLabel setBezeled:NO];
    [self.oldAppLabel setDrawsBackground:NO];
    [self.oldAppLabel setEditable:NO];
    [self.oldAppLabel setSelectable:NO];
    [self.view addSubview:self.oldAppLabel];

    // 旧版 App 路径显示框（只读）
    self.oldAppPathField = [[NSTextField alloc] initWithFrame:NSMakeRect(padding + labelWidth, 440, fieldWidth, height)];
    [self.oldAppPathField setEditable:NO];
    [self.view addSubview:self.oldAppPathField];

    // 旧版 App 选择按钮
    self.oldAppSelectButton = [[NSButton alloc] initWithFrame:NSMakeRect(padding + labelWidth + fieldWidth + 10, 435, buttonWidth, 30)];
    [self.oldAppSelectButton setTitle:@"choose old App"];
    [self.oldAppSelectButton setTarget:self];
    [self.oldAppSelectButton setAction:@selector(selectOldApp)];
    [self.view addSubview:self.oldAppSelectButton];

    // 新版 App 标签
    self.updatedAppLabel = [[NSTextField alloc] initWithFrame:NSMakeRect(padding, 390, labelWidth, height)];
    [self.updatedAppLabel setStringValue:@"new App:"];
    [self.updatedAppLabel setBezeled:NO];
    [self.updatedAppLabel setDrawsBackground:NO];
    [self.updatedAppLabel setEditable:NO];
    [self.updatedAppLabel setSelectable:NO];
    [self.view addSubview:self.updatedAppLabel];

    // 新版 App 路径显示框（只读）
    self.updatedAppPathField = [[NSTextField alloc] initWithFrame:NSMakeRect(padding + labelWidth, 390, fieldWidth, height)];
    [self.updatedAppPathField setEditable:NO];
    [self.view addSubview:self.updatedAppPathField];

    // 新版 App 选择按钮
    self.updatedAppSelectButton = [[NSButton alloc] initWithFrame:NSMakeRect(padding + labelWidth + fieldWidth + 10, 385, buttonWidth, 30)];
    [self.updatedAppSelectButton setTitle:@"choose new App"];
    [self.updatedAppSelectButton setTarget:self];
    [self.updatedAppSelectButton setAction:@selector(selectUpdatedApp)];
    [self.view addSubview:self.updatedAppSelectButton];

    // 生成增量更新按钮
    self.generateUpdateButton = [[NSButton alloc] initWithFrame:NSMakeRect(padding, 340, 160, 30)];
    [self.generateUpdateButton setTitle:@"generate delta"];
    [self.generateUpdateButton setTarget:self];
    [self.generateUpdateButton setAction:@selector(generateUpdate)];
    [self.view addSubview:self.generateUpdateButton];

    // 日志显示框（NSTextView 放在 NSScrollView 中）
    NSScrollView *scrollView = [[NSScrollView alloc] initWithFrame:NSMakeRect(padding, 20, self.view.bounds.size.width - padding * 2, 300)];
    scrollView.hasVerticalScroller = YES;
    scrollView.borderType = NSBezelBorder;

    self.logTextView = [[NSTextView alloc] initWithFrame:scrollView.bounds];
    [self.logTextView setEditable:NO];
    [self.logTextView setFont:[NSFont fontWithName:@"Menlo" size:13]];
    scrollView.documentView = self.logTextView;
    [self.view addSubview:scrollView];
    
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



#pragma mark - Button Actions
- (void)selectOldApp {

    _oldAppDir = [self openAppFromSubdirectory:@"sparkleOldApp"];
    if (_oldAppDir) {
        [self.oldAppPathField setStringValue:_oldAppDir];
        [self logMessage:[NSString stringWithFormat:@"✅ choose old App: %@", _oldAppDir]];
        NSDictionary *versionInfo = [self getAppVersionInfoFromPath:_oldAppDir];

        if (versionInfo) {
            _oldVersion = versionInfo[@"version"];
            _oldBuildVersion = versionInfo[@"build"];
            [self logMessage:[NSString stringWithFormat:@"📦 OLD App Build Version: %@ (Build: %@)", _oldVersion, _oldBuildVersion]];
        }
    }
}

- (void)selectUpdatedApp {
    _NewAppDir = [self openAppFromSubdirectory:@"sparkleNewApp"];

    if (_NewAppDir) {
        [self.updatedAppPathField setStringValue:_NewAppDir];
        [self logMessage:[NSString stringWithFormat:@"✅ choose new App: %@", _NewAppDir]];
        
        NSDictionary *versionInfo = [self getAppVersionInfoFromPath:_NewAppDir];

        if (versionInfo) {
            _NewVersion = versionInfo[@"version"];
            _NewBuildVersion = versionInfo[@"build"];
            [self logMessage:[NSString stringWithFormat:@"📦 NEW App Build Version: %@ (Build: %@)", _NewVersion, _NewBuildVersion]];
        }
    }
}

/// 打开文件选择面板，限制只能选择 .app 文件
//- (NSString *)openAppSelectionPanel {
//    NSOpenPanel *panel = [NSOpenPanel openPanel];
//
//    panel.canChooseFiles = YES;
//    panel.canChooseDirectories = NO;
//    panel.allowsMultipleSelection = NO;
//    
//    panel.allowedContentTypes = @[ UTTypeApplicationBundle ];
//
//    if ([panel runModal] == NSModalResponseOK) {
//        return panel.URL.path;
//    }
//    return nil;
//}


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
        // 这里可以打印日志或者更新 UI
//        NSLog(@"📣 %@", log);
        
        [self logMessage:log];
    }];
    
    if (success) {
        [self logMessage:@"✅ success create delta.update copy to _outputDir"];
        [FileHelper copyFileAtPath:_oldAppDir toDirectory:_outputDir];
        [FileHelper copyFileAtPath:_NewAppDir toDirectory:_outputDir];
        [FileHelper copyFileAtPath:_deltaDir toDirectory:_outputDir];
    } else {
        [self logMessage:@"❌ failed create delta.update"];
    }
}

- (void)writeAppcastXML:(NSString *)xml toPath:(NSString *)appcastPath {
    NSError *writeError = nil;
    BOOL success = [xml writeToFile:appcastPath atomically:YES encoding:NSUTF8StringEncoding error:&writeError];
    if (!success || writeError) {
        [self logMessage:[NSString stringWithFormat:@"❌ write appcast.xml feiled: %@", writeError.localizedDescription]];
    } else {
        [self logMessage:[NSString stringWithFormat:@"📄 write appcast.xml: %@", appcastPath]];
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




- (NSDictionary *)getAppVersionInfoFromPath:(NSString *)appPath {
    NSString *infoPlistPath = [appPath stringByAppendingPathComponent:@"Contents/Info.plist"];
    NSDictionary *infoPlist = [NSDictionary dictionaryWithContentsOfFile:infoPlistPath];

    if (!infoPlist) {
        [self logMessage:[NSString stringWithFormat:@"❌ cannot read Info.plist: %@", infoPlistPath]];
        return nil;
    }

    NSString *version = infoPlist[@"CFBundleShortVersionString"] ?: @"";
    NSString *build = infoPlist[@"CFBundleVersion"] ?: @"";

    return @{
        @"version": version,
        @"build": build
    };
}

- (void)generateAppcastXMLWithVersion:(NSString *)version
                         shortVersion:(NSString *)shortVersion
                              pubDate:(NSDate *)pubDate
                          fullZipPath:(NSString *)zipPath
                            deltaPath:(NSString *)deltaPath
                    deltaFromVersion:(NSString *)deltaFromVersion
                            signature:(NSString *)signature
                       deltaSignature:(NSString *)deltaSignature
                           outputPath:(NSString *)xmlOutputPath
{
    // 日期格式化
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    NSString *dateString = [formatter stringFromDate:pubDate];

    // 获取文件大小
    unsigned long long fullSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:zipPath error:nil] fileSize];
    unsigned long long deltaSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:deltaPath error:nil] fileSize];

    // 拼接 XML 字符串
    NSString *xml = [NSString stringWithFormat:
                     @"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"
                     "<rss version=\"2.0\" xmlns:sparkle=\"http://www.andymatuschak.org/xml-namespaces/sparkle\"\n"
                     "     xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n"
                     "  <channel>\n"
                     "    <title>App Updates</title>\n"
                     "    <link>https://yourserver.com/updates/</link>\n"
                     "    <description>Latest updates for your app</description>\n"
                     "    <language>en</language>\n"
                     "\n"
                     "    <item>\n"
                     "      <title>Version %@</title>\n"
                     "      <sparkle:releaseNotesLink>https://yourserver.com/updates/release_notes_%@.html</sparkle:releaseNotesLink>\n"
                     "      <pubDate>%@</pubDate>\n"
                     "      <enclosure url=\"https://yourserver.com/updates/YourApp-%@.zip\"\n"
                     "                 sparkle:version=\"%@\"\n"
                     "                 sparkle:shortVersionString=\"%@\"\n"
                     "                 length=\"%llu\"\n"
                     "                 type=\"application/octet-stream\"\n"
                     "                 sparkle:edSignature=\"%@\" />\n"
                     "\n"
                     "      <sparkle:delta>\n"
                     "        <enclosure url=\"https://yourserver.com/updates/YourApp-%@-to-%@.delta\"\n"
                     "                   sparkle:version=\"%@\"\n"
                     "                   sparkle:deltaFrom=\"%@\"\n"
                     "                   length=\"%llu\"\n"
                     "                   type=\"application/octet-stream\"\n"
                     "                   sparkle:edSignature=\"%@\" />\n"
                     "      </sparkle:delta>\n"
                     "    </item>\n"
                     "  </channel>\n"
                     "</rss>\n",
                     version, version, dateString,
                     version, version, shortVersion, fullSize, signature,
                     deltaFromVersion, version, version, deltaFromVersion, deltaSize, deltaSignature];

    // 写入 XML 文件（封装）
    [self writeAppcastXML:xml toPath:xmlOutputPath];
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
