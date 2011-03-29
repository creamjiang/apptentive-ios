//
//  ATHUDView.m
//  ApptentiveConnect
//
//  Created by Andrew Wooster on 3/28/11.
//  Copyright 2011 Planetary Scale LLC. All rights reserved.
//

#import "ATHUDView.h"
#import "ATConnect.h"
#import <QuartzCore/QuartzCore.h>
#import <math.h>

#define DRAW_ROUND_RECT 0

@interface ATHUDView (Private)
- (void)setup;
- (void)teardown;
- (void)animateIn;
- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context;
@end

@implementation ATHUDView
@synthesize label, markType, size, cornerRadius;

- (id)initWithWindow:(UIWindow *)window {
    if ((self = [super initWithFrame:CGRectMake(0.0, 0.0, 100.0, 100.0)])) {
        [self setup];
        parentView = window;
    }
    return self;
}

- (void)dealloc {
    [self teardown];
    [super dealloc];
}

- (void)layoutSubviews {
    [super layoutSubviews];
#if !DRAW_ROUND_RECT
    self.layer.cornerRadius = self.cornerRadius;
#endif
    
    [label sizeToFit];
    
    CGFloat labelTopPadding = 2.0;
    if (NO) {
        CGRect b = self.frame;
        b.size = self.size;
        self.frame = b;
        
        // Inset everything by the corner radius.
        CGRect insetRect = CGRectInset(self.bounds, self.cornerRadius, self.cornerRadius);
        CGRect iconRect = insetRect;
        iconRect.size.height -= (label.bounds.size.height + labelTopPadding);
        
        CGRect labelRect = label.bounds;
        labelRect.size.width = insetRect.size.width;
        labelRect.origin.x = iconRect.origin.x;
        labelRect.origin.y = iconRect.origin.y + iconRect.size.height + labelTopPadding;
        
        label.frame = labelRect;
        icon.frame = iconRect;
    } else {
        CGSize imageSize = icon.image.size;
        [label sizeToFit];
        CGSize labelSize = [label sizeThatFits:CGSizeMake(200.0, label.bounds.size.height)];
        
        CGRect imageRect = CGRectMake(0.0, 0.0, imageSize.width, imageSize.height);
        CGRect labelRect = CGRectMake(0.0, imageSize.height + labelTopPadding, labelSize.width, labelSize.height);
        CGRect allRect = CGRectUnion(imageRect, labelRect);
        CGRect insetAllRect = CGRectStandardize(CGRectInset(allRect, -1.0*self.cornerRadius, -1.0*self.cornerRadius));
        CGFloat squareLength = MAX(insetAllRect.size.width, insetAllRect.size.height);
        insetAllRect.size.width = squareLength;
        insetAllRect.size.height = squareLength;
        
        
        // Center imageRect.
        CGRect finalImageRect = imageRect;
        if (finalImageRect.size.width < insetAllRect.size.width) {
            finalImageRect.origin.x += floorf((insetAllRect.size.width - imageRect.size.width)/2.0);
        }
        
        // Center labelRect.
        CGRect finalLabelRect = labelRect;
        if (finalLabelRect.size.width < insetAllRect.size.width) {
            finalLabelRect.origin.x += floorf((insetAllRect.size.width - finalLabelRect.size.width)/2.0);
        }
        
        self.frame = insetAllRect;
        self.center = parentView.center;
        label.frame = finalLabelRect;
        icon.frame = finalImageRect;
    }
}

- (void)show {
    [self animateIn];
}

#if DRAW_ROUND_RECT
- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGRect roundRect = CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height);
    CGFloat radius = self.cornerRadius;
    
    CGContextSaveGState(context);
    CGContextTranslateCTM(context, self.bounds.origin.x, self.bounds.origin.y);
    CGContextBeginPath(context);
    CGContextSetGrayFillColor(context, 0.0, 0.8);
    
    
	CGContextBeginPath(context);
	CGContextMoveToPoint(context, CGRectGetMinX(roundRect) + radius, CGRectGetMinY(roundRect));
	CGContextAddArc(context, CGRectGetMaxX(roundRect) - radius, CGRectGetMinY(roundRect) + radius, radius, 3 * M_PI / 2, 0, 0);
	CGContextAddArc(context, CGRectGetMaxX(roundRect) - radius, CGRectGetMaxY(roundRect) - radius, radius, 0, M_PI / 2, 0);
	CGContextAddArc(context, CGRectGetMinX(roundRect) + radius, CGRectGetMaxY(roundRect) - radius, radius, M_PI / 2, M_PI, 0);
	CGContextAddArc(context, CGRectGetMinX(roundRect) + radius, CGRectGetMinY(roundRect) + radius, radius, M_PI, 3 * M_PI / 2, 0);
	CGContextClosePath(context);
    
	CGContextFillPath(context);
    CGContextRestoreGState(context);
}
#endif

@end

@implementation ATHUDView (Private)
- (void)setup {
    [self setUserInteractionEnabled:NO];
    
    label = [[UILabel alloc] initWithFrame:CGRectZero];
    label.backgroundColor = [UIColor clearColor];
    label.opaque = NO;
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont boldSystemFontOfSize:17.0];
    label.textAlignment = UITextAlignmentCenter;
    label.lineBreakMode = UILineBreakModeTailTruncation;
    label.adjustsFontSizeToFitWidth = YES;
    [self addSubview:label];
    
    NSString *iconPath = nil;
    CGFloat scale = [[UIScreen mainScreen] scale];
    if (scale > 1.0) {
        iconPath = [[ATConnect resourceBundle] pathForResource:@"at_checkmark@2x" ofType:@"png"];
    } else {
        iconPath = [[ATConnect resourceBundle] pathForResource:@"at_checkmark" ofType:@"png"];
    }
    UIImage *iconImage = [[UIImage alloc] initWithContentsOfFile:iconPath];
    icon = [[UIImageView alloc] initWithImage:iconImage];
    [iconImage release];
    iconImage = nil;
    icon.backgroundColor = [UIColor clearColor];
    icon.opaque = NO;
    [self addSubview:icon];
    
    self.size = CGSizeMake(100.0, 100.0);
    self.cornerRadius = 10.0;
#if DRAW_ROUND_RECT
    self.backgroundColor = [UIColor clearColor];
#else
    self.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.8];
#endif
    self.opaque = NO;
    [self setNeedsLayout];
    [self setNeedsDisplay];
}

- (void)teardown {
    [icon removeFromSuperview];
    [icon release];
    icon = nil;
    [label removeFromSuperview];
    [label release];
    label = nil;
    parentView = nil;
}

- (void)animateIn {
    self.alpha = 1.0;
    [self layoutSubviews];
    [parentView addSubview:self];
    self.center = parentView.center;
    [parentView bringSubviewToFront:self];
    
    [UIView beginAnimations:@"animateIn" context:NULL];
    [UIView setAnimationDuration:3.0];
    [UIView setAnimationDelegate:self];
    [UIView setAnimationDidStopSelector:@selector(animationDidStop:finished:context:)];
    self.alpha = 1.0;
    [UIView commitAnimations];
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
    if ([animationID isEqualToString:@"animateIn"]) {
        [UIView beginAnimations:@"animateOut" context:NULL];
        [UIView setAnimationDelegate:self];
        [UIView setAnimationDuration:2.0];
        self.alpha = 0.0;
        [UIView commitAnimations];
    } else {
        [self removeFromSuperview];
    }
}
@end