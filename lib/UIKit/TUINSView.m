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

#import "TUINSView.h"
#import "TUIView+Private.h"
#import "TUITextRenderer+Event.h"
#import "TUITooltipWindow.h"
#import <CoreFoundation/CoreFoundation.h>

@implementation TUINSView

@synthesize rootView;

- (id)initWithFrame:(NSRect)frameRect
{
	if((self = [super initWithFrame:frameRect])) {
		opaque = YES;
	}
	return self;
}

- (void)dealloc
{
	[rootView release];
	rootView = nil;
	[_hoverView release];
	_hoverView = nil;
	[_trackingView release];
	_trackingView = nil;
	[_trackingArea release];
	_trackingArea = nil;
	[_hyperCompletion release];
	
	[super dealloc];
}

- (void)resetCursorRects
{
	NSRect f = [self frame];
	f.origin = NSZeroPoint;
	[self addCursorRect:f cursor:[NSCursor arrowCursor]];
}
		 
- (void)ab_setIsOpaque:(BOOL)o
{
	opaque = o;
}

- (BOOL)isOpaque
{
	return opaque;
}

- (BOOL)mouseDownCanMoveWindow
{
	return NO;
}

- (void)updateTrackingAreas
{
	[super updateTrackingAreas];
	
	if(_trackingArea) {
		[self removeTrackingArea:_trackingArea];
		[_trackingArea release];
	}
	
	NSRect r = [self frame];
	r.origin = NSZeroPoint;
	_trackingArea = [[NSTrackingArea alloc] initWithRect:r options:NSTrackingMouseEnteredAndExited | NSTrackingMouseMoved | NSTrackingActiveAlways owner:self userInfo:nil];
	[self addTrackingArea:_trackingArea];
}

- (void)viewWillStartLiveResize
{
	[super viewWillStartLiveResize];
	inLiveResize = YES;
	[rootView viewWillStartLiveResize];
}

- (BOOL)inLiveResize
{
	return inLiveResize;
}

- (void)viewDidEndLiveResize
{
	[super viewDidEndLiveResize];
	inLiveResize = NO;
	[rootView viewDidEndLiveResize]; // will send to all subviews
	
	if([[self window] respondsToSelector:@selector(ensureWindowRectIsOnScreen)])
		[[self window] performSelector:@selector(ensureWindowRectIsOnScreen)];
}

- (void)setRootView:(TUIView *)v
{
	v.autoresizingMask = TUIViewAutoresizingFlexibleSize;

	rootView.nsView = nil;
	[v retain];
	[rootView release];
	rootView = v;
	rootView.nsView = self;
	
	[rootView setNextResponder:self];
	
	CGSize s = [self frame].size;
	v.frame = CGRectMake(0, 0, s.width, s.height);
	
	[self setWantsLayer:YES];
	CALayer *layer = [self layer];
	[layer setDelegate:self];
	[layer addSublayer:rootView.layer];
	if(Screen_Scale != 1.0) {
		layer.anchorPoint = CGPointMake(0, 0);
		layer.transform = CATransform3DMakeScale(Screen_Scale, Screen_Scale, Screen_Scale);
	}
}

- (void)viewDidMoveToWindow
{
	if(self.window != nil && rootView.layer.superlayer != [self layer]) {
		[[self layer] addSublayer:rootView.layer];
	}
}

- (TUIView *)viewForLocalPoint:(NSPoint)p
{
	return [rootView hitTest:p withEvent:nil];
}

- (NSPoint)localPointForLocationInWindow:(NSPoint)locationInWindow
{
	return [self convertPoint:locationInWindow fromView:nil];
}

- (TUIView *)viewForLocationInWindow:(NSPoint)locationInWindow
{
	return [self viewForLocalPoint:[self localPointForLocationInWindow:locationInWindow]];
}

- (TUIView *)viewForEvent:(NSEvent *)event
{
	return [self viewForLocationInWindow:[event locationInWindow]];
}

- (void)_updateHoverView:(TUIView *)_newHoverView withEvent:(NSEvent *)event
{
	if(_hyperFocusView) {
		if(![_newHoverView isDescendantOfView:_hyperFocusView]) {
			_newHoverView = nil; // don't allow hover
		}
	}
	
	if(_newHoverView != _hoverView) {
		[_newHoverView mouseEntered:event];
		[_hoverView mouseExited:event];
		[_hoverView release];
		_hoverView = [_newHoverView retain];
		
		if([[self window] isKeyWindow]) {
			[TUITooltipWindow updateTooltip:_hoverView.toolTip delay:_hoverView.toolTipDelay];
		} else {
			[TUITooltipWindow updateTooltip:nil delay:_hoverView.toolTipDelay];
		}
	}
}

- (void)_updateHoverViewWithEvent:(NSEvent *)event
{
	TUIView *_newHoverView = [self viewForEvent:event];
	
	if(![[self window] isKeyWindow]) {
		if(![_newHoverView acceptsFirstMouse:event]) {
			// in background, don't do hover for things that don't accept first mouse
			_newHoverView = nil;
		}
	}
	
	[self _updateHoverView:_newHoverView withEvent:event];
}

- (void)invalidateHover
{
	[self _updateHoverView:nil withEvent:nil];
}

- (void)invalidateHoverForView:(TUIView *)v
{
	if([_hoverView isDescendantOfView:v]) {
		[self invalidateHover];
	}
}

