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
//    [SparkleHelper generateKeys];
//    NSString *publicKey = [SparkleHelper getPublicKey];
//    if (publicKey) {
//        NSLog(@"✅ 公钥为: %@", publicKey);
//    } else {
//        NSLog(@"⚠️ 未能获取公钥");
//    }

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
    [self.logTextView setFont:[NSFont fontWithName:@"Menlo" size:12]];
    scrollView.documentView = self.logTextView;
    [self.view addSubview:scrollView];
    
    self.logTextView.font = [NSFont systemFontOfSize:14];
    
    [self logMessage:@"-------------------------------------------------------------------------------------------------"];
    
    [self logMessage:@"use generate keys to generate RAS public and private Keys before use this app!!! and Put public key into app you would like to update!!"];



}
#pragma mark - setupDir

- (void)setupDir{
    
    _outputDir = [FileHelper fullPathInDocuments:@"sparkle_output/readme.md"];
    _deltaDir  = [FileHelper fullPathInDocuments:@"sparkle_patch/update.delta"];
    _logFileDir = [FileHelper fullPathInDocuments:@"sparkleLogDir/sparkle_log.txt"];
    _appcastDir = [FileHelper fullPathInDocuments:@"sparkleAppcastDir/appcast.xml"];
    
    [FileHelper prepareEmptyFileAtPath:_outputDir];
    [FileHelper prepareEmptyFileAtPath:_deltaDir];
    [FileHelper prepareEmptyFileAtPath:_logFileDir];
    [FileHelper prepareEmptyFileAtPath:_appcastDir];
    
    [self logMessage:[NSString stringWithFormat:@"outputDir: %@",  _outputDir]];
    [self logMessage:[NSString stringWithFormat:@"deltaDir: %@",   _deltaDir]];
    [self logMessage:[NSString stringWithFormat:@"logFileDir: %@", _logFileDir]];
    [self logMessage:[NSString stringWithFormat:@"appcastDir: %@", _appcastDir]];
    
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
            [self logMessage:[NSString stringWithFormat:@"📦 OLD 版本号: %@ (Build: %@)", _oldVersion, _oldBuildVersion]];
        }
        _oldfullZipPathFileName = [FileHelper zipAppAtPath:_oldAppDir logBlock:^(NSString *msg) {
            [self logMessage:msg]; // ✅ 使用 ViewController 的日志方法
        }];
        [self logMessage:[NSString stringWithFormat:@"✅ FileHelper zip new App: %@", _oldfullZipPathFileName]];
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
            [self logMessage:[NSString stringWithFormat:@"📦 NEW 版本号: %@ (Build: %@)", _NewVersion, _NewBuildVersion]];
        }
        _newfullZipPathFileName = [FileHelper zipAppAtPath:_NewAppDir logBlock:^(NSString *msg) {
            [self logMessage:msg]; // ✅ 使用 ViewController 的日志方法
        }];
        [self logMessage:[NSString stringWithFormat:@"✅ FileHelper zip new App: %@", _newfullZipPathFileName]];
        
    }
}

/// 打开文件选择面板，限制只能选择 .app 文件
- (NSString *)openAppSelectionPanel {
    NSOpenPanel *panel = [NSOpenPanel openPanel];

    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;
    
    panel.allowedContentTypes = @[ UTTypeApplicationBundle ];

    if ([panel runModal] == NSModalResponseOK) {
        return panel.URL.path;
    }
    return nil;
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
    [self generateBinaryDeltaWithOldPath:_oldAppDir newPath:_NewAppDir];
}


