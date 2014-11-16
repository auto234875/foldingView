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

typedef NS_ENUM(NSInteger, LayerSection) {
    LayerSectionTop,
    LayerSectionBottom
};

@interface FoldingView() <POPAnimationDelegate,UIGestureRecognizerDelegate>
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
@property(nonatomic)CALayer *superViewLayer;
@property(nonatomic)UIPanGestureRecognizer *foldGestureRecognizer;
@property(nonatomic)CATransformLayer *scaleLayer;
@property(nonatomic)CGFloat angle;
@property(nonatomic)BOOL adjustRotationSpeed;
@end

@implementation FoldingView

- (id)initWithFrame:(CGRect)frame request:(NSURLRequest*)request
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor=[UIColor clearColor];
        _webView=[[WKWebView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width,self.bounds.size.height)];
        [_webView loadRequest:request];
        [self addSubview:_webView];
        [self addGestureRecognizers];
        _adjustRotationSpeed=YES;
    }
    return self;
}

-(BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer{
    return YES;
}
-(CALayer*)scaleLayer{
    if (!_scaleLayer) {
        _scaleLayer=[CATransformLayer layer];
        _scaleLayer.frame=self.bounds;
    }
    if ([_scaleLayer superlayer] != self.layer) {
        [self.layer addSublayer:_scaleLayer];
    }
    return _scaleLayer;
}

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
    [self.scaleLayer addSublayer:self.topView];
    
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
-(BOOL)gestureRecognizerShouldBegin:(UIPanGestureRecognizer *)gestureRecognizer{
    if (gestureRecognizer==self.foldGestureRecognizer) {
        CGPoint location = [gestureRecognizer locationInView:self];
        //CGPoint startingPoint=[gestureRecognizer translationInView:self];
        //CGFloat angle=(-([[self.topView valueForKeyPath:@"transform.rotation.x"]floatValue]*(180/M_PI)));
        if (self.webView.scrollView.contentOffset.y==0) {
        return YES;
        }
    else{
        if (location.y<=60) {
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
    
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        
        self.initialLocation = location.y;
        [self createFoldLayers];
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
        CGFloat angle=(-([[self.topView valueForKeyPath:@"transform.rotation.x"]floatValue]*(180/M_PI)));
        [self animateViewWithRotation:angle translation:startingPoint.x verticalPoint:location.y];
}
    else {
        recognizer.enabled = NO;
        recognizer.enabled = YES;
    }
    
    if (recognizer.state == UIGestureRecognizerStateEnded || recognizer.state == UIGestureRecognizerStateCancelled) {
        CGFloat angle=(-([[self.topView valueForKeyPath:@"transform.rotation.x"]floatValue]*(180/M_PI)));

        if (angle < 30){
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
    rotationAnimation.duration=(-rotationAngle*(180/M_PI))/1200;
    }
    else{
        rotationAnimation.duration=0.01;
    }
    [rotationAnimation setCompletionBlock:^(POPAnimation *anim, BOOL finished) {
        //self.adjustRotationSpeed=NO;
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
        [self removeFromSuperview];
    }];
    [self.topView pop_addAnimation:rotateToCloseAnimation forKey:@"rotationToCloseAnimation"];
    [self.scaleLayer pop_addAnimation:scaleToCloseAnimation forKey:@"scaleToCloseAnimation"];
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
        self.adjustRotationSpeed=YES;
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