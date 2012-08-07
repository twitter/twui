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

#import "TUIImage.h"

@class TUIColor;

@interface TUIImage (Drawing)

+ (TUIImage *)imageWithSize:(CGSize)size drawing:(void(^)(CGContextRef))draw; // thread safe

- (TUIImage *)crop:(CGRect)cropRect;
- (TUIImage *)upsideDownCrop:(CGRect)cropRect;
- (TUIImage *)scale:(CGSize)size;
- (TUIImage *)thumbnail:(CGSize)size;
- (TUIImage *)pad:(CGFloat)padding; // can be negative (to crop to center)
- (TUIImage *)roundImage:(CGFloat)radius;
- (TUIImage *)invertedMask;
- (TUIImage *)embossMaskWithOffset:(CGSize)offset; // subtract reciever from itself offset by 'offset', use as a mask to draw emboss
- (TUIImage *)innerShadowWithOffset:(CGSize)offset radius:(CGFloat)radius color:(TUIColor *)color backgroundColor:(TUIColor *)backgroundColor; // 'backgroundColor' is used as the color the shadow is drawn with, it is mostly masked out, but a halo will remain, leading to artifacts unless it is close enough to the background color

@end
