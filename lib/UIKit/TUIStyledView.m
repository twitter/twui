//
//  TUIStyledView.m
//  TwUI
//
//  Created by Josh Abernathy on 5/31/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "TUIStyledView.h"
#import "TUICGAdditions.h"
#import "TUITextRenderer.h"

@implementation TUIStyledView

#pragma mark TUIView

- (void)drawRect:(CGRect)rect {
	[super drawRect:rect];
	
	CGContextRef context = TUIGraphicsGetCurrentContext();
	[self.backgroundColor set];
	CGContextFillRect(context, self.bounds);
	
	if(self.strokeColor != nil) {
		[self.strokeColor set];
		CGContextStrokeRectWithWidth(context, self.bounds, self.strokeWidth);
	}
	
	for(TUITextRenderer *renderer in self.textRenderers) {
		[renderer draw];
	}
}


#pragma mark API

@synthesize strokeColor;
@synthesize strokeWidth;

@end
