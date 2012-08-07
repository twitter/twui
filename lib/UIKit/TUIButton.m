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

#import "TUIButton.h"
#import "TUICGAdditions.h"
#import "TUIControl+Private.h"
#import "TUIImageView.h"
#import "TUILabel.h"
#import "TUINSView.h"
#import "TUIStretchableImage.h"
#import "TUITextRenderer.h"

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
		self.backgroundColor = [NSColor clearColor];
		self.needsDisplayWhenWindowsKeyednessChanges = YES;
		self.reversesTitleShadowWhenHighlighted = NO;
	}
	return self;
}


+ (id)button
{
	return [self buttonWithType:TUIButtonTypeCustom];
}

+ (id)buttonWithType:(TUIButtonType)buttonType
{
	TUIButton *b = [[self alloc] initWithFrame:CGRectZero];
	return b;
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
		_titleView.backgroundColor = [NSColor clearColor];
		_titleView.hidden = YES; // we'll be drawing it ourselves
		[self addSubview:_titleView];
	}
	return _titleView;
}

- (TUIImageView *)imageView
{
	if(!_imageView) {
		_imageView = [[TUIImageView alloc] initWithFrame:CGRectZero];
		_imageView.backgroundColor = [NSColor clearColor];
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
    if (a.size.width > b.size.width || a.size.height > b.size.height) {
        // scale "a" to fit "b" proportionally
        CGFloat ra = a.size.width / a.size.height;
        if (ra > 1) {
            // "long" a
            a.size.width = b.size.width;
            a.size.height = a.size.width / ra;
        } else {
            // "tall" a
            a.size.height = b.size.height;
            a.size.width = a.size.height * ra;
        }
    }
    CGRect r;
    r.size = a.size;
	r.origin.x = b.origin.x + (b.size.width - a.size.width) * 0.5;
	r.origin.y = b.origin.y + (b.size.height - a.size.height) * 0.5;
	return r;
}

- (CGSize)sizeThatFits:(CGSize)size {
	return self.currentImage.size;
}


- (void)drawRect:(CGRect)r
{
	if(_buttonFlags.firstDraw) {
		[self _update];
		_buttonFlags.firstDraw = 0;
	}
	
	CGRect bounds = self.bounds;

	BOOL key = [self.nsView isWindowKey];
	BOOL down = self.state == TUIControlStateHighlighted;
	CGFloat alpha = (self.buttonType == TUIButtonTypeCustom ? 1.0 : down?0.7:1.0);
	if(_buttonFlags.dimsInBackground)
		alpha = key?alpha:0.5;
	
	if(self.backgroundColor != nil) {
		[self.backgroundColor setFill];
		CGContextFillRect(TUIGraphicsGetCurrentContext(), self.bounds);
	}
	
	NSImage *backgroundImage = self.currentBackgroundImage;
	NSImage *image = self.currentImage;
	
	[backgroundImage drawInRect:[self backgroundRectForBounds:bounds] fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
	
	if(image) {
		CGRect imageRect;
		if([image isKindOfClass:[TUIStretchableImage class]]) {
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

		[image drawInRect:imageRect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:alpha];
	}
	
	NSString *title = self.currentTitle;
	if(title != nil) {
		_titleView.text = title;
	}
	
	NSColor *color = self.currentTitleColor;
	if(color != nil) {
		_titleView.textColor = color;
	}
	
	NSColor *shadowColor = self.currentTitleShadowColor;
	// they may have manually set the renderer's shadow color, in which case we 
	// don't want to reset it to nothing
	if(shadowColor != nil) {
		_titleView.renderer.shadowColor = shadowColor;
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
	
}

- (void)_stateDidChange {
	[super _stateDidChange];
	
	[self _update];
	
	[self setNeedsDisplay];
}

- (void)setHighlighted:(BOOL)highlighted {
	if(self.highlighted != highlighted && self.reversesTitleShadowWhenHighlighted) {
		_titleView.renderer.shadowOffset = CGSizeMake(_titleView.renderer.shadowOffset.width, -_titleView.renderer.shadowOffset.height);
	}
	
	[super setHighlighted:highlighted];
}

- (BOOL)reversesTitleShadowWhenHighlighted {
	return _buttonFlags.reversesTitleShadowWhenHighlighted;
}

- (void)setReversesTitleShadowWhenHighlighted:(BOOL)reversesTitleShadowWhenHighlighted {
	_buttonFlags.reversesTitleShadowWhenHighlighted = reversesTitleShadowWhenHighlighted;
}

@end
