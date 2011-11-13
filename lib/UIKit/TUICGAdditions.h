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

#import <Foundation/Foundation.h>

extern CGContextRef TUICreateOpaqueGraphicsContext(CGSize size);
extern CGContextRef TUICreateGraphicsContext(CGSize size);
extern CGContextRef TUICreateGraphicsContextWithOptions(CGSize size, BOOL opaque);
extern CGImageRef TUICreateCGImageFromBitmapContext(CGContextRef ctx);

extern void CGContextAddRoundRect(CGContextRef context, CGRect rect, CGFloat radius);
extern void CGContextClipToRoundRect(CGContextRef context, CGRect rect, CGFloat radius);

extern CGRect ABScaleToFill(CGSize s, CGRect r);
extern CGRect ABScaleToFit(CGSize s, CGRect r);
extern CGRect ABRectCenteredInRect(CGRect a, CGRect b);
extern CGRect ABRectRoundOrigin(CGRect f);
extern CGRect ABIntegralRectWithSizeCenteredInRect(CGSize s, CGRect r);

extern void CGContextFillRoundRect(CGContextRef context, CGRect rect, CGFloat radius);
extern void CGContextDrawLinearGradientBetweenPoints(CGContextRef context, CGPoint a, CGFloat color_a[4], CGPoint b, CGFloat color_b[4]);
