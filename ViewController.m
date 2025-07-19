//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

#import "ViewController.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>


@interface ViewController ()

@property (nonatomic, strong) NSTextField *oldAppLabel;
@property (nonatomic, strong) NSTextField *oldAppPathField;
@property (nonatomic, strong) NSButton *oldAppSelectButton;

@property (nonatomic, strong) NSTextField *updatedAppLabel;
@property (nonatomic, strong) NSTextField *updatedAppPathField;
@property (nonatomic, strong) NSButton *updatedAppSelectButton;

@property (nonatomic, strong) NSButton *generateUpdateButton;
@property (nonatomic, strong) NSTextView *logTextView;

@end

@implementation ViewController

- (void)loadView {
    // 创建根视图
    self.view = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 700, 500)];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupUI];
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
    
    
    [self logMessage:@"put new app to ~/Documents/NewApp/"];
    
    [self logMessage:@"put old app to ~/Documents/OldApp/"];
    
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *logFilePath = [docsDir stringByAppendingPathComponent:@"sparkle_log.txt"];
    
    
    [self logMessage:[NSString stringWithFormat:@"log path: %@", logFilePath]];
    
}

#pragma mark - Button Actions

- (void)selectOldApp {
//    NSString *path = [self openAppSelectionPanel];
    
    NSString *oldAppPath = [self openAppFromSubdirectory:@"OldApp"];
    
    if (oldAppPath) {
        [self.oldAppPathField setStringValue:oldAppPath];
        [self logMessage:[NSString stringWithFormat:@"✅ choose old App: %@", oldAppPath]];
        NSString *zipPath = [self zipAppAtPath:oldAppPath];
        [self logMessage:[NSString stringWithFormat:@"✅ zip old App: %@", zipPath]];
    }
}

- (void)selectUpdatedApp {
//    NSString *path = [self openAppSelectionPanel];
    
    NSString *newAppPath = [self openAppFromSubdirectory:@"NewApp"];

    if (newAppPath) {
        [self.updatedAppPathField setStringValue:newAppPath];
        [self logMessage:[NSString stringWithFormat:@"✅ choose new App: %@", newAppPath]];
    }
    
}


- (NSString *)zipAppAtPath:(NSString *)appPath {
    if (![[NSFileManager defaultManager] fileExistsAtPath:appPath]) {
        [self logMessage:@"❌ 要压缩的 .app 文件不存在"];
        return nil;
    }

    NSString *appName = [[appPath lastPathComponent] stringByDeletingPathExtension];
    NSString *appDirectory = [appPath stringByDeletingLastPathComponent];
    NSString *zipPath = [appDirectory stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.zip", appName]];

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/zip";
    task.currentDirectoryPath = appDirectory; // 必须设置为 .app 所在目录
    task.arguments = @[@"-r", zipPath, [appPath lastPathComponent]];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];

    [self logMessage:[NSString stringWithFormat:@"📦 开始压缩 %@ → %@", appPath, zipPath]];
    
    task.terminationHandler = ^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self logMessage:output];
            if (finishedTask.terminationStatus == 0) {
                [self logMessage:@"✅ 压缩完成"];
            } else {
                [self logMessage:@"❌ 压缩失败"];
            }
        });
    };

    [task launch];

    return zipPath;
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
    NSString *oldPath = self.oldAppPathField.stringValue;
    NSString *newPath = self.updatedAppPathField.stringValue;
    NSString *outputDir = [@"~/Documents/sparkle_patch" stringByExpandingTildeInPath];

    
    if (oldPath.length == 0 || newPath.length == 0) {
        [self logMessage:@"❌ Choose old and new App Paths"];
        return;
    }
    
    if (outputDir.length == 0) {
        [self logMessage:@"❌ create ~/Documents/sparkle_patch first"];
        return;
    }
    
    // Step 1: Generate Patch
    [self generateBinaryDeltaWithOldPath:oldPath newPath:newPath outputDir:outputDir];
}

