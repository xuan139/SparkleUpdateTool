//
//  DynamicJSONEditorView.h
//  SparkleUpdateTool
//
//  Created by lijiaxi on 1/1/26.
//


#import <Cocoa/Cocoa.h>

NS_ASSUME_NONNULL_BEGIN

@interface DynamicJSONEditorView : NSView

/**
 * 核心方法：传入一个 JSON 字典，自动渲染 UI
 * @param jsonDict 需要编辑的字典数据
 */
- (void)reloadDataWithJSON:(NSDictionary *)jsonDict;

/**
 * 核心方法：获取当前 UI 上的数据，组装回字典
 * @return 修改后的 JSON 字典
 */
- (NSDictionary *)exportJSON;

/**
 * 清空当前编辑器内容
 */
- (void)clear;

@end

NS_ASSUME_NONNULL_END