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

#import "TUITableView+Additions.h"

@implementation TUITableView (Additions)

- (TUITableViewCell *)ab_reusableCellOfClass:(Class)cellClass identifier:(NSString *)identifier initializationBlock:(TUITableViewInitializationBlock)block
{
	TUITableViewCell *cell = [self dequeueReusableCellWithIdentifier:identifier];
	if(!cell) {
		cell = [[cellClass alloc] initWithStyle:TUITableViewCellStyleDefault reuseIdentifier:identifier];
		if(block != nil) block(cell);
	}
	return cell;
}

@end
