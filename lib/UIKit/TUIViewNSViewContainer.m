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

//	Portions of this code were taken from Velvet,
//	which is copyright (c) 2012 Bitswift, Inc.
//	See LICENSE.txt for more information.

#import "TUIViewNSViewContainer.h"
#import "CATransaction+TUIExtensions.h"
#import "NSView+TUIExtensions.h"
#import "TUINSView.h"
#import "TUINSView+Private.h"
#import "TUIViewNSViewContainer+Private.h"
#import <QuartzCore/QuartzCore.h>

@interface TUIViewNSViewContainer () {
	/**
	 * A count indicating how many nested calls to <startRenderingContainedView>
	 * are in effect.
	 */
	NSUInteger _renderingContainedViewCount;
}

- (void)synchronizeNSViewGeometry;
- (void)startRenderingContainedView;
- (void)stopRenderingContainedView;
@end

@implementation TUIViewNSViewContainer

#pragma mark Properties

@dynamic hostView;
@synthesize rootView = _rootView;

- (void)setRootView:(NSView *)view {
	NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

	// remove any existing guest view
	[_rootView removeFromSuperview];
	_rootView.hostView = nil;

	_rootView = view;

	TUINSView *nsView = self.ancestorTUINSView;

	// and set up our new view
	if (_rootView) {
		// set up layer-backing on the view
		[_rootView setWantsLayer:YES];
		[_rootView setNeedsDisplay:YES];

		[nsView.appKitHostView addSubview:_rootView];
		_rootView.hostView = self;

		[nsView recalculateNSViewOrdering];

		_rootView.nextResponder = self;
		[self synchronizeNSViewGeometry];
	} else {
		// remove the old view from the TUINSView's clipping path
		[nsView recalculateNSViewClipping];
	}
}

- (CGRect)NSViewFrame; {
	// we use 'self' and 'bounds' here instead of the superview and frame
	// because the superview may be a TUIScrollView, and accessing it directly
	// will skip over the CAScrollLayer that's in the hierarchy
	return [self convertRect:self.bounds toView:self.ancestorTUINSView.rootView];
}

- (void)setFrame:(CGRect)frame {
	[super setFrame:frame];
	[self synchronizeNSViewGeometry];
}

- (void)setBounds:(CGRect)bounds {
	[super setBounds:bounds];
	[self synchronizeNSViewGeometry];
}

- (void)setCenter:(CGPoint)center {
	[super setCenter:center];
	[self synchronizeNSViewGeometry];
}

- (void)didAddSubview:(TUIView *)subview {
	NSAssert(NO, @"%@ must be a leaf in the TwUI hierarchy, should not have added subview: %@", self, subview);
	[super didAddSubview:subview];
}

- (BOOL)isRenderingContainedView {
	return _renderingContainedViewCount > 0;
}

#pragma mark Lifecycle

- (id)initWithFrame:(CGRect)frame {
	self = [super initWithFrame:frame];
	if (!self)
		return nil;

	self.layer.masksToBounds = NO;

	// prevents the layer from displaying until we need to render our contained
	// view
	self.contentMode = TUIViewContentModeScaleToFill;
	return self;
}

- (id)initWithNSView:(NSView *)view; {
	NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

	self = [self initWithFrame:view.frame];
	if (!self)
		return nil;

	self.rootView = view;
	return self;
}

- (void)dealloc {
	self.rootView.hostView = nil;
}

#pragma mark Geometry

- (void)synchronizeNSViewGeometry; {
	NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

	if (!self.nsWindow) {
		// can't do this without being in a window
		return;
	}

	NSAssert(self.ancestorTUINSView, @"%@ should be in an TUINSView if it has a window", self);

	CGRect frame = self.NSViewFrame;
	self.rootView.frame = frame;

	[self.ancestorTUINSView recalculateNSViewClipping];
}

#pragma mark Drawing

- (void)drawRect:(CGRect)rect {
	if (!self.renderingContainedView) {
		return;
	}

	CGContextRef context = [NSGraphicsContext currentContext].graphicsPort;
	CGContextSaveGState(context);

	if ([self.rootView isFlipped]) {
		CGContextTranslateCTM(context, 0, self.bounds.size.height);
		CGContextScaleCTM(context, 1, -1);
	}

	[self.rootView.layer renderInContext:context];
	CGContextRestoreGState(context);
}

