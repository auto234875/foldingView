//
//  FoldView.m
//  Popping
//
//  Created by André Schneider on 22.06.14.
//  Copyright (c) 2014 André Schneider. All rights reserved.
//

#import "FoldingView.h"
#import "UIImage+Blur.h"
#import <POP/POP.h>
#import <WebKit/WebKit.h>

typedef NS_ENUM(NSInteger, LayerSection) {
    LayerSectionTop,
    LayerSectionBottom
};

@interface FoldingView() <POPAnimationDelegate,UIScrollViewDelegate,UIWebViewDelegate>
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
@property(nonatomic) CALayer *backLayer;
@property(nonatomic)CALayer *bottomView;
@property(nonatomic) CAGradientLayer *bottomShadowLayer;
@property(nonatomic) CAGradientLayer *topShadowLayer;
@property(nonatomic) NSUInteger initialLocation;
@property(nonatomic)WKWebView *webView;
@property(nonatomic)UIView *handleView;
@property(nonatomic)CALayer *superViewLayer;
@property(nonatomic)UIPanGestureRecognizer *foldGestureRecognizer;
@property(nonatomic)CALayer *scaleLayer;
@property(nonatomic)CGFloat angle;
@property(nonatomic)CGFloat translationValue;
@property(nonatomic)NSBlockOperation *translationCalculation;
@end

@implementation FoldingView

- (id)initWithFrame:(CGRect)frame request:(NSURLRequest*)request
{
    self = [super initWithFrame:frame];
    if (self) {
        _webView=[[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width,self.bounds.size.height)];
        [_webView loadRequest:request];
        [self addSubview:_webView];
        _handleView=[[UIView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, 100)];
        _handleView.userInteractionEnabled=YES;
        [self addSubview:_handleView];
        [self addGestureRecognizers];
        
        
        
}
    return self;
}

#pragma mark - Private Instance methods
- (void)updateBottomAndTopView {
    [self updateContentSnapshot:self.webView afterScreenUpdate:NO];
    [self addTopView];
    [self addBottomView];
}
- (void)updateContentSnapshot:(UIView *)view afterScreenUpdate:(BOOL)update
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO,0);
    [view drawViewHierarchyInRect:view.bounds afterScreenUpdates:update];
    self.image=UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
}

- (void)captureSuperViewScreenShot:(UIView *)view afterScreenUpdate:(BOOL)update
{
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, NO,0);
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
    self.topView.backgroundColor=[UIColor clearColor].CGColor;
    self.topView.anchorPoint = CGPointMake(0.5, 1.0);
    self.topView.position = CGPointMake(CGRectGetMidX(self.webView.frame), CGRectGetMidY(self.webView.frame));
    self.topView.transform = [self transform3D];
    self.topView.contentsGravity = kCAGravityResizeAspect;
    self.topView.allowsEdgeAntialiasing=YES;
    self.backLayer= [CALayer layer];
    self.backLayer.opacity = 0.0;
    self.backLayer.frame=self.topView.bounds;
    self.backLayer.backgroundColor=[UIColor whiteColor].CGColor;
    self.backLayer.allowsEdgeAntialiasing=YES;
    self.topShadowLayer = [CAGradientLayer layer];
    self.topShadowLayer.frame = self.topView.bounds;
    self.topShadowLayer.colors = @[(id)[UIColor clearColor].CGColor, (id)[UIColor blackColor].CGColor];
    self.topShadowLayer.opacity = 0;
    
    [self.topView addSublayer:self.backLayer];
    [self.topView addSublayer:self.topShadowLayer];
    [self.layer addSublayer:self.topView];
    
}

- (void)addBottomView
{
    
    
    self.bottomView=[CALayer layer];
    self.bottomView.frame =CGRectMake(0.f,
                                      CGRectGetMidY(self.webView.bounds),
                                      CGRectGetWidth(self.webView.bounds),
                                      CGRectGetMidY(self.webView.bounds));
    self.bottomView.backgroundColor=[UIColor clearColor].CGColor;
    self.bottomView.contentsGravity = kCAGravityResizeAspect;
    
    self.bottomShadowLayer = [CAGradientLayer layer];
    self.bottomShadowLayer.frame = self.bottomView.bounds;
    self.bottomShadowLayer.colors = @[(id)[UIColor blackColor].CGColor, (id)[UIColor clearColor].CGColor];
    self.bottomShadowLayer.opacity = 0;
    
    [self.bottomView addSublayer:self.bottomShadowLayer];
    [self.layer addSublayer:self.bottomView];
}

