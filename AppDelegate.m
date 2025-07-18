//
//  AppDelegate.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/17/25.
//

#import "AppDelegate.h"
#import "ViewController.h"

@interface AppDelegate ()

@property (strong) NSWindow *window;
@property (strong) ViewController *viewController;

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // 创建主窗口
    NSRect frame = NSMakeRect(0, 0, 700, 500);
    NSUInteger style = NSWindowStyleMaskTitled | NSWindowStyleMaskClosable | NSWindowStyleMaskResizable;

    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:style
                                                backing:NSBackingStoreBuffered
                                                  defer:NO];
    [self.window center];
    [self.window setTitle:@"Sparkle 增量更新工具"];

    // 创建主视图控制器
    self.viewController = [[ViewController alloc] init];

    // 把 viewController 的视图设为窗口内容视图
    [self.window setContentView:self.viewController.view];

    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}

@end

