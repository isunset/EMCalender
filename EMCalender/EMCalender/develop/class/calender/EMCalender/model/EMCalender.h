//
//  EMCalender.h
//  EMCalender
//
//  Created by tramp on 2018/4/17.
//  Copyright © 2018年 tramp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EMCalenderMonth,EMCalenderDay,EMEvent;
@interface EMCalender : NSObject

/// current EMCalenderDay
@property(nonatomic,strong) EMCalenderDay * currentDay;

/**
 保存同步
 
 @param event 需要同步的事件
 @param completionHandler 完成回调
 */
-(void)saveEvent:(EMEvent *)event completionHandler:(void(^)(BOOL isSucceed)) completionHandler;

/**
 获取年份数据 (asynchronous)
 
 @param year 指定年份
 @param completionHandler 完成回调
 */
-(void)asynchronousLoadDataForYear:(NSInteger) year
                 completionHandler:(void(^)(NSArray<EMCalenderMonth *> * array)) completionHandler;



@end
