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

@interface TUIView (Event)

- (BOOL)didDrag; // valid when called from mouseUp: will determine if a drag happened in this event sequence

- (void)viewWillStartLiveResize; // call super to propogate to subviews
- (void)viewDidEndLiveResize;

/* Observing events in subviews
 * 
 * The subview parameter is the view which recieved the event, not the
 * immediate subview of the view recieving the message. To determine if
 * the event belongs to a subview of a particular immediate subview, use
 * -isDescendantOfView:.
 */
- (void)mouseDown:(NSEvent *)event onSubview:(TUIView *)subview;
- (void)mouseDragged:(NSEvent *)event onSubview:(TUIView *)subview;
- (void)mouseUp:(NSEvent *)event fromSubview:(TUIView *)subview;
- (void)rightMouseDown:(NSEvent *)event onSubview:(TUIView *)subview;
- (void)rightMouseUp:(NSEvent *)event fromSubview:(TUIView *)subview;
- (void)mouseEntered:(NSEvent *)event onSubview:(TUIView *)subview;
- (void)mouseExited:(NSEvent *)event fromSubview:(TUIView *)subview;

@end
