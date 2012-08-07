//
//	TUIView+TUIBridgedView.m
//	TwUI
//
//	Created by Justin Spahr-Summers on 17.07.12.
//
//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.
//

#import "TUIView+TUIBridgedView.h"
#import "TUINSView.h"
#import "TUIBridgedScrollView.h"
#import <objc/runtime.h>

@implementation TUIView (TUIBridgedView)

#pragma mark Properties

// implemented by TUIView proper
@dynamic layer;

#pragma mark Geometry

// TODO: the implementations of these conversion methods are not strictly
// correct -- they only take into account position, and do not include things
// like transforms (however, the implementation does match TUIView geometry)

- (CGPoint)convertFromWindowPoint:(CGPoint)point; {
	if (self.hostView) {
		CGPoint pointInHostView = [self.hostView convertFromWindowPoint:point];
		return [self.layer convertPoint:pointInHostView fromLayer:self.hostView.layer];
	}

	CGRect hostViewFrame = self.frameInNSView;

	CGPoint pointInHostView = [self.nsView convertPoint:point fromView:nil];
	return CGPointMake(pointInHostView.x - hostViewFrame.origin.x, pointInHostView.y - hostViewFrame.origin.y);
}

- (CGPoint)convertToWindowPoint:(CGPoint)point; {
	if (self.hostView) {
		CGPoint pointInHostView = [self.layer convertPoint:point toLayer:self.hostView.layer];
		return [self.hostView convertToWindowPoint:pointInHostView];
	}

	CGRect hostViewFrame = self.frameInNSView;

	CGPoint pointInHostView = CGPointMake(point.x + hostViewFrame.origin.x, point.y + hostViewFrame.origin.y);
	return [self.nsView convertPoint:pointInHostView toView:nil];
}

- (CGRect)convertFromWindowRect:(CGRect)rect; {
	if (self.hostView) {
		CGRect rectInHostView = [self.hostView convertFromWindowRect:rect];
		return [self.layer convertRect:rectInHostView fromLayer:self.hostView.layer];
	}

	CGRect hostViewFrame = self.frameInNSView;

	CGRect rectInHostView = [self.nsView convertRect:rect fromView:nil];
	return CGRectOffset(rectInHostView, -hostViewFrame.origin.x, -hostViewFrame.origin.y);
}

- (CGRect)convertToWindowRect:(CGRect)rect; {
	if (self.hostView) {
		CGRect rectInHostView = [self.layer convertRect:rect toLayer:self.hostView.layer];
		return [self.hostView convertToWindowRect:rectInHostView];
	}

	CGRect hostViewFrame = self.frameInNSView;

	CGRect rectInHostView = CGRectOffset(rect, hostViewFrame.origin.x, hostViewFrame.origin.y);
	return [self.nsView convertRect:rectInHostView toView:nil];
}

#pragma mark Hit testing

- (id<TUIBridgedView>)descendantViewAtPoint:(NSPoint)point {
	// Clip to self
	if (!self.userInteractionEnabled || self.hidden || ![self pointInside:point] || self.alpha <= 0.0f)
		return nil;

	__block id<TUIBridgedView> result = self;

	[self.subviews
		enumerateObjectsUsingBlock:^(TUIView *view, NSUInteger index, BOOL *stop){
			CGPoint subviewPoint = [view convertPoint:point fromView:self];

			id<TUIBridgedView> hitTestedView = [view descendantViewAtPoint:subviewPoint];
			if (hitTestedView) {
				result = hitTestedView;
				*stop = YES;
			}
	}];

	return result;
}

- (BOOL)pointInside:(CGPoint)point; {
	return [self pointInside:point withEvent:nil];
}

#pragma mark View hierarchy

- (id<TUIHostView>)hostView {
	id<TUIHostView> hostView = objc_getAssociatedObject(self, @selector(hostView));
	if (hostView)
		return hostView;
	else
		return self.superview.hostView;
}

- (id<TUIBridgedView>)immediateParentView {
	id<TUIHostView> hostView = objc_getAssociatedObject(self, @selector(hostView));
	if (hostView)
		return hostView;
	else
		return self.superview;
}

- (void)setHostView:(id<TUIHostView>)view {
    @autoreleasepool {
        TUINSView *oldTUINSView = self.ancestorTUINSView;
        TUINSView *newTUINSView = view.ancestorTUINSView;

        if (oldTUINSView != newTUINSView)
            [self willMoveToTUINSView:newTUINSView];

		objc_setAssociatedObject(self, @selector(hostView), view, OBJC_ASSOCIATION_ASSIGN);

        if (oldTUINSView != newTUINSView)
            [self didMoveFromTUINSView:oldTUINSView];

        [self viewHierarchyDidChange];
    }
}

- (void)ancestorDidLayout; {
	[self.subviews makeObjectsPerformSelector:_cmd];
}

- (TUINSView *)ancestorTUINSView; {
	return self.nsView;
}

- (id<TUIBridgedScrollView>)ancestorScrollView; {
	if ([self conformsToProtocol:@protocol(TUIBridgedScrollView)])
		return (id)self;

	TUIView *superview = self.superview;
	if (superview)
		return superview.ancestorScrollView;

	return self.hostView.ancestorScrollView;
}

- (void)didMoveFromTUINSView:(TUINSView *)view; {
	[self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)willMoveToTUINSView:(TUINSView *)view; {
	[self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)viewHierarchyDidChange; {
	[self.subviews makeObjectsPerformSelector:_cmd];
}

@end

