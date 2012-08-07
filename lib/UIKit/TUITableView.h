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

#import "TUIScrollView.h"

typedef enum {
	TUITableViewStylePlain,              // regular table view
	TUITableViewStyleGrouped, // grouped table view—headers stick to the top of the table view and scroll with it
} TUITableViewStyle;

typedef enum {
	TUITableViewScrollPositionNone,        
	TUITableViewScrollPositionTop,    
	TUITableViewScrollPositionMiddle,   
	TUITableViewScrollPositionBottom,
	TUITableViewScrollPositionToVisible, // currently the only supported arg
} TUITableViewScrollPosition;

typedef enum {
  TUITableViewInsertionMethodBeforeIndex  = NSOrderedAscending,
  TUITableViewInsertionMethodAtIndex      = NSOrderedSame,
  TUITableViewInsertionMethodAfterIndex   = NSOrderedDescending
} TUITableViewInsertionMethod;

@class TUITableViewCell;
@protocol TUITableViewDataSource;

@class TUITableView;

@protocol TUITableViewDelegate<NSObject, TUIScrollViewDelegate>

- (CGFloat)tableView:(TUITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (void)tableView:(TUITableView *)tableView willDisplayCell:(TUITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath; // called after the cell's frame has been set but before it's added as a subview
- (void)tableView:(TUITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath; // happens on left/right mouse down, key up/down
- (void)tableView:(TUITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TUITableView *)tableView didClickRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event; // happens on left/right mouse up (can look at clickCount)

- (BOOL)tableView:(TUITableView*)tableView shouldSelectRowAtIndexPath:(NSIndexPath*)indexPath forEvent:(NSEvent*)event; // YES, if not implemented
- (NSMenu *)tableView:(TUITableView *)tableView menuForRowAtIndexPath:(NSIndexPath *)indexPath withEvent:(NSEvent *)event;

// the following are good places to update or restore state (such as selection) when the table data reloads
- (void)tableViewWillReloadData:(TUITableView *)tableView;
- (void)tableViewDidReloadData:(TUITableView *)tableView;

// the following is optional for row reordering
- (NSIndexPath *)tableView:(TUITableView *)tableView targetIndexPathForMoveFromRowAtIndexPath:(NSIndexPath *)fromPath toProposedIndexPath:(NSIndexPath *)proposedPath;

@end

@interface TUITableView : TUIScrollView
{
	TUITableViewStyle             _style;
	__unsafe_unretained id <TUITableViewDataSource>	_dataSource; // weak
	NSArray                     * _sectionInfo;
	
	TUIView                     * _pullDownView;
	TUIView							        * _headerView;
	
	CGSize                        _lastSize;
	CGFloat                       _contentHeight;
	
	NSMutableIndexSet           * _visibleSectionHeaders;
	NSMutableDictionary         * _visibleItems;
	NSMutableDictionary         * _reusableTableCells;
	
	NSIndexPath            * _selectedIndexPath;
	NSIndexPath            * _indexPathShouldBeFirstResponder;
	NSInteger                     _futureMakeFirstResponderToken;
	NSIndexPath            * _keepVisibleIndexPathForReload;
	CGFloat                       _relativeOffsetForReload;
	
	// drag-to-reorder state
  TUITableViewCell            * _dragToReorderCell;
  CGPoint                       _currentDragToReorderLocation;
  CGPoint                       _currentDragToReorderMouseOffset;
  NSIndexPath            * _currentDragToReorderIndexPath;
  TUITableViewInsertionMethod   _currentDragToReorderInsertionMethod;
  NSIndexPath            * _previousDragToReorderIndexPath;
  TUITableViewInsertionMethod   _previousDragToReorderInsertionMethod;
  
	struct {
		unsigned int animateSelectionChanges:1;
		unsigned int forceSaveScrollPosition:1;
		unsigned int derepeaterEnabled:1;
		unsigned int layoutSubviewsReentrancyGuard:1;
		unsigned int didFirstLayout:1;
		unsigned int dataSourceNumberOfSectionsInTableView:1;
		unsigned int delegateTableViewWillDisplayCellForRowAtIndexPath:1;
		unsigned int maintainContentOffsetAfterReload:1;
	} _tableFlags;
	
}

- (id)initWithFrame:(CGRect)frame style:(TUITableViewStyle)style;                // must specify style at creation. -initWithFrame: calls this with UITableViewStylePlain

@property (nonatomic,unsafe_unretained) id <TUITableViewDataSource>  dataSource;
@property (nonatomic,unsafe_unretained) id <TUITableViewDelegate>    delegate;

@property (readwrite, assign) BOOL                        animateSelectionChanges;
@property (nonatomic, assign) BOOL maintainContentOffsetAfterReload;

- (void)reloadData;

/**
 The table view itself has mechanisms for maintaining scroll position. During a live resize the table view should automatically "do the right thing".  This method may be useful during a reload if you want to stay in the same spot.  Use it instead of -reloadData.
 */
- (void)reloadDataMaintainingVisibleIndexPath:(NSIndexPath *)indexPath relativeOffset:(CGFloat)relativeOffset;

// Forces a re-calculation and re-layout of the table. This is most useful for animating the relayout. It is potentially _more_ expensive than -reloadData since it has to allow for animating.
- (void)reloadLayout;

- (NSInteger)numberOfSections;
- (NSInteger)numberOfRowsInSection:(NSInteger)section;

- (CGRect)rectForHeaderOfSection:(NSInteger)section;
- (CGRect)rectForSection:(NSInteger)section;
- (CGRect)rectForRowAtIndexPath:(NSIndexPath *)indexPath;

- (NSIndexSet *)indexesOfSectionsInRect:(CGRect)rect;
- (NSIndexSet *)indexesOfSectionHeadersInRect:(CGRect)rect;
- (NSIndexPath *)indexPathForCell:(TUITableViewCell *)cell;                      // returns nil if cell is not visible
- (NSArray *)indexPathsForRowsInRect:(CGRect)rect;                                    // returns nil if rect not valid
- (NSIndexPath *)indexPathForRowAtPoint:(CGPoint)point;
- (NSIndexPath *)indexPathForRowAtVerticalOffset:(CGFloat)offset;
- (NSInteger)indexOfSectionWithHeaderAtPoint:(CGPoint)point;
- (NSInteger)indexOfSectionWithHeaderAtVerticalOffset:(CGFloat)offset;

- (void)enumerateIndexPathsUsingBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block;
- (void)enumerateIndexPathsWithOptions:(NSEnumerationOptions)options usingBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block;
- (void)enumerateIndexPathsFromIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath withOptions:(NSEnumerationOptions)options usingBlock:(void (^)(NSIndexPath *indexPath, BOOL *stop))block;

- (TUIView *)headerViewForSection:(NSInteger)section;
- (TUITableViewCell *)cellForRowAtIndexPath:(NSIndexPath *)indexPath;            // returns nil if cell is not visible or index path is out of range
- (NSArray *)visibleCells; // no particular order
- (NSArray *)sortedVisibleCells; // top to bottom
- (NSArray *)indexPathsForVisibleRows;

- (void)scrollToRowAtIndexPath:(NSIndexPath *)indexPath atScrollPosition:(TUITableViewScrollPosition)scrollPosition animated:(BOOL)animated;

- (NSIndexPath *)indexPathForSelectedRow;                                       // return nil or index path representing section and row of selection.
- (NSIndexPath *)indexPathForFirstRow;
- (NSIndexPath *)indexPathForLastRow;

- (void)selectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated scrollPosition:(TUITableViewScrollPosition)scrollPosition;
- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath animated:(BOOL)animated;

/**
 Above the top cell, only visible if you pull down (if you have scroll bouncing enabled)
 */
@property (nonatomic, strong) TUIView *pullDownView;

- (BOOL)pullDownViewIsVisible;

@property (nonatomic, strong) TUIView *headerView;

/**
 Used by the delegate to acquire an already allocated cell, in lieu of allocating a new one.
 */
- (TUITableViewCell *)dequeueReusableCellWithIdentifier:(NSString *)identifier;

@end

@protocol TUITableViewDataSource<NSObject>

@required

- (NSInteger)tableView:(TUITableView *)table numberOfRowsInSection:(NSInteger)section;

- (TUITableViewCell *)tableView:(TUITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@optional

- (TUIView *)tableView:(TUITableView *)tableView headerViewForSection:(NSInteger)section;

// the following are required to support row reordering
- (BOOL)tableView:(TUITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TUITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

// the following are required to support row reordering
- (BOOL)tableView:(TUITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)tableView:(TUITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath;

/**
 Default is 1 if not implemented
 */
- (NSInteger)numberOfSectionsInTableView:(TUITableView *)tableView;

@end

@interface NSIndexPath (TUITableView)

+ (NSIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section;

@property(nonatomic,readonly) NSUInteger section;
@property(nonatomic,readonly) NSUInteger row;

@end

#import "TUITableViewCell.h"
#import "TUITableView+Derepeater.h"
