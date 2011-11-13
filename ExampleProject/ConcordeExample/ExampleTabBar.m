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

#import "ExampleTabBar.h"

@interface ExampleTab : TUIView
@end
@implementation ExampleTab

- (ExampleTabBar *)tabBar
{
	return (ExampleTabBar *)self.superview;
}

- (void)mouseDown:(NSEvent *)event
{
	[super mouseDown:event]; // always call super when overriding mouseXXX: methods - lots of plumbing happens in TUIView
	[self setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)event
{
	[super mouseUp:event];
	
	// rather than a simple -setNeedsDisplay, let's fade it back out
	[TUIView animateWithDuration:0.5 animations:^{
		[self redraw]; // -redraw forces a .contents update immediately based on drawRect, and it happens inside an animation block, so CoreAnimation gives us a cross-fade for free
	}];
	
	if([self eventInside:event]) { // only perform the action if the mouse up happened inside our bounds - ignores mouse down, drag-out, mouse up
		[[self tabBar].delegate tabBar:[self tabBar] didSelectTab:self.tag];
	}
}

@end

@implementation ExampleTabBar

@synthesize delegate;
@synthesize tabViews;

- (id)initWithNumberOfTabs:(NSInteger)nTabs
{
	if((self = [super initWithFrame:CGRectZero])) {
		NSMutableArray *_tabViews = [NSMutableArray arrayWithCapacity:nTabs];
		for(int i = 0; i < nTabs; ++i) {
			ExampleTab *t = [[ExampleTab alloc] initWithFrame:CGRectZero];
			t.tag = i;
			t.layout = ^(TUIView *v) { // the layout of an individual tab is a function of the superview bounds, the number of tabs, and the current tab index
				CGRect b = v.superview.bounds; // reference the passed-in 'v' rather than 't' to avoid a retain cycle
				float width = b.size.width / nTabs;
				float x = i * width;
				return CGRectMake(roundf(x), 0, roundf(width), b.size.height);
			};
			[self addSubview:t];
			[_tabViews addObject:t];
		}
		
		tabViews = [[NSArray alloc] initWithArray:_tabViews];
	}
	return self;
}


- (void)drawRect:(CGRect)rect
{
	// draw tab bar background
	
	CGRect b = self.bounds;
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	// gray gradient
	CGFloat colorA[] = { 0.85, 0.85, 0.85, 1.0 };
	CGFloat colorB[] = { 0.71, 0.71, 0.71, 1.0 };
	CGContextDrawLinearGradientBetweenPoints(ctx, CGPointMake(0, b.size.height), colorA, CGPointMake(0, 0), colorB);
	
	// top emboss
	CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.5);
	CGContextFillRect(ctx, CGRectMake(0, b.size.height-2, b.size.width, 1));
	CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.3);
	CGContextFillRect(ctx, CGRectMake(0, b.size.height-1, b.size.width, 1));
}

@end
