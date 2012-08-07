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

/*
 Your best bet is to build commonly used fonts at launch, cache for the lifetime of the app
 */

@interface TUIFont : NSObject
{
	CTFontRef _ctFont;
}

+ (TUIFont *)fontWithName:(NSString *)fontName size:(CGFloat)fontSize;

+ (TUIFont *)systemFontOfSize:(CGFloat)fontSize;
+ (TUIFont *)boldSystemFontOfSize:(CGFloat)fontSize;

@property(nonatomic,readonly,strong) NSString *familyName;
@property(nonatomic,readonly,strong) NSString *fontName;
@property(nonatomic,readonly)        CGFloat   pointSize;
@property(nonatomic,readonly)        CGFloat   ascender;
@property(nonatomic,readonly)        CGFloat   descender;
@property(nonatomic,readonly)        CGFloat   leading;
@property(nonatomic,readonly)        CGFloat   capHeight;
@property(nonatomic,readonly)        CGFloat   xHeight;

@property (nonatomic, readonly) CTFontRef ctFont;

@end
