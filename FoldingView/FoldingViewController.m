//
//  FoldViewController.m
//  Popping
//
//  Created by André Schneider on 20.06.14.
//  Copyright (c) 2014 André Schneider. All rights reserved.
//

#import "FoldingViewController.h"
#import "FoldingView.h"
#import <QuartzCore/QuartzCore.h>

@interface FoldingViewController()<UIWebViewDelegate>
- (void)addFoldView;
@property(nonatomic) FoldingView *foldView;
@end

@implementation FoldingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];
    UIButton *button=[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 60)];
    button.center=self.view.center;
    button.backgroundColor=[UIColor whiteColor];
    button.layer.borderColor=[UIColor blackColor].CGColor;
    button.layer.borderWidth=0.5f;
    [button setTitle:@"Testing" forState:UIControlStateNormal];
    button.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [button addTarget:self action:@selector(addFoldView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Private instance methods

- (void)addFoldView
{
    NSURL *url=[NSURL URLWithString:@"http://www.engadget.com"];
    NSURLRequest *request=[NSURLRequest requestWithURL:url];
    CGRect frame = CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height);
    self.foldView = [[FoldingView alloc] initWithFrame:frame request:request];
    [self.foldView captureSuperViewScreenShot:self.view afterScreenUpdate:NO];
    [self.view addSubview:self.foldView];
}



@end
