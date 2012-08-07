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

#import "TUIView.h"
#import "TUIAttributedString.h"

/*
 Check out TUITextRenderer, you probably want to use that to get
 subpixel AA and a flatter view heirarchy.
 */

@interface TUILabel : TUIView
@property(nonatomic, copy) NSString *text;
@property(nonatomic, strong) NSAttributedString	*attributedString;
@property(nonatomic, getter=isSelectable) BOOL selectable;
@property(nonatomic, readonly) TUITextRenderer *renderer;
@property(nonatomic, strong) NSFont *font;
@property(nonatomic, strong) NSColor *textColor;
@property(nonatomic, assign) TUITextAlignment alignment;
@property(nonatomic, assign) TUILineBreakMode lineBreakMode; 
@end
