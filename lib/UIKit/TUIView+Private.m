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

#import "TUIView+Private.h"
#import "TUITextRenderer.h"

@implementation TUIView (Private)

- (NSArray *)textRenderers
{
	return _textRenderers;
}

- (void)setTextRenderers:(NSArray *)renderers
{
	_currentTextRenderer = nil;
	
	for(TUITextRenderer *renderer in _textRenderers)
		renderer.view = nil;
	
	_textRenderers = renderers;

	for(TUITextRenderer *renderer in _textRenderers) {
		[renderer setNextResponder:self];
		renderer.view = self;
	}
}

- (TUITextRenderer *)textRendererAtPoint:(CGPoint)point
{
	for(TUITextRenderer *r in _textRenderers) {
		if(CGRectContainsPoint(r.frame, point))
			return r;
	}
	return nil;
}

@end
