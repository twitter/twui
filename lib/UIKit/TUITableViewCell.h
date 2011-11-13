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
#import "TUIFastIndexPath.h"

typedef enum {
	TUITableViewCellStyleDefault,
} TUITableViewCellStyle;

@class TUITableView;

@interface TUITableViewCell : TUIView
{
  
  NSString  * _reuseIdentifier;
  CGPoint     _mouseOffset;
	
	struct {
		unsigned int highlighted:1;
		unsigned int selected:1;
	} _tableViewCellFlags;
	
}

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier;

@property(nonatomic,readonly,copy) NSString       *reuseIdentifier;

- (void)prepareForReuse;                                                        // if the cell is reusable (has a reuse identifier), this is called just before the cell is returned from the table view method dequeueReusableCellWithIdentifier:.  If you override, you MUST call super.
- (void)prepareForDisplay; // after frame is set, before it is brought onscreen

@property (weak, nonatomic, readonly) TUITableView *tableView;
@property (strong, nonatomic, readonly) TUIFastIndexPath *indexPath;

@property (nonatomic, readonly, getter=isHighlighted) BOOL highlighted;
@property (nonatomic, assign, getter=isSelected) BOOL selected;

- (void)setSelected:(BOOL)s animated:(BOOL)animated; // called by table view (don't call directly). subclasses can override

@end