- (void)addGestureRecognizers
{
    self.foldGestureRecognizer= [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                                                           action:@selector(handlePan:)];
    [self.handleView addGestureRecognizer:self.foldGestureRecognizer];
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer
{
    CGPoint location = [recognizer locationInView:self];
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH,0), ^(void){
      self.translationValue= -((self.bounds.size.height/2)-self.bottomView.frame.size.height)/2.000f;
});
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        self.initialLocation = location.y;
        self.webView.scrollView.scrollEnabled=NO;
        [self updateBottomAndTopView];
        self.superViewLayer.contents=(__bridge id)self.superViewImage.CGImage;
        UIImage *topImage = [self imageForSection:LayerSectionTop withImage:self.image];
       // UIImage *backImage=[topImage blurredImage];
        self.topView.contents = (__bridge id)(topImage.CGImage);
        //self.backLayer.contents=(__bridge id)(backImage.CGImage);
        UIImage *bottomImage = [self imageForSection:LayerSectionBottom withImage:self.image];
        self.bottomView.contents = (__bridge id)(bottomImage.CGImage);
        self.topShadowLayer.frame = self.topView.bounds;
        self.bottomShadowLayer.frame = self.bottomView.bounds;
    }
    
    if ([[self.topView valueForKeyPath:@"transform.rotation.x"] floatValue] < -M_PI_2) {
        self.backLayer.opacity = 1.0;
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        self.topShadowLayer.opacity = 0.0;
        self.bottomShadowLayer.opacity = (location.y-self.initialLocation)/(CGRectGetHeight(self.bounds)-self.initialLocation);
        [CATransaction commit];
    } else {
        self.backLayer.opacity = 0.0;
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        CGFloat opacity = (location.y-self.initialLocation)/(CGRectGetHeight(self.bounds)-self.initialLocation);
        self.bottomShadowLayer.opacity = opacity;
        self.topShadowLayer.opacity = opacity;
        [CATransaction commit];
    }
    
    if ([self isLocation:location inView:self]) {
        CGFloat conversionFactor = -M_PI / (CGRectGetHeight(self.bounds) - self.initialLocation);
        CGFloat angle=(-([[self.topView valueForKeyPath:@"transform.rotation.x"]floatValue]*(180/M_PI)));
        const CGFloat scaleConversionFactor= 1-(angle/400);
        const CGFloat maxScaleAngle=75.0f;
        const CGFloat maxDownScaleConversionFactor= 1-(maxScaleAngle/400);
        POPBasicAnimation *rotationAnimation = [POPBasicAnimation animationWithPropertyNamed:kPOPLayerRotationX];
        POPBasicAnimation *translateAnimation=[POPBasicAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
        POPBasicAnimation *scaleAnimation=[POPBasicAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
        
        translateAnimation.toValue=@(self.translationValue);
       translateAnimation.duration=0;
        scaleAnimation.duration=0.0001;
        if (angle > 0  && angle <= maxScaleAngle) {
            scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(scaleConversionFactor,scaleConversionFactor)];
        }
        else if (angle > maxScaleAngle){
            scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(maxDownScaleConversionFactor, maxDownScaleConversionFactor)];
        }
        else{
            scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(1, 1)];
        }
        
        rotationAnimation.duration =0.0001;
        rotationAnimation.toValue = @((location.y-self.initialLocation)*conversionFactor);
        [self.topView pop_addAnimation:rotationAnimation forKey:@"rotationAnimation"];
        [self.bottomView pop_addAnimation:translateAnimation forKey:@"translateAnimation"];

        [self.topView pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
        [self.bottomView pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
}
    else {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        [self rotateToOriginWithVelocity:0];
        [self rescaleLayer];
        recognizer.enabled=NO;
    }
}

-(void)rescaleLayer{
    const CGFloat scaleConversionFactor= 1-(self.angle/400);
    const CGFloat maxScaleAngle=75.0f;
    const CGFloat maxDownScaleConversionFactor= 1-(maxScaleAngle/400);
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_HIGH,0), ^(void){
        self.translationValue= -((self.bounds.size.height/2)-self.bottomView.frame.size.height)/2.000f;
    });
    POPSpringAnimation *scaleAnimation=[POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
    //scaleAnimation.duration=0.5;
    if (self.angle > 0  && self.angle <= maxScaleAngle) {
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(scaleConversionFactor, scaleConversionFactor)];
    }
    else if (self.angle > maxScaleAngle){
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(maxDownScaleConversionFactor, maxDownScaleConversionFactor)];
    }
    else{
        scaleAnimation.toValue=[NSValue valueWithCGSize:CGSizeMake(1, 1)];
    }
    POPSpringAnimation *translateAnimation=[POPSpringAnimation animationWithPropertyNamed:kPOPLayerTranslationY];
    
    translateAnimation.toValue=@(self.translationValue);
    [self.bottomView pop_addAnimation:translateAnimation forKey:@"translateAnimation"];

    [self.topView pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];
    [self.bottomView pop_addAnimation:scaleAnimation forKey:@"scaleAnimation"];


}
- (void)rotateToOriginWithVelocity:(CGFloat)velocity
{
    POPSpringAnimation *rotationAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerRotationX];
 
    [rotationAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        [self.superViewLayer removeFromSuperlayer];
        [self.topView removeFromSuperlayer];
        [self.bottomView removeFromSuperlayer];
        self.webView.scrollView.scrollEnabled=YES;
        self.foldGestureRecognizer.enabled=YES;
        
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
    transform.m34 = 2.5 / -2000;
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
    CGFloat currentValue = [[anim valueForKey:@"currentValue"] floatValue];
    if (currentValue > -M_PI_2) {
        self.backLayer.opacity = 0.f;
        [CATransaction begin];
        [CATransaction setValue:(id)kCFBooleanTrue
                         forKey:kCATransactionDisableActions];
        self.bottomShadowLayer.opacity = -currentValue/M_PI;
        self.topShadowLayer.opacity = -currentValue/M_PI;
        [CATransaction commit];
    }
}

@end