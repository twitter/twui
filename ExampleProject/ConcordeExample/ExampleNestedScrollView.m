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

#import "ExampleNestedScrollView.h"

@interface ExampleNestedScrollView (){
    TUIScrollView *_outerScrollView;
    TUIScrollView *_innerScrollView;
}
@end

@implementation ExampleNestedScrollView
- (id)initWithFrame:(CGRect)frame
{
	if((self = [super initWithFrame:frame])) {
        _outerScrollView = [[TUIScrollView alloc] initWithFrame:frame];
        _outerScrollView.autoresizingMask = TUIViewAutoresizingFlexibleSize;
        [self addSubview:_outerScrollView];
        [_outerScrollView release];
        _outerScrollView.backgroundColor = [TUIColor whiteColor];
        _outerScrollView.contentSize = CGSizeMake(frame.size.width, 800);

        _innerScrollView = [[TUIScrollView alloc] initWithFrame:CGRectMake(0, 200, frame.size.width, 300)];
        _innerScrollView.backgroundColor = [TUIColor greenColor];
        _innerScrollView.autoresizingMask = TUIViewAutoresizingFlexibleWidth;
        _innerScrollView.contentSize = CGSizeMake(600, 220);

        int x = 10;
        for (int i = 0; i < 3; i++) {
            TUIView *v = [[TUIView alloc] initWithFrame:CGRectMake(x, 10, 100, 100)];
            v.backgroundColor = [TUIColor blackColor];
            [_innerScrollView addSubview:v];
            [v release];
            x += 110;
        }

        [_outerScrollView addSubview:_innerScrollView];
        [_innerScrollView release];
    }
    return self;
}
@end
