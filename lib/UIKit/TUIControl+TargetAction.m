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

#import "TUIControl.h"

@interface TUIControlTargetAction : NSObject
{
	id __unsafe_unretained target; // nil goes up the responder chain
	SEL action;
	void (^block)(void);
	TUIControlEvents controlEvents;
}

@property (nonatomic, unsafe_unretained) id target;
@property (nonatomic, assign) SEL action;
@property (nonatomic, copy) void(^block)(void);
@property (nonatomic, assign) TUIControlEvents controlEvents;

@end

@implementation TUIControlTargetAction

@synthesize target;
@synthesize action;
@synthesize block;
@synthesize controlEvents;


@end


@implementation TUIControl (TargetAction)

- (NSMutableArray *)_targetActions
{
	if(!_targetActions)
		_targetActions = [[NSMutableArray alloc] init];
	return _targetActions;
}

// add target/action for particular event. you can call this multiple times and you can specify multiple target/actions for a particular event.
// passing in nil as the target goes up the responder chain. The action may optionally include the sender and the event in that order
// the action cannot be NULL.
- (void)addTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents
{
	if(action) {
		TUIControlTargetAction *t = [[TUIControlTargetAction alloc] init];
		t.target = target;
		t.action = action;
		t.controlEvents = controlEvents;
		[[self _targetActions] addObject:t];
	}
}

- (void)addActionForControlEvents:(TUIControlEvents)controlEvents block:(void(^)(void))block
{
	if(block) {
		TUIControlTargetAction *t = [[TUIControlTargetAction alloc] init];
		t.block = block;
		t.controlEvents = controlEvents;
		[[self _targetActions] addObject:t];
	}
}

// remove the target/action for a set of events. pass in NULL for the action to remove all actions for that target
- (void)removeTarget:(id)target action:(SEL)action forControlEvents:(TUIControlEvents)controlEvents
{
	NSMutableArray *targetActionsToRemove = [NSMutableArray array];
	
	for(TUIControlTargetAction *t in [self _targetActions]) {
		
		BOOL actionMatches = action == t.action;
		BOOL targetMatches = [target isEqual:t.target];
		BOOL controlMatches = controlEvents == t.controlEvents; // is this the way UIKit does it? Should I just remove certain bits from t.controlEvents?
		
		if((action && targetMatches && actionMatches && controlMatches) || 
		   (!action && targetMatches && controlMatches))
		{
			[targetActionsToRemove addObject:t];
		}
	}
}

- (NSSet *)allTargets                                                                     // set may include NSNull to indicate at least one nil target
{
	NSMutableSet *targets = [NSMutableSet set];
	for(TUIControlTargetAction *t in [self _targetActions]) {
		id target = t.target;
		[targets addObject:target?target:[NSNull null]];
	}
	return targets;
}

- (TUIControlEvents)allControlEvents                                                       // list of all events that have at least one action
{
	TUIControlEvents e = 0;
	for(TUIControlTargetAction *t in [self _targetActions]) {
		e |= t.controlEvents;
	}
	return e;
}

- (NSArray *)actionsForTarget:(id)target forControlEvent:(TUIControlEvents)controlEvent    // single event. returns NSArray of NSString selector names. returns nil if none
{
	NSMutableArray *actions = [NSMutableArray array];
	for(TUIControlTargetAction *t in [self _targetActions]) {
		if([target isEqual:t.target] && controlEvent == t.controlEvents) {
			[actions addObject:NSStringFromSelector(t.action)];
		}
	}
	
	if([actions count])
		return actions;
	return nil;
}

// send the action. the first method is called for the event and is a point at which you can observe or override behavior. it is called repeately by the second.
- (void)sendAction:(SEL)action to:(id)target forEvent:(NSEvent *)event
{
	[NSApp sendAction:action to:target from:self];
}

- (void)sendActionsForControlEvents:(TUIControlEvents)controlEvents                        // send all actions associated with events
{
	for(TUIControlTargetAction *t in [self _targetActions]) {
		if(t.controlEvents == controlEvents) {
			if(t.target && t.action) {
				[self sendAction:t.action to:t.target forEvent:nil];
			} else if(t.block) {
				t.block();
			}
		}
	}
}

@end
