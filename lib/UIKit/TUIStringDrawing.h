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
#import "TUIAttributedString.h"

@class TUIFont;
@class TUIColor;

@interface NSAttributedString (TUIStringDrawing)

- (CGSize)ab_size;
- (CGSize)ab_sizeConstrainedToSize:(CGSize)size;
- (CGSize)ab_sizeConstrainedToWidth:(CGFloat)width;

- (CGSize)ab_drawInRect:(CGRect)rect;
- (CGSize)ab_drawInRect:(CGRect)rect context:(CGContextRef)ctx;

@end

@interface NSString (TUIStringDrawing)

- (CGSize)ab_sizeWithFont:(TUIFont *)font;
- (CGSize)ab_sizeWithFont:(TUIFont *)font constrainedToSize:(CGSize)size;

#if TARGET_OS_MAC
// for ABRowView
//- (CGSize)drawInRect:(CGRect)rect withFont:(TUIFont *)font lineBreakMode:(TUILineBreakMode)lineBreakMode alignment:(TUITextAlignment)alignment;
#endif

- (CGSize)ab_drawInRect:(CGRect)rect color:(TUIColor *)color font:(TUIFont *)font;
- (CGSize)ab_drawInRect:(CGRect)rect withFont:(TUIFont *)font lineBreakMode:(TUILineBreakMode)lineBreakMode alignment:(TUITextAlignment)alignment;

@end
