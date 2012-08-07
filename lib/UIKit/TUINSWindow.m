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

#import "TUINSWindow.h"
#import "TUICGAdditions.h"
#import "TUINSView.h"
#import "TUINSView+Hyperfocus.h"

@interface NSView (TUIWindowAdditions)
@end
@implementation NSView (TUIWindowAdditions)

- (void)findViewsOfClass:(Class)cls addTo:(NSMutableArray *)array
{
	if([self isKindOfClass:cls])
		[array addObject:self];
	for(NSView *v in [self subviews])
		[v findViewsOfClass:cls addTo:array];
}

@end

@implementation NSWindow (TUIWindowAdditions)

- (NSArray *)TUINSViews
{
	NSMutableArray *array = [NSMutableArray array];
	[[self contentView] findViewsOfClass:[TUINSView class] addTo:array];
	return array;
}

- (void)setEverythingNeedsDisplay
{
	[[self contentView] setNeedsDisplay:YES];
	[[self TUINSViews] makeObjectsPerformSelector:@selector(setEverythingNeedsDisplay)];
}

NSInteger makeFirstResponderCount = 0;

- (BOOL)tui_containsObjectInResponderChain:(NSResponder *)r
{
	NSResponder *responder = [self firstResponder];
	do {
		if(r == responder)
			return YES;
	} while((responder = [responder nextResponder]));
	return NO;
}

- (NSInteger)futureMakeFirstResponderRequestToken
{
	return makeFirstResponderCount;
}

- (BOOL)tui_makeFirstResponder:(NSResponder *)aResponder
{
	++makeFirstResponderCount; // cool if it overflows
	if([aResponder respondsToSelector:@selector(initialFirstResponder)])
		aResponder = ((TUIResponder *)aResponder).initialFirstResponder;
	return [self makeFirstResponder:aResponder];
}

- (BOOL)makeFirstResponder:(NSResponder *)aResponder withFutureRequestToken:(NSInteger)token
{
	if(token == makeFirstResponderCount) {
		return [self tui_makeFirstResponder:aResponder];
	} else {
		return NO;
	}
}

- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder
{
	if(![self tui_containsObjectInResponderChain:responder])
		return [self tui_makeFirstResponder:responder];
	return NO;
}

- (BOOL)makeFirstResponderIfNotAlreadyInResponderChain:(NSResponder *)responder withFutureRequestToken:(NSInteger)token
{
	if(![self tui_containsObjectInResponderChain:responder])
		return [self makeFirstResponder:responder withFutureRequestToken:token];
	return NO;
}


@end


@interface TUINSWindowFrame : NSView
{
	@public
	TUINSWindow *w;
}
@end

@implementation TUINSWindowFrame

- (void)drawRect:(CGRect)r
{
	[w drawBackground:r];
}

@end


@implementation TUINSWindow

@synthesize nsView;
@synthesize altUINSViews;

+ (NSInteger)windowMask
{
	return NSBorderlessWindowMask;
}

- (CGFloat)toolbarHeight
{
	return 22;
}

- (BOOL)useCustomContentView
{
	return NO;
}

- (id)initWithContentRect:(CGRect)rect
{
	if((self = [super initWithContentRect:rect styleMask:[[self class] windowMask] backing:NSBackingStoreBuffered defer:NO]))
	{
		[self setCollectionBehavior:NSWindowCollectionBehaviorParticipatesInCycle | NSWindowCollectionBehaviorManaged];
		[self setAcceptsMouseMovedEvents:YES];

		CGRect b = [[self contentView] frame];

		if([self useCustomContentView]) {
			[self setOpaque:NO];
			[self setBackgroundColor:[NSColor clearColor]];
			[self setHasShadow:YES];
			
			TUINSWindowFrame *contentView = [[TUINSWindowFrame alloc] initWithFrame:b];
			contentView->w = self;
			[self setContentView:contentView];
		} else {
			[self setOpaque:YES];
            [self setHasShadow:YES];
		}

		b.size.height -= ([self toolbarHeight]-22);
		
		nsView = [[TUINSView alloc] initWithFrame:b];
		[nsView setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[[self contentView] addSubview:nsView];
		
		altUINSViews = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void)drawBackground:(CGRect)rect
{
	// overridden by subclasses
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	CGRect f = [self frame];
	CGContextSetRGBFillColor(ctx, 1, 1, 1, 1);
	CGContextFillRect(ctx, f);
}

- (void)becomeKeyWindow
{
	[super becomeKeyWindow];
	[self setEverythingNeedsDisplay];
}

- (void)resignKeyWindow
{
	[super resignKeyWindow];
	[nsView endHyperFocus:YES];
	[self setEverythingNeedsDisplay];
}

- (BOOL)canBecomeKeyWindow
{
	return YES;
}

@end

static NSScreen *ABScreenForProposedWindowRect(NSRect proposedRect)
{
	NSScreen *screen = [NSScreen mainScreen];
	
	NSPoint center = NSMakePoint(proposedRect.origin.x + proposedRect.size.width * 0.5, proposedRect.origin.y + proposedRect.size.height * 0.5);
	for(NSScreen *s in [NSScreen screens]) {
		NSRect r = [s visibleFrame];
		if(NSPointInRect(center, r))
			screen = s;
	}
	
	return screen;
}

NSRect ABClampProposedRectToScreen(NSRect proposedRect)
{
	NSScreen *screen = ABScreenForProposedWindowRect(proposedRect);
	NSRect screenRect = [screen visibleFrame];

	if(proposedRect.origin.y < screenRect.origin.y) {
		proposedRect.origin.y = screenRect.origin.y;
	}

	if(proposedRect.origin.y + proposedRect.size.height > screenRect.origin.y + screenRect.size.height) {
		proposedRect.origin.y = screenRect.origin.y + screenRect.size.height - proposedRect.size.height;
	}

	if(proposedRect.origin.x + proposedRect.size.width > screenRect.origin.x + screenRect.size.width) {
		proposedRect.origin.x = screenRect.origin.x + screenRect.size.width - proposedRect.size.width;
	}

	if(proposedRect.origin.x < screenRect.origin.x) {
		proposedRect.origin.x = screenRect.origin.x;
	}

	return proposedRect;
}
