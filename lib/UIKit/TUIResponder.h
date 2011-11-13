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

#import <Cocoa/Cocoa.h>
#import <QuartzCore/QuartzCore.h>

@interface TUIResponder : NSResponder

/* Use from NSResponder
- (NSResponder *)nextResponder;
- (BOOL)becomeFirstResponder;
- (BOOL)resignFirstResponder;
 */

@property (strong, nonatomic, readonly) TUIResponder *initialFirstResponder;

- (NSMenu *)menuForEvent:(NSEvent *)event;
- (BOOL)acceptsFirstMouse:(NSEvent *)event;
- (BOOL)performKeyAction:(NSEvent *)event; // similar semantics to performKeyEquivalent, as in you can implement, but return NO if you don't want to responsibility based on the event, but it travels *up the responder chain*, rather that to everything

@end