- (void)generateBinaryDeltaWithOldPath:(NSString *)oldPath
                          newPath:(NSString *)newPath
                        outputDir:(NSString *)outputDir {
    
    NSString *binaryDeltaPath = @"/usr/local/bin/binarydelta";

    if (![[NSFileManager defaultManager] isExecutableFileAtPath:binaryDeltaPath]) {
        [self logMessage:@"❌ 找不到 binarydelta 命令，请确认已安装且路径正确"];
        return;
    }

    // 确保输出目录存在
    NSError *dirError = nil;
    [[NSFileManager defaultManager] createDirectoryAtPath:outputDir
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:&dirError];
    if (dirError) {
        [self logMessage:[NSString stringWithFormat:@"❌ 创建输出目录失败: %@", dirError]];
        return;
    }

    // 构造 delta 文件输出路径
    NSString *deltaPath = [outputDir stringByAppendingPathComponent:@"update.delta"];

    [self logMessage:[NSString stringWithFormat:@"✅ use binarydelta: %@", binaryDeltaPath]];
    [self logMessage:@"call Sparkle binarydelta to generate delta..."];

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = binaryDeltaPath;
    task.arguments = @[ @"create", oldPath, newPath, deltaPath ]; // ✅ 使用 deltaPath 而不是目录

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];

    task.terminationHandler = ^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self logMessage:output];
            if ([[NSFileManager defaultManager] fileExistsAtPath:deltaPath]) {
                [self logMessage:@"✅ finish generate delta"];
                // ✅ 你也可以在这里调用签名方法，例如：
                NSString *deltaPath = [outputDir stringByAppendingPathComponent:@"update.delta"];
                            
                [self logMessage:[NSString stringWithFormat:@"✅ begin generate signUpdate at : %@", deltaPath]];
                
                [self signUpdateAtPath:deltaPath completion:^(NSString *signature) {
                    if (signature) {
                        // ✅ 拿到签名后可用于 appcast.xml 生成
                        NSLog(@"签名是：%@", signature);
                        [self logMessage:[NSString stringWithFormat:@"✅ use signature is: %@", signature]];
                        
                        NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                        
                        NSString *oldAppDir = [docsDir stringByAppendingPathComponent:@"OldApp"];
                        
                        NSString *appcastPath = [oldAppDir stringByAppendingPathComponent:@"appcast.xml"];
                        NSString *fullZipPath = [oldAppDir stringByAppendingPathComponent:@"OStation.zip"];
                        
                        NSString *deltaPath = [docsDir stringByAppendingPathComponent:@"sparkle_patch/update.delta"];
                        
                        NSString *sourceDeltaPath = [docsDir stringByAppendingPathComponent:@"sparkle_patch/update.delta"];
                        
                        [self logMessage:[NSString stringWithFormat:@"📄 Appcast Path: %@", appcastPath]];
                        [self logMessage:[NSString stringWithFormat:@"📦 Full ZIP Path: %@", fullZipPath]];
                        [self logMessage:[NSString stringWithFormat:@"🧩 Delta Path: %@", deltaPath]];
                        
                        [self logMessage:[NSString stringWithFormat:@"🧩 sourceDeltaPath: %@", sourceDeltaPath]];

                

                        
                        [self copyDeltaFromPath:sourceDeltaPath toDirectory:oldAppDir];

                        
                        // ⚠️ 替换为你自己预先生成的 full zip 的签名字符串
                        NSString *zipSignature = @"ApZHFghsd4Sl8nUy3eN2+XzO0VoD...";

                        [self generateAppcastXMLWithVersion:@"2.0"
                                              shortVersion:@"2.0"
                                                   pubDate:[NSDate date]
                                               fullZipPath:fullZipPath
                                                 deltaPath:deltaPath
                                         deltaFromVersion:@"1.5"
                                                 signature:zipSignature
                                            deltaSignature:signature
                                                outputPath:appcastPath];
                        
                        
                    } else {
                        NSLog(@"签名提取失败");
                    }
                }];
                
            } else {
                [self logMessage:@"❌ 增量更新失败，未生成 update.delta 文件"];
            }
        });
    };

    [task launch];
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
            [self logMessage:[NSString stringWithFormat:@"❌ 创建目录失败: %@", dirError.localizedDescription]];
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
        [self logMessage:[NSString stringWithFormat:@"❌ 拷贝 delta 文件失败: %@", copyError.localizedDescription]];
    } else {
        [self logMessage:[NSString stringWithFormat:@"✅ 已将 update.delta 拷贝到 %@", targetDir]];
    }
}


