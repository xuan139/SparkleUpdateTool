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
    self.window = [self createCenteredWindowWithWidthRatio:0.80
                                               heightRatio:0.9
                                               title:@"Sparkle Delta Generator V1.0"];

    self.viewController = [[ViewController alloc] init];
    [self.window setContentView:self.viewController.view];
    [self.window makeKeyAndOrderFront:nil];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender {
    return YES;
}


- (NSWindow *)createCenteredWindowWithWidthRatio:(CGFloat)widthRatio
                                    heightRatio:(CGFloat)heightRatio
                                           title:(NSString *)title {
    // 获取主屏幕
    NSScreen *mainScreen = [NSScreen mainScreen];
    NSRect screenFrame = [mainScreen visibleFrame];

    // 按比例计算大小
    CGFloat windowWidth  = screenFrame.size.width * widthRatio;
    CGFloat windowHeight = screenFrame.size.height * heightRatio;

    // 居中计算
    CGFloat windowX = NSMidX(screenFrame) - windowWidth / 2.0;
    CGFloat windowY = NSMidY(screenFrame) - windowHeight / 2.0;
    NSRect frame = NSMakeRect(windowX, windowY, windowWidth, windowHeight);

    // 样式
    NSUInteger style = NSWindowStyleMaskTitled |
                       NSWindowStyleMaskClosable |
                       NSWindowStyleMaskResizable;

    // 初始化窗口
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
                                                  styleMask:style
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];
    [window setTitle:title];
    return window;
}


@end

