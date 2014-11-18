//
//  AppDelegate.m
//  FoldingView
//
//  Created by John on 11/1/14.
//  Copyright (c) 2014 John. All rights reserved.
//

#import "FoldingView.h"
#import "UIImage+Blur.h"
#import <POP/POP.h>
#import <WebKit/WebKit.h>
#import "Colours.h"

typedef NS_ENUM(NSInteger, LayerSection) {
    LayerSectionTop,
    LayerSectionBottom
};

@interface FoldingView() <POPAnimationDelegate,UIGestureRecognizerDelegate,WKNavigationDelegate,UIScrollViewDelegate>
- (void)addTopView;
- (void)addBottomView;
- (void)addGestureRecognizers;
- (void)rotateToOriginWithVelocity:(CGFloat)velocity;
- (void)handlePan:(UIPanGestureRecognizer *)recognizer;
- (CATransform3D)transform3D;
- (UIImage *)imageForSection:(LayerSection)section withImage:(UIImage *)image;
- (BOOL)isLocation:(CGPoint)location inView:(UIView *)view;

@property(nonatomic) UIImage *image;
@property(nonatomic) CALayer *topView;
@property(nonatomic) CAGradientLayer *backLayer;
@property(nonatomic)CALayer *bottomView;
@property(nonatomic) CAGradientLayer *bottomShadowLayer;
@property(nonatomic) CAGradientLayer *topShadowLayer;
@property(nonatomic) NSUInteger initialLocation;
@property(nonatomic)WKWebView *webView;
@property(nonatomic)CALayer *superViewLayer;
@property(nonatomic)UIPanGestureRecognizer *foldGestureRecognizer;
@property(nonatomic)CATransformLayer *scaleLayer;
@property(nonatomic)CGFloat angle;
@property(nonatomic)BOOL adjustRotationSpeed;
@property(nonatomic,strong)UIProgressView *progressView;
@property(nonatomic,strong)UIButton *backButton;
@property(nonatomic,strong)UIButton *forwardButton;
@property(nonatomic)NSTimeInterval lastOffsetCapture;
@property(nonatomic)CGPoint lastOffset;
@property(nonatomic)CALayer *pullDownLayer;
@property(nonatomic,strong)CALayer *imprintLayer1;
@property(nonatomic,strong)CALayer *imprintLayer2;
@property(nonatomic,strong)CALayer *backImageLayer;
@end

@implementation FoldingView
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
    CGPoint translation = [scrollView.panGestureRecognizer translationInView:scrollView.superview];
    
    if(translation.y >0)
    {
        CGPoint currentOffset = scrollView.contentOffset;
        NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
        
        NSTimeInterval timeDiff = currentTime - self.lastOffsetCapture;
        if(timeDiff > 0.1) {
            CGFloat distance = currentOffset.y - self.lastOffset.y;
            //The multiply by 10, / 1000 isn't really necessary.......
            CGFloat scrollSpeedNotAbs = (distance * 10) / 1000; //in pixels per millisecond
            CGFloat scrollSpeed = fabsf(scrollSpeedNotAbs);
            if (scrollSpeed > 0.5) {
                [self setupNavigationButton];
                self.pullDownLayer.opacity=0.4f;
            } else {
                NSLog(@"Slow");
            }
            
            self.lastOffset = currentOffset;
            self.lastOffsetCapture = currentTime;
        }
    } else if (translation.y < 0)
    {
        self.backButton.hidden=YES;
        self.forwardButton.hidden=YES;
        self.pullDownLayer.opacity=0;
    }

}
-(void)setupNavigationButton{
    if (self.webView.canGoBack) {
        self.backButton.hidden=NO;
    }
    else{
        self.backButton.hidden=YES;
    }
    if (self.webView.canGoForward) {
        self.forwardButton.hidden=NO;
    }
    else{
        self.forwardButton.hidden=YES;
    }
}
-(void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation{
    [self setupNavigationButton];
}
- (id)initWithFrame:(CGRect)frame request:(NSURLRequest*)request
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor=[UIColor whiteColor];
        WKWebViewConfiguration *configuration=[[WKWebViewConfiguration alloc]init];
        configuration.allowsInlineMediaPlayback=YES;
        _webView=[[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width,self.bounds.size.height) configuration:configuration];
        _progressView=[[UIProgressView alloc] initWithFrame:CGRectMake(0, 0, _webView.bounds.size.width,0)];
        _progressView.progressViewStyle=UIProgressViewStyleBar;
        _progressView.alpha=0.3f;
        _webView.navigationDelegate=self;
        _progressView.tintColor=[UIColor blackColor];
        _progressView.trackTintColor=[UIColor lightGrayColor];
        [_webView addSubview:_progressView];
        [_webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:NULL];
        [_webView loadRequest:request];
        _webView.scrollView.delegate=self;
        _lastOffsetCapture=[NSDate timeIntervalSinceReferenceDate];
        _lastOffset=_webView.scrollView.contentOffset;
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
        [self addGestureRecognizers];
        _adjustRotationSpeed=YES;
    }
    return self;
}

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
    [self.foldGestureRecognizer setDelegate:nil];
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
-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
-(CALayer*)scaleLayer{
    if (!_scaleLayer) {
        _scaleLayer=[CATransformLayer layer];
        _scaleLayer.frame=self.webView.bounds;
    }
    if ([_scaleLayer superlayer] != self.layer) {
        [self.layer addSublayer:_scaleLayer];
    }
    return _scaleLayer;
}

