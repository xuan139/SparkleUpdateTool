//
//  ViewController.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

#import "ViewController.h"

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
}

#pragma mark - Button Actions

- (void)selectOldApp {
    NSString *path = [self openAppSelectionPanel];
    if (path) {
        [self.oldAppPathField setStringValue:path];
        [self logMessage:[NSString stringWithFormat:@"choose old App: %@", path]];
    }
}

- (void)selectUpdatedApp {
    NSString *path = [self openAppSelectionPanel];
    if (path) {
        [self.updatedAppPathField setStringValue:path];
        [self logMessage:[NSString stringWithFormat:@"choose new App: %@", path]];
    }
}

/// 打开文件选择面板，限制只能选择 .app 文件
- (NSString *)openAppSelectionPanel {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowedFileTypes = @[@"app"];
    panel.canChooseFiles = YES;
    panel.canChooseDirectories = NO;
    panel.allowsMultipleSelection = NO;

    if ([panel runModal] == NSModalResponseOK) {
        return panel.URL.path;
    }
    return nil;
}

- (void)generateUpdate {
    NSString *oldPath = self.oldAppPathField.stringValue;
    NSString *newPath = self.updatedAppPathField.stringValue;
//    NSString *outputDir = [self preparePatchOutputDirectory];
    
    NSString *outputDir = [@"~/Documents/sparkle_patch" stringByExpandingTildeInPath];

    
    if (oldPath.length == 0 || newPath.length == 0) {
        [self logMessage:@"❌ 请先选择旧版和新版 App 路径"];
        return;
    }
    
    // Step 1: Generate Patch
//    [self runBinaryDeltaWithOldPath:oldPath newPath:newPath outputDir:outputDir];
    
    [self generatePatchWithOldApp:oldPath newApp:newPath];

}

- (NSString *)preparePatchOutputDirectory {
    NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *outputDir = [docsDir stringByAppendingPathComponent:@"sparkle_patch"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isDir = NO;
    BOOL exists = [fileManager fileExistsAtPath:outputDir isDirectory:&isDir];
    
    if (exists && !isDir) {
        // 如果存在但是是普通文件，先删除
        NSError *removeError = nil;
        [fileManager removeItemAtPath:outputDir error:&removeError];
        if (removeError) {
            NSLog(@"❌ 删除冲突文件失败: %@", removeError);
            return nil;
        }
    }
    
    // 不存在或者删除成功后，确保目录存在
    NSError *error = nil;
    if (![fileManager createDirectoryAtPath:outputDir
                withIntermediateDirectories:YES
                                 attributes:nil
                                      error:&error]) {
        NSLog(@"❌ 创建目录失败: %@", error);
        return nil;
    }

    return outputDir;
}


- (void)runBinaryDeltaWithOldPath:(NSString *)oldPath
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

    [self logMessage:[NSString stringWithFormat:@"✔️ 使用 binarydelta: %@", binaryDeltaPath]];
    [self logMessage:@"开始调用 Sparkle 生成增量更新..."];

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
                [self logMessage:@"✅ 增量更新生成完成"];
                // ✅ 你也可以在这里调用签名方法，例如：
                // [self signUpdateAtPath:deltaPath];
                
                NSString *deltaPath = [outputDir stringByAppendingPathComponent:@"update.delta"];
                [self signUpdateAtPath:deltaPath];
                
                
                NSString *docsDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
                NSString *appcastPath = [docsDir stringByAppendingPathComponent:@"appcast.xml"];
                NSString *fullZipPath = [docsDir stringByAppendingPathComponent:@"OStation-2.0.zip"];
//                NSString *deltaPath = [docsDir stringByAppendingPathComponent:@"sparkle_patch/update.delta"];

                NSLog(@"📄 Appcast Path: %@", appcastPath);
                NSLog(@"📦 Full ZIP Path: %@", fullZipPath);
                NSLog(@"🧩 Delta Path: %@", deltaPath);
                
                [self generateAppcastXMLWithVersion:@"2.0"
                                      shortVersion:@"2.0"
                                           pubDate:[NSDate date]
                                       fullZipPath:fullZipPath
                                         deltaPath:deltaPath
                                 deltaFromVersion:@"1.5"
                                         signature:@"ApZHFghsd4Sl8nUy3eN2+XzO0VoD..." // zip 签名
                                    deltaSignature:@"LWHx4F65ifViHpkguF0UziBnwYpi..." // delta 签名
                                        outputPath:appcastPath];
                
                
            } else {
                [self logMessage:@"❌ 增量更新失败，未生成 update.delta 文件"];
            }
        });
    };

    [task launch];
}