- (void)mouseDown:(NSEvent *)event
{
	if(_hyperFocusView) {
		TUIView *v = [self viewForEvent:event];
		if([v isDescendantOfView:_hyperFocusView]) {
			// activate it normally
			[self endHyperFocus:NO]; // not cancelled
			goto normal;
		} else {
			// dismiss hover, don't click anything
			[self endHyperFocus:YES];
		}
	} else {
		// normal case
	normal:
		[_trackingView release];
		_trackingView = [[self viewForEvent:event] retain];
		[_trackingView mouseDown:event];
	}
	
	[TUITooltipWindow endTooltip];
}

- (void)mouseUp:(NSEvent *)event
{
	TUIView *lastTrackingView = [[_trackingView retain] autorelease];

	[_trackingView release];
	_trackingView = nil;

	[lastTrackingView mouseUp:event]; // after _trackingView set to nil, will call mouseUp:fromSubview:
	
	[self _updateHoverViewWithEvent:event];
}

- (void)mouseDragged:(NSEvent *)event
{
	[_trackingView mouseDragged:event];
}

- (void)mouseMoved:(NSEvent *)event
{
	[self _updateHoverViewWithEvent:event];
}

- (void)rightMouseDown:(NSEvent *)event
{
	[_trackingView release];
	_trackingView = [[self viewForEvent:event] retain];
	[_trackingView rightMouseDown:event];
	[TUITooltipWindow endTooltip];
	[super rightMouseDown:event]; // we need to send this up the responder chain so that -menuForEvent: will get called for two-finger taps
}

- (void)rightMouseUp:(NSEvent *)event
{
	TUIView *lastTrackingView = [[_trackingView retain] autorelease];
	
	[_trackingView release];
	_trackingView = nil;
	
	[lastTrackingView rightMouseUp:event]; // after _trackingView set to nil, will call mouseUp:fromSubview:
}

- (void)scrollWheel:(NSEvent *)event
{
	[[self viewForEvent:event] scrollWheel:event];
	[self _updateHoverView:nil withEvent:event]; // don't pop in while scrolling
}

- (void)beginGestureWithEvent:(NSEvent *)event
{
	[[self viewForEvent:event] beginGestureWithEvent:event];
}

- (void)endGestureWithEvent:(NSEvent *)event
{
	[[self viewForEvent:event] endGestureWithEvent:event];
}

- (void)magnifyWithEvent:(NSEvent *)event
{
	if(!deliveringEvent) {
		deliveringEvent = YES;
		[[self viewForEvent:event] magnifyWithEvent:event];	
		deliveringEvent = NO;
	}
}

- (void)rotateWithEvent:(NSEvent *)event
{
	if(!deliveringEvent) {
		deliveringEvent = YES;
		[[self viewForEvent:event] rotateWithEvent:event];
		deliveringEvent = NO;
	}
}

- (void)swipeWithEvent:(NSEvent *)event
{
	if(!deliveringEvent) {
		deliveringEvent = YES;
		[[self viewForEvent:event] swipeWithEvent:event];
		deliveringEvent = NO;
	}
}

- (BOOL)performKeyEquivalent:(NSEvent *)event
{
	return [rootView performKeyEquivalent:event];
}

- (void)setEverythingNeedsDisplay
{
	[rootView setEverythingNeedsDisplay];
}

- (BOOL)isTrackingSubviewOfView:(TUIView *)v
{
	return [_trackingView isDescendantOfView:v];
}

- (BOOL)isHoveringSubviewOfView:(TUIView *)v
{
	return [_hoverView isDescendantOfView:v];
}

- (BOOL)isHoveringView:(TUIView *)v
{
	return _hoverView == v;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return [[self viewForEvent:event] acceptsFirstMouse:event];
}

/* http://developer.apple.com/Mac/library/documentation/Cocoa/Conceptual/MenuList/Articles/EnablingMenuItems.html
 If the menu item’s target is not set and the NSMenu object is a contextual menu, NSMenu goes through the same steps as before but the search order for the responder chain is different:
 - The responder chain for the window in which the view that triggered the context menu resides, starting with the view.
 - The window itself.
 - The window’s delegate.
 - The NSApplication object.
 - The NSApplication object’s delegate.
 */

- (NSResponder *)firstResponderForSelector:(SEL)action
{
	if(!action)
		return nil;
	
	NSResponder *f = [[self window] firstResponder];
//	NSLog(@"starting search at %@", f);
	do {
		if([f respondsToSelector:action])
			return f;
	} while((f = [f nextResponder]));
	
	return nil;
}

- (void)_patchMenu:(NSMenu *)menu
{
	for(NSMenuItem *item in [menu itemArray]) {
		if(![item target]) {
			// would normally travel the responder chain starting too high up, patch it to target what it would target if it hit the true responder chain
			[item setTarget:[self firstResponderForSelector:[item action]]];
		}
		
		if([item submenu])
			[self _patchMenu:[item submenu]]; // recurse
	}
}

// the problem is for context menus the responder chain search starts with the NSView... we want it to start deeper, so we can patch up targets of a copy of the menu here
- (NSMenu *)menuWithPatchedItems:(NSMenu *)menu
{
	NSData *d = [NSKeyedArchiver archivedDataWithRootObject:menu]; // this is bad - doesn't persist 'target'?
	menu = [NSKeyedUnarchiver unarchiveObjectWithData:d];
	
	[self _patchMenu:menu];
	
	return menu;
}

- (NSMenu *)menuForEvent:(NSEvent *)event
{
	TUIView *v = [self viewForEvent:event];
	do {
		NSMenu *m = [v menuForEvent:event];
		if(m)
			return m; // not patched
		v = v.superview;
	} while(v);
	return nil;
}

#define ENABLE_NSTEXT_INPUT_CLIENT
#import "TUINSView+NSTextInputClient.m"
#undef ENABLE_NSTEXT_INPUT_CLIENT

@end
