//
//  FoldingWebView.m
//  FoldingView
//
//  Created by John on 12/2/14.
//  Copyright (c) 2014 John. All rights reserved.
//

#import "FoldingWebView.h"
#import <WebKit/WebKit.h>
@interface FoldingWebView()<WKNavigationDelegate,UIScrollViewDelegate,UIGestureRecognizerDelegate>
@property(nonatomic,strong)UIButton *backButton;
@property(nonatomic,strong)UIButton *forwardButton;
@property(nonatomic)CALayer *pullDownLayer;
@property(nonatomic)WKWebView *webView;
@property(nonatomic,strong)UIProgressView *progressView;


@end
@implementation FoldingWebView
-(void)goBack{
    [self.webView goBack];
}
-(void)goForward{
    [self.webView goForward];
}
-(void)dealloc{
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    [self.webView setNavigationDelegate:nil];
    [self.webView setUIDelegate:nil];
    [self.webView.scrollView setDelegate:nil];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"estimatedProgress"] && object == self.webView) {
        if (self.webView.estimatedProgress==1.0f) {
            self.progressView.progress=0;
            self.progressView.trackTintColor=[UIColor clearColor];
        }
        else{
            self.progressView.trackTintColor=[UIColor lightGrayColor];
            [self.progressView setProgress:self.webView.estimatedProgress animated:YES];
        }
    }
    else {
        // Make sure to call the superclass's implementation in the else block in case it is also implementing KVO
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}
-(void)scrollViewDidScroll:(UIScrollView *)scrollView{
    CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView];
    if (translation.y < 0 ) {
        self.backButton.hidden=YES;
        self.forwardButton.hidden=YES;
        self.pullDownLayer.opacity=0;
    }
    else{
        CGPoint velocity=[scrollView.panGestureRecognizer velocityInView:scrollView];
        //velocity.y > x , lower x - higher sensitivity
        if (velocity.y > 1200) {
            [self setupNavigationButton];
            self.pullDownLayer.opacity=0.4f;
        }
    }
    
}
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    if (scrollView.contentOffset.y==0) {
        [self setupNavigationButton];
        self.pullDownLayer.opacity=0.4f;
    }
}
-(void)setupNavigationButton{
    self.backButton.hidden=self.webView.canGoBack ? NO : YES;
    self.forwardButton.hidden=self.webView.canGoForward?NO:YES;
}
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self setupNavigationButton];
    self.pullDownLayer.opacity=0.4f;
}
-(instancetype)initWithFrame:(CGRect)frame request:(NSURLRequest *)request{
    self=[super initWithFrame:frame];
    if (self) {
        WKWebViewConfiguration *configuration=[[WKWebViewConfiguration alloc]init];
        configuration.allowsInlineMediaPlayback=YES;
        _webView=[[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width,self.bounds.size.height) configuration:configuration];
        _progressView=[[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, _webView.bounds.size.width,0)];
        _progressView.progressViewStyle=UIProgressViewStyleBar;
        _progressView.alpha=0.4f;
        _webView.navigationDelegate=self;
        _progressView.tintColor=[UIColor blackColor];
        _progressView.trackTintColor=[UIColor lightGrayColor];
        [_webView addSubview:_progressView];
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
        [_webView loadRequest:request];
        _webView.scrollView.delegate=self;
        _pullDownLayer=[CALayer layer];
        _pullDownLayer.frame=CGRectMake(_webView.bounds.size.width/2 - 25,60, 50, 20);
        _pullDownLayer.contents=(__bridge id)([UIImage imageNamed:@"down"].CGImage);
        _pullDownLayer.opacity=0;
        _pullDownLayer.contentsScale=[UIScreen mainScreen].scale;
        
        [self addSubview:_webView];
        [_webView.layer addSublayer:_pullDownLayer];
        
        _backButton=[[UIButton alloc] initWithFrame:CGRectMake(20, _webView.bounds.size.height-50, 30, 30)];
        _backButton.backgroundColor=[UIColor clearColor];
        _backButton.alpha=0.4f;
        [_backButton setBackgroundImage:[UIImage imageNamed:@"previous.png"] forState:UIControlStateNormal];
        [_backButton addTarget:self action:@selector(goBack) forControlEvents:UIControlEventTouchUpInside];
        [_webView addSubview:_backButton];
        _forwardButton=[[UIButton alloc] initWithFrame:CGRectMake(110, _webView.bounds.size.height-50, 30, 30)];
        _forwardButton.backgroundColor=[UIColor clearColor];
        _forwardButton.alpha=0.4f;
        [_forwardButton setBackgroundImage:[UIImage imageNamed:@"forward.png"] forState:UIControlStateNormal];
        [_forwardButton addTarget:self action:@selector(goForward) forControlEvents:UIControlEventTouchUpInside];
        [_webView addSubview:_forwardButton];
        self.subclassView=_webView;

    }
    return self;
}
-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer==self.foldGestureRecognizer) {
        CGPoint location = [gestureRecognizer locationInView:self];
        CGPoint startingPoint=[gestureRecognizer translationInView:self];
        if (self.webView.scrollView.contentOffset.y==0 && startingPoint.y >0) {
            self.webView.scrollView.scrollEnabled=NO;
            
            return YES;
        }
        else{
            if (location.y<=80) {
                self.webView.scrollView.scrollEnabled=NO;
                
                return YES;
            }
            else{
                return NO;
            }
        }
    }
    else{
        return YES;
    }
}
-(void)handlePanControl{
    self.backButton.hidden=YES;
    self.forwardButton.hidden=YES;
    self.pullDownLayer.opacity=0;
}
-(void)rotateToOriginCompletionBlockMethod{
    [super rotateToOriginCompletionBlockMethod];
    self.webView.scrollView.scrollEnabled=YES;
    [self setupNavigationButton];
}

@end
