//
//	TUICAAction.m
//
//	Created by James Lawton on 11/21/11.
//	Copyright (c) 2011 Bitswift. All rights reserved.
//

#import "TUICAAction.h"
#import "TUINSWindow.h"
#import "TUIView.h"
#import "TUIViewNSViewContainer+Private.h"
#import "CATransaction+TUIExtensions.h"
#import <objc/runtime.h>

@interface TUICAAction ()
/*
 * The action that this action is proxying, as specified at the time of
 * initialization.
 */
@property (nonatomic, strong, readonly) id<CAAction> innerAction;

/*
 * The first responder when the animation began, to be restored when the
 * animation completes.
 */
@property (nonatomic, strong) NSResponder *originalFirstResponder;

/*
 * Invoked whenever the geometry property `key` of `layer` has changed.
 */
- (void)geometryChangedForKey:(NSString *)key layer:(CALayer *)layer;

/*
 * Invoked whenever the opacity of `layer` has changed.
 */
- (void)opacityChangedForLayer:(CALayer *)layer;

/*
 * Renders the `NSView` of the given view into its layer and hides the `NSView`.
 *
 * This can be used to capture a static rendering of the `NSView` for animation
 * or other purposes.
 *
 * @param view The <TUIViewNSViewContainer> hosting the `NSView`.
 *
 * @note <stopRenderingNSViewOfView:> should be invoked to restore the normal
 * rendering of the `NSView`. Calls to these methods cannot be nested.
 */
- (void)startRenderingNSViewOfView:(TUIViewNSViewContainer *)view;

/*
 * Restores the normal rendering of the given view's `NSView` after a previous
 * call to <startRenderingNSViewOfView:>.
 *
 * @param view The <TUIViewNSViewContainer> hosting the `NSView`.
 *
 * @note Calls to this method cannot be nested.
 */
- (void)stopRenderingNSViewOfView:(TUIViewNSViewContainer *)view;

/*
 * Schedules the given block to execute when the animation represented by the
 * receiver completes.
 *
 * @param block A block to be run when the animation completes.
 * @param layer The layer that the receiver is attached to.
 */
- (void)runWhenAnimationCompletes:(void (^)(void))block forLayer:(CALayer *)layer;

/*
 * Returns `YES` if objects of this class add features to actions for the given
 * geometry property.
 */
+ (BOOL)interceptsGeometryActionForKey:(NSString *)key;

@end

@implementation TUICAAction

#pragma mark Properties

@synthesize innerAction = m_innerAction;
@synthesize originalFirstResponder = m_originalFirstResponder;

#pragma mark Lifecycle

- (id)initWithAction:(id<CAAction>)innerAction {
	self = [super init];
	if (!self)
		return nil;

	m_innerAction = innerAction;
	return self;
}

+ (id)actionWithAction:(id<CAAction>)innerAction {
	return [[self alloc] initWithAction:innerAction];
}

#pragma mark TUIViewNSViewContainer support

- (void)enumerateTUIViewNSViewContainersInLayer:(CALayer *)layer block:(void(^)(TUIViewNSViewContainer *))block {
	if ([layer.delegate isKindOfClass:[TUIViewNSViewContainer class]]) {
		block(layer.delegate);
	} else {
		for (CALayer *sublayer in [layer sublayers]) {
			[self enumerateTUIViewNSViewContainersInLayer:sublayer block:block];
		}
	}
}

- (void)startRenderingNSViewOfView:(TUIViewNSViewContainer *)view; {
	// Resign first responder on an animating NSView
	// to disable focus ring.
	id responder = view.nsWindow.firstResponder;
	if ([responder isKindOfClass:[NSView class]] && [responder isDescendantOf:view.rootView]) {
		// find the next responder which is not in this NSView hierarchy, and
		// make that the first responder for the duration of the animation
		id nextResponder = [responder nextResponder];

		BOOL (^validResponder)(id) = ^(id obj){
			if (!obj)
				return YES;

			if ([obj isKindOfClass:[NSView class]] && [responder isDescendantOf:view.rootView])
				return NO;

			if (![obj acceptsFirstResponder])
				return NO;

			return YES;
		};

		while (!validResponder(nextResponder)) {
			nextResponder = [nextResponder nextResponder];
		}

		if ([view.nsWindow makeFirstResponder:nextResponder]) {
			self.originalFirstResponder = responder;
		}
	}

	BOOL wasAlreadyRendering = view.renderingContainedView;

	[view startRenderingContainedView];
	if (!wasAlreadyRendering) {
		view.rootView.alphaValue = 0.0;
	}
}

