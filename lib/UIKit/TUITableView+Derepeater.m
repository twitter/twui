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
#import "TUITableView+Derepeater.h"

@implementation TUITableView (Derepeater)

- (BOOL)derepeaterEnabled
{
	return _tableFlags.derepeaterEnabled;
}

- (void)setDerepeaterEnabled:(BOOL)s
{
	_tableFlags.derepeaterEnabled = s;
}

- (void)_updateDerepeaterViews
{
	CGFloat padding = 7;
	
	[CATransaction begin];
	[CATransaction setDisableActions:YES];
	
	NSInteger zIndex = 5000;
	CGRect visibleRect = [self visibleRect];
	NSString *lastIdentifier = nil;
	TUIView *previousView = nil;
	CGFloat groupHeight = 0.0;
	
	for(TUITableViewCell<ABDerepeaterTableViewCell> *cell in [self sortedVisibleCells]) {
		zIndex--;
		cell.layer.zPosition = zIndex;
		CGRect cellFrame = cell.frame;
		
		NSString *identifier = [cell derepeaterIdentifier];
		TUIView *derepeaterView = [cell derepeaterView];
		if([identifier isEqual:lastIdentifier]) {
			derepeaterView.hidden = YES;
			groupHeight += cellFrame.size.height;
		} else {
			// make sure previous cell isn't too far down
			if(previousView) {
				CGRect f = previousView.frame;
				CGFloat min = -groupHeight + padding;
				if(f.origin.y < min)
					f.origin.y = min;
				
				previousView.frame = f;
				previousView = nil;
			}
			
			groupHeight = 0.0;
			previousView = derepeaterView;
			
			derepeaterView.hidden = NO;
			CGRect f = derepeaterView.frame;
			f.origin.y = f.origin.y = cellFrame.size.height - f.size.height - padding;
			if(cellFrame.origin.y + cellFrame.size.height > visibleRect.origin.y + visibleRect.size.height)
				f.origin.y += (visibleRect.origin.y + visibleRect.size.height) - (cellFrame.origin.y + cellFrame.size.height);
			
			derepeaterView.frame = f;
			lastIdentifier = identifier;
		}
	}
	
	[CATransaction commit];
}

@end
