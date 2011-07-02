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

#import "TUIColor.h"
#import "TUIKit.h"

@implementation TUIColor

+ (TUIColor *)colorWithPatternImage:(TUIImage *)image
{
	return [[[self alloc] initWithPatternImage:image] autorelease];
}

+ (TUIColor *)colorWithNSColor:(NSColor *)nsColor
{
	nsColor = [nsColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace];
	CGFloat r, g, b, a;
	[nsColor getRed:&r green:&g blue:&b alpha:&a];
	return [self colorWithRed:r green:g blue:b alpha:a];
}

+ (TUIColor *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
	return [[[self alloc] initWithWhite:white alpha:alpha] autorelease];
}

+ (TUIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	return [[[self alloc] initWithRed:red green:green blue:blue alpha:alpha] autorelease];
}

+ (TUIColor *)colorWithCGColor:(CGColorRef)cgColor
{
	return [[[self alloc] initWithCGColor:cgColor] autorelease];
}

- (TUIColor *)initWithWhite:(CGFloat)white alpha:(CGFloat)alpha
{
	CGColorRef c = CGColorCreateGenericGray(white, alpha);
	self = [self initWithCGColor:c];
	CGColorRelease(c);
	return self;
}

- (TUIColor *)initWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha
{
	CGColorRef c = CGColorCreateGenericRGB(red, green, blue, alpha);
	self = [self initWithCGColor:c];
	CGColorRelease(c);
	return self;
}

- (TUIColor *)initWithCGColor:(CGColorRef)cgColor
{
	if((self = [super init]))
	{
		_cgColor = cgColor;
		CGColorRetain(_cgColor);
	}
	return self;
}

static void patternDraw(void *info, CGContextRef ctx)
{
	TUIImage *image = (TUIImage *)info;
	CGRect rect;
	rect.origin = CGPointZero;
	rect.size = image.size;
	CGContextDrawImage(ctx, rect, image.CGImage);
}

static void patternRelease(void *info)
{
	TUIImage *image = (TUIImage *)info;
	[image release];
}

- (TUIColor *)initWithPatternImage:(TUIImage *)image
{
	if((self = [super init]))
	{
		CGRect bounds;
		bounds.origin = CGPointZero;
		bounds.size = image.size;
		
		CGPatternCallbacks callbacks;
		callbacks.version = 0;
		callbacks.drawPattern = patternDraw;
		callbacks.releaseInfo = patternRelease;
		
		[image retain]; // released in patternRelease
		
		CGColorSpaceRef colorSpace = CGColorSpaceCreatePattern(NULL);
		CGPatternRef pattern = CGPatternCreate(image, bounds, CGAffineTransformIdentity, bounds.size.width, bounds.size.height, kCGPatternTilingConstantSpacing, YES, &callbacks);
		CGFloat components[] = {1.0, 1.0, 1.0, 1.0};
		_cgColor = CGColorCreateWithPattern(colorSpace, pattern, components);
		CGPatternRelease(pattern);
		CGColorSpaceRelease(colorSpace);
	}
	return self;
}

- (void)dealloc
{
	CGColorRelease(_cgColor);
	[_nsColor release];
	[super dealloc];
}

- (CGColorRef)CGColor
{
	return _cgColor;
}

- (void)set
{
	[self setFill];
	[self setStroke];
}

- (void)setFill
{
	CGContextSetFillColorWithColor(TUIGraphicsGetCurrentContext(), _cgColor);
}

- (void)setStroke
{
	CGContextSetStrokeColorWithColor(TUIGraphicsGetCurrentContext(), _cgColor);
}

- (TUIColor *)colorWithAlphaComponent:(CGFloat)alpha
{
	CGColorRef c = CGColorCreateCopyWithAlpha(_cgColor, alpha);
	TUIColor *a = [TUIColor colorWithCGColor:c];
	CGColorRelease(c);
	return a;
}

