//
//  EMCalenderView.m
//  EMCalender
//
//  Created by tramp on 2018/4/17.
//  Copyright © 2018年 tramp. All rights reserved.
//

#import "EMCalenderView.h"
#import "EMCalenderHeader.h"
#import <Masonry.h>
#import "EMCalenderCell.h"
#import "UIColor+Extension.h"
#import "EMCalender.h"
#import "EMCalenderDay.h"
#import "EMCalenderItem.h"
#import "EMCalenderEditView.h"
#import "EMCalenderDetailView.h"

@interface EMCalenderView ()<UICollectionViewDataSource,UICollectionViewDelegate>

/// header view
@property(nonatomic,strong) EMCalenderHeader * calenderHeader;
/// collection View
@property(nonatomic,strong) UICollectionView * calenderCollection;
/// flowlayout
@property(nonatomic,strong) UICollectionViewFlowLayout * flowLayout;
/// EMCalender
@property(nonatomic,strong) EMCalender * calender;
/// data source
@property(nonatomic,strong) NSArray<EMCalenderMonth *> * dataArray;
/// current calendr year
@property(nonatomic,assign) NSInteger currentYear;
/// current calendr month
@property(nonatomic,assign) NSInteger currentMonth;
/// first calender item
@property(nonatomic,strong) EMCalenderItem * firstCalenderItem;
/// last calender  item
@property(nonatomic,strong) EMCalenderItem * lastCalenderItem;

/// edit view
@property(nonatomic,strong) EMCalenderEditView * calenderEditView;
/// detail view
@property(nonatomic,strong) EMCalenderDetailView * calenderDetailView;

@end

@implementation EMCalenderView

// MARK: - 生命周期 -
-(instancetype)init {
    if (self = [super init]) {
        // 初始化UI
        [self initUi];
        // initialzation
        [self initialzation];
    }
    return self;
}

-(void)layoutSubviews {
    [super layoutSubviews];
    // 设置item size
    _flowLayout.itemSize = _calenderCollection.bounds.size;
}

// MARK: - 自定义方法 -

/// calender change selected
-(void)selectCalenderItems:(CGPoint) location {
    // array
    NSArray * array = [self calenerItemInLocation:location];
    // last item
    _lastCalenderItem = array.firstObject;
    // all items
    NSArray <EMCalenderItem *> * items = array.lastObject;
    
    // exchange start and end
    NSDate * start = _firstCalenderItem.day.date;
    NSDate * end = _lastCalenderItem.day.date;
    if ([start compare:end] == NSOrderedDescending) {
        NSDate * temp = start;
        start = end;
        end = temp;
    }
    
    // 遍历
    for (EMCalenderItem * item in items) {
        NSComparisonResult result1 = [item.day.date compare:start];
        NSComparisonResult result2 = [item.day.date compare:end];
        if (result1 == NSOrderedSame || result2 == NSOrderedSame || (result1 == NSOrderedDescending && result2 == NSOrderedAscending )) {
            
            item.markType = EMCalenderMarkTypeRemind;
            
        } else {
            
            item.markType = EMCalenderMarkTypeNone;
            
        }
    }
}

/// 获取当前 EMCalenderItem  current and all
-(NSArray *)calenerItemInLocation:(CGPoint) location {
    // NSIndexPaht in location
    NSIndexPath * indexPath = [_calenderCollection indexPathForItemAtPoint:location];
    // cell
    EMCalenderCell * cell = (EMCalenderCell *)[_calenderCollection cellForItemAtIndexPath:indexPath];
    // cover point
    location = [_calenderCollection convertPoint:location toView:cell];
    // EMCalenderItem
    EMCalenderItem * item = [cell itemInLocation:location];
    return @[item,cell.items];
}

/// collection view tap gesture
-(void)calenderCollectionViewTapGestureHandler:(UITapGestureRecognizer *) gestureRecongnizer {
    // touch point
    CGPoint touchPoint = [gestureRecongnizer locationInView:_calenderCollection];
    // cover point
    UIWindow * window = [UIApplication sharedApplication].windows.firstObject;
    touchPoint = [_calenderCollection convertPoint:touchPoint toView:window];
    [self.calenderDetailView showInLocation:touchPoint info:nil];
}

