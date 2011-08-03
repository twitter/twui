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

#import "TUITableView.h"

typedef void (^TUITableViewInitializationBlock)(id cell);

@interface TUITableView (Additions)

- (TUITableViewCell *)ab_reusableCellOfClass:(Class)cellClass identifier:(NSString *)identifier initializationBlock:(TUITableViewInitializationBlock)block;

@end

#define reusableTableCellOfClassWithBlock(TABLE, CLASS, BLOCK) \
	(CLASS *)[(TABLE) ab_reusableCellOfClass:[CLASS class] identifier:@"ab." @#CLASS initializationBlock:BLOCK]

#define reusableTableCellOfClass(TABLE, CLASS) \
(CLASS *)[(TABLE) ab_reusableCellOfClass:[CLASS class] identifier:@"ab." @#CLASS initializationBlock:nil]
