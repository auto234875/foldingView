//
//  AppDelegate.m
//  FoldingView
//
//  Created by John on 11/1/14.
//  Copyright (c) 2014 John. All rights reserved.
//

#import "FoldingViewController.h"
#import "FoldingView.h"
#import <QuartzCore/QuartzCore.h>
#import "POP/POP.h"
#import "Colours.h"

@interface FoldingViewController()<UIWebViewDelegate>
- (void)addFoldView;
//@property(nonatomic) FoldingView *foldView;
@end

@implementation FoldingViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor snowColor];
    UIButton *button=[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 200, 60)];
    button.center=self.view.center;
    button.backgroundColor=[UIColor snowColor];
    button.layer.borderColor=[UIColor blackColor].CGColor;
    button.layer.borderWidth=0.5f;
    [button setTitle:@"Testing" forState:UIControlStateNormal];
    button.titleLabel.font=[UIFont fontWithName:@"HelveticaNeue-UltraLight" size:25];
    [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
    [button addTarget:self action:@selector(addFoldView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
    
    CALayer *layer=[CALayer layer];
    layer.frame=CGRectMake(100, 100, 100, 100);
    layer.backgroundColor= [UIColor redColor].CGColor;
    layer.shadowColor=[UIColor blackColor].CGColor;
    layer.shadowOpacity=0.8f;
    layer.shadowRadius=20.0f;
    layer.shadowOffset=CGSizeMake(0, -40);
  //  [self.view.layer addSublayer:layer];
    

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

#pragma mark - Private instance methods

- (void)addFoldView
{
    NSURL *url=[NSURL URLWithString:@"http://www.google.com"];
    NSURLRequest *request=[NSURLRequest requestWithURL:url];
    CGRect frame = CGRectMake(0, -self.view.bounds.size.height, self.view.bounds.size.width, self.view.bounds.size.height);
    FoldingView *foldView = [[FoldingView alloc] initWithFrame:frame request:request];
    [foldView captureSuperViewScreenShot:self.view afterScreenUpdate:YES];
    [self.view addSubview:foldView];
    POPSpringAnimation *segueAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPViewFrame];
    segueAnimation.toValue=[NSValue valueWithCGRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.height)];
    segueAnimation.springBounciness=5.0f;
    segueAnimation.springSpeed=20.0f;
    [foldView pop_addAnimation:segueAnimation forKey:@"segueAnimation"];
}



@end