- (void)startRenderingContainedView; {
	if (_renderingContainedViewCount++ == 0) {
		[CATransaction tui_performWithDisabledActions:^{
			[self synchronizeNSViewGeometry];
			[self.rootView displayIfNeeded];
			[self.layer display];
		}];
	}
}

- (void)stopRenderingContainedView; {
	NSAssert(_renderingContainedViewCount > 0, @"Mismatched call to %s", __func__);

	if (--_renderingContainedViewCount == 0) {
		self.layer.contents = nil;
	}
}

#pragma mark View hierarchy

- (void)ancestorDidLayout; {
	[self synchronizeNSViewGeometry];
	[super ancestorDidLayout];
}

- (void)willMoveToTUINSView:(TUINSView *)view; {
	[super willMoveToTUINSView:view];
	[self.rootView willMoveToTUINSView:view];

	[CATransaction tui_performWithDisabledActions:^{
		[self.rootView removeFromSuperview];
	}];
}

- (void)didMoveFromTUINSView:(TUINSView *)view; {
	[super didMoveFromTUINSView:view];

	TUINSView *newView = self.ancestorTUINSView;
	if (newView) {
		[CATransaction tui_performWithDisabledActions:^{
			[newView.appKitHostView addSubview:self.rootView];
		}];

		self.rootView.nextResponder = self;
	}

	[self.rootView didMoveFromTUINSView:view];
}

- (void)viewHierarchyDidChange {
	[super viewHierarchyDidChange];

	// verify that TUIViewNSViewContainers are on top of other subviews
	#if DEBUG
	NSArray *siblings = self.superview.subviews;
	__block BOOL foundTUIView = NO;

	[siblings enumerateObjectsWithOptions:NSEnumerationReverse usingBlock:^(TUIView *view, NSUInteger index, BOOL *stop){
		if ([view isKindOfClass:[TUIViewNSViewContainer class]]) {
			NSAssert2(!foundTUIView, @"%@ must be on top of its sibling TUIViews: %@", view, siblings);
		} else {
			foundTUIView = YES;
		}
	}];
	#endif

	[self.ancestorTUINSView recalculateNSViewOrdering];
	[self synchronizeNSViewGeometry];
	[self.rootView viewHierarchyDidChange];
}

- (id<TUIBridgedView>)descendantViewAtPoint:(CGPoint)point {
	if (![self pointInside:point])
		return nil;

	CGPoint NSViewPoint = [self.rootView convertFromWindowPoint:[self convertToWindowPoint:point]];

	// never return 'self', since we don't want to catch clicks that didn't
	// directly hit the NSView
	return [self.rootView descendantViewAtPoint:NSViewPoint];
}

#pragma mark Layout

- (void)layoutSubviews {
	[super layoutSubviews];
	[self synchronizeNSViewGeometry];
}

- (CGSize)sizeThatFits:(CGSize)constraint {
	NSAssert1([NSThread isMainThread], @"%s should only be called from the main thread", __func__);

	id view = self.rootView;
	NSSize cellSize = NSMakeSize(10000, 10000);

	NSCell *cell = nil;

	if ([view respondsToSelector:@selector(cell)]) {
		cell = [view cell];
	}

	if ([cell respondsToSelector:@selector(cellSize)]) {
		cellSize = [cell cellSize];
	}

	// if we don't have a cell, or it didn't give us a true size
	if (CGSizeEqualToSize(cellSize, CGSizeMake(10000, 10000))) {
		return [super sizeThatFits:constraint];
	}

	return cellSize;
}

- (void)sizeToFit {
	if ([self.rootView respondsToSelector:@selector(sizeToFit)]) {
		[self.rootView performSelector:@selector(sizeToFit)];

		self.bounds = self.rootView.bounds;
	} else {
		[super sizeToFit];
	}
}

#pragma mark NSObject overrides

- (NSString *)description {
	return [NSString stringWithFormat:@"<%@ %p> frame = %@, NSView = %@ %@", [self class], self, NSStringFromRect(self.frame), self.rootView, NSStringFromRect(self.rootView.frame)];
}

@end
