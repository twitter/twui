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

enum _TUICGRoundedRectCorner {
	TUICGRoundedRectCornerTopLeft = 1 << 0,
	TUICGRoundedRectCornerTopRight = 1 << 1,
	TUICGRoundedRectCornerBottomLeft = 1 << 2,
	TUICGRoundedRectCornerBottomRight = 1 << 3,
	TUICGRoundedRectCornerTop = TUICGRoundedRectCornerTopLeft | TUICGRoundedRectCornerTopRight,
	TUICGRoundedRectCornerBottom = TUICGRoundedRectCornerBottomLeft | TUICGRoundedRectCornerBottomRight,
	TUICGRoundedRectCornerAll = TUICGRoundedRectCornerTopLeft | TUICGRoundedRectCornerTopRight | TUICGRoundedRectCornerBottomLeft | TUICGRoundedRectCornerBottomRight,
	TUICGRoundedRectCornerNone = 0,
};

typedef NSUInteger TUICGRoundedRectCorner;

#import <Foundation/Foundation.h>

@class TUIView;

extern CGContextRef TUICreateOpaqueGraphicsContext(CGSize size);
extern CGContextRef TUICreateGraphicsContext(CGSize size);
extern CGContextRef TUICreateGraphicsContextWithOptions(CGSize size, BOOL opaque);
extern CGImageRef TUICreateCGImageFromBitmapContext(CGContextRef ctx);

extern CGPathRef TUICGPathCreateRoundedRect(CGRect rect, CGFloat radius);
extern CGPathRef TUICGPathCreateRoundedRectWithCorners(CGRect rect, CGFloat radius, TUICGRoundedRectCorner corners);
extern void CGContextAddRoundRect(CGContextRef context, CGRect rect, CGFloat radius);
extern void CGContextClipToRoundRect(CGContextRef context, CGRect rect, CGFloat radius);

extern CGRect ABScaleToFill(CGSize s, CGRect r);
extern CGRect ABScaleToFit(CGSize s, CGRect r);
extern CGRect ABRectCenteredInRect(CGRect a, CGRect b);
extern CGRect ABRectRoundOrigin(CGRect f);
extern CGRect ABIntegralRectWithSizeCenteredInRect(CGSize s, CGRect r);

extern void CGContextFillRoundRect(CGContextRef context, CGRect rect, CGFloat radius);
extern void CGContextDrawLinearGradientBetweenPoints(CGContextRef context, CGPoint a, CGFloat color_a[4], CGPoint b, CGFloat color_b[4]);

extern CGContextRef TUIGraphicsGetCurrentContext(void);
extern void TUIGraphicsPushContext(CGContextRef context);
extern void TUIGraphicsPopContext(void);

extern NSImage *TUIGraphicsContextGetImage(CGContextRef ctx);

extern void TUIGraphicsBeginImageContext(CGSize size);
extern void TUIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque, CGFloat scale);
extern NSImage *TUIGraphicsGetImageFromCurrentImageContext(void);
extern void TUIGraphicsEndImageContext(void); 

extern NSImage *TUIGraphicsGetImageForView(TUIView *view);

extern NSImage *TUIGraphicsDrawAsImage(CGSize size, void(^draw)(void));

/**
 Draw drawing as a PDF
 @param optionalMediaBox may be NULL
 @returns NSData encapsulating the PDF drawing, suitable for writing to a file or the pasteboard
 */
extern NSData *TUIGraphicsDrawAsPDF(CGRect *optionalMediaBox, void(^draw)(CGContextRef));