- (void)updateBottomAndTopView {
    [self updateContentSnapshot:self.webView afterScreenUpdate:YES];
    [self addTopView];
    [self addBottomView];
}
- (void)updateContentSnapshot:(UIView *)view afterScreenUpdate:(BOOL)update
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES,0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:update];
    self.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void)captureSuperViewScreenShot:(UIView *)view afterScreenUpdate:(BOOL)update
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, YES,0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:update];
    self.superViewImage=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void)addTopView
{
    self.superViewLayer= [CALayer layer];
    self.superViewLayer.frame=self.webView.bounds;
    [self.webView.layer addSublayer:self.superViewLayer];
    self.topView=[CALayer layer];
    self.topView.frame=CGRectMake(0.f,
                                  0.f,
                                  CGRectGetWidth(self.webView.bounds),
                                  CGRectGetMidY(self.webView.bounds));
    self.topView.backgroundColor=[UIColor whiteColor].CGColor;
    self.topView.opaque=YES;
    self.topView.anchorPoint = CGPointMake(0.5, 1.0);
    self.topView.position = CGPointMake(CGRectGetMidX(self.webView.frame), CGRectGetMidY(self.webView.frame));
    self.topView.transform = [self transform3D];
    self.topView.contentsGravity = kCAGravityResizeAspect;
    self.topView.allowsEdgeAntialiasing=YES;
    self.topView.shadowColor=[UIColor blackColor].CGColor;
    self.topView.shadowOffset=CGSizeMake(0, 0);
    self.topView.shadowOpacity = 0.85f;
    self.topView.shadowRadius = 25.0;
    self.backLayer= [CAGradientLayer layer];
    self.backLayer.opacity = 0.0;
    self.backLayer.frame=self.topView.bounds;
    //self.backLayer.backgroundColor=[UIColor whiteColor].CGColor;colorWithR:141 G:218 B:247 A:1.0];
    UIColor *fluorescentColor=[UIColor colorWithRed:141/255.0f green:218/255.0f blue:247/255.0f alpha:0.0f];
    self.backLayer.colors=@[(__bridge id)[UIColor clearColor].CGColor, (__bridge id)fluorescentColor.CGColor,(__bridge id)[UIColor whiteColor].CGColor,(__bridge id)[UIColor whiteColor].CGColor,(__bridge id)fluorescentColor.CGColor,(__bridge id)[UIColor clearColor].CGColor];
    //self.backLayer.colors=@[(__bridge id)[UIColor clearColor].CGColor, (__bridge id)[UIColor whiteColor].CGColor,(__bridge id)[UIColor whiteColor].CGColor,(__bridge id)[UIColor clearColor].CGColor];
    self.backLayer.startPoint=CGPointMake(0, 0);
    self.backLayer.endPoint=CGPointMake(1, 1);
    self.backImageLayer=[CALayer layer];
    self.backImageLayer.opacity=0.0;
    self.backImageLayer.frame=self.topView.bounds;
    self.backImageLayer.opaque=YES;
    self.backLayer.allowsEdgeAntialiasing=YES;
    self.topShadowLayer = [CAGradientLayer layer];
    self.topShadowLayer.frame = self.topView.bounds;
    self.topShadowLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor];
    self.topShadowLayer.opacity = 0;
   [self.topView addSublayer:self.backImageLayer];
    [self.backImageLayer addSublayer:self.backLayer];
    [self.topView addSublayer:self.topShadowLayer];
    [self.scaleLayer addSublayer:self.topView];
}

