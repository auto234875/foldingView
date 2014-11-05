//
//  FoldView.h
//  Popping
//
//  Created by André Schneider on 22.06.14.
//  Copyright (c) 2014 André Schneider. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FoldingView : UIView

- (id)initWithFrame:(CGRect)frame request:(NSURLRequest*)request;
- (void)captureSuperViewScreenShot:(UIView *)view afterScreenUpdate:(BOOL)update;
@property(nonatomic)UIImage *superViewImage;

@end
