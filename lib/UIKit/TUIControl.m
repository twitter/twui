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
#import "TUIControl+Private.h"

@implementation TUIControl

- (void)dealloc
{
	[_targetActions release];
	[super dealloc];
}

- (BOOL)isEnabled
{
	return !_controlFlags.disabled;
}

- (void)setEnabled:(BOOL)e
{
	_controlFlags.disabled = !e;
}

- (BOOL)isTracking
{
	return _controlFlags.tracking;
}

- (TUIControlState)state
{
	if(_controlFlags.tracking)
		return TUIControlStateHighlighted;
	return [self.nsWindow isKeyWindow]?TUIControlStateNormal:TUIControlStateNotKey;
}

- (BOOL)acceptsFirstMouse
{
	return _controlFlags.acceptsFirstMouse;
}

- (void)setAcceptsFirstMouse:(BOOL)s
{
	_controlFlags.acceptsFirstMouse = s;
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return self.acceptsFirstMouse;
}

- (void)mouseDown:(NSEvent *)event
{
	[super mouseDown:event];
	[self _stateWillChange];
	_controlFlags.tracking = 1;
	[self _stateDidChange];
	[self setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)event
{
	[super mouseUp:event];
	[self _stateWillChange];
	_controlFlags.tracking = 0;
	[self _stateDidChange];
	[self setNeedsDisplay];
}

@end
