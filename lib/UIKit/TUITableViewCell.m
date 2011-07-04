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

#import "TUITableViewCell.h"
#import "TUITableView.h"

@implementation TUITableViewCell

- (void)setReuseIdentifier:(NSString *)r
{
	[_reuseIdentifier release];
	_reuseIdentifier = [r copy];
}

- (id)initWithStyle:(TUITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	if((self = [super initWithFrame:CGRectZero]))
	{
		[self setReuseIdentifier:reuseIdentifier];
	}
	return self;
}

- (void)dealloc
{
	[_reuseIdentifier release];
	[super dealloc];
}

- (NSString *)reuseIdentifier
{
	return _reuseIdentifier;
}

- (void)prepareForReuse
{
	[self removeAllAnimations];
	[self.textRenderers makeObjectsPerformSelector:@selector(resetSelection)];
	[self setNeedsDisplay];
}

- (void)prepareForDisplay
{
	[self removeAllAnimations];
}

- (TUITableView *)tableView
{
	return (TUITableView *)self.superview;
}

- (TUIFastIndexPath *)indexPath
{
	return [self.tableView indexPathForCell:self];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)event
{
	return NO;
}

- (void)mouseDown:(NSEvent *)event
{
	TUITableView *tableView = self.tableView;
	[tableView selectRowAtIndexPath:self.indexPath animated:YES scrollPosition:TUITableViewScrollPositionNone];
	if([tableView.delegate respondsToSelector:@selector(tableView:didSelectRowAtIndexPath:)])
		[tableView.delegate tableView:tableView didSelectRowAtIndexPath:self.indexPath];
	
	[super mouseDown:event]; // may make the text renderer first responder, so we want to do the selection before this
	_tableViewCellFlags.highlighted = 1;
	[self setNeedsDisplay];
}

- (void)mouseUp:(NSEvent *)event
{
	[super mouseUp:event];
	_tableViewCellFlags.highlighted = 0;
	[self setNeedsDisplay];
	
	if([self eventInside:event]) {
		TUITableView *tableView = self.tableView;
		if([tableView.delegate respondsToSelector:@selector(tableView:didClickRowAtIndexPath:withEvent:)])
			[tableView.delegate tableView:tableView didClickRowAtIndexPath:self.indexPath withEvent:event];
	}
}

- (BOOL)isHighlighted
{
	return _tableViewCellFlags.highlighted;
}

- (BOOL)isSelected
{
	return _tableViewCellFlags.selected;
}

- (void)setSelected:(BOOL)s
{
	[self setSelected:s animated:NO];
}

- (void)setSelected:(BOOL)s animated:(BOOL)animated
{
	if(animated) {
		[TUIView beginAnimations:NSStringFromSelector(_cmd) context:nil];
	}
	
	_tableViewCellFlags.selected = s;
	
	if(animated) {
		[self redraw];
		[TUIView commitAnimations];
	}
}

- (TUIView *)derepeaterView
{
	return nil;
}

- (id)derepeaterIdentifier
{
	return nil;
}

@end
