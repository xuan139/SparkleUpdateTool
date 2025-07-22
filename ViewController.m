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
        [self logMessage:[NSString stringWithFormat:@"✅ App Name: %@", _appName]];
        
    }
}

- (void)selectUpdatedApp {
    _NewAppDir = [self openAppFromSubdirectory:@"sparkleNewApp"];

    if (_NewAppDir) {
        [self.updatedAppPathField setStringValue:_NewAppDir];
        [self logMessage:[NSString stringWithFormat:@"✅ choose new App: %@", _NewAppDir]];
        
        NSDictionary *versionInfo = [self getAppVersionInfoFromPath:_NewAppDir];

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
//        
        NSString *baseURL = @"https://unigo.com/updates/";
        NSString *fullURL = [baseURL stringByAppendingPathComponent:_appName];

        [self generateAppcastXMLWithAppName:_appName
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

- (NSString *)rfc822DateStringFromDate:(NSDate *)date {
    static NSDateFormatter *rfc822Formatter = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        rfc822Formatter = [[NSDateFormatter alloc] init];
        rfc822Formatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
        rfc822Formatter.dateFormat = @"EEE, dd MMM yyyy HH:mm:ss Z";
    });
    return [rfc822Formatter stringFromDate:date];
}

- (unsigned long long)fileSizeAtPath:(NSString *)filePath {
    NSDictionary *attributes = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath error:nil];
    return [attributes fileSize];
}


- (void)generateAppcastXMLWithAppName:(NSString *)appName
                              version:(NSString *)version
                         shortVersion:(NSString *)shortVersion
                              pubDate:(NSDate *)pubDate
                         fullAppPath:(NSString *)fullAppPath
                        fullSignature:(NSString *)fullSignature
                        deltaFilePath:(NSString *)deltaFilePath
                     deltaFromVersion:(NSString *)deltaFromVersion
                      deltaSignature:(NSString *)deltaSignature
                              baseURL:(NSString *)baseURL
                          outputPath:(NSString *)xmlOutputPath {
    // 验证输入
    if (!appName || !version || !shortVersion || !pubDate || !fullAppPath || !fullSignature || !xmlOutputPath) {
        NSLog(@"缺少必要参数: appName=%@, version=%@, shortVersion=%@, pubDate=%@, fullAppPath=%@, fullSignature=%@, xmlOutputPath=%@",
              appName, version, shortVersion, pubDate, fullAppPath, fullSignature, xmlOutputPath);
        return;
    }

    // 动态拼接 baseURL
//    NSString *appBaseURL = baseURL ?: @"https://unigo.com";
//    appBaseURL = [appBaseURL stringByAppendingString:@"/"];
    
    NSString *validBaseURL = baseURL ?: @"https://unigo.com";
        if ([validBaseURL hasPrefix:@"https:/"] && ![validBaseURL hasPrefix:@"https://"]) {
            validBaseURL = [@"https://" stringByAppendingString:[validBaseURL substringFromIndex:7]];
        }
    NSString *appBaseURL = validBaseURL;
    
        if (![appBaseURL hasSuffix:@"/"]) {
            appBaseURL = [appBaseURL stringByAppendingString:@"/"];
        }
    

    // 获取文件大小
    unsigned long long fullSize = [self fileSizeAtPath:fullAppPath];
    unsigned long long deltaSize = deltaFilePath ? [self fileSizeAtPath:deltaFilePath] : 0;

    // 构建 XML
    NSMutableString *xml = [NSMutableString string];
    [xml appendString:@"<?xml version=\"1.0\" encoding=\"utf-8\"?>\n"];
    [xml appendString:@"<rss version=\"2.0\" xmlns:sparkle=\"http://www.andymatuschak.org/xml-namespaces/sparkle\" xmlns:dc=\"http://purl.org/dc/elements/1.1/\">\n"];
    [xml appendString:@"  <channel>\n"];
    [xml appendFormat:@"    <title>%@ Updates</title>\n", appName];
    [xml appendFormat:@"    <link>%@appcast.xml</link>\n", appBaseURL];
    [xml appendFormat:@"    <description>Latest updates for %@</description>\n", appName];
    [xml appendString:@"    <language>en</language>\n"];
    [xml appendString:@"    <item>\n"];
    [xml appendFormat:@"      <title>Version %@</title>\n", version];
    [xml appendFormat:@"      <sparkle:releaseNotesLink>%@release_notes_%@.html</sparkle:releaseNotesLink>\n", appBaseURL, version];
    [xml appendFormat:@"      <pubDate>%@</pubDate>\n", [self rfc822DateStringFromDate:pubDate]];

     
     [xml appendFormat:@"      <enclosure url=\"%@%@\" sparkle:version=\"%@\" sparkle:shortVersionString=\"%@\" length=\"%llu\" type=\"application/octet-stream\" sparkle:edSignature=\"%@\" />\n",
      appBaseURL, appName, version, shortVersion, fullSize, fullSignature];
     

    if (deltaFilePath && deltaFromVersion && deltaSignature && deltaSize > 0) {
        [xml appendString:@"      <sparkle:delta>\n"];
        [xml appendFormat:@"        <enclosure url=\"%@upadte.delta\" sparkle:version=\"%@\" sparkle:deltaFrom=\"%@\" length=\"%llu\" type=\"application/octet-stream\" sparkle:edSignature=\"%@\" />\n",
         appBaseURL, version, deltaFromVersion, deltaSize, deltaSignature];
        [xml appendString:@"      </sparkle:delta>\n"];
    }
    [xml appendString:@"    </item>\n"];
    [xml appendString:@"  </channel>\n"];
    [xml appendString:@"</rss>\n"];
    
    // 写入文件
    [self writeAppcastXML:xml toPath:xmlOutputPath];
    
    NSDictionary *result = [self parseAppcastXMLFromPath:_appcastDir];
//    NSLog(@"%@", result);
    
    [self logMessage:[NSString stringWithFormat:@" result of  %@", result]];
    
}

- (NSDictionary *)parseAppcastXMLFromPath:(NSString *)xmlPath {
    NSError *error;
    NSData *xmlData = [NSData dataWithContentsOfFile:xmlPath options:0 error:&error];
    if (!xmlData) return nil;

    NSXMLDocument *doc = [[NSXMLDocument alloc] initWithData:xmlData options:0 error:&error];
    if (!doc) return nil;

    NSMutableDictionary *result = [NSMutableDictionary dictionary];
    result[@"appName"] = [[[doc nodesForXPath:@"//channel/title" error:nil].firstObject stringValue] stringByReplacingOccurrencesOfString:@" Updates" withString:@""];
    result[@"baseURL"] = [[[doc nodesForXPath:@"//channel/link" error:nil].firstObject stringValue] stringByReplacingOccurrencesOfString:@"appcast.xml" withString:@""];
    
    NSXMLElement *item = [doc nodesForXPath:@"//item" error:nil].firstObject;
    if (item) {
        result[@"version"] = [[[item nodesForXPath:@"title" error:nil].firstObject stringValue] stringByReplacingOccurrencesOfString:@"Version " withString:@""];
        result[@"releaseNotesLink"] = [[item nodesForXPath:@"sparkle:releaseNotesLink" error:nil].firstObject stringValue];
        result[@"pubDate"] = [[item nodesForXPath:@"pubDate" error:nil].firstObject stringValue];

        NSXMLElement *enclosure = [item nodesForXPath:@"enclosure" error:nil].firstObject;
        if (enclosure) {
            result[@"fullAppURL"] = [enclosure attributeForName:@"url"].stringValue;
            result[@"shortVersion"] = [enclosure attributeForName:@"sparkle:shortVersionString"].stringValue;
            result[@"fullSize"] = [enclosure attributeForName:@"length"].stringValue;
            result[@"fullSignature"] = [enclosure attributeForName:@"sparkle:edSignature"].stringValue;
        }

        NSXMLElement *deltaEnclosure = [item nodesForXPath:@"sparkle:delta/enclosure" error:nil].firstObject;
        if (deltaEnclosure) {
            result[@"deltaURL"] = [deltaEnclosure attributeForName:@"url"].stringValue;
            result[@"deltaFromVersion"] = [deltaEnclosure attributeForName:@"sparkle:deltaFrom"].stringValue;
            result[@"deltaSize"] = [deltaEnclosure attributeForName:@"length"].stringValue;
            result[@"deltaSignature"] = [deltaEnclosure attributeForName:@"sparkle:edSignature"].stringValue;
        }
    }

    return result;
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
