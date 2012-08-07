/*
 Copyright 2012 Twitter, Inc.
 
 Licensed under the Apache License, Version 2.0 (the "License");
 you may not use this work except in compliance with the License.
 You may obtain a copy of the License in the LICENSE file, or at:
 
 http://www.apache.org/licenses/LICENSE-2.0
 
 Unless required by applicable law or agreed to in writing, software
 distributed under the License is distributed on an "AS IS" BASIS,
 WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 See the License for the specific language governing permissions and
 limitations under the License.
 */

#import "TUIProgressBar.h"
#import "CAAnimation+TUIExtensions.h"
#import "TUICGAdditions.h"

NSString *GHUIProgressBarSetNeedsDisplayObservationContext = @"GHUIProgressBarSetNeedsDisplayObservationContext";

CGFloat const GHUIProgressBarBarberPoleAnimationDuration = 5.0;
CGFloat const GHUIProgressBarBarberPolePatternWidth = 8.0;
CGFloat const GHUIProgressBarIdealTrackHeight = 12.0;

void GHUIProgressPatternDrawCallback(void *info, CGContextRef context);

@interface TUIProgressBar ()

@property (nonatomic, strong) TUIView *animationView; //Merely used for easy cleanup as needed
@property (nonatomic, readonly) CGPoint farLeftAnimatingPosition;
@property (nonatomic, readonly) CGPoint farRightAnimatingPosition;
@property (nonatomic, readonly) TUIProgressBarStyle style;

- (CGRect)fillRect;

@end

@implementation TUIProgressBar

@synthesize drawTrack = _drawTrack;
@synthesize drawFill = _drawFill;
@synthesize progress = _progress;
@synthesize indeterminate = _indeterminate;

@synthesize animationView = _animationContainer;
@synthesize style = _style;

#pragma mark TUIView

- (id)initWithFrame:(CGRect)frame
{	
	return [self initWithFrame:frame style:TUIProgressBarStyleBlue];
}

- (id)initWithFrame:(CGRect)frame style:(TUIProgressBarStyle)style {
	self = [super initWithFrame:frame];
	if(self == nil) return nil;
	
	self.backgroundColor = [NSColor clearColor];
	self.clipsToBounds = YES;
	_style = style;
	
	CGRect (^trackRectForFrame)(CGRect) = ^ (CGRect givenFrame) {
		return CGRectMake(NSMinX(givenFrame) + 0.5, NSMinY(givenFrame) + 1.5, NSWidth(givenFrame) - 1.0, NSHeight(givenFrame) - 2.0);
	};
	
	CGFloat (^trackRadiusForTrackRect)(CGRect) = ^ (CGRect trackRect) {
		return ceil(NSHeight(trackRect) / 2.0);
	};
		
	self.drawTrack = ^ (TUIView *view, CGRect dirtyRect) {
		CGRect trackRect = trackRectForFrame(view.bounds);
		CGFloat radius = trackRadiusForTrackRect(trackRect);
		
		//Backing grad
		[NSGraphicsContext saveGraphicsState];		
		CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort];
		
		CGContextAddRoundRect(context, trackRect, radius);
		CGContextClip(context);
		
		NSGradient *backingGrad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:(51.0/255.0) alpha:0.6] endingColor:[NSColor colorWithCalibratedWhite:(85.0/255.0) alpha:0.6]];
		[backingGrad drawInRect:trackRect angle:270.0];
		
		[NSGraphicsContext restoreGraphicsState];
		
		//Stroke
		[NSGraphicsContext saveGraphicsState];
		context = [[NSGraphicsContext currentContext] graphicsPort];
		CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeMultiply);
		[[NSColor colorWithCalibratedWhite:(66.0/255.0) alpha:1.0] set];
		CGContextAddRoundRect(context, trackRect, radius);
		CGContextStrokePath(context);
		[NSGraphicsContext restoreGraphicsState];
		
		//Drop shadow
		[NSGraphicsContext saveGraphicsState];
		CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeScreen);
		[[NSColor colorWithCalibratedWhite:1.0 alpha:0.54] set];
		CGFloat y = NSMinY(view.bounds);
		[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(view.bounds) + radius, y) toPoint:NSMakePoint((NSMaxX(view.bounds) - radius), y)];
		[NSGraphicsContext restoreGraphicsState];
		 		
		[NSGraphicsContext saveGraphicsState];
		//Inner shadow
		[[NSColor colorWithCalibratedWhite:0.0 alpha:0.16] set];
		y = NSMaxY(trackRect) - 1.0;
		[NSBezierPath strokeLineFromPoint:NSMakePoint((NSMinX(view.bounds) + (radius - 3.0)), y) toPoint:NSMakePoint((NSMaxX(view.bounds) - (radius - 3.0)), y)];
		
		[NSGraphicsContext restoreGraphicsState];
	};
	
	self.drawFill = ^ (TUIView *view, CGRect dirtyRect) {
		TUIProgressBar *progressBar = (TUIProgressBar *)view;
		if (!progressBar.indeterminate && progressBar.progress == 0.0) //Eesh… I feel dirty comparing to 0 here
			return;
		
		CGContextRef currentContext = [[NSGraphicsContext currentContext] graphicsPort];
		CGRect fillRect = [progressBar fillRect];
		CGFloat radius = (NSHeight(fillRect) / 2.0);
		
		//Backing grad
		[NSGraphicsContext saveGraphicsState];
		CGContextAddRoundRect(currentContext, fillRect, radius);
		CGContextClip(currentContext);
		
		NSGradient *backingGrad = nil;
		if (style == TUIProgressBarStyleGray) {
			backingGrad = [[NSGradient alloc] initWithStartingColor:[NSColor colorWithCalibratedWhite:(140.0/255.0) alpha:1.0] endingColor:[NSColor colorWithCalibratedWhite:(186.0/255.0) alpha:1.0]];
		} else {
			NSColor *startColor = [NSColor colorWithCalibratedRed:(6.0/255.0) green:(109.0/255.0) blue:(176.0/255.0) alpha:1.0];
			NSColor *mid1Color = [NSColor colorWithCalibratedRed:0.0 green:(136.0/255.0) blue:(213.0/255.0) alpha:1.0];
			NSColor *mid2Color = [NSColor colorWithCalibratedRed:(36.0/255.0) green:(144.0/255.0) blue:(228.0/255.0) alpha:1.0];
			NSColor *endColor = [NSColor colorWithCalibratedRed:(27.0/255.0) green:(160.0/255.0) blue:(245.0/255.0) alpha:1.0];
			backingGrad = [[NSGradient alloc] initWithColorsAndLocations:startColor, 0.0, mid1Color, 0.49, mid2Color, 0.51, endColor, 1.0, nil];
		}
		
		[backingGrad drawInRect:fillRect angle:90.0];
		
		if (style != TUIProgressBarStyleGray) {
			//Inner Shadow
			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.29] set];
			CGFloat y = NSMaxY(fillRect) - 1.0;
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(fillRect), y) toPoint:NSMakePoint(NSMaxX(fillRect), y)];
		}
		
		[NSGraphicsContext restoreGraphicsState];
		
		//Stroke
		[NSGraphicsContext saveGraphicsState];
		CGContextSetBlendMode(currentContext, kCGBlendModeOverlay);
				
		if (style == TUIProgressBarStyleGray) {
			//Inner Shadow
			[[NSColor colorWithCalibratedWhite:1.0 alpha:0.19] set];
			CGFloat y = NSMaxY(fillRect) - 1.0;
			[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(fillRect), y) toPoint:NSMakePoint(NSMaxX(fillRect), y)];
			
			//(stroke)
			[[NSColor colorWithCalibratedWhite:(71.0/255.0) alpha:1.0] set];
		} else {
			[[NSColor colorWithCalibratedRed:(27.0/255.0) green:(54.0/255.0) blue:(149.0/255.0) alpha:1.0] set];
		}
		
		CGContextAddRoundRect(currentContext, fillRect, radius);
		CGContextStrokePath(currentContext);
		
		[NSGraphicsContext restoreGraphicsState];
		
		if (style != TUIProgressBarStyleGray) {
			//Colour overlay
			[NSGraphicsContext saveGraphicsState];
			CGContextSetBlendMode(currentContext, kCGBlendModeColor);
			[[NSColor colorWithCalibratedRed:(9.0/255.0) green:(115.0/255.0) blue:(198.0/255.0) alpha:1.0] set];
			CGContextAddRoundRect(currentContext, fillRect, radius);
			CGContextFillPath(currentContext);
			[NSGraphicsContext restoreGraphicsState];
		}
	};
	
	[self addObserver:self forKeyPath:@"drawTrack" options:0 context:&GHUIProgressBarSetNeedsDisplayObservationContext];
	[self addObserver:self forKeyPath:@"drawFill" options:0 context:&GHUIProgressBarSetNeedsDisplayObservationContext];
	[self addObserver:self forKeyPath:@"progress" options:0 context:&GHUIProgressBarSetNeedsDisplayObservationContext];
	[self addObserver:self forKeyPath:@"indeterminate" options:0 context:&GHUIProgressBarSetNeedsDisplayObservationContext];
	
	return self;
}

- (void)dealloc
{
	[self removeObserver:self forKeyPath:@"drawTrack"];
	[self removeObserver:self forKeyPath:@"drawFill"];
	[self removeObserver:self forKeyPath:@"progress"];
	[self removeObserver:self forKeyPath:@"indeterminate"];
}

- (void)drawRect:(CGRect)dirtyRect {
	[self.backgroundColor set];
	CGContextFillRect(TUIGraphicsGetCurrentContext(), self.bounds);
	
	if (self.drawTrack != nil)
		self.drawTrack(self, dirtyRect);
	if (self.drawFill != nil)
		self.drawFill(self, dirtyRect);
}

- (CGSize)sizeThatFits:(CGSize)size {
	return CGSizeMake(size.width, GHUIProgressBarIdealTrackHeight);
}

- (CGRect)fillRect
{
	CGFloat drawingProgress = (self.indeterminate ? 1.0 : self.progress);
	if (drawingProgress > 1.0)
		drawingProgress = 1.0;
	
	static const CGFloat minimumWidth = 10.0f;
	CGRect fillRect = self.bounds;
	fillRect.size.width = MAX(ceil(drawingProgress * fillRect.size.width), minimumWidth);

	CGFloat delta = (self.style == TUIProgressBarStyleGray ? 0.5 : 1.5);
	fillRect = CGRectInset(fillRect, delta, delta);
	
	fillRect.size.height --;
	fillRect.origin.y ++;
	
	return fillRect;
}

#pragma mark API

- (CABasicAnimation *)basicAnimationForView:(TUIView *)view animationKey:(NSString *)animationKey
{
	CABasicAnimation *barberPoleAnimation = [CABasicAnimation animationWithKeyPath:@"position"];
	barberPoleAnimation.duration = GHUIProgressBarBarberPoleAnimationDuration;
	barberPoleAnimation.toValue = [NSValue valueWithPoint:self.farLeftAnimatingPosition];
	barberPoleAnimation.tui_completionBlock = ^ {
		view.layer.position = self.farRightAnimatingPosition;
		CABasicAnimation *newAnimation = [self basicAnimationForView:view animationKey:animationKey];
		[view.layer addAnimation:newAnimation forKey:animationKey];
	};
	
	return barberPoleAnimation;
}

- (CGPoint)farLeftAnimatingPosition
{
	return CGPointMake((NSMidX(self.animationView.superview.bounds) - (NSWidth(self.animationView.superview.bounds) / 2.0)) + 1.0, NSMidY(self.animationView.superview.bounds));
}

- (CGPoint)farRightAnimatingPosition
{
	return CGPointMake(NSMaxX(self.animationView.superview.bounds), NSMidY(self.animationView.superview.bounds));
}

- (void)setIndeterminate:(BOOL)indeterminate
{
	static NSString *animationKey = @"GHUIBarberPoleAnimation";

	_indeterminate = indeterminate;

	if (!indeterminate) {
		[self.animationView.superview removeFromSuperview];
		self.animationView = nil;
		return;
	}
	
	if (self.animationView != nil) { //We already have an animation view added but the progress bar could have been taken off screen, so stopped animating
		NSArray *animationKeys = self.animationView.layer.animationKeys;
		if (animationKeys == nil || ![animationKeys containsObject:animationKey]) {
			[self.animationView.layer addAnimation:[self basicAnimationForView:self.animationView animationKey:animationKey] forKey:animationKey];
		}
		return;
	}
	
	// Animation container
	TUIView *animationClippingView = [[TUIView alloc] initWithFrame:[self fillRect]];
	animationClippingView.clipsToBounds = YES;
	animationClippingView.opaque = NO;
	animationClippingView.backgroundColor = [NSColor clearColor];
	
	CGPathRef clipPath = TUICGPathCreateRoundedRect(animationClippingView.bounds, ceil(NSHeight(animationClippingView.bounds) / 2.0));
	CAShapeLayer *clipLayer = [[CAShapeLayer alloc] init];
	clipLayer.path = clipPath;
	animationClippingView.layer.mask = clipLayer;
	CGPathRelease(clipPath);
	
	CGRect animationViewFrame = CGRectMake(NSMinX(animationClippingView.bounds),NSMinY(animationClippingView.bounds), (NSWidth(animationClippingView.bounds) * 2.0), NSHeight(animationClippingView.bounds));
	self.animationView = [[TUIView alloc] initWithFrame:animationViewFrame];
	self.animationView.opaque = NO;
	self.animationView.backgroundColor = [NSColor clearColor];
	self.animationView.drawRect = ^ (TUIView *view, CGRect dirtyRect) {
		CGRect patternBounds = CGRectMake(0.0, 0.0, GHUIProgressBarBarberPolePatternWidth, NSHeight(view.bounds));
		
		[NSGraphicsContext saveGraphicsState];
		CGContextRef currentContext = [[NSGraphicsContext currentContext] graphicsPort];
		
		CGColorSpaceRef patternColorSpace = CGColorSpaceCreatePattern(NULL);
		CGContextSetFillColorSpace(currentContext, patternColorSpace);
		CGColorSpaceRelease(patternColorSpace);
		
		const struct CGPatternCallbacks callbacks = {0, &GHUIProgressPatternDrawCallback, NULL};
		CGPatternRef pattern = CGPatternCreate((__bridge void *)[NSValue valueWithRect:patternBounds], patternBounds, CGAffineTransformIdentity, GHUIProgressBarBarberPolePatternWidth, NSHeight(view.bounds), kCGPatternTilingConstantSpacing, true, &callbacks);
		CGFloat components = 1.0; //It's a coloured pattern so just alpha is fine
		CGContextSetFillPattern(currentContext, pattern, &components); 
		CGContextFillRect(currentContext, view.bounds);
		CGPatternRelease(pattern);
		[NSGraphicsContext restoreGraphicsState];
	};
	
	[self addSubview:animationClippingView];
	[animationClippingView addSubview:self.animationView];
	
	[self.animationView.layer addAnimation:[self basicAnimationForView:self.animationView animationKey:animationKey] forKey:animationKey];
	
	[self setNeedsDisplay];
}

- (void)setProgress:(CGFloat)progress
{
	_progress = progress;
	if (progress > 0.0 && self.indeterminate)
		self.indeterminate = NO;
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (context == &GHUIProgressBarSetNeedsDisplayObservationContext) {
        [self setNeedsDisplay];
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Pattern Drawing Callbacks

void GHUIProgressPatternDrawCallback(void *info, CGContextRef context)
{
	[NSGraphicsContext saveGraphicsState];
	CGRect bounds = [(__bridge NSValue *)info rectValue];
	CGContextSetBlendMode([[NSGraphicsContext currentContext] graphicsPort], kCGBlendModeOverlay);
	[[NSColor colorWithCalibratedWhite:1.0 alpha:0.24] set];

	// I have _no_ idea why the save/restore of graphics state is fucking this up… working around it with this crap for now
	CGFloat previousLineWidth = [NSBezierPath defaultLineWidth];
	NSLineCapStyle previousLineCapStyle = [NSBezierPath defaultLineCapStyle];
	//
	
	[NSBezierPath setDefaultLineWidth:3.0];
	[NSBezierPath setDefaultLineCapStyle:NSSquareLineCapStyle];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMinX(bounds), NSMidY(bounds)) toPoint:NSMakePoint(NSMaxX(bounds), NSMaxY(bounds))];
	[NSBezierPath strokeLineFromPoint:NSMakePoint(NSMidX(bounds), NSMinY(bounds)) toPoint:NSMakePoint((NSMaxX(bounds) + 1.0), NSMidY(bounds))];
	
	// Fuck AppKit
	[NSBezierPath setDefaultLineWidth:previousLineWidth];
	[NSBezierPath setDefaultLineCapStyle:previousLineCapStyle];
	//
	
	[NSGraphicsContext restoreGraphicsState];
}

@end