- (void)addBottomView
{
    self.bottomView=[CALayer layer];
    self.bottomView.frame =CGRectMake(0.f,
                                      CGRectGetMidY(self.webView.bounds),
                                      CGRectGetWidth(self.webView.bounds),
                                      CGRectGetMidY(self.webView.bounds));
    self.bottomView.backgroundColor=[UIColor blackColor].CGColor;
    self.bottomView.contentsGravity = kCAGravityResizeAspect;
    self.bottomView.opaque=YES;
    self.bottomView.shadowColor=[UIColor blackColor].CGColor;
    self.bottomView.shadowOffset=CGSizeMake(0,0);
    self.bottomView.shadowOpacity =0.85f ;
    self.bottomView.shadowRadius = 25.0f;
    self.imprintLayer1=[CALayer layer];
    self.imprintLayer1.frame=CGRectMake(0, self.bottomView.bounds.origin.y+0.6f, self.bottomView.bounds.size.width, 0.3f);
    self.imprintLayer1.backgroundColor=[UIColor blackColor].CGColor;
    [self.bottomView addSublayer:self.imprintLayer1];
    self.imprintLayer2=[CALayer layer];
    self.imprintLayer2.frame=CGRectMake(0, self.bottomView.bounds.origin.y+1.7f, self.bottomView.bounds.size.width, 0.3f);
    self.imprintLayer2.backgroundColor=[UIColor blackColor].CGColor;
    [self.bottomView addSublayer:self.imprintLayer2];
    self.imprintLayer1.opacity=0.06f;
    self.imprintLayer2.opacity=0.03f;
    self.bottomShadowLayer = [CAGradientLayer layer];
    self.bottomShadowLayer.frame = self.bottomView.bounds;
    self.bottomShadowLayer.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
    self.bottomShadowLayer.opacity = 0;
    
    [self.bottomView addSublayer:self.bottomShadowLayer];
    [self.scaleLayer addSublayer:self.bottomView];
}

- (void)addGestureRecognizers
{
    self.foldGestureRecognizer= [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(handlePan:)];
    self.foldGestureRecognizer.delegate=self;
    [self addGestureRecognizer:self.foldGestureRecognizer];
}

