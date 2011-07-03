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

#import "TUIKit.h"
#import "TUIImage+Drawing.h"

@implementation TUIImage (Drawing)

+ (TUIImage *)imageWithSize:(CGSize)size drawing:(void(^)(CGContextRef))draw
{
	if(size.width < 1 || size.height < 1)
		return nil;

	CGContextRef ctx = TUICreateGraphicsContextWithOptions(size, NO);
	draw(ctx);
	TUIImage *i = TUIGraphicsContextGetImage(ctx);
	CGContextRelease(ctx);
	return i;
}

- (TUIImage *)scale:(CGSize)size
{
	return [TUIImage imageWithSize:size drawing:^(CGContextRef ctx) {
		CGRect r;
		r.origin = CGPointZero;
		r.size = size;
		CGContextDrawImage(ctx, r, self.CGImage);
	}];
}

- (TUIImage *)crop:(CGRect)cropRect
{
	if((cropRect.size.width < 1) || (cropRect.size.height < 1))
		return nil;
	
	CGSize s = self.size;
	CGFloat mx = cropRect.origin.x + cropRect.size.width;
	CGFloat my = cropRect.origin.y + cropRect.size.height;
	if((cropRect.origin.x >= 0.0) && (cropRect.origin.y >= 0.0) && (mx <= s.width) && (my <= s.height)) {
		// fast crop
		CGImageRef cgimage = CGImageCreateWithImageInRect(self.CGImage, cropRect);
		if(!cgimage) {
			NSLog(@"CGImageCreateWithImageInRect failed %@ %@", NSStringFromRect(cropRect), NSStringFromSize(s));
			return nil;
		}
		TUIImage *i = [TUIImage imageWithCGImage:cgimage];
		CGImageRelease(cgimage);
		return i;
	} else {
		// slow crop - probably doing pad
		return [TUIImage imageWithSize:cropRect.size drawing:^(CGContextRef ctx) {
			CGRect imageRect;
			imageRect.origin.x = -cropRect.origin.x;
			imageRect.origin.y = -cropRect.origin.y;
			imageRect.size = s;
			CGContextDrawImage(ctx, imageRect, self.CGImage);
		}];
	}
}

- (TUIImage *)upsideDownCrop:(CGRect)cropRect
{
	CGSize s = self.size;
	cropRect.origin.y = s.height - (cropRect.origin.y + cropRect.size.height);
	return [self crop:cropRect];
}

- (TUIImage *)thumbnail:(CGSize)newSize 
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
  return [[self crop:cropRect] scale:newSize];
}

- (TUIImage *)pad:(CGFloat)padding
{
	CGSize s = self.size;
	return [self crop:CGRectMake(-padding, -padding, s.width + padding*2, s.height + padding*2)];
}

- (TUIImage *)roundImage:(CGFloat)radius
{
	CGRect r;
	r.origin = CGPointZero;
	r.size = self.size;
	return [TUIImage imageWithSize:r.size drawing:^(CGContextRef ctx) {
		CGContextClipToRoundRect(ctx, r, radius);
		CGContextDrawImage(ctx, r, self.CGImage);
	}];
}

- (TUIImage *)invertedMask
{
	CGSize s = self.size;
	return [TUIImage imageWithSize:s drawing:^(CGContextRef ctx) {
		CGRect rect = CGRectMake(0, 0, s.width, s.height);
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
		CGContextFillRect(ctx, rect);
		CGContextSaveGState(ctx);
		CGContextClipToMask(ctx, rect, self.CGImage);
		CGContextClearRect(ctx, rect);
		CGContextRestoreGState(ctx);
	}];
}

- (TUIImage *)innerShadowWithOffset:(CGSize)offset radius:(CGFloat)radius color:(TUIColor *)color backgroundColor:(TUIColor *)backgroundColor
{
	CGFloat padding = ceil(radius);
	self = [self pad:padding];
	self = [TUIImage imageWithSize:self.size drawing:^(CGContextRef ctx) {
		CGContextSaveGState(ctx);
		CGRect r = CGRectMake(0, 0, self.size.width, self.size.height);
		CGContextClipToMask(ctx, r, self.CGImage); // clip to image
		CGContextSetShadowWithColor(ctx, offset, radius, color.CGColor);
		CGContextBeginTransparencyLayer(ctx, NULL);
		{
			CGContextClipToMask(ctx, r, [[self invertedMask] CGImage]); // clip to inverted
			CGContextSetFillColorWithColor(ctx, backgroundColor.CGColor);
			CGContextFillRect(ctx, r); // draw with shadow
		}
		CGContextEndTransparencyLayer(ctx);
		CGContextRestoreGState(ctx);
	}];
	self = [self pad:-padding];
	return self;
}

- (TUIImage *)embossMaskWithOffset:(CGSize)offset
{
	CGFloat padding = MAX(offset.width, offset.height) + 1;
	self = [self pad:padding];
	CGSize s = self.size;
	self = [TUIImage imageWithSize:s drawing:^(CGContextRef ctx) {
		CGContextSaveGState(ctx);
		CGRect r = CGRectMake(0, 0, s.width, s.height);
		CGContextClipToMask(ctx, r, [self CGImage]);
		CGContextClipToMask(ctx, CGRectOffset(r, offset.width, offset.height), [[self invertedMask] CGImage]);
		CGContextSetRGBFillColor(ctx, 0, 0, 0, 1);
		CGContextFillRect(ctx, r);
		CGContextRestoreGState(ctx);
	}];
	self = [self pad:-padding];
	return self;
}

@end
