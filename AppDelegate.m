//
//  AppDelegate.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

//  Refactored: Modern Window Management & UX Improvements
//

//
//  AppDelegate.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

//
//  AppDelegate.m
//  SparkleUpdateTool
//
//  Refactored: Fix Window Centering Issue
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (strong) NSWindow *window;
@property (strong) ViewController *viewController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 1. 定义初始尺寸
    // 必须与 ViewController loadView 中的尺寸一致或接近，确保 center 计算准确
    NSRect initialFrame = NSMakeRect(0, 0, 1400, 800);
    
    NSUInteger style = NSWindowStyleMaskTitled |
                       NSWindowStyleMaskClosable |
                       NSWindowStyleMaskResizable |
                       NSWindowStyleMaskMiniaturizable;

    // 2. 初始化窗口 (使用 initialFrame 而不是 NSZeroRect)
    self.window = [[NSWindow alloc] initWithContentRect:initialFrame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];

    // 3. 设置标题
    NSString *version = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] ?: @"1.0";
    [self.window setTitle:[NSString stringWithFormat:@"Sparkle Delta Generator v%@", version]];

    // 4. 绑定 ViewController
    self.viewController = [[ViewController alloc] init];
    self.window.contentViewController = self.viewController;
    
    // 5. 设置最小尺寸
    [self.window setMinSize:NSMakeSize(1000, 700)];

    // 6. 居中 (关键步骤)
    [self.window center];

    // 7. 设置位置记忆 (关键修复)
    // 修改名字 (V2) 以重置之前的错误位置记忆。
    // 如果你希望每次打开都在屏幕正中间，可以注释掉下面这行代码。
    [self.window setFrameAutosaveName:@"SparkleMainWindow_V2"];

    // 8. 显示窗口
    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end
