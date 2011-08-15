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

#import "TUIImage.h"
#import "TUIButton.h"
#import "TUILabel.h"
#import "TUINSView.h"
#import "TUIControl+Private.h"

@interface TUIButton ()

- (void)_update;

@end

@implementation TUIButton

@synthesize popUpMenu;

- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame]))
	{
		_contentLookup = [[NSMutableDictionary alloc] init];
		self.opaque = NO; // won't matter unless image is set
		_buttonFlags.buttonType = TUIButtonTypeCustom;
		_buttonFlags.dimsInBackground = 1;
		_buttonFlags.firstDraw = 1;
	}
	return self;
}

- (void)dealloc
{
	[_contentLookup release];
	[_titleView release];
	[popUpMenu release];
	[super dealloc];
}

+ (id)button
{
	return [self buttonWithType:TUIButtonTypeCustom];
}

+ (id)buttonWithType:(TUIButtonType)buttonType
{
	TUIButton *b = [[self alloc] initWithFrame:CGRectZero];
	return [b autorelease];
}

- (BOOL)acceptsFirstResponder
{
	return NO;
}

- (void)setImageEdgeInsets:(TUIEdgeInsets)i
{
	_imageEdgeInsets = i;
}

- (TUIEdgeInsets)imageEdgeInsets
{
	return _imageEdgeInsets;
}

- (void)setTitleEdgeInsets:(TUIEdgeInsets)i
{
	_titleEdgeInsets = i;
}

- (TUIEdgeInsets)titleEdgeInsets
{
	return _titleEdgeInsets;
}

- (TUIButtonType)buttonType
{
	return _buttonFlags.buttonType;
}

- (TUILabel *)titleLabel
{
	if(!_titleView) {
		_titleView = [[TUILabel alloc] initWithFrame:CGRectZero];
		_titleView.userInteractionEnabled = NO;
		_titleView.backgroundColor = [TUIColor clearColor];
		_titleView.hidden = YES; // we'll be drawing it ourselves
		[self addSubview:_titleView];
	}
	return _titleView;
}

- (TUIImageView *)imageView
{
	if(!_imageView) {
		_imageView = [[TUIImageView alloc] initWithFrame:CGRectZero];
		_imageView.backgroundColor = [TUIColor clearColor];
		_imageView.hidden = YES;
	}
	return _imageView;
}

- (BOOL)dimsInBackground
{
	return _buttonFlags.dimsInBackground;
}

- (void)setDimsInBackground:(BOOL)b
{
	_buttonFlags.dimsInBackground = b;
}

- (CGRect)backgroundRectForBounds:(CGRect)bounds
{
	return bounds;
}

- (CGRect)contentRectForBounds:(CGRect)bounds
{
	return bounds;
}

- (CGRect)titleRectForContentRect:(CGRect)contentRect
{
	return contentRect;
}

- (CGRect)imageRectForContentRect:(CGRect)contentRect
{
	return contentRect;
}

static CGRect ButtonRectRoundOrigin(CGRect f)
{
	f.origin.x = roundf(f.origin.x);
	f.origin.y = roundf(f.origin.y);
	return f;
}

static CGRect ButtonRectCenteredInRect(CGRect a, CGRect b)
{
	CGRect r;
	r.size = a.size;
	r.origin.x = b.origin.x + (b.size.width - a.size.width) * 0.5;
	r.origin.y = b.origin.y + (b.size.height - a.size.height) * 0.5;
	return r;
}


- (void)drawRect:(CGRect)r
{
	if(_buttonFlags.firstDraw) {
		[self _update];
		_buttonFlags.firstDraw = 0;
	}
	
	CGRect bounds = self.bounds;

	BOOL key = [self.nsWindow isKeyWindow];
	BOOL down = self.state == TUIControlStateHighlighted;
	CGFloat alpha = down?0.7:1.0;
	if(_buttonFlags.dimsInBackground)
		alpha = key?alpha:0.5;
	
	TUIImage *backgroundImage = self.currentBackgroundImage;
	TUIImage *image = self.currentImage;
	
	[backgroundImage drawInRect:[self backgroundRectForBounds:bounds] blendMode:kCGBlendModeNormal alpha:1.0];
	
	if(image) {
		CGRect imageRect;
		if(image.leftCapWidth || image.topCapHeight) {
			// stretchable
			imageRect = self.bounds;
		} else {
			// normal centered + insets
			imageRect.origin = CGPointZero;
			imageRect.size = [image size];
			CGRect b = self.bounds;
			b.origin.x += _imageEdgeInsets.left;
			b.origin.y += _imageEdgeInsets.bottom;
			b.size.width -= _imageEdgeInsets.left + _imageEdgeInsets.right;
			b.size.height -= _imageEdgeInsets.bottom + _imageEdgeInsets.top;
			imageRect = ButtonRectRoundOrigin(ButtonRectCenteredInRect(imageRect, b));
		}
		[image drawInRect:imageRect blendMode:kCGBlendModeNormal alpha:alpha];
	}
	
	CGContextRef ctx = TUIGraphicsGetCurrentContext();
	CGContextSaveGState(ctx);
	CGContextTranslateCTM(ctx, _titleEdgeInsets.left, _titleEdgeInsets.bottom);
	if(!key)
		CGContextSetAlpha(ctx, 0.5);
	CGRect titleFrame = self.bounds;
	titleFrame.size.width -= (_titleEdgeInsets.left + _titleEdgeInsets.right);
	_titleView.frame = titleFrame;
	[_titleView drawRect:_titleView.bounds];
	CGContextRestoreGState(ctx);
}

- (void)mouseDown:(NSEvent *)event
{
	[super mouseDown:event];

	if(popUpMenu) { // happens even if clickCount is big
		NSMenu *menu = popUpMenu;
		NSPoint p = [self frameInNSView].origin;
		p.x += 6;
		p.y -= 2;
		[menu popUpMenuPositioningItem:nil atLocation:p inView:self.nsView];
		/*
		 after this happens, we never get a mouseUp: in the TUINSView.  this screws up _trackingView
		 for now, fake it with a fake mouseUp:
		 */
		[self.nsView performSelector:@selector(mouseUp:) withObject:event afterDelay:0.0];
		
		_controlFlags.tracking = 0;
		[TUIView animateWithDuration:0.2 animations:^{
			[self redraw];
		}];
	}
}

- (void)_update {
	_titleView.text = self.currentTitle;
	_titleView.textColor = self.currentTitleColor;
}

- (void)_stateDidChange {
	[super _stateDidChange];
	
	[self _update];
	
	[self setNeedsDisplay];
}

@end
