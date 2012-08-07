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

@class TUIImage;

@interface TUIColor : NSObject
{
	CGColorRef _cgColor; // backing color
	NSColor *_nsColor; // created on demand
}

+ (TUIColor *)colorWithWhite:(CGFloat)white alpha:(CGFloat)alpha;
+ (TUIColor *)colorWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
+ (TUIColor *)colorWithCGColor:(CGColorRef)cgColor;
+ (TUIColor *)colorWithNSColor:(NSColor *)nsColor;
+ (TUIColor *)colorWithPatternImage:(TUIImage *)image;

- (TUIColor *)initWithWhite:(CGFloat)white alpha:(CGFloat)alpha;
- (TUIColor *)initWithRed:(CGFloat)red green:(CGFloat)green blue:(CGFloat)blue alpha:(CGFloat)alpha;
- (TUIColor *)initWithCGColor:(CGColorRef)cgColor;
- (TUIColor *)initWithPatternImage:(TUIImage *)image;

// cached
+ (TUIColor *)blackColor;      // 0.0 white
+ (TUIColor *)darkGrayColor;   // 0.333 white
+ (TUIColor *)lightGrayColor;  // 0.667 white
+ (TUIColor *)whiteColor;      // 1.0 white
+ (TUIColor *)grayColor;       // 0.5 white
+ (TUIColor *)redColor;        // 1.0, 0.0, 0.0 RGB
+ (TUIColor *)greenColor;      // 0.0, 1.0, 0.0 RGB
+ (TUIColor *)blueColor;       // 0.0, 0.0, 1.0 RGB
+ (TUIColor *)cyanColor;       // 0.0, 1.0, 1.0 RGB
+ (TUIColor *)yellowColor;     // 1.0, 1.0, 0.0 RGB
+ (TUIColor *)magentaColor;    // 1.0, 0.0, 1.0 RGB
+ (TUIColor *)orangeColor;     // 1.0, 0.5, 0.0 RGB
+ (TUIColor *)purpleColor;     // 0.5, 0.0, 0.5 RGB
+ (TUIColor *)brownColor;      // 0.6, 0.4, 0.2 RGB
+ (TUIColor *)clearColor;      // 0.0 white, 0.0 alpha

// UIKit Additions

+ (TUIColor *)selectedGradientBottomBlue;
+ (TUIColor *)graphiteColor;

+ (TUIColor *)linkColor;

/**
 Sets fill and stroke for the current context
 */
- (void)set;

- (void)setFill;
- (void)setStroke;

- (TUIColor *)colorWithAlphaComponent:(CGFloat)alpha;

@property (nonatomic, readonly) CGColorRef CGColor;

@property (nonatomic, readonly) CGFloat alphaComponent;

/**
 It is the caller's responsibility to ensure the reciever is an RGBA color. Pass NULL for components you don't care about.
 */
- (void)getRed:(CGFloat *)r green:(CGFloat *)g blue:(CGFloat *)b alpha:(CGFloat *)a;

/**
 It is the caller's responsibility to ensure the reciever is an Luminance/Alpha color. Pass NULL for components you don't care about.
 */
- (void)getWhite:(CGFloat *)w alpha:(CGFloat *)a;

/**
 Not cached
 */
@property (strong, nonatomic, readonly) NSColor *nsColor;

@end