- (void)signUpdateAtPath:(NSString *)deltaPath completion:(void (^)(NSString *signature))completion {
    NSString *signToolPath = @"/usr/local/bin/sign_update";

    if (![[NSFileManager defaultManager] isExecutableFileAtPath:signToolPath]) {
        [self logMessage:@"❌ 找不到 sign_update 工具，请确认路径正确"];
        if (completion) completion(nil);
        return;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:deltaPath]) {
        [self logMessage:@"❌ 找不到要签名的 delta 更新文件"];
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
                [self logMessage:[NSString stringWithFormat:@"❌ 正则解析错误: %@", regexError.localizedDescription]];
                if (completion) completion(nil);
                return;
            }

            NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];
            if (match && [match numberOfRanges] > 1) {
                NSString *signature = [output substringWithRange:[match rangeAtIndex:1]];
                [self logMessage:[NSString stringWithFormat:@"✍️ 提取到签名: %@", signature]];
                if (completion) completion(signature);
            } else {
                [self logMessage:@"❌ 未找到签名"];
                if (completion) completion(nil);
            }
        });
    };

    [task launch];
}
//
//- (void)signUpdateAtPath:(NSString *)deltaPath completion:(void (^)(NSString *signature))completion {
//    NSString *signToolPath = @"/usr/local/bin/sign_update";
//
//    if (![[NSFileManager defaultManager] isExecutableFileAtPath:signToolPath]) {
//        [self logMessage:@"❌ 找不到 sign_update 工具，请确认路径正确"];
//        return;
//    }
//
//    if (![[NSFileManager defaultManager] fileExistsAtPath:deltaPath]) {
//        [self logMessage:@"❌ 找不到要签名的 delta 更新文件"];
//        return;
//    }
//
//    NSTask *task = [[NSTask alloc] init];
//    task.launchPath = signToolPath;
//    task.arguments = @[ deltaPath ]; // 默认使用钥匙串中的私钥
//
//    NSPipe *pipe = [NSPipe pipe];
//    task.standardOutput = pipe;
//    task.standardError = pipe;
//
//    NSFileHandle *readHandle = [pipe fileHandleForReading];
//
//    task.terminationHandler = ^(NSTask *finishedTask) {
//        NSData *outputData = [readHandle readDataToEndOfFile];
//        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
//
//        dispatch_async(dispatch_get_main_queue(), ^{
//            [self logMessage:output];
//
//            NSError *error = nil;
//            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"sparkle:edSignature=\\\"([^\"]+)\\\"" options:0 error:&error];
//            NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];
//
//            if (match && [match numberOfRanges] > 1) {
//                NSString *signature = [output substringWithRange:[match rangeAtIndex:1]];
//                [self logMessage:[NSString stringWithFormat:@"✍️ retrieve: %@", signature]];
//
//                // 📦 自动拼装 appcast.xml 所需参数
//                NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//                NSString *appcastPath = [docsDir stringByAppendingPathComponent:@"appcast.xml"];
//                NSString *fullZipPath = [docsDir stringByAppendingPathComponent:@"OStation-2.0.zip"];
//                NSString *deltaPathLocal = [docsDir stringByAppendingPathComponent:@"sparkle_patch/update.delta"];
//
//                NSLog(@"📄 Appcast Path: %@", appcastPath);
//                NSLog(@"📦 Full ZIP Path: %@", fullZipPath);
//                NSLog(@"🧩 Delta Path: %@", deltaPathLocal);
//
//                // ⚠️ 替换为你自己预先生成的 full zip 的签名字符串
//                NSString *zipSignature = @"ApZHFghsd4Sl8nUy3eN2+XzO0VoD...";
//
//                [self generateAppcastXMLWithVersion:@"2.0"
//                                      shortVersion:@"2.0"
//                                           pubDate:[NSDate date]
//                                       fullZipPath:fullZipPath
//                                         deltaPath:deltaPathLocal
//                                 deltaFromVersion:@"1.5"
//                                         signature:zipSignature
//                                    deltaSignature:signature
//                                        outputPath:appcastPath];
//
//                [self logMessage:@"✅ already generate Appcast.xml"];
//            } else {
//                [self logMessage:@"⚠️ cant retrieve signature"];
//            }
//
//            [self logMessage:@"✅ finish generate delta signature and appcast.xml file and you can upload to your server manual or ? "];
//        });
//    };
//
//    [task launch];
//}



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

    // 写入 XML 到目标路径
    NSError *error = nil;
    [xml writeToFile:xmlOutputPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        [self logMessage:@"❌ write into appcast.xml failed"];
    } else {
//        [self logMessage:@"appcast.xml finished"];
        [self logMessage:[NSString stringWithFormat:@"📄 appcast.xml finished: %@", xmlOutputPath]];
    }
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
            [self logMessage:@"🚀 上传完成"];
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

        // 3. 写入日志文件（追加）
        NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        NSString *logFilePath = [docsDir stringByAppendingPathComponent:@"sparkle_log.txt"];

        NSFileHandle *fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        if (!fileHandle) {
            // 文件不存在则创建
            [[NSFileManager defaultManager] createFileAtPath:logFilePath contents:nil attributes:nil];
            fileHandle = [NSFileHandle fileHandleForWritingAtPath:logFilePath];
        }

        if (fileHandle) {
            [fileHandle seekToEndOfFile];
            NSData *logData = [timestampedMessage dataUsingEncoding:NSUTF8StringEncoding];
            [fileHandle writeData:logData];
            [fileHandle closeFile];
        }
    });
}



- (NSString *)findSparkleCLIPath {
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/which";
    task.arguments = @[@"sparkle"];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;

    NSFileHandle *file = pipe.fileHandleForReading;
    [task launch];
    [task waitUntilExit];

    NSData *data = [file readDataToEndOfFile];
    NSString *path = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    return [path stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

@end
