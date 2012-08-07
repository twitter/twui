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

/*
 Stub class
 It would be nice to be able to embed NSView-based views inside of a 
 TUIView-based view. The only ways I can think to do it are incredibly hacky. 
 Plus, it still wouldn't work right if you apply CAAnimations.  Maybe someone
 smarter than me can figure out a good way to do it.
 */

@interface TUIViewNSViewContainer : TUIView
{
	NSView *nsView;
}

- (id)initWithNSView:(NSView *)v;

@end
