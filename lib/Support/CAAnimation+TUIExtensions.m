/*
 Copyright 2012 Twitter, Inc.
 
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

#import "CAAnimation+TUIExtensions.h"

#import <objc/runtime.h>

NSString *TUICAAnimationCompletionBlockAssociatedObjectKey = @"TUICAAnimationCompletionBlockAssociatedObjectKey";

@implementation CAAnimation (TUIExtensions)

- (void)setTui_completionBlock:(TUICAAnimationCompletionBlock)block
{
	self.delegate = self;
	objc_setAssociatedObject(self, &TUICAAnimationCompletionBlockAssociatedObjectKey, block, OBJC_ASSOCIATION_COPY);
}

- (TUICAAnimationCompletionBlock)tui_completionBlock
{
	return objc_getAssociatedObject(self, &TUICAAnimationCompletionBlockAssociatedObjectKey);
}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
	if (flag && self.tui_completionBlock != nil)
		self.tui_completionBlock();
}

@end
