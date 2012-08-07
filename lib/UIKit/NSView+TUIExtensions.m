//
//	NSView+TUIExtensions.m
//	TwUI
//
//	Created by Justin Spahr-Summers on 17.07.12.
//
//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.
//

#import "NSView+TUIExtensions.h"
#import "TUINSView.h"
#import "TUIBridgedScrollView.h"
#import <objc/runtime.h>

@implementation NSView (TUIExtensions)

// NSView already implements a layer property
@dynamic layer;

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

- (void)setHostView:(id<TUIHostView>)hostView {
	objc_setAssociatedObject(self, @selector(hostView), hostView, OBJC_ASSOCIATION_ASSIGN);
}

- (void)ancestorDidLayout; {
	[self.subviews makeObjectsPerformSelector:_cmd];
}

- (TUINSView *)ancestorTUINSView; {
	NSView *view = self;

	do {
		if ([view isKindOfClass:[TUINSView class]])
			return (id)view;

		view = view.superview;
	} while (view);
	
	return nil;
}

- (id<TUIBridgedScrollView>)ancestorScrollView {
	if ([self conformsToProtocol:@protocol(TUIBridgedScrollView)])
		return (id)self;

	return self.immediateParentView.ancestorScrollView;
}

#pragma mark Geometry

- (CGPoint)convertFromWindowPoint:(CGPoint)point; {
	NSPoint windowPoint = NSPointFromCGPoint(point);
	NSPoint selfPoint = [self convertPoint:windowPoint fromView:nil];
	return NSPointToCGPoint(selfPoint);
}

- (CGPoint)convertToWindowPoint:(CGPoint)point; {
	NSPoint windowPoint = NSPointFromCGPoint(point);
	NSPoint selfPoint = [self convertPoint:windowPoint toView:nil];
	return NSPointToCGPoint(selfPoint);
}

- (CGRect)convertFromWindowRect:(CGRect)rect; {
	NSRect windowRect = NSRectFromCGRect(rect);
	NSRect selfRect = [self convertRect:windowRect fromView:nil];
	return NSRectToCGRect(selfRect);
}

- (CGRect)convertToWindowRect:(CGRect)rect; {
	NSRect windowRect = NSRectFromCGRect(rect);
	NSRect selfRect = [self convertRect:windowRect toView:nil];
	return NSRectToCGRect(selfRect);
}

#pragma mark Hit testing

- (id<TUIBridgedView>)descendantViewAtPoint:(NSPoint)point {
	NSPoint superviewPoint = [self convertPoint:point toView:self.superview];
	id hitView = [self hitTest:superviewPoint];

	if ([hitView isKindOfClass:[TUINSView class]]) {
		NSPoint descendantPoint = [self convertPoint:point toView:hitView];
		return [hitView descendantViewAtPoint:descendantPoint];
	}

	return hitView;
}

- (BOOL)pointInside:(CGPoint)point {
	NSPoint superviewPoint = [self convertPoint:point toView:self.superview];
	return [self hitTest:superviewPoint] ? YES : NO;
}

#pragma mark View hierarchy

- (void)willMoveToTUINSView:(TUINSView *)view; {
	[self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)didMoveFromTUINSView:(TUINSView *)view; {
	[self.subviews makeObjectsPerformSelector:_cmd withObject:view];
}

- (void)viewHierarchyDidChange {
	[self.subviews makeObjectsPerformSelector:_cmd];
}

@end
