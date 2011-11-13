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

#import "TUITextRenderer.h"

@interface TUITextEditor : TUITextRenderer <NSTextInputClient>
{
	NSTextInputContext *inputContext;
	NSMutableAttributedString *backingStore;
	NSRange markedRange;
	NSDictionary *defaultAttributes;
	NSDictionary *markedAttributes;
}

- (NSTextInputContext *)inputContext;
- (NSMutableAttributedString *)backingStore;

@property (nonatomic, copy) NSString *text;

@property (nonatomic, strong) NSDictionary *defaultAttributes;
@property (nonatomic, strong) NSDictionary *markedAttributes;

@property (nonatomic, assign) NSRange selectedRange;

- (void)insertText:(id)aString; // at cursor
- (void)insertText:(id)aString replacementRange:(NSRange)replacementRange;
- (void)deleteCharactersInRange:(NSRange)range;

@end