- (void)generatePatchWithOldApp:(NSString *)oldPath newApp:(NSString *)newPath {
    NSString *outputDir = [self preparePatchOutputDirectory];
    if (!outputDir) return;

    [self runBinaryDeltaWithOldPath:oldPath newPath:newPath outputDir:outputDir];
}

- (void)signUpdateAtPath:(NSString *)deltaPath {
    NSString *signToolPath = @"/usr/local/bin/sign_update";

    if (![[NSFileManager defaultManager] isExecutableFileAtPath:signToolPath]) {
        [self logMessage:@"❌ 找不到 sign_update 工具，请确认路径正确"];
        return;
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:deltaPath]) {
        [self logMessage:@"❌ 找不到要签名的 delta 更新文件"];
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
            
            // 使用正则表达式提取签名
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"sparkle:edSignature=\\\"([^\"]+)\\\"" options:0 error:nil];
            NSTextCheckingResult *match = [regex firstMatchInString:output options:0 range:NSMakeRange(0, output.length)];
            
            if (match && match.numberOfRanges > 1) {
                NSString *signature = [output substringWithRange:[match rangeAtIndex:1]];
                [self logMessage:[NSString stringWithFormat:@"✍️ 提取到签名: %@", signature]];

                // 👉 可以将 signature 保存到变量 / 写入 appcast.xml / 显示 UI 等
            } else {
                [self logMessage:@"⚠️ 未能从输出中提取签名"];
            }

            [self logMessage:@"✅ 签名完成"];
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

    // 写入 XML 到目标路径
    NSError *error = nil;
    [xml writeToFile:xmlOutputPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
//        NSLog(@"❌ 写入 appcast.xml 失败: %@", error);
        [self logMessage:@"❌ 写入 appcast.xml 失败"];
    } else {
//        NSLog(@"✅ appcast.xml 写入完成: %@", xmlOutputPath);
        [self logMessage:@"appcast.xml 写入完成"];
    }
}



- (void)generateAppcastFromPatch:(NSString *)directoryPath {
    NSString *generateAppcastTool = @"/usr/local/bin/generate_appcast";

    if (![[NSFileManager defaultManager] isExecutableFileAtPath:generateAppcastTool]) {
        [self logMessage:@"❌ 找不到 generate_appcast 工具"];
        return;
    }

    NSTask *task = [[NSTask alloc] init];
    task.launchPath = generateAppcastTool;
    task.arguments = @[directoryPath];

    NSPipe *pipe = [NSPipe pipe];
    task.standardOutput = pipe;
    task.standardError = pipe;

    NSFileHandle *readHandle = [pipe fileHandleForReading];
    task.terminationHandler = ^(NSTask *finishedTask) {
        NSData *outputData = [readHandle readDataToEndOfFile];
        NSString *output = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];

        dispatch_async(dispatch_get_main_queue(), ^{
            [self logMessage:@"📝 Appcast 生成完成"];
            [self logMessage:output];
        });
    };

    [task launch];
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
        NSString *existingText = self.logTextView.string ?: @"";
        NSString *updatedText = [existingText stringByAppendingFormat:@"%@\n", message];
        [self.logTextView setString:updatedText];

        // 自动滚动到底部
        NSRange bottom = NSMakeRange(updatedText.length, 0);
        [self.logTextView scrollRangeToVisible:bottom];
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
