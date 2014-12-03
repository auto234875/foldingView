//
//  AppDelegate.m
//  FoldingView
//
//  Created by John on 11/1/14.
//  Copyright (c) 2014 John. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FoldingView : UIView

- (id)initWithFrame:(CGRect)frame;
- (void)captureSuperViewScreenShot:(UIView *)view afterScreenUpdate:(BOOL)update;
-(void)handlePanControl;
-(void)rotateToOriginCompletionBlockMethod;
@property(nonatomic,readonly)UIPanGestureRecognizer *foldGestureRecognizer;
@property(nonatomic,strong)UIView *subclassView;


@end