- (void)createFoldLayers
{
    [self updateBottomAndTopView];
    self.superViewLayer.contents=(__bridge id)self.superViewImage.CGImage;
    UIImage *topImage = [self imageForSection:LayerSectionTop withImage:self.image];
    self.topView.contents = (__bridge id)(topImage.CGImage);
    self.backImageLayer.contents=(__bridge id)(topImage.CGImage);
    UIImage *bottomImage = [self imageForSection:LayerSectionBottom withImage:self.image];
    self.bottomView.contents = (__bridge id)(bottomImage.CGImage);
    self.topShadowLayer.frame = self.topView.bounds;
    self.bottomShadowLayer.frame = self.bottomView.bounds;
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
- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self];
    CGPoint startingPoint=[recognizer translationInView:self];
    self.backButton.hidden=YES;
    self.forwardButton.hidden=YES;
    self.pullDownLayer.opacity=0;
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        self.initialLocation = location.y;
        [self createFoldLayers];
    }
    
    if ([[self.topView valueForKeyPath:@"transform.rotation.x"] floatValue] < -M_PI_2) {
        self.backLayer.opacity = 0.15;
        self.backImageLayer.opacity=1.0;
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        self.topShadowLayer.opacity = 0.0;
        self.bottomShadowLayer.opacity = (location.y-self.initialLocation)/(CGRectGetHeight(self.bounds)-self.initialLocation);
        [CATransaction commit];
    } else {
        self.backLayer.opacity = 0.0;
        self.backImageLayer.opacity=0.0;
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        CGFloat opacity = (location.y-self.initialLocation)/(CGRectGetHeight(self.bounds)-self.initialLocation);
        self.bottomShadowLayer.opacity = opacity;
        self.topShadowLayer.opacity = opacity;
        [CATransaction commit];
    }
    
    if ([self isLocation:location inView:self]) {
        CGFloat angle=(-([[self.topView valueForKeyPath:@"transform.rotation.x"]floatValue]*(180/M_PI)));
        [self animateViewWithRotation:angle translation:startingPoint.x verticalPoint:location.y];
        [self.bottomView setShadowPath:[UIBezierPath bezierPathWithRect:CGRectMake(self.bottomView.bounds.origin.x, self.bottomView.bounds.origin.y+50, self.bottomView.bounds.size.width, self.bottomView.bounds.size.height-50)].CGPath];
        /*[self.topView setShadowPath:[UIBezierPath bezierPathWithRect:CGRectMake(self.scaleLayer.bounds.origin.x, self.topView.frame.origin.y-angle*1.3, self.scaleLayer.bounds.size.width, self.scaleLayer.bounds.size.height)].CGPath];*/
        CGFloat shineGradientFactor=angle*0.02071429f;
        //CGFloat shineGradientFactor=angle*0.020f;
        [CATransaction begin];
        [CATransaction setValue:[NSNumber numberWithFloat:0.016f] forKey:kCATransactionAnimationDuration];
        //Perform CALayer actions, such as changing the layer contents, position, whatever.
        self.backLayer.locations=@[[NSNumber numberWithFloat:-2.45f+shineGradientFactor],[NSNumber numberWithFloat:-2.4f+shineGradientFactor],[NSNumber numberWithFloat:-2.34f+shineGradientFactor],[NSNumber numberWithFloat:-2.09f+shineGradientFactor],[NSNumber numberWithFloat:-2.05f+shineGradientFactor],[NSNumber numberWithFloat:-2.0f+shineGradientFactor]];
        //self.backLayer.locations=@[[NSNumber numberWithFloat:-2.45f+shineGradientFactor],[NSNumber numberWithFloat:-2.35f+shineGradientFactor],[NSNumber numberWithFloat:-2.10f+shineGradientFactor],[NSNumber numberWithFloat:-2.0f+shineGradientFactor]];
        [CATransaction commit];

}
    else {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGFloat angle=(-([[self.topView valueForKeyPath:@"transform.rotation.x"]floatValue]*(180/M_PI)));

        if (angle < 45){
        [self rotateToOriginWithVelocity:0];
        [self rescaleLayer];
        recognizer.enabled=NO;}
        else{
            [self closeWithVelocity:0];
            
        }
    }
}
-(void)animateViewWithRotation:(CGFloat)angle translation:(CGFloat)startingpoint verticalPoint:(CGFloat)verticalPoint{
    POPBasicAnimation *rotationAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    POPBasicAnimation *scaleAnimation=[POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    POPBasicAnimation *translateAnimation=[POPBasicAnimation animationWithPropertyNamed:kPOPLayerTranslationX];
    CGFloat rotationAngle;
    CGFloat hypotenuse=self.bounds.size.height/2;
    CGFloat adjacent=fabsf(hypotenuse-verticalPoint);
    CGFloat nonadjustedAngle= -(acos(adjacent/hypotenuse));
    if (verticalPoint >(self.center.y)){
        rotationAngle=-M_PI-nonadjustedAngle;
}
    else{
        rotationAngle=nonadjustedAngle;
    }
    const CGFloat scaleConversionFactor= 1-(angle/650);
    const CGFloat maxScaleAngle=90.0f;
    const CGFloat maxDownScaleConversionFactor= 1-(maxScaleAngle/650);
    
    translateAnimation.toValue=@(startingpoint);
    translateAnimation.duration=0.01;
    scaleAnimation.duration=0.01;
    if (angle > 0  && angle <= maxScaleAngle) {
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(scaleConversionFactor,scaleConversionFactor)];
    }
    else if (angle > maxScaleAngle){
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(maxDownScaleConversionFactor, maxDownScaleConversionFactor)];
    }
    else{
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(1, 1)];
    }
    if (self.adjustRotationSpeed) {
    rotationAnimation.duration=(-rotationAngle*(180/M_PI))/1400;
    }
    else{
        rotationAnimation.duration=0.01;
    }
    [rotationAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        if (finished) {
            self.adjustRotationSpeed=NO;
        }
    }];
    rotationAnimation.toValue = @(rotationAngle);
    [self.scaleLayer pop_addAnimation:translateAnimation forKey:@"translateAnimation"];
    [self.topView pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
    [self.scaleLayer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
}
-(void)rescaleLayer{
    const CGFloat scaleConversionFactor= 1-(self.angle/650);
    const CGFloat maxScaleAngle=90.0f;
    const CGFloat maxDownScaleConversionFactor= 1-(maxScaleAngle/650);
    POPSpringAnimation *scaleAnimation=[POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    POPSpringAnimation *translateAnimation=[POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationX];
    translateAnimation.toValue=@(0);
    if (self.angle > 0  && self.angle <= maxScaleAngle) {
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(scaleConversionFactor, scaleConversionFactor)];
    }
    else if (self.angle > maxScaleAngle){
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(maxDownScaleConversionFactor, maxDownScaleConversionFactor)];
    }
    else{
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(1, 1)];
    }
    [self.scaleLayer pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    [self.scaleLayer pop_addAnimation:translateAnimation forKey:@"translateAnimation"];
}

-(void)closeWithVelocity:(CGFloat)velocity{
    POPSpringAnimation *rotateToCloseAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    POPBasicAnimation *scaleToCloseAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    scaleToCloseAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(0, 0)];
    scaleToCloseAnimation.duration=0.4f;
    if (velocity > 0) {
        rotateToCloseAnimation.velocity = @(velocity);
    }
    rotateToCloseAnimation.springBounciness = 0.0f;
    rotateToCloseAnimation.dynamicsMass = 2.0f;
    rotateToCloseAnimation.dynamicsTension = 200;
    rotateToCloseAnimation.toValue = @(-M_PI);
    rotateToCloseAnimation.delegate = self;
    [scaleToCloseAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        if (finished) {
            [self removeFromSuperview];
        }
    }];
    [self.topView pop_addAnimation:rotateToCloseAnimation forKey:@"rotationToCloseAnimation"];
    [self.scaleLayer pop_addAnimation:scaleToCloseAnimation forKey:@"scaleToCloseAnimation"];
}
- (void)rotateToOriginWithVelocity:(CGFloat)velocity
{
    POPSpringAnimation *rotationAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotationX];
    POPBasicAnimation *imprintLayerAnimation=[POPBasicAnimation animationWithPropertyNamed:kPOPLayerOpacity];
    imprintLayerAnimation.toValue=@(0);
    imprintLayerAnimation.duration=0.04f;
   [self.imprintLayer1 pop_addAnimation:imprintLayerAnimation forKey:nil];
    [self.imprintLayer2 pop_addAnimation:imprintLayerAnimation forKey:nil];
    [imprintLayerAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        if (finished){
            self.imprintLayer1=nil;
            self.imprintLayer2=nil;
            self.bottomView.shadowOpacity=0;
        }
    }];
    [rotationAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        if (finished) {
        [self.superViewLayer removeFromSuperlayer];
        [self.topView removeFromSuperlayer];
        [self.bottomView removeFromSuperlayer];
        self.webView.scrollView.scrollEnabled=YES;
        self.foldGestureRecognizer.enabled=YES;
        self.adjustRotationSpeed=YES;
            [self setupNavigationButton];
        }
    }];
     if (velocity > 0) {
        rotationAnimation.velocity = @(velocity);
    }
    rotationAnimation.springBounciness = 0.0f;
    rotationAnimation.dynamicsMass = 2.0f;
    rotationAnimation.dynamicsTension = 200;
    rotationAnimation.toValue = @(0);
    rotationAnimation.delegate = self;
    [self.topView pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
}

- (CATransform3D)transform3D
{
    CATransform3D transform = CATransform3DIdentity;
    transform.m34 = 2.5 / -4600;
    return transform;
}

- (BOOL)isLocation:(CGPoint)location inView:(UIView *)view
{
    if ((location.x > 0 && location.x < CGRectGetWidth(self.bounds)) &&
        (location.y > 0 && location.y < CGRectGetHeight(self.bounds))) {
        return YES;
    }
    return NO;
}

- (UIImage *)imageForSection:(LayerSection)section withImage:(UIImage *)image
{
    CGRect rect = CGRectMake(0.f, 0.f, image.size.width*2, image.size.height);
    if (section == LayerSectionBottom) {
        rect.origin.y = image.size.height / 1.f;

        }
    
    CGImageRef imgRef = CGImageCreateWithImageInRect(image.CGImage, rect);
    UIImage *imagePart = [UIImage imageWithCGImage:imgRef];
    CGImageRelease(imgRef);
    
    return imagePart;
}
#pragma mark - POPAnimationDelegate

- (void)pop_animationDidApply:(POPAnimation *)anim
{
    self.angle=(-([[self.topView valueForKeyPath:@"transform.rotation.x"]floatValue]*(180/M_PI)));
}

@end