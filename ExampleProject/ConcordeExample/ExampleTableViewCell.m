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

#import "ExampleTableViewCell.h"

@implementation ExampleTableViewCell

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		textRenderer = [[TUITextRenderer alloc] init];
		
		/*
		 Add the text renderer to the view so events get routed to it properly.
		 Text selection, dictionary popup, etc should just work.
		 You can add more than one.
		 
		 The text renderer encapsulates an attributed string and a frame.
		 The attributed string in this case is set by setAttributedString:
		 which is configured by the table view delegate.  The frame needs to be 
		 set before it can be drawn, we do that in drawRect: below.
		 */
		self.textRenderers = [NSArray arrayWithObjects:textRenderer, nil];
	}
	return self;
}


- (NSAttributedString *)attributedString
{
	return textRenderer.attributedString;
}

- (void)setAttributedString:(NSAttributedString *)attributedString
{
	textRenderer.attributedString = attributedString;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect
{
	CGRect b = self.bounds;
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	
	if(self.selected) {
		// selected background
		CGContextSetRGBFillColor(ctx, .87, .87, .87, 1);
		CGContextFillRect(ctx, b);
	} else {
		// light gray background
		CGContextSetRGBFillColor(ctx, .97, .97, .97, 1);
		CGContextFillRect(ctx, b);
		
		// emboss
		CGContextSetRGBFillColor(ctx, 1, 1, 1, 0.9); // light at the top
		CGContextFillRect(ctx, CGRectMake(0, b.size.height-1, b.size.width, 1));
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 0.08); // dark at the bottom
		CGContextFillRect(ctx, CGRectMake(0, 0, b.size.width, 1));
	}
	
	// text
	CGRect textRect = CGRectOffset(b, 15, -15);
	textRenderer.frame = textRect; // set the frame so it knows where to draw itself
	[textRenderer draw];
	
}

@end
