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

#import "NSImage+TUIExtensions.h"
#import "NSColor+TUIExtensions.h"
#import "TUICGAdditions.h"
#import "TUIStretchableImage.h"

@implementation NSImage (TUIExtensions)

+ (NSImage *)tui_imageWithCGImage:(CGImageRef)cgImage {
	CGSize size = CGSizeMake(CGImageGetWidth(cgImage), CGImageGetHeight(cgImage));
	return [[self alloc] initWithCGImage:cgImage size:size];
}

+ (NSImage *)tui_imageWithSize:(CGSize)size drawing:(void(^)(CGContextRef))draw
{
	if(size.width < 1 || size.height < 1)
		return nil;
	
	CGFloat scale = [[NSScreen mainScreen] backingScaleFactor];
	size = CGSizeMake(size.width * scale, size.height * scale);

	CGContextRef ctx = TUICreateGraphicsContextWithOptions(size, NO);
	CGContextScaleCTM(ctx, scale, scale);

	draw(ctx);
	NSImage *i = TUIGraphicsContextGetImage(ctx);
	CGContextRelease(ctx);
	return i;
}

- (CGImageRef)tui_CGImage
{
	return [self CGImageForProposedRect:NULL context:nil hints:nil];
}

- (CGImageRef)tui_CGImageForProposedRect:(CGRect *)rectPtr CGContext:(CGContextRef)context
{
	NSGraphicsContext *graphicsContext = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
	return [self CGImageForProposedRect:rectPtr context:graphicsContext hints:nil];
}

