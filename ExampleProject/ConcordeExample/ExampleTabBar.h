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

#import "TUIKit.h"

@class ExampleTabBar;

@protocol ExampleTabBarDelegate <NSObject>
@required
- (void)tabBar:(ExampleTabBar *)tabBar didSelectTab:(NSInteger)index;
@end

/*
 An example of how to build a custom UI control, in this case a simple tab bar
 */

@interface ExampleTabBar : TUIView
{
	id<ExampleTabBarDelegate> __unsafe_unretained delegate;
	NSArray *tabViews;
}

- (id)initWithNumberOfTabs:(NSInteger)nTabs;

@property (nonatomic, unsafe_unretained) id<ExampleTabBarDelegate> delegate;
@property (nonatomic, readonly) NSArray *tabViews;

@end
