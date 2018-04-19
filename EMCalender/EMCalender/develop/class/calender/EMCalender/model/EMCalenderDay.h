//
//  EMCalenderDay.h
//  EMCalender
//
//  Created by tramp on 2018/4/17.
//  Copyright © 2018年 tramp. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EKEvent;
@interface EMCalenderDay : NSObject

/// NSDate
@property(nonatomic,strong) NSDate * date;
/// year
@property(nonatomic,assign) NSInteger year;
/// month
@property(nonatomic,assign) NSInteger month;
/// day
@property(nonatomic,assign) NSInteger day;
/// in month
@property(nonatomic,assign,getter=isInMonth) BOOL inMonth;

/// EKEvent
@property(nonatomic,strong) EKEvent * event;

@end