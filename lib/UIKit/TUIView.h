/*
 Copyright 2011 Twitter, Inc.
 
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

#import "TUIResponder.h"
#import "TUIColor.h"
#import "TUIAccessibility.h"

extern NSString * const TUIViewWillMoveToWindowNotification; // both notification's userInfo will contain the new window under the key TUIViewWindow
extern NSString * const TUIViewDidMoveToWindowNotification;
extern NSString * const TUIViewWindow;

enum {
	TUIViewAutoresizingNone                 = 0,
	TUIViewAutoresizingFlexibleLeftMargin   = 1 << 0,
	TUIViewAutoresizingFlexibleWidth        = 1 << 1,
	TUIViewAutoresizingFlexibleRightMargin  = 1 << 2,
	TUIViewAutoresizingFlexibleBottomMargin = 1 << 3,
	TUIViewAutoresizingFlexibleHeight       = 1 << 4,
	TUIViewAutoresizingFlexibleTopMargin    = 1 << 5,
};
typedef NSUInteger TUIViewAutoresizing;

#define TUIViewAutoresizingFlexibleSize (TUIViewAutoresizingFlexibleWidth | TUIViewAutoresizingFlexibleHeight)

typedef enum {
	TUIViewAnimationCurveEaseInOut,
	TUIViewAnimationCurveEaseIn,
	TUIViewAnimationCurveEaseOut,
	TUIViewAnimationCurveLinear
} TUIViewAnimationCurve;

typedef enum {
	TUIViewAnimationTransitionNone,
} TUIViewAnimationTransition;

typedef enum {
    TUIViewContentModeCenter,
    TUIViewContentModeTop,
    TUIViewContentModeBottom,
    TUIViewContentModeLeft,
    TUIViewContentModeRight,
    TUIViewContentModeTopLeft,
    TUIViewContentModeTopRight,
    TUIViewContentModeBottomLeft,
    TUIViewContentModeBottomRight,
	TUIViewContentModeScaleToFill,
    TUIViewContentModeScaleAspectFit,
    TUIViewContentModeScaleAspectFill,
} TUIViewContentMode;

@class TUIView;
@class TUINSView;
@class TUINSWindow;

typedef void(^TUIViewDrawRect)(TUIView *, CGRect);
typedef CGRect(^TUIViewLayout)(TUIView *);

extern CGRect(^TUIViewCenteredLayout)(TUIView*);

@protocol TUIViewDelegate;

/**
 Root view class
 */

@interface TUIView : TUIResponder
{
	CALayer		*_layer;
	NSInteger	 _tag;
	NSArray		*_textRenderers;
	__unsafe_unretained id   _currentTextRenderer; // weak
	
	CGPoint		startDrag;
	
	__unsafe_unretained id<TUIViewDelegate> _viewDelegate;
	
	TUIViewDrawRect	drawRect;
	TUIViewLayout		layout;
	
	NSString *toolTip;
	NSTimeInterval toolTipDelay;
	
	@public
	TUINSView *_nsView; // keep this updated, fast way of getting .nsView
	
	struct {
		NSInteger lastWidth;
		NSInteger lastHeight;
		BOOL lastOpaque;
		CGContextRef context;
		CGRect dirtyRect;
		CGFloat lastContentsScale;
	} _context;
	
	struct {
		unsigned int userInteractionDisabled:1;
		unsigned int moveWindowByDragging:1;
		unsigned int resizeWindowByDragging:1;
		unsigned int didStartMovingByDragging:1;
		unsigned int didStartResizeByDragging:1;
		unsigned int disableSubpixelTextRendering:1;
		unsigned int pasteboardDraggingEnabled:1;
		unsigned int pasteboardDraggingIsDragging:1;
		unsigned int dragDistanceLock:1;
		unsigned int clearsContextBeforeDrawing:1;
		unsigned int drawInBackground:1;
		unsigned int needsDisplayWhenWindowsKeyednessChanges:1;
		
		unsigned int delegateMouseEntered:1;
		unsigned int delegateMouseExited:1;
		unsigned int delegateWillDisplayLayer:1;
	} _viewFlags;

	BOOL isAccessibilityElement;
	NSString *accessibilityLabel;
	NSString *accessibilityHint;
	NSString *accessibilityValue;
	TUIAccessibilityTraits accessibilityTraits;
	CGRect accessibilityFrame;
	NSOperationQueue *drawQueue;
}

/**
 Must be a subclass of CALayer. Default is CALayer. Subclasses may override.
 @returns the class of the layer to be allocated as the view backing layer.
 */
+ (Class)layerClass;

@property (nonatomic, unsafe_unretained) id<TUIViewDelegate> viewDelegate;

/**
 Designated initializer
 */
- (id)initWithFrame:(CGRect)frame;

/**
 Default is YES. if set to NO, user events (touch, keys) are ignored and removed from the event queue.
 */
@property (nonatomic,getter=isUserInteractionEnabled) BOOL userInteractionEnabled;

/**
 Default is 0
 */
@property (nonatomic) NSInteger tag;

/**
 Will always return a non-nil value. Reciever is the layer's delegate.
 @returns the reciever's backing layer.
 */
@property (nonatomic,readonly,strong) CALayer *layer;

/**
 Supply a block as an alternative to overriding -layoutSubviews
 */
@property (nonatomic, copy) TUIViewLayout layout;

@property (nonatomic, assign) BOOL moveWindowByDragging;
@property (nonatomic, assign) BOOL resizeWindowByDragging;

/**
 If set to NO, will disable subpixel antialiasing for text.
 */
@property (nonatomic, assign) BOOL subpixelTextRenderingEnabled; // defaults to YES

/**
 Tooltip will pop up if cursor hovers a view for toolTipDelay seconds
 */
@property (nonatomic, strong) NSString *toolTip;

/**
 Default is 1.5s
 */
@property (nonatomic, assign) NSTimeInterval toolTipDelay;

@property (nonatomic, assign) TUIViewContentMode contentMode;

/**
 If YES, drawing will be done in a background queue. If `drawQueue` is nil, it will be performed in the DISPATCH_QUEUE_PRIORITY_DEFAULT global queue. Note that `-viewWillDisplayLayer:` will still be called on the main thread.
 
 Defaults to NO.
 */
@property (nonatomic, assign) BOOL drawInBackground;

/**
 The queue in which drawing should be performed. Only used if `drawInBackground` is YES.
 
 Defaults to nil.
 */
@property (nonatomic, retain) NSOperationQueue *drawQueue;

/**
 Make this view the first responder. Returns NO if it fails.
 */
- (BOOL)makeFirstResponder;

/**
 * The window become key.
 */
- (void)windowDidBecomeKey;

/**
 * The window resigned key.
 */
- (void)windowDidResignKey;

/**
 * Does this view need to be redisplayed when the view's window's keyedness changes? If YES, the view will get automatically marked as needing display when the window's keyedness changes. Defaults to NO.
 */
@property (nonatomic, assign) BOOL needsDisplayWhenWindowsKeyednessChanges;

@end

@interface TUIView (TUIViewGeometry)

/**
 Animatable. Do not use frame if view is transformed since it will not correctly reflect the actual location of the view. use bounds + center instead.
 */
@property (nonatomic, assign) CGRect frame;

/**
 Use bounds/center and not frame if non-identity transform. if bounds dimension is odd, center may be have fractional part
 Default bounds is zero origin, frame size. animatable
 */
@property (nonatomic, assign) CGRect bounds;

/**
 Center is center of frame. animatable
 */
@property (nonatomic, assign) CGPoint center;

/**
 Default is CGAffineTransformIdentity. animatable
 */
@property (nonatomic, assign) CGAffineTransform transform;

/**
 Recursively calls -pointInside:withEvent:. point is in frame coordinates (event ignored)
 */
- (TUIView *)hitTest:(CGPoint)point withEvent:(id)event;

/**
 Default returns YES if point is in bounds (event ignored)
 */
- (BOOL)pointInside:(CGPoint)point withEvent:(id)event;

- (CGPoint)convertPoint:(CGPoint)point toView:(TUIView *)view;
- (CGPoint)convertPoint:(CGPoint)point fromView:(TUIView *)view;
- (CGRect)convertRect:(CGRect)rect toView:(TUIView *)view;
- (CGRect)convertRect:(CGRect)rect fromView:(TUIView *)view;

/**
 Simple resize. default is TUIViewAutoresizingNone
 */
@property (nonatomic, assign) TUIViewAutoresizing autoresizingMask;

/**
 @returns 'best' size to fit given size. does not actually resize view. Default is return existing view size
 */
- (CGSize)sizeThatFits:(CGSize)size;
- (void)sizeToFit;                       // calls sizeThatFits: with current view bounds and changes bounds size.

- (NSArray *)sortedSubviews;

@end

@interface TUIView (TUIViewHierarchy)

@property (nonatomic, readonly) TUIView *superview;
@property (nonatomic, readonly, strong) NSArray *subviews;

/**
 Recursive search, handy for debugging.
 */
@property (nonatomic, readonly) NSInteger deepNumberOfSubviews;

- (void)removeFromSuperview;
- (void)insertSubview:(TUIView *)view atIndex:(NSInteger)index;

- (void)addSubview:(TUIView *)view;
- (void)insertSubview:(TUIView *)view belowSubview:(TUIView *)siblingSubview;
- (void)insertSubview:(TUIView *)view aboveSubview:(TUIView *)siblingSubview;

- (void)bringSubviewToFront:(TUIView *)view;
- (void)sendSubviewToBack:(TUIView *)view;

- (void)didAddSubview:(TUIView *)subview;
- (void)willRemoveSubview:(TUIView *)subview;

- (void)willMoveToSuperview:(TUIView *)newSuperview;
- (void)didMoveToSuperview;
- (void)willMoveToWindow:(TUINSWindow *)newWindow;
- (void)didMoveToWindow;

/**
 Note: returns YES ff view == reciever
 */
- (BOOL)isDescendantOfView:(TUIView *)view;

/**
 Recursive search, includes reciever.
 */
- (TUIView *)viewWithTag:(NSInteger)tag;

/**
 Includes reciever.
 */
- (TUIView *)firstSuperviewOfClass:(Class)c;

- (void)setNeedsLayout;
- (void)layoutIfNeeded;

/**
 Subclasses may override to layout their subviews.  Also see the ^layout property for another mechanism for this.
 */
- (void)layoutSubviews;

@end

@interface TUIView (TUIViewRendering)

/**
 Supply a block as an alternative to subclassing and overriding -drawRect:
 */
@property (nonatomic, copy) TUIViewDrawRect drawRect;

/**
 Forces an immediate update of the backing view's layer.contents. May be inside an animation block to cross-fade.
 */
- (void)redraw; // forces a 'contents' update immediately - will animate contents if called inside an animation block

/**
 Subclasses should override to provide custom drawing.  Don't override unless needed, as overriding with a blank implementation incurs overhead (backing stores are allocated and rendered).
 You may also provide a block-based drawRect override with the .drawRect property.
 */
- (void)drawRect:(CGRect)rect;

/**
 Marks the view as needing display, will happen before the next run loop cycle
 */
- (void)setNeedsDisplay;
- (void)setNeedsDisplayInRect:(CGRect)rect;

/**
 Recursive -setNeedsDisplay
 */
- (void)setEverythingNeedsDisplay;

/**
 When YES, content and subviews are clipped to the bounds of the view. Default is NO.
 */
@property (nonatomic) BOOL clipsToBounds;

/**
 default is nil.  Setting this with a color with <1.0 alpha will also set opaque=NO
 */
@property (nonatomic,copy) TUIColor *backgroundColor;

/**
 animatable. default is 1.0
 */
@property (nonatomic) CGFloat alpha;

/**
 default is YES. opaque views must fill their entire bounds or the results are undefined. the active CGContext in drawRect: will not have been cleared and may have non-zeroed pixels
 */
@property (nonatomic,getter=isOpaque) BOOL opaque;

/**
 default is NO. doesn't check superviews
 */
@property (nonatomic,getter=isHidden) BOOL hidden;

/**
 default is YES. if set to NO, the view must fill its entire bounds, otherwise the view may contain graphical garbage.
 */
@property (nonatomic) BOOL clearsContextBeforeDrawing;

@end

@interface TUIView (TUIViewAnimation)

/**
 additional context info passed to will start/did stop selectors. begin/commit can be nested
 */
+ (void)beginAnimations:(NSString *)animationID context:(void *)context;

/**
 starts up any animations when the top level animation is commited
 */
+ (void)commitAnimations;

// no getters. if called outside animation block, these setters have no effect.

/**
 default = nil
 */
+ (void)setAnimationDelegate:(id)delegate;

/**
 default = NULL. -animationWillStart:(NSString *)animationID context:(void *)context
 */
+ (void)setAnimationWillStartSelector:(SEL)selector;

/**
 default = NULL. -animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context
 */
+ (void)setAnimationDidStopSelector:(SEL)selector;

/**
 default = 0.2
 */
+ (void)setAnimationDuration:(NSTimeInterval)duration;

/**
 default = 0.0
 */
+ (void)setAnimationDelay:(NSTimeInterval)delay;

+ (void)setAnimationStartDate:(NSDate *)startDate;                  // default = now ([NSDate date])
+ (void)setAnimationCurve:(TUIViewAnimationCurve)curve;              // default = UIViewAnimationCurveEaseInOut
+ (void)setAnimationRepeatCount:(float)repeatCount;                 // default = 0.0.  May be fractional
+ (void)setAnimationRepeatAutoreverses:(BOOL)repeatAutoreverses;    // default = NO. used if repeat count is non-zero
+ (void)setAnimationBeginsFromCurrentState:(BOOL)fromCurrentState;  // default = NO. If YES, the current view position is always used for new animations -- allowing animations to "pile up" on each other. Otherwise, the last end state is used for the animation (the default).
+ (void)setAnimationIsAdditive:(BOOL)additive;

+ (void)setAnimationTransition:(TUIViewAnimationTransition)transition forView:(TUIView *)view cache:(BOOL)cache;  // current limitation - only one per begin/commit block

+ (void)setAnimationsEnabled:(BOOL)enabled block:(void(^)(void))block;
+ (void)setAnimationsEnabled:(BOOL)enabled;                         // ignore any attribute changes while set.
+ (BOOL)areAnimationsEnabled;

/**
 animate the 'contents' property when set, defaults to NO
 */
+ (void)setAnimateContents:(BOOL)enabled;
+ (BOOL)willAnimateContents;

+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations;
+ (void)animateWithDuration:(NSTimeInterval)duration animations:(void (^)(void))animations completion:(void (^)(BOOL finished))completion;

/**
 from receiver and all subviews
 */
- (void)removeAllAnimations;

@end

@interface TUIView (TUIViewAppKit)

@property (nonatomic, assign, setter=setNSView:) TUINSView *nsView;
@property (nonatomic, readonly) TUINSWindow *nsWindow;

/**
 doesn't take any transforms into effect
 */
@property (nonatomic, readonly) NSRect frameInNSView;
@property (nonatomic, readonly) NSRect frameOnScreen;

- (CGPoint)localPointForLocationInWindow:(NSPoint)locationInWindow;
- (CGPoint)localPointForEvent:(NSEvent *)event;

/**
 @returns whether mouse event occured within the bounds of reciever
 */
- (BOOL)eventInside:(NSEvent *)event;

@end

@protocol TUIViewDelegate <NSObject>

@optional

- (void)view:(TUIView *)v mouseEntered:(NSEvent *)event;
- (void)view:(TUIView *)v mouseExited:(NSEvent *)event;
- (void)viewWillDisplayLayer:(TUIView *)v;

@end

#import "TUIView+Private.h"
#import "TUIView+Event.h"
#import "TUIView+PasteboardDragging.h"
