//
//  AppUpdateViewController.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 7/26/25.
//


#import <Cocoa/Cocoa.h>

@interface AppUpdateViewController : NSViewController

@property (nonatomic, strong) NSTextField *oldAppLabel;
@property (nonatomic, strong) NSTextField *oldAppPathField;
@property (nonatomic, strong) NSButton *oldAppSelectButton;
@property (nonatomic, strong) NSTextField *deltaLabel;
@property (nonatomic, strong) NSTextField *deltaPathField;
@property (nonatomic, strong) NSButton *deltaSelectButton;
@property (nonatomic, strong) NSTextField *NewAppNameLabel;
@property (nonatomic, strong) NSTextField *NewAppNameField;
@property (nonatomic, strong) NSButton *okButton;
@property (nonatomic, strong) NSButton *cancelButton;
@property (nonatomic, strong) NSTextView *logTextView;
@property (nonatomic, strong) NSString *oldAppDir;
@property (nonatomic, strong) NSString *deltaDir;
@property (nonatomic, strong) NSString *logFileDir;

@end