#define CACHED_COLOR(NAME, IMPLEMENTATION) \
+ (TUIColor *)NAME { \
	static TUIColor *c = nil; \
	if(!c) \
		c = [IMPLEMENTATION retain]; \
	return c; \
}

CACHED_COLOR(clearColor,		[self colorWithWhite:0.0	alpha:0.0])
CACHED_COLOR(blackColor,		[self colorWithWhite:0.0	alpha:1.0])
CACHED_COLOR(darkGrayColor,		[self colorWithWhite:0.333	alpha:1.0])
CACHED_COLOR(lightGrayColor,	[self colorWithWhite:0.667	alpha:1.0])
CACHED_COLOR(whiteColor,		[self colorWithWhite:1.0	alpha:1.0])
CACHED_COLOR(grayColor,			[self colorWithWhite:0.5	alpha:1.0])
CACHED_COLOR(redColor,			[self colorWithRed:1.0 green:0.0 blue:0.0 alpha:1.0])
CACHED_COLOR(greenColor,		[self colorWithRed:0.0 green:1.0 blue:0.0 alpha:1.0])
CACHED_COLOR(blueColor,			[self colorWithRed:0.0 green:0.0 blue:1.0 alpha:1.0])
CACHED_COLOR(cyanColor,			[self colorWithRed:0.0 green:1.0 blue:1.0 alpha:1.0])
CACHED_COLOR(yellowColor,		[self colorWithRed:1.0 green:1.0 blue:0.0 alpha:1.0])
CACHED_COLOR(magentaColor,		[self colorWithRed:1.0 green:0.0 blue:1.0 alpha:1.0])
CACHED_COLOR(orangeColor,		[self colorWithRed:1.0 green:0.5 blue:0.0 alpha:1.0])
CACHED_COLOR(purpleColor,		[self colorWithRed:0.5 green:0.0 blue:0.5 alpha:1.0])
CACHED_COLOR(brownColor,		[self colorWithRed:0.6 green:0.4 blue:0.2 alpha:1.0])
CACHED_COLOR(selectedGradientBottomBlue,		[self colorWithRed:0.0 green:0.38 blue:0.92 alpha:1.0])
CACHED_COLOR(graphiteColor,		[self colorWithRed:0.45 green:0.49 blue:0.58 alpha:1.0])

+ (TUIColor *)linkColor
{
	return [TUIColor colorWithRed:13.0f/255.0f green:140.0f/255.0f blue:231.0f/255.0f alpha:1.0f];
}

- (NSColor *)nsColor
{
	if(!_nsColor) {
		size_t n = CGColorGetNumberOfComponents(_cgColor);
		const CGFloat *components = CGColorGetComponents(_cgColor);
		if(n == 4) {
			// assume RGBA -- fixme
			_nsColor = [[NSColor colorWithCalibratedRed:components[0] green:components[1] blue:components[2] alpha:components[3]] retain];
		} else if(n == 2) {
			// assume LA -- fixme
			_nsColor = [[NSColor colorWithCalibratedWhite:components[0] alpha:components[1]] retain];
		}
	}
	return _nsColor;
}

- (CGFloat)alphaComponent
{
	return CGColorGetAlpha(_cgColor);
}

- (void)getRed:(CGFloat *)r green:(CGFloat *)g blue:(CGFloat *)b alpha:(CGFloat *)a
{
	switch(CGColorGetNumberOfComponents(_cgColor)) {
		case 4: { // assume RGBA
			const CGFloat *components = CGColorGetComponents(_cgColor);
			if(r) *r = components[0];
			if(g) *g = components[1];
			if(b) *b = components[2];
			if(a) *a = components[3];
			break;
		}
		default:
			// fail silently
			break;
	}
}

- (void)getWhite:(CGFloat *)w alpha:(CGFloat *)a
{
	switch(CGColorGetNumberOfComponents(_cgColor)) {
		case 2: { // assume LA
			const CGFloat *components = CGColorGetComponents(_cgColor);
			if(w) *w = components[0];
			if(a) *a = components[1];
			break;
		}
		default:
			// fail silently
			break;
	}
}

@end
