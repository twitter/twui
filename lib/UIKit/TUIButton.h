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

/*
 TUIButton adopts some baggage from UIButton, probably a mistake
 this class is likely to change (be simplified) radically.
 */

#import "TUIControl.h"
#import "TUIGeometry.h"

@class TUILabel;
@class TUIImageView;

typedef enum {
    TUIButtonTypeCustom = 0,
} TUIButtonType;

@interface TUIButton : TUIControl
{
	NSMutableDictionary		*_contentLookup;
	TUIEdgeInsets           _titleEdgeInsets;
    TUIEdgeInsets           _imageEdgeInsets;

	TUIImageView           *_imageView;
	TUILabel               *_titleView;
	
	NSMenu *popUpMenu;
	
    struct {
		unsigned int dimsInBackground:1;
        unsigned int buttonType:8;
		unsigned int firstDraw:1;
		unsigned int reversesTitleShadowWhenHighlighted:1;
    } _buttonFlags;
}

+ (id)buttonWithType:(TUIButtonType)buttonType;
+ (id)button; // custom

@property(nonatomic,assign)        TUIEdgeInsets    titleEdgeInsets;
@property(nonatomic,assign)        TUIEdgeInsets    imageEdgeInsets;
@property(nonatomic,assign) BOOL dimsInBackground;

@property(nonatomic,readonly) TUIButtonType buttonType;

@property (nonatomic, strong) NSMenu *popUpMenu;

@property(nonatomic,readonly,strong) TUILabel     *titleLabel;
@property(nonatomic,readonly,strong) TUIImageView *imageView;

@property (nonatomic, assign) BOOL reversesTitleShadowWhenHighlighted;

- (CGRect)backgroundRectForBounds:(CGRect)bounds;
- (CGRect)contentRectForBounds:(CGRect)bounds;
- (CGRect)titleRectForContentRect:(CGRect)contentRect;
- (CGRect)imageRectForContentRect:(CGRect)contentRect;

@end

@interface TUIButton (Content)

- (void)setTitle:(NSString *)title forState:(TUIControlState)state;
- (void)setTitleColor:(NSColor *)color forState:(TUIControlState)state;
- (void)setTitleShadowColor:(NSColor *)color forState:(TUIControlState)state;
- (void)setImage:(NSImage *)image forState:(TUIControlState)state;
- (void)setBackgroundImage:(NSImage *)image forState:(TUIControlState)state;

- (NSString *)titleForState:(TUIControlState)state;
- (NSColor *)titleColorForState:(TUIControlState)state;
- (NSColor *)titleShadowColorForState:(TUIControlState)state;
- (NSImage *)imageForState:(TUIControlState)state;
- (NSImage *)backgroundImageForState:(TUIControlState)state;

@property(nonatomic, readonly, strong) NSString *currentTitle;
@property(nonatomic, readonly, strong) NSColor *currentTitleColor;
@property(nonatomic, readonly, strong) NSColor *currentTitleShadowColor;
@property(nonatomic, readonly, strong) NSImage *currentImage;
@property(nonatomic, readonly, strong) NSImage *currentBackgroundImage;
@end
