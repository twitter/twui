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

@interface TUINSView ()
- (void)windowDidResignKey:(NSNotification *)notification;
- (void)windowDidBecomeKey:(NSNotification *)notification;
- (void)screenProfileOrBackingPropertiesDidChange:(NSNotification *)notification;
@end


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
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:nil];
	[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:nil];
	
	[rootView removeFromSuperview];
    rootView.nsView = nil;
	
	rootView = nil;
	_hoverView = nil;
	_trackingView = nil;
	_trackingArea = nil;
	
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

- (void)tui_setOpaque:(BOOL)o
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
	rootView = v;
	rootView.nsView = self;
	
	[rootView setNextResponder:self];
	
	CGSize s = [self frame].size;
	v.frame = CGRectMake(0, 0, s.width, s.height);
	
	[self setWantsLayer:YES];
	CALayer *layer = [self layer];
	[layer setDelegate:self];
	[layer addSublayer:rootView.layer];
	
	[self _updateLayerScaleFactor];
}

- (void)setNextResponder:(NSResponder *)r
{
	NSResponder *nextResponder = [self nextResponder];
	if([nextResponder isKindOfClass:[NSViewController class]]) {
		// keep view controller in chain
		[nextResponder setNextResponder:r];
	} else {
		[super setNextResponder:r];
	}
}

- (void)viewWillMoveToWindow:(NSWindow *)newWindow {
	if(self.window != nil) {
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidBecomeKeyNotification object:self.window];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidResignKeyNotification object:self.window];
		[[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowDidChangeScreenProfileNotification object:self.window];
	}
	
	if(newWindow != nil && rootView.layer.superlayer != [self layer]) {
		rootView.layer.frame = self.layer.bounds;
		[[self layer] addSublayer:rootView.layer];
	}
	
	[self.rootView willMoveToWindow:(TUINSWindow *) newWindow];
	
	if(newWindow == nil) {
		[rootView removeFromSuperview];
	}
}

- (void)viewDidMoveToWindow
{
	[self _updateLayerScaleFactor];
	
	[self.rootView didMoveToWindow];
	
	if(self.window != nil) {
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:self.window];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:self.window];
		
		// make sure the window will post NSWindowDidChangeScreenProfileNotification
		[self.window setDisplaysWhenScreenProfileChanges:YES];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(screenProfileOrBackingPropertiesDidChange:) name:NSWindowDidChangeScreenProfileNotification object:self.window];
	}
}

- (void)_updateLayerScaleFactor {
	if([self window] != nil) {
		CGFloat scale = 1.0f;
		if([[self window] respondsToSelector:@selector(backingScaleFactor)]) {
			scale = [[self window] backingScaleFactor];
		}
		
		if([self.layer respondsToSelector:@selector(setContentsScale:)]) {
			if(fabs(self.layer.contentsScale - scale) > 0.1f) {
				self.layer.contentsScale = scale;
			}
		}
		
		[self.rootView _updateLayerScaleFactor];
	}
}

- (void)screenProfileOrBackingPropertiesDidChange:(NSNotification *)notification
{
	[self _updateLayerScaleFactor];
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

- (void)windowDidResignKey:(NSNotification *)notification
{
	[TUITooltipWindow endTooltip];
	
	if(![self isWindowKey]) {
		[self.rootView windowDidResignKey];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)notification
{
	[self.rootView windowDidBecomeKey];
}

- (BOOL)isWindowKey
{
	if([self.window isKeyWindow]) return YES;
	
	NSWindow *keyWindow = [NSApp keyWindow];
	if(keyWindow == nil) return NO;
	
	return keyWindow == [self.window attachedSheet];
}

- (void)viewWillMoveToSuperview:(NSView *)newSuperview
{
	[super viewWillMoveToSuperview:newSuperview];
	
	if(newSuperview == nil) {
		[TUITooltipWindow endTooltip];
	}
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
		_hoverView = _newHoverView;
		
		if([[self window] isKeyWindow]) {
			[TUITooltipWindow updateTooltip:_hoverView.toolTip delay:_hoverView.toolTipDelay];
		} else {
			[TUITooltipWindow updateTooltip:nil delay:_hoverView.toolTipDelay];
		}
	} else {
		[_hoverView mouseMoved:event];
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
		;
		_trackingView = [self viewForEvent:event];
		[_trackingView mouseDown:event];
	}
	
	[TUITooltipWindow endTooltip];
}

- (void)mouseUp:(NSEvent *)event
{
	TUIView *lastTrackingView = _trackingView;

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

-(void)mouseEntered:(NSEvent *)event {
  [self _updateHoverViewWithEvent:event];
}

-(void)mouseExited:(NSEvent *)event {
  [self _updateHoverViewWithEvent:event];
}

- (void)rightMouseDown:(NSEvent *)event
{
	_trackingView = [self viewForEvent:event];
	[_trackingView rightMouseDown:event];
	[TUITooltipWindow endTooltip];
	[super rightMouseDown:event]; // we need to send this up the responder chain so that -menuForEvent: will get called for two-finger taps
}

- (void)rightMouseUp:(NSEvent *)event
{
	TUIView *lastTrackingView = _trackingView;
	
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

- (void)keyDown:(NSEvent *)event
{
	BOOL consumed = NO;
	// TUIView uses -performKeyAction: in -keyDown: to do its key equivalents. If none of our TUIViews consumed the key down as a key action, we want to give our view controller a chance to handle the key down as a key equivalent.
	if([[self nextResponder] isKindOfClass:[NSViewController class]]) {
		consumed = [[self nextResponder] performKeyEquivalent:event];
	}
	
	if(!consumed) {
		[super keyDown:event];
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
