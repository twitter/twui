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

#import "TUITooltipWindow.h"
#import "TUIAttributedString.h"
#import "TUICGAdditions.h"
#import "TUIStringDrawing.h"

#define TOOLTIP_HEIGHT 18
#define SWITCH_DELAY 0.2
#define FADE_OUT_SPEED 0.07

static TUIAttributedString *CurrentTooltipString = nil;
static NSTimer *FadeOutTimer = nil;

@interface TUITooltipWindowView : NSView
@end

@implementation TUITooltipWindowView

- (void)drawRect:(NSRect)r
{
	CGRect b = [self frame];
	b.origin = CGPointZero;
	
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	CGContextSaveGState(ctx);
	CGFloat _a[] = {1.0, 1.0, 198/255., 1.0};
	CGFloat _b[] = {1.0, 1.0, 158/255., 1.0};
	CGContextClipToRoundRect(ctx, b, 2);
	CGContextDrawLinearGradientBetweenPoints(ctx, CGPointMake(0, b.size.height), _a, CGPointMake(0, 0), _b);
	CGContextRestoreGState(ctx);
	
	[CurrentTooltipString ab_drawInRect:CGRectMake(0, -2, b.size.width, b.size.height)];
}

@end


@implementation TUITooltipWindow

+ (TUITooltipWindow *)sharedTooltipWindow
{
	static TUITooltipWindow *w = nil;
	if(!w) {
		NSRect r = NSMakeRect(0, 0, 10, TOOLTIP_HEIGHT);
		w = [[TUITooltipWindow alloc] initWithContentRect:r
												 styleMask:NSBorderlessWindowMask 
												   backing:NSBackingStoreBuffered
													 defer:NO];
		[w setLevel:NSPopUpMenuWindowLevel];
		[w setOpaque:NO];
		[w setBackgroundColor:[NSColor clearColor]];
		[w setHasShadow:YES];
		[w setIgnoresMouseEvents:YES];
		
		TUITooltipWindowView *v = [[TUITooltipWindowView alloc] initWithFrame:r];
		[v setAutoresizingMask:NSViewWidthSizable | NSViewHeightSizable];
		[w setContentView:v];
	}
	return w;
}

static BOOL ShowingTooltip = NO;

+ (CGRect)_tooltipRect
{
	CGFloat width = [CurrentTooltipString ab_size].width + 5;
	NSPoint p = [NSEvent mouseLocation];
	NSRect r = NSMakeRect(p.x - width*0.5 + 15, p.y - 37, width, TOOLTIP_HEIGHT);
	return r;
}

+ (void)_fixTooltipWindow
{
	TUITooltipWindow *tooltipWindow = [self sharedTooltipWindow];
	NSRect r = [tooltipWindow frame];
	if(r.origin.y < 50)
		r.origin.y += 37 + TOOLTIP_HEIGHT;
	[tooltipWindow setFrameOrigin:r.origin];
}

+ (void)_beginTooltip
{
	if([NSApp isHidden]) {
		// ignore
	} else {
		ShowingTooltip = YES;
		
		TUITooltipWindow *tooltipWindow = [self sharedTooltipWindow];
		
		[tooltipWindow setFrame:[self _tooltipRect] display:YES animate:NO];
		[self _fixTooltipWindow];
		[tooltipWindow orderFront:nil];
		[tooltipWindow setAlphaValue:0.93];
		
		[[[self sharedTooltipWindow] contentView] setNeedsDisplay:YES];
	}
}

+ (void)tick:(id)sender
{
	CGFloat a = [[self sharedTooltipWindow] alphaValue];
	a -= FADE_OUT_SPEED;
	if(a <= 0.0) {
		[self endTooltip];
	} else {
		[[self sharedTooltipWindow] setAlphaValue:a];
	}
}

+ (void)updateTooltip:(NSString *)s delay:(NSTimeInterval)delay
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_beginTooltip) object:nil];

	if(s) {
		if(FadeOutTimer || ShowingTooltip) {
			// quick switch
			[FadeOutTimer invalidate];
			FadeOutTimer = nil;
			[self performSelector:@selector(_beginTooltip) withObject:nil afterDelay:SWITCH_DELAY];
		} else {
			// show
			[self performSelector:@selector(_beginTooltip) withObject:nil afterDelay:delay];
		}
		
		CurrentTooltipString = [TUIAttributedString stringWithString:s];
		CurrentTooltipString.font = [NSFont fontWithName:@"HelveticaNeue" size:11];
		CurrentTooltipString.kerning = 0.2;
		[CurrentTooltipString setAlignment:TUITextAlignmentCenter lineBreakMode:TUILineBreakModeClip];
	} else {
		if(ShowingTooltip) {
			// fade out
			if(!FadeOutTimer) {
				FadeOutTimer = [NSTimer scheduledTimerWithTimeInterval:1/30. target:self selector:@selector(tick:) userInfo:nil repeats:YES];
			}
		} else {
			// nothing
		}
	}
}

+ (void)endTooltip
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(_beginTooltip) object:nil];
	[FadeOutTimer invalidate];
	FadeOutTimer = nil;
	[[self sharedTooltipWindow] orderOut:nil];
	ShowingTooltip = NO;
}

@end
