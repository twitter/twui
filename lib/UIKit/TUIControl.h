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

enum {
  TUIControlEventTouchDown           = 1 <<  0,
  TUIControlEventTouchDownRepeat     = 1 <<  1,
  TUIControlEventTouchUpInside       = 1 <<  6,
  TUIControlEventTouchUpOutside      = 1 <<  7,
  TUIControlEventValueChanged        = 1 << 12,
  TUIControlEventEditingDidEndOnExit = 1 << 19,
  TUIControlEventAllTouchEvents      = 0x00000FFF,
  TUIControlEventAllEditingEvents    = 0x000F0000,
  TUIControlEventApplicationReserved = 0x0F000000,
  TUIControlEventSystemReserved      = 0xF0000000,
  TUIControlEventAllEvents           = 0xFFFFFFFF
};
typedef NSUInteger TUIControlEvents;

enum {
  TUIControlStateNormal       = 0,                       
  TUIControlStateHighlighted  = 1 << 0,
  TUIControlStateDisabled     = 1 << 1,
  TUIControlStateSelected     = 1 << 2,
  TUIControlStateNotKey       = 1 << 11,
  TUIControlStateApplication  = 0x00FF0000,
  TUIControlStateReserved     = 0xFF000000
};
typedef NSUInteger TUIControlState;

@interface TUIControl : TUIView
{
  NSMutableArray*   _targetActions;
	struct {
		unsigned int disabled:1;
		unsigned int selected:1;
		unsigned int acceptsFirstMouse:1;
		unsigned int tracking:1;
	} _controlFlags;
}

@property(nonatomic,getter=isEnabled) BOOL enabled;

@property(nonatomic,readonly) TUIControlState state;
@property(nonatomic,readonly,getter=isTracking) BOOL tracking;
@property(nonatomic,assign) BOOL selected;

@property (nonatomic, assign) BOOL acceptsFirstMouse;

@end

@interface TUIControl (TargetAction)

- (void)addTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents;

- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents;

- (void)addActionForControlEvents:(TUIControlEvents)controlEvents block:(void(^)(void))action;

- (NSSet *)allTargets;
- (TUIControlEvents)allControlEvents;
- (NSArray *)actionsForTarget:(id)target forControlEvent:(TUIControlEvents)controlEvent;

- (void)sendAction:(SEL)action to:(id)target forEvent:(NSEvent *)event;
- (void)sendActionsForControlEvents:(TUIControlEvents)controlEvents;

@end