- (void)stopRenderingNSViewOfView:(TUIViewNSViewContainer *)view; {
	[view stopRenderingContainedView];

	if (!view.renderingContainedView) {
		[view synchronizeNSViewGeometry];
		view.rootView.alphaValue = 1.0;
	}

	if (self.originalFirstResponder) {
		[view.nsWindow makeFirstResponder:self.originalFirstResponder];
		self.originalFirstResponder = nil;
	}
}

#pragma mark Action interception

- (void)runActionForKey:(NSString *)key object:(id)anObject arguments:(NSDictionary *)dict {
	if (![[NSNull null] isEqual:self.innerAction])
		[self.innerAction runActionForKey:key object:anObject arguments:dict];

	CAAnimation *animation = [anObject animationForKey:key];
	if (!animation)
		return;

	if ([key isEqualToString:@"opacity"]) {
		[self opacityChangedForLayer:anObject];
	} else if ([[self class] interceptsGeometryActionForKey:key]) {
		[self geometryChangedForKey:key layer:anObject];
	}
}

+ (BOOL)interceptsGeometryActionForKey:(NSString *)key {
	return [key isEqualToString:@"position"] || [key isEqualToString:@"bounds"] || [key isEqualToString:@"transform"];
}

+ (BOOL)interceptsActionForKey:(NSString *)key {
	return [key isEqualToString:@"opacity"] || [self interceptsGeometryActionForKey:key];
}

#pragma mark Action handlers

- (void)geometryChangedForKey:(NSString *)key layer:(CALayer *)layer {
	// For all contained TUIViewNSViewContainers, render their NSView into their layer
	// and hide the NSView. Now the visual element is part of the layer
	// hierarchy we're animating.
	NSMutableArray *cachedViews = [NSMutableArray array];
	[self enumerateTUIViewNSViewContainersInLayer:layer block:^(TUIViewNSViewContainer *view) {
		[self startRenderingNSViewOfView:view];
		[cachedViews addObject:view];
	}];

	// If we did nothing, there's no cleanup needed.
	if (![cachedViews count])
		return;

	// return NSViews to rendering themselves after this animation completes
	[self runWhenAnimationCompletes:^{
		[cachedViews enumerateObjectsUsingBlock:^(TUIViewNSViewContainer *view, NSUInteger idx, BOOL *stop) {
			[self stopRenderingNSViewOfView:view];
		}];
	} forLayer:layer];
}

- (void)opacityChangedForLayer:(CALayer *)layer; {
	float newOpacity = layer.opacity;

	if (fabs(1 - newOpacity) < 0.001) {
		// return NSViews to rendering themselves after this animation completes
		[self runWhenAnimationCompletes:^{
			[self enumerateTUIViewNSViewContainersInLayer:layer block:^(TUIViewNSViewContainer *view) {
				[self stopRenderingNSViewOfView:view];
			}];
		} forLayer:layer];
	} else {
		// For all contained TUIViewNSViewContainers, render their NSView into their layer
		// and hide the NSView. Now the visual element is part of the layer
		// hierarchy we're animating.
		[self enumerateTUIViewNSViewContainersInLayer:layer block:^(TUIViewNSViewContainer *view) {
			[self startRenderingNSViewOfView:view];
		}];
	}
}

- (void)runWhenAnimationCompletes:(void (^)(void))block forLayer:(CALayer *)layer; {
	NSParameterAssert(block != nil);
	NSParameterAssert(layer != nil);

	CFTimeInterval duration = [CATransaction animationDuration];

	if ([(id)self.innerAction isKindOfClass:[CAAnimation class]]) {
		CAAnimation *animation = (id)self.innerAction;
		if (animation.duration)
			duration = animation.duration;

		duration += animation.beginTime;
		duration /= animation.speed;

		do {
			duration += layer.beginTime - layer.timeOffset;
			duration /= layer.speed;

			layer = layer.superlayer;
		} while (layer);
	}

	dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(duration * NSEC_PER_SEC));
	dispatch_after(popTime, dispatch_get_main_queue(), block);
}

@end

