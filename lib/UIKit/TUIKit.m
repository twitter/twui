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

CGFloat Screen_Scale = 1.0;
BOOL AtLeastLion = NO;

CGContextRef TUIGraphicsGetCurrentContext(void)
{
	return (CGContextRef)[[NSGraphicsContext currentContext] graphicsPort];
}

void TUIGraphicsPushContext(CGContextRef context)
{
	NSGraphicsContext *c = [NSGraphicsContext graphicsContextWithGraphicsPort:context flipped:NO];
	[NSGraphicsContext saveGraphicsState];
	[NSGraphicsContext setCurrentContext:c];
}

void TUIGraphicsPopContext(void)
{
	[NSGraphicsContext restoreGraphicsState];
}

TUIImage* TUIGraphicsContextGetImage(CGContextRef ctx)
{
	CGImageRef CGImage = TUICreateCGImageFromBitmapContext(ctx);
	TUIImage *image = [TUIImage imageWithCGImage:CGImage];
	CGImageRelease(CGImage);

	return image;
}

void TUIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale)
{
	size.width *= scale;
	size.height *= scale;
	if(size.width < 1) size.width = 1;
	if(size.height < 1) size.height = 1;
	CGContextRef ctx = TUICreateGraphicsContextWithOptions(size, opaque);
	TUIGraphicsPushContext(ctx);
	CGContextRelease(ctx);
}

void TUIGraphicsBeginImageContext(CGSize size)
{
	TUIGraphicsBeginImageContextWithOptions(size, NO, 1.0f);
}

TUIImage* TUIGraphicsGetImageFromCurrentImageContext(void)
{
	return TUIGraphicsContextGetImage(TUIGraphicsGetCurrentContext());
}

TUIImage* TUIGraphicsGetImageForView(TUIView *view)
{
	TUIGraphicsBeginImageContext(view.frame.size);
	[view.layer renderInContext:TUIGraphicsGetCurrentContext()];
	TUIImage *image = TUIGraphicsGetImageFromCurrentImageContext();
	TUIGraphicsEndImageContext();
	return image;
}

void TUIGraphicsEndImageContext(void)
{
	TUIGraphicsPopContext();
}

TUIImage *TUIGraphicsDrawAsImage(CGSize size, void(^draw)(void))
{
	TUIGraphicsBeginImageContext(size);
	draw();
	TUIImage *image = TUIGraphicsGetImageFromCurrentImageContext();
	TUIGraphicsEndImageContext();
	return image;
}

NSData* TUIGraphicsDrawAsPDF(CGRect *optionalMediaBox, void(^draw)(CGContextRef))
{
	NSMutableData *data = [NSMutableData data];
	CGDataConsumerRef dataConsumer = CGDataConsumerCreateWithCFData((__bridge CFMutableDataRef)data);
	CGContextRef ctx = CGPDFContextCreate(dataConsumer, optionalMediaBox, NULL);
	CGPDFContextBeginPage(ctx, NULL);
	TUIGraphicsPushContext(ctx);
	draw(ctx);
	TUIGraphicsPopContext();
	CGPDFContextEndPage(ctx);
	CGPDFContextClose(ctx);
	CGContextRelease(ctx);
	CGDataConsumerRelease(dataConsumer);
	return data;
}
