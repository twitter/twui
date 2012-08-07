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

#import "TUIActivityIndicatorView.h"

@implementation TUIActivityIndicatorView

- (id)initWithActivityIndicatorStyle:(TUIActivityIndicatorViewStyle)style
{
	if((self = [super initWithFrame:CGRectMake(0, 0, 20, 20)]))
	{
		_activityIndicatorViewStyle = style;
		
		spinner = [[TUIView alloc] initWithFrame:self.bounds];
		spinner.backgroundColor = [NSColor blackColor];
		spinner.alpha = 0.2;
		spinner.layer.cornerRadius = 10.0;
		[self addSubview:spinner];
	}
	return self;
}

- (TUIActivityIndicatorViewStyle)activityIndicatorViewStyle
{
	return _activityIndicatorViewStyle;
}

- (void)startAnimating
{
	if(!_animating) {
		CGFloat duration = 1.0;
		
		{
			CABasicAnimation *animation = [CABasicAnimation animation];
			animation.repeatCount = INT_MAX;
			animation.duration = duration;
			animation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(0.1, 0.1, 0.1)];
			animation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.0, 1.0, 1.0)];
			[spinner.layer addAnimation:animation forKey:@"transform"];
		}
		
		{
			CAKeyframeAnimation *animation = [CAKeyframeAnimation animation];
			animation.values = [NSArray arrayWithObjects:
								[NSNumber numberWithFloat:0.0],
								[NSNumber numberWithFloat:0.3],
								[NSNumber numberWithFloat:0.0],
								nil];
			animation.repeatCount = INT_MAX;
			animation.duration = duration;
			[spinner.layer addAnimation:animation forKey:@"opacity"];
		}
		
		_animating = YES;
	}
}

- (void)stopAnimating
{
	if(_animating) {
		[spinner.layer removeAllAnimations];
		_animating = NO;
	}
}

- (BOOL)isAnimating
{
	return _animating;
}

- (CGSize)sizeThatFits:(CGSize)size
{
	return CGSizeMake(20, 20);
}

- (void)removeAllAnimations
{
	// do nothing
}

@end