- (void)tui_drawAtPoint:(CGPoint)point
{
	[self drawAtPoint:point fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (void)tui_drawInRect:(CGRect)rect
{
	[self drawInRect:rect fromRect:NSZeroRect operation:NSCompositeSourceOver fraction:1.0];
}

- (TUIStretchableImage *)tui_resizableImageWithCapInsets:(TUIEdgeInsets)insets {
	TUIStretchableImage *image = [[TUIStretchableImage alloc] init];
	[image addRepresentations:self.representations];

	image.capInsets = insets;
	return image;
}

- (NSImage *)tui_scale:(CGSize)size
{
	return [NSImage tui_imageWithSize:size drawing:^(CGContextRef ctx) {
		CGRect r;
		r.origin = CGPointZero;
		r.size = size;
		CGContextDrawImage(ctx, r, self.tui_CGImage);
	}];
}

- (NSImage *)tui_crop:(CGRect)cropRect
{
	if((cropRect.size.width < 1) || (cropRect.size.height < 1))
		return nil;
	
	CGSize s = self.size;
	CGFloat mx = cropRect.origin.x + cropRect.size.width;
	CGFloat my = cropRect.origin.y + cropRect.size.height;
	if((cropRect.origin.x >= 0.0) && (cropRect.origin.y >= 0.0) && (mx <= s.width) && (my <= s.height)) {
		// fast crop
		CGImageRef cgimage = CGImageCreateWithImageInRect(self.tui_CGImage, cropRect);
		if(!cgimage) {
			NSLog(@"CGImageCreateWithImageInRect failed %@ %@", NSStringFromRect(cropRect), NSStringFromSize(s));
			return nil;
		}
		NSImage *i = [NSImage tui_imageWithCGImage:cgimage];
		CGImageRelease(cgimage);
		return i;
	} else {
		// slow crop - probably doing pad
		return [NSImage tui_imageWithSize:cropRect.size drawing:^(CGContextRef ctx) {
			CGRect imageRect;
			imageRect.origin.x = -cropRect.origin.x;
			imageRect.origin.y = -cropRect.origin.y;
			imageRect.size = s;
			CGContextDrawImage(ctx, imageRect, self.tui_CGImage);
		}];
	}
}

- (NSImage *)tui_upsideDownCrop:(CGRect)cropRect
{
	CGSize s = self.size;
	cropRect.origin.y = s.height - (cropRect.origin.y + cropRect.size.height);
	return [self tui_crop:cropRect];
}

- (NSImage *)tui_thumbnail:(CGSize)newSize 
{
	CGSize s = self.size;
  float oldProp = s.width / s.height;
  float newProp = newSize.width / newSize.height;  
  CGRect cropRect;
  if (oldProp > newProp) {
    cropRect.size.height = s.height;
    cropRect.size.width = s.height * newProp;
  } else {
    cropRect.size.width = s.width;
    cropRect.size.height = s.width / newProp;
  }
  cropRect.origin = CGPointMake((s.width - cropRect.size.width) / 2.0, (s.height - cropRect.size.height) / 2.0);
  return [[self tui_crop:cropRect] tui_scale:newSize];
}

- (NSImage *)tui_pad:(CGFloat)padding
{
	CGSize s = self.size;
	return [self tui_crop:CGRectMake(-padding, -padding, s.width + padding*2, s.height + padding*2)];
}

- (NSImage *)tui_roundImage:(CGFloat)radius
{
	CGRect r;
	r.origin = CGPointZero;
	r.size = self.size;
	return [NSImage tui_imageWithSize:r.size drawing:^(CGContextRef ctx) {
		CGContextClipToRoundRect(ctx, r, radius);
		CGContextDrawImage(ctx, r, self.tui_CGImage);
	}];
}

- (NSImage *)tui_invertedMask
{
	CGSize s = self.size;
	return [NSImage tui_imageWithSize:s drawing:^(CGContextRef ctx) {
		CGRect rect = CGRectMake(0, 0, s.width, s.height);
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
		CGContextFillRect(ctx, rect);
		CGContextSaveGState(ctx);
		CGContextClipToMask(ctx, rect, self.tui_CGImage);
		CGContextClearRect(ctx, rect);
		CGContextRestoreGState(ctx);
	}];
}

- (NSImage *)tui_innerShadowWithOffset:(CGSize)offset radius:(CGFloat)radius color:(NSColor *)color backgroundColor:(NSColor *)backgroundColor
{
	CGFloat padding = ceil(radius);
	NSImage *paddedImage = [self tui_pad:padding];
	NSImage *shadowImage = [NSImage tui_imageWithSize:paddedImage.size drawing:^(CGContextRef ctx) {
		CGContextSaveGState(ctx);
		CGRect r = CGRectMake(0, 0, paddedImage.size.width, paddedImage.size.height);
		CGContextClipToMask(ctx, r, paddedImage.tui_CGImage); // clip to image
		CGContextSetShadowWithColor(ctx, offset, radius, color.tui_CGColor);
		CGContextBeginTransparencyLayer(ctx, NULL);
		{
			CGContextClipToMask(ctx, r, [[paddedImage tui_invertedMask] tui_CGImage]); // clip to inverted
			CGContextSetFillColorWithColor(ctx, backgroundColor.tui_CGColor);
			CGContextFillRect(ctx, r); // draw with shadow
		}

		CGContextEndTransparencyLayer(ctx);
		CGContextRestoreGState(ctx);
	}];
	
	return [shadowImage tui_pad:-padding];
}

- (NSImage *)tui_embossMaskWithOffset:(CGSize)offset
{
	CGFloat padding = MAX(offset.width, offset.height) + 1;
	NSImage *paddedImage = [self tui_pad:padding];
	CGSize s = paddedImage.size;
	NSImage *embossedImage = [NSImage tui_imageWithSize:s drawing:^(CGContextRef ctx) {
		CGContextSaveGState(ctx);
		CGRect r = CGRectMake(0, 0, s.width, s.height);
		CGContextClipToMask(ctx, r, [paddedImage tui_CGImage]);
		CGContextClipToMask(ctx, CGRectOffset(r, offset.width, offset.height), [[paddedImage tui_invertedMask] tui_CGImage]);
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
		CGContextFillRect(ctx, r);
		CGContextRestoreGState(ctx);
	}];
	
	return [embossedImage tui_pad:-padding];
}

@end
