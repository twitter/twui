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

#import "TUICGAdditions.h"

CGContextRef TUICreateOpaqueGraphicsContext(CGSize size)
{
	size_t width = size.width;
	size_t height = size.height;
	size_t bitsPerComponent = 8;
	size_t bytesPerRow = 4 * width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaNoneSkipFirst;
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
	CGColorSpaceRelease(colorSpace);
	return ctx;
}

CGContextRef TUICreateGraphicsContext(CGSize size)
{
	size_t width = size.width;
	size_t height = size.height;
	size_t bitsPerComponent = 8;
	size_t bytesPerRow = 4 * width;
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	// http://www.cocoTUIlder.com/archive/cocoa/228931-sub-pixel-font-smoothing-with-cgbitmapcontext.html
	// http://developer.apple.com/mac/library/qa/qa2001/qa1037.html
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrder32Host | kCGImageAlphaPremultipliedFirst;
	CGContextRef ctx = CGBitmapContextCreate(NULL, width, height, bitsPerComponent, bytesPerRow, colorSpace, bitmapInfo);
	CGColorSpaceRelease(colorSpace);
	return ctx;
}

CGContextRef TUICreateGraphicsContextWithOptions(CGSize size, BOOL opaque)
{
	if(opaque)
		return TUICreateOpaqueGraphicsContext(size);
	else
		return TUICreateGraphicsContext(size);
}

CGImageRef TUICGImageFromBitmapContext(CGContextRef ctx) // autoreleased
{
	CGImageRef i = CGBitmapContextCreateImage(ctx);
	return (CGImageRef)[(id)i autorelease];
}

void CGContextAddRoundRect(CGContextRef context, CGRect rect, CGFloat radius)
{
	radius = MIN(radius, rect.size.width / 2);
	radius = MIN(radius, rect.size.height / 2);
	radius = floor(radius);
	
	CGContextMoveToPoint(context, rect.origin.x, rect.origin.y + radius);
	CGContextAddLineToPoint(context, rect.origin.x, rect.origin.y + rect.size.height - radius);
	CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + rect.size.height - radius, radius, M_PI, M_PI / 2, 1);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height);
	CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + rect.size.height - radius, radius, M_PI / 2, 0.0f, 1);
	CGContextAddLineToPoint(context, rect.origin.x + rect.size.width, rect.origin.y + radius);
	CGContextAddArc(context, rect.origin.x + rect.size.width - radius, rect.origin.y + radius, radius, 0.0f, -M_PI / 2, 1);
	CGContextAddLineToPoint(context, rect.origin.x + radius, rect.origin.y);
	CGContextAddArc(context, rect.origin.x + radius, rect.origin.y + radius, radius, -M_PI / 2, M_PI, 1);
}

void CGContextClipToRoundRect(CGContextRef context, CGRect rect, CGFloat radius)
{
	CGContextBeginPath(context);
	CGContextAddRoundRect(context, rect, radius);
	CGContextClosePath(context);
	CGContextClip(context);
}

CGRect ABScaleToFill(CGSize s, CGRect r)
{
	float rx = r.size.width / s.width;
	float ry = r.size.height / s.height;
	float scale = MAX(rx, ry);
	CGRect sr;
	sr.size = CGSizeMake(s.width * scale, s.height * scale);
	sr.origin = CGPointMake(r.origin.x + (r.size.width - sr.size.width)*0.5, r.origin.y + (r.size.height - sr.size.height)*0.5);
	return sr;
}

CGRect ABScaleToFit(CGSize s, CGRect r)
{
	float rx = r.size.width / s.width;
	float ry = r.size.height / s.height;
	float scale = MIN(rx, ry);
	CGRect sr;
	sr.size = CGSizeMake(s.width * scale, s.height * scale);
	sr.origin = CGPointMake(r.origin.x + (r.size.width - sr.size.width)*0.5, r.origin.y + (r.size.height - sr.size.height)*0.5);
	return sr;
}

CGRect ABRectRoundOrigin(CGRect f)
{
	f.origin.x = roundf(f.origin.x);
	f.origin.y = roundf(f.origin.y);
	return f;
}

CGRect ABIntegralRectWithSizeCenteredInRect(CGSize s, CGRect r)
{
	return ABRectRoundOrigin(ABRectCenteredInRect(CGRectMake(0, 0, s.width, s.height), r));
}

CGRect ABRectCenteredInRect(CGRect a, CGRect b)
{
	CGRect r;
	r.size = a.size;
	r.origin.x = b.origin.x + (b.size.width - a.size.width) * 0.5;
	r.origin.y = b.origin.y + (b.size.height - a.size.height) * 0.5;
	return r;
}

void CGContextFillRoundRect(CGContextRef context, CGRect rect, CGFloat radius)
{
	CGContextBeginPath(context);
	CGContextAddRoundRect(context, rect, radius);
	CGContextClosePath(context);
	CGContextFillPath(context);
}

void CGContextDrawLinearGradientBetweenPoints(CGContextRef context, CGPoint a, CGFloat color_a[4], CGPoint b, CGFloat color_b[4])
{
	CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
	CGFloat components[] = { color_a[0], color_a[1], color_a[2], color_a[3], color_b[0], color_b[1], color_b[2], color_b[3] };
	CGGradientRef gradient = CGGradientCreateWithColorComponents(colorspace, components, NULL, 2);
	CGContextDrawLinearGradient(context, gradient, a, b, 0);
	CGColorSpaceRelease(colorspace);
	CGGradientRelease(gradient);
}