/// colllection view longPressGesture
-(void)calenderCollectionViewLongPressGesture:(UILongPressGestureRecognizer *) gestureRecognizer {
    // touch point
    CGPoint touchPoint = [gestureRecognizer locationInView:_calenderCollection];
    // state
    UIGestureRecognizerState state = gestureRecognizer.state;
    if (state == UIGestureRecognizerStateBegan) {
        
        _firstCalenderItem = [self calenerItemInLocation:touchPoint].firstObject;
        
    } else if (state == UIGestureRecognizerStateChanged) {
        
        [self selectCalenderItems:touchPoint];
        
    } else {
        [self.calenderEditView show];
    }
}

/// 调用代理方法
-(void)invokeDelegateChange:(NSUInteger) year month:(NSInteger) month {
    EMCalenderDay * day = [[EMCalenderDay alloc] init];
    day.year = year;
    day.month = month;
    // invoke
    if ([_delegate respondsToSelector:@selector(calenderView:changeValue:)]) {
        [_delegate calenderView:self changeValue:day];
    }
}

/// 加载数据
-(void)loadDataForYear:(NSInteger)year completionHandler:(void(^)(NSArray<EMCalenderMonth *> * array) ) completionHandler {
    // 异步加载
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray<EMCalenderMonth *> * array = [self->_calender dataForYear:year];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completionHandler) {
                completionHandler(array);
            }
        });
    });
}

/// 循环 展示
-(void)showCellInLoop:(UIScrollView *) scrollView {
    // 获取当前index
    NSInteger index = scrollView.contentOffset.x / scrollView.bounds.size.width;
    
    // cell 切换
    if (index == 13) { // 滑动到了最右端
        // update current year
        _currentYear ++;
        // update current month
        _currentMonth = 1;
        // refresh data
        __weak typeof(self) weakSelf = self;
        [self loadDataForYear:_currentYear completionHandler:^(NSArray<EMCalenderMonth *> *array) {
            // 刷新数据
            weakSelf.dataArray = array;
            [weakSelf.calenderCollection reloadData];
            
            // 滚动到指定位置
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:weakSelf.currentMonth
                                                          inSection:0];
            [weakSelf.calenderCollection scrollToItemAtIndexPath:indexPath
                                                atScrollPosition:UICollectionViewScrollPositionNone
                                                        animated:NO];
            // invoke delegate method
            [weakSelf invokeDelegateChange:weakSelf.currentYear
                                     month:weakSelf.currentMonth];
        }];
        
    } else if (index == 0) { // 滑动到了最左端
        // update current year
        _currentYear --;
        // update current month
        _currentMonth = 12;
        
        // refresh data
        __weak typeof(self) weakSelf = self;
        [self loadDataForYear:_currentYear completionHandler:^(NSArray<EMCalenderMonth *> *array) {
            // 刷新数据
            weakSelf.dataArray = array;
            [weakSelf.calenderCollection reloadData];
            
            // 滚动到指定位置
            NSIndexPath * indexPath = [NSIndexPath indexPathForItem:weakSelf.currentMonth
                                                          inSection:0];
            [weakSelf.calenderCollection scrollToItemAtIndexPath:indexPath
                                                atScrollPosition:UICollectionViewScrollPositionNone
                                                        animated:NO];
            // invoke delegate method
            [weakSelf invokeDelegateChange:weakSelf.currentYear
                                     month:weakSelf.currentMonth];
        }];
        
    } else { // 1 - 12
        // update current month
        _currentMonth = index;
        // invoke delegate method
        [self invokeDelegateChange:_currentYear month:_currentMonth];
    }
}

// MARK: - UIScrollViewDelegate -

-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    // 循环展示
    [self showCellInLoop:scrollView];
}

// MARK: - UICollectionViewDataSource -

- (NSInteger)collectionView:(nonnull UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _dataArray.count;
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 获取cell
    EMCalenderCell * cell = (EMCalenderCell *) [collectionView dequeueReusableCellWithReuseIdentifier:EM_CALENDER_CELL_ID
                                                                                         forIndexPath:indexPath];
    // cell 背景色
    cell.backgroundColor = [UIColor randomColor];
    // 设置数据
    cell.month = _dataArray[indexPath.item];
    // 返回
    return cell;
}