- (void)generateBinaryDeltaWithOldPath:(NSString *)oldPath
                          newPath:(NSString *)newPath{
    
    NSString *binaryDeltaPath = @"/usr/local/bin/binarydelta";

    if (![[NSFileManager defaultManager] isExecutableFileAtPath:binaryDeltaPath]) {
        [self logMessage:@"❌ 找不到 binarydelta 命令，请确认已安装且路径正确"];
        return;
    }

    [self logMessage:[NSString stringWithFormat:@"✅ use binarydelta: %@", binaryDeltaPath]];
    [self logMessage:@"call Sparkle binarydelta to generate delta..."];

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = binaryDeltaPath;
    task.arguments = @[ @"create", oldPath, newPath, _deltaDir ]; // ✅ 使用 deltaPath 而不是目录

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];

    task.terminationHandler = ^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        [self logMessage:output];
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([[NSFileManager defaultManager] fileExistsAtPath:self->_deltaDir]) {
                [self logMessage:@"✅ finish generate delta"];
                // ✅ 你也可以在这里调用签名方法，例如：
                [self logMessage:[NSString stringWithFormat:@"✅ begin generate signUpdate at : %@", self->_deltaDir]];
//                [self logAllImportantPaths];
                
                [self signZipAndDeltaWithZipPath:self.newfullZipPathFileName
                                       deltaPath:self.deltaDir
                                      completion:^(NSString *zipSignature, NSString *deltaSignature) {
                    if (zipSignature && deltaSignature) {
                        [self generateAppcastXMLWithVersion:self->_oldVersion
                                               shortVersion:self->_oldBuildVersion
                                                   pubDate:[NSDate date]
                                                fullZipPath:self.newfullZipPathFileName
                                                  deltaPath:self.deltaDir
                                           deltaFromVersion:self.NewVersion
                                                 signature:zipSignature
                                            deltaSignature:deltaSignature
                                                 outputPath:self.appcastDir];
                    } else {
                        [self logMessage:@"❌ 生成 appcast.xml 失败：签名为空"];
                    }
                }];
                
            } else {
                [self logMessage:@"❌ 增量更新失败，未生成 update.delta 文件"];
            }
        });
    };

    [task launch];
}

- (void)signZipAndDeltaWithZipPath:(NSString *)zipPath
                         deltaPath:(NSString *)deltaPath
                         completion:(void (^)(NSString *zipSignature, NSString *deltaSignature))completion{
    [self signUpdateAtPath:zipPath completion:^(NSString *zipSignature) {
        if (!zipSignature) {
            [self logMessage:@"❌ zipSignature failed"];
            if (completion) completion(nil, nil);
            return;
        }
        [self logMessage:@"✅ zipSignature success"];
        [self logMessage:zipSignature];

        [self signUpdateAtPath:deltaPath completion:^(NSString *deltaSignature) {
            if (!deltaSignature) {
                [self logMessage:@"❌ deltaSignature failed"];
                if (completion) completion(nil, nil);
                return;
            }
            
            [self logMessage:@"✅ deltaSignature success"];
            [self logMessage:deltaSignature];

            [self logMessage:@"✅ ZIP DELTA Signature all done "];
            if (completion) completion(zipSignature, deltaSignature);
        }];
    }];
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
    [self logMessage:[NSString stringWithFormat:@"📄 Appcast Path: %@", self.appcastDir]];
    [self logMessage:[NSString stringWithFormat:@"📦 Full New ZIP Path: %@", self.newfullZipPathFileName]];
    [self logMessage:[NSString stringWithFormat:@"📦 Full Old ZIP Path: %@", self.oldfullZipPathFileName]];
    [self logMessage:[NSString stringWithFormat:@"🧩 Delta Path: %@", self.deltaDir]];
}

- (BOOL)verifySignatureUsingSignUpdate:(NSString *)filePath
                              signature:(NSString *)signature
                             publicKeyPath:(NSString *)pubKeyPath
                                   error:(NSError **)error {

    NSString *signToolPath = @"/usr/local/bin/sign_update";
    
    if (![[NSFileManager defaultManager] isExecutableFileAtPath:signToolPath]) {
        if (error) *error = [NSError errorWithDomain:@"SparkleVerify" code:1 userInfo:@{NSLocalizedDescriptionKey: @"找不到 sign_update 工具"}];
        return NO;
    }

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = signToolPath;
    task.arguments = @[ @"verify", filePath, signature, pubKeyPath ];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];

    [task launch];
    [task waitUntilExit];

    NSData *outputData = [readHandle readDataToEndOfFile];
    NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

    if ([output containsString:@"Signature is valid"]) {
        return YES;
    } else {
        if (error) *error = [NSError errorWithDomain:@"SparkleVerify" code:2 userInfo:@{NSLocalizedDescriptionKey: output ?: @"未知错误"}];
        return NO;
    }
}

