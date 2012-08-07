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

#import "TUIImageView.h"

@implementation TUIImageView
@synthesize image = _image;

- (void)setImage:(NSImage *)i
{
	_image = i;
	[self setNeedsDisplay];
}

- (id)initWithImage:(NSImage *)image
{
	CGRect frame = CGRectZero;
	if (image) frame = CGRectMake(0, 0, image.size.width, image.size.height);

	self = [super initWithFrame:frame];
	if (self == nil) return nil;

	self.userInteractionEnabled = NO;
	_image = image;

	return self;
}

- (void)drawRect:(CGRect)rect
{
	[super drawRect:rect];
	if (_image == nil)
		return;
    
    [_image drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (CGSize)sizeThatFits:(CGSize)size {
	return _image.size;
}

@end
