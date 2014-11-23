//
//  AppDelegate.m
//  FoldingView
//
//  Created by John on 11/1/14.
//  Copyright (c) 2014 John. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FoldingView : UIView

- (id)initWithFrame:(CGRect)frame request:(NSURLRequest*)request;
- (void)captureSuperViewScreenShot:(UIView *)view afterScreenUpdate:(BOOL)update;
@end