// MARK: - 初始化 -

/// initialzation
-(void)initialzation {
    // calender
    _calender = [[EMCalender alloc] init];
    // current year
    _currentYear = _calender.currentDay.year;
    // current month
    _currentMonth = _calender.currentDay.month;
    
    // load data
    __weak typeof(self) weakSelf = self;
    [self loadDataForYear:_currentYear completionHandler:^(NSArray<EMCalenderMonth *> *array) {
        // 刷新数据
        weakSelf.dataArray = array;
        [weakSelf.calenderCollection reloadData];
        // 滚动到指定位置
        NSIndexPath * indexPath = [NSIndexPath indexPathForItem:weakSelf.currentMonth
                                                      inSection:0];
        [weakSelf.calenderCollection scrollToItemAtIndexPath:indexPath
                                            atScrollPosition:UICollectionViewScrollPositionNone
                                                    animated:NO];
        // invoke delegate
        [weakSelf invokeDelegateChange:weakSelf.currentYear
                                 month:weakSelf.currentMonth];
    }];
}

/// 初始化Ui
-(void)initUi {
    // 背景色
    self.backgroundColor = [UIColor orangeColor];
    
    // header view
    [self addSubview:self.calenderHeader];
    [_calenderHeader mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.left.right.mas_equalTo(self);
        make.height.mas_equalTo(32.f);
    }];
    
    // collection view
    [self addSubview:self.calenderCollection];
    [_calenderCollection mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.mas_equalTo(self);
        make.top.mas_equalTo(self.calenderHeader.mas_bottom);
        make.bottom.mas_equalTo(self).offset(-64.f);
    }];
}

// MARK: - 懒加载 -

/// detail view
-(EMCalenderDetailView *)calenderDetailView {
    if (!_calenderDetailView) {
        _calenderDetailView = [[EMCalenderDetailView alloc] init];
    }
    return _calenderDetailView;
}

/// eidt view
-(EMCalenderEditView *)calenderEditView {
    if (!_calenderEditView) {
        _calenderEditView = [[EMCalenderEditView alloc] init];
    }
    return _calenderEditView;
}

/// flow layout
-(UICollectionViewFlowLayout *)flowLayout {
    if (!_flowLayout) {
        _flowLayout = [[UICollectionViewFlowLayout alloc] init];
        _flowLayout.minimumLineSpacing = 0;
        _flowLayout.minimumInteritemSpacing = 0;
        _flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    }
    return _flowLayout;
}

/// calender collection
-(UICollectionView *)calenderCollection {
    if (!_calenderCollection) {
        _calenderCollection = [[UICollectionView alloc] initWithFrame:CGRectZero
                                                 collectionViewLayout:self.flowLayout];
        // 预设
        _calenderCollection.delegate = self;
        _calenderCollection.dataSource = self;
        _calenderCollection.showsVerticalScrollIndicator = NO;
        _calenderCollection.pagingEnabled = YES;
        _calenderCollection.bounces = NO;
        _calenderCollection.backgroundColor = [UIColor whiteColor];
        // 注册cell
        [_calenderCollection registerClass:[EMCalenderCell class] forCellWithReuseIdentifier: EM_CALENDER_CELL_ID];
        
        // long press gesture
        UILongPressGestureRecognizer * gesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(calenderCollectionViewLongPressGesture:)];
        [_calenderCollection addGestureRecognizer:gesture];
        
        // tap getsture
        UITapGestureRecognizer * tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(calenderCollectionViewTapGestureHandler:)];
        [_calenderCollection addGestureRecognizer:tap];
    }
    return _calenderCollection;
}

/// header view
-(EMCalenderHeader *)calenderHeader {
    if (!_calenderHeader) {
        _calenderHeader = [[EMCalenderHeader alloc] init];
        _calenderHeader.titles = @[@"日",@"一",@"二",@"三",@"四",@"五",@"六"];
        [_calenderHeader selected:YES index:3];
    }
    return _calenderHeader;
}

@end