- (NSString *)createSubdirectory:(NSString *)subDirName inDirectory:(NSString *)parentDir {
    if (!parentDir || !subDirName) return nil;

    NSString *fullPath = [parentDir stringByAppendingPathComponent:subDirName];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    if (![fileManager fileExistsAtPath:fullPath]) {
        NSError *error = nil;
        BOOL created = [fileManager createDirectoryAtPath:fullPath
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&error];
        if (!created) {
            NSLog(@"❌ Failed to create directory %@: %@", fullPath, error.localizedDescription);
            return nil;
        }
        NSLog(@"✅ Created directory: %@", fullPath);
    } else {
        NSLog(@"📂 Directory already exists: %@", fullPath);
    }

    return fullPath;
}

- (void)copyDeltaFromPath:(NSString *)sourceDeltaPath toDirectory:(NSString *)targetDir {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    // 创建目标目录（如果不存在）
    if (![fileManager fileExistsAtPath:targetDir]) {
        NSError *dirError = nil;
        [fileManager createDirectoryAtPath:targetDir
               withIntermediateDirectories:YES
                                attributes:nil
                                     error:&dirError];
        if (dirError) {
            [self logMessage:[NSString stringWithFormat:@"❌ create directory: %@", dirError.localizedDescription]];
            return;
        }
    }
    
    NSString *targetPath = [targetDir stringByAppendingPathComponent:@"update.delta"];
    
    NSError *copyError = nil;
    
    // 如果目标已有文件，先删除
    if ([fileManager fileExistsAtPath:targetPath]) {
        [fileManager removeItemAtPath:targetPath error:nil];
    }
    
    // 复制文件
    [fileManager copyItemAtPath:sourceDeltaPath toPath:targetPath error:&copyError];
    
    if (copyError) {
        [self logMessage:[NSString stringWithFormat:@"❌ copy delta failed: %@", copyError.localizedDescription]];
    } else {
        [self logMessage:[NSString stringWithFormat:@"✅ already update.delta copy to  %@", targetDir]];
    }
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

- (void)signUpdateAtPath:(NSString *)deltaPath completion:(void (^)(NSString *signature))completion {
    NSString *signToolPath = @"/usr/local/bin/sign_update";

    if (![[NSFileManager defaultManager] isExecutableFileAtPath:signToolPath]) {
        [self logMessage:@"❌ can't sign_update tool"];
        if (completion) completion(nil);
        return;
    }
    



    if (![[NSFileManager defaultManager] fileExistsAtPath:deltaPath]) {
        [self logMessage:@"❌ can't find delta file"];
        if (completion) completion(nil);
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = signToolPath;
    task.arguments = @[ deltaPath ]; // 默认使用钥匙串中的私钥

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];

    task.terminationHandler = ^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self logMessage:output];
            
            // 这里用正则提取签名
            NSError *regexError = nil;
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"edSignature=\"([^\"]+)\"" options:0 error:&regexError];
            if (regexError) {
                [self logMessage:[NSString stringWithFormat:@"❌ reg failed: %@", regexError.localizedDescription]];
                if (completion) completion(nil);
                return;
            }

            NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];
            if (match && [match numberOfRanges] > 1) {
                NSString *signature = [output substringWithRange:[match rangeAtIndex:1]];
//                [self logMessage:[NSString stringWithFormat:@"✍️ 提取到签名: %@", signature]];
                if (completion) completion(signature);
            } else {
                [self logMessage:@"❌ can't find signature"];
                if (completion) completion(nil);
            }
        });
    };

    [task launch];
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

//        // 3. 写入日志文件（追加）
//        NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//        NSString *logFilePath = [docsDir stringByAppendingPathComponent:@"sparkle_log.txt"];

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

//- (NSString *)findSparkleCLIPath {
//    NSTask *task = [[NSTask alloc] init];
//    task.launchPath = @"/usr/bin/which";
//    task.arguments = @[@"sparkle"];
//
//    NSPipe *pipe = [NSPipe pipe];
//    task.standardOutput = pipe;
//
//    NSFileHandle *file = pipe.fileHandleForReading;
//    [task launch];
//    [task waitUntilExit];
//
//    NSData *data = [file readDataToEndOfFile];
//    NSString *path = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
//    return [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
//}

@end
