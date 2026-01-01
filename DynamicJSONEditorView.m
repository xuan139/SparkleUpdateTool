//
//  DynamicJSONEditorView.m
//  SparkleUpdateTool
//
//  Created by lijiaxi on 1/1/26.
//

#import "DynamicJSONEditorView.h"
#import "UIFactory.h" // 假设你还在用原来的工厂类

// --- 内部辅助类：FlippedStackView ---
// 放在这里，对外隐藏实现细节
@interface EditorFlippedStackView : NSStackView
@end

@implementation EditorFlippedStackView
- (BOOL)isFlipped { return YES; }
@end

// --- 主实现 ---
@interface DynamicJSONEditorView ()

@property (nonatomic, strong) NSScrollView *scrollView;
@property (nonatomic, strong) EditorFlippedStackView *editorStack; // 内容容器
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSTextField *> *fieldMap; // 内部持有 TextFields

@end

@implementation DynamicJSONEditorView

#pragma mark - Initialization

- (instancetype)initWithFrame:(NSRect)frameRect {
    self = [super initWithFrame:frameRect];
    if (self) {
        [self setupUI];
        _fieldMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder {
    self = [super initWithCoder:coder];
    if (self) {
        [self setupUI];
        _fieldMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setupUI {
    // 1. 创建 ScrollView
    self.scrollView = [[NSScrollView alloc] initWithFrame:self.bounds];
    self.scrollView.hasVerticalScroller = YES;
    self.scrollView.autohidesScrollers = YES;
    self.scrollView.borderType = NSBezelBorder;
    self.scrollView.drawsBackground = NO;
    self.scrollView.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:self.scrollView];
    
    // 2. 创建内部 StackView
    self.editorStack = [[EditorFlippedStackView alloc] init];
    self.editorStack.orientation = NSUserInterfaceLayoutOrientationVertical;
    self.editorStack.alignment = NSLayoutAttributeLeading;
    self.editorStack.spacing = 10;
    self.editorStack.edgeInsets = NSEdgeInsetsMake(10, 10, 10, 10);
    self.editorStack.translatesAutoresizingMaskIntoConstraints = NO;
    
    // 3. 连接 DocumentView
    self.scrollView.documentView = self.editorStack;
    
    // 4. Auto Layout 约束
    [NSLayoutConstraint activateConstraints:@[
        // ScrollView 填满自己
        [self.scrollView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.scrollView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        [self.scrollView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.scrollView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        
        // StackView 宽度跟随 ScrollView 的内容区
        [self.editorStack.widthAnchor constraintEqualToAnchor:self.scrollView.contentView.widthAnchor]
    ]];
}

#pragma mark - Public Methods

- (void)clear {
    // 移除所有子视图
    NSArray *views = [self.editorStack.arrangedSubviews copy];
    for (NSView *view in views) {
        [self.editorStack removeView:view];
        [view removeFromSuperview];
    }
    // 清空映射
    [self.fieldMap removeAllObjects];
}

- (void)reloadDataWithJSON:(NSDictionary *)jsonDict {
    // 必须在主线程 UI 操作，这里做一个保护
    dispatch_block_t work = ^{
        [self clear];
        if (jsonDict) {
            [self createFieldsForJSON:jsonDict prefix:@"" indent:0];
            [self.editorStack layoutSubtreeIfNeeded];
        }
    };
    
    if ([NSThread isMainThread]) {
        work();
    } else {
        dispatch_async(dispatch_get_main_queue(), work);
    }
}

- (NSDictionary *)exportJSON {
    // 1. 收集扁平化数据
    NSMutableDictionary *flatJSON = [NSMutableDictionary dictionary];
    for (NSString *key in self.fieldMap) {
        // 获取输入框最新的值
        flatJSON[key] = self.fieldMap[key].stringValue;
    }
    
    // 2. 重建嵌套字典
    return [self reconstructNestedDictionaryFromFlat:flatJSON];
}

#pragma mark - Private Logic (Recursive UI Generation)

- (void)createFieldsForJSON:(NSDictionary *)json prefix:(NSString *)prefix indent:(CGFloat)indent {
    [json enumerateKeysAndObjectsUsingBlock:^(NSString *key, id obj, BOOL *stop) {
        NSString *fullKey = prefix.length ? [NSString stringWithFormat:@"%@.%@", prefix, key] : key;
        
        if ([obj isKindOfClass:[NSDictionary class]]) {
            // --- Group Header ---
            // 这里可以简单用 Label，也可以封装一个小 View
            NSTextField *groupLabel = [UIFactory labelWithText:key];
            groupLabel.font = [NSFont boldSystemFontOfSize:12];
            
            NSStackView *groupRow = [[NSStackView alloc] init];
            groupRow.orientation = NSUserInterfaceLayoutOrientationHorizontal;
            [groupRow addArrangedSubview:[[NSView alloc] initWithFrame:NSMakeRect(0, 0, indent, 10)]]; // Indent spacer
            [groupRow addArrangedSubview:groupLabel];
            
            [self.editorStack addArrangedSubview:groupRow];
            
            // 递归
            [self createFieldsForJSON:obj prefix:fullKey indent:indent + 20];
            
        } else {
            // --- Key-Value Row ---
            NSStackView *row = [[NSStackView alloc] init];
            row.orientation = NSUserInterfaceLayoutOrientationHorizontal;
            
            // Indent
            if (indent > 0) {
                 [row addArrangedSubview:[[NSView alloc] initWithFrame:NSMakeRect(0, 0, indent, 10)]];
            }
            
            // Key
            NSTextField *keyLabel = [UIFactory labelWithText:key];
            [keyLabel.widthAnchor constraintEqualToConstant:100].active = YES;
            [row addArrangedSubview:keyLabel];
            
            // Value (Editable)
            NSTextField *valField = [[NSTextField alloc] init];
            valField.stringValue = [NSString stringWithFormat:@"%@", obj];
            valField.toolTip = fullKey;
            // 允许横向拉伸
            [valField setContentHuggingPriority:NSLayoutPriorityDefaultLow forOrientation:NSLayoutConstraintOrientationHorizontal];
            [row addArrangedSubview:valField];
            
            [self.editorStack addArrangedSubview:row];
            
            // 存入 Map
            self.fieldMap[fullKey] = valField;
            
            // 让 Row 填满宽度
             [row.widthAnchor constraintEqualToAnchor:self.editorStack.widthAnchor].active = YES;
        }
    }];
}

#pragma mark - Private Logic (Reconstruction)

- (NSDictionary *)reconstructNestedDictionaryFromFlat:(NSDictionary *)flatDict {
    NSMutableDictionary *nested = [NSMutableDictionary dictionary];
    for (NSString *flatKey in flatDict) {
        NSArray *components = [flatKey componentsSeparatedByString:@"."];
        NSMutableDictionary *current = nested;
        
        for (NSInteger i = 0; i < components.count; i++) {
            NSString *part = components[i];
            if (i == components.count - 1) {
                // 最后一级，赋值
                current[part] = flatDict[flatKey];
            } else {
                // 中间级，寻找或创建字典
                if (!current[part]) {
                    current[part] = [NSMutableDictionary dictionary];
                }
                // 简单的类型保护，防止同名 Key 既是值又是字典
                if ([current[part] isKindOfClass:[NSMutableDictionary class]]) {
                    current = current[part];
                } else {
                    // 异常情况处理：如果 key 冲突，这里只是简单的覆盖或忽略，
                    // 实际产品中可能需要更复杂的错误处理
                    current[part] = [NSMutableDictionary dictionary];
                    current = current[part];
                }
            }
        }
    }
    return nested;
}

@end
