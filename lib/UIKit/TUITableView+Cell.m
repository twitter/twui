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

#import "TUITableView+Cell.h"

// Dragged cells should be just above pinned headers
#define kTUITableViewDraggedCellZPosition 1001

@interface TUITableView (CellPrivate)

- (BOOL)_preLayoutCells;
- (void)_layoutSectionHeaders:(BOOL)needLayout;
- (void)_layoutCells:(BOOL)needLayout;

@end

@implementation TUITableView (Cell)

/**
 * @brief Mouse down in a cell
 */
-(void)__mouseDownInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  [self __beginDraggingCell:cell offset:offset location:[[cell superview] localPointForEvent:event]];
}

/**
 * @brief Mouse up in a cell
 */
-(void)__mouseUpInCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  [self __endDraggingCell:cell offset:offset location:[[cell superview] localPointForEvent:event]];
}

/**
 * @brief A cell was dragged
 * 
 * If reordering is permitted by the table, this will begin a move operation.
 */
-(void)__mouseDraggedCell:(TUITableViewCell *)cell offset:(CGPoint)offset event:(NSEvent *)event {
  [self __updateDraggingCell:cell offset:offset location:[[cell superview] localPointForEvent:event]];
}

/**
 * @brief Determine if we're dragging a cell or not
 */
-(BOOL)__isDraggingCell {
  return _dragToReorderCell != nil && _currentDragToReorderIndexPath != nil;
}

/**
 * @brief Begin dragging a cell
 */
-(void)__beginDraggingCell:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
  
  _currentDragToReorderLocation = location;
  _currentDragToReorderMouseOffset = offset;
  
  _dragToReorderCell = cell;
  
  _currentDragToReorderIndexPath = nil;
  _previousDragToReorderIndexPath = nil;
  
}

/**
 * @brief Update cell dragging
 */
-(void)__updateDraggingCell:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
  BOOL animate = TRUE;
  
  // note the location in any event
  _currentDragToReorderLocation = location;
  _currentDragToReorderMouseOffset = offset;
  
  // return if there wasn't a proper drag
  if(![cell didDrag]) return;
  
  // make sure reordering is supported by our data source (this should probably be done only once somewhere)
  if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]){
    return; // reordering is not supported by the data source
  }
  
  // determine if reordering this cell is permitted or not via our data source (this should probably be done only once somewhere)
  if(self.dataSource == nil || ![self.dataSource respondsToSelector:@selector(tableView:canMoveRowAtIndexPath:)] || ![self.dataSource tableView:self canMoveRowAtIndexPath:cell.indexPath]){
    return; // reordering is not permitted
  }
  
  // initialize defaults on the first drag
  if(_currentDragToReorderIndexPath == nil || _previousDragToReorderIndexPath == nil){
    // make sure the dragged cell is on top
    _dragToReorderCell.layer.zPosition = kTUITableViewDraggedCellZPosition;
    // setup index paths
    _currentDragToReorderIndexPath = cell.indexPath;
    _previousDragToReorderIndexPath = cell.indexPath;
    return; // just initialize on the first event
  }
  
  CGRect visible = [self visibleRect];
  // dragged cell destination frame
  CGRect dest = CGRectMake(0, roundf(MAX(visible.origin.y, MIN(visible.origin.y + visible.size.height - cell.frame.size.height, location.y + visible.origin.y - offset.y))), self.bounds.size.width, cell.frame.size.height);
  // bring to front
  [[cell superview] bringSubviewToFront:cell];
  // move the cell
  cell.frame = dest;
  
  // constraint the location to the viewport
  location = CGPointMake(location.x, MAX(0, MIN(visible.size.height, location.y)));
  // scroll content if necessary (scroll view figures out whether it's necessary or not)
  [self beginContinuousScrollForDragAtPoint:location animated:TRUE];
  
  TUITableViewInsertionMethod insertMethod = TUITableViewInsertionMethodAtIndex;
  NSIndexPath *currentPath = nil;
  NSInteger sectionIndex = -1;
  
  // determine the current index path the cell is occupying
  if((currentPath = [self indexPathForRowAtVerticalOffset:location.y + visible.origin.y]) == nil){
    if((sectionIndex = [self indexOfSectionWithHeaderAtVerticalOffset:location.y + visible.origin.y]) > 0){
      if(sectionIndex <= cell.indexPath.section){
        // if we're on a section header (but not the first one, which can't move) which is above the origin
        // index path we insert after the last index in the section above
        NSInteger targetSectionIndex = sectionIndex - 1;
        currentPath = [NSIndexPath indexPathForRow:[self numberOfRowsInSection:targetSectionIndex] - 1 inSection:targetSectionIndex];
        insertMethod = TUITableViewInsertionMethodAfterIndex;
      }else{
        // if we're on a section header below the origin index we insert before the first index in the
        // section below
        NSInteger targetSectionIndex = sectionIndex;
        currentPath = [NSIndexPath indexPathForRow:0 inSection:targetSectionIndex];
        insertMethod = TUITableViewInsertionMethodBeforeIndex;
      }
    }
  }
  
  // make sure we have a valid current path before proceeding
  if(currentPath == nil) return;
  
  // allow the delegate to revise the proposed index path if it wants to
  if(self.delegate != nil && [self.delegate respondsToSelector:@selector(tableView:targetIndexPathForMoveFromRowAtIndexPath:toProposedIndexPath:)]){
    NSIndexPath *proposedPath = currentPath;
    currentPath = [self.delegate tableView:self targetIndexPathForMoveFromRowAtIndexPath:cell.indexPath toProposedIndexPath:currentPath];
    // revised index paths always use the "at" insertion method
    switch([currentPath compare:proposedPath]){
      case NSOrderedAscending:
      case NSOrderedDescending:
        insertMethod = TUITableViewInsertionMethodAtIndex;
        break;
      case NSOrderedSame:
      default:
        // do nothing
        break;
    }
  }
  
  // note the previous path
  _previousDragToReorderIndexPath = _currentDragToReorderIndexPath;
  _previousDragToReorderInsertionMethod = _currentDragToReorderInsertionMethod;
  
  // note the current path
  _currentDragToReorderIndexPath = currentPath;
  _currentDragToReorderInsertionMethod = insertMethod;
  
  // determine the current drag direction
  NSComparisonResult currentDragDirection = (_previousDragToReorderIndexPath != nil) ? [currentPath compare:_previousDragToReorderIndexPath] : NSOrderedSame;
  
  // ordered index paths for enumeration
  NSIndexPath *fromIndexPath = nil;
  NSIndexPath *toIndexPath = nil;
  
  if(currentDragDirection == NSOrderedAscending){
    fromIndexPath = currentPath;
    toIndexPath = _previousDragToReorderIndexPath;
  }else if(currentDragDirection == NSOrderedDescending){
    fromIndexPath = _previousDragToReorderIndexPath;
    toIndexPath = currentPath;
  }else if(insertMethod != _previousDragToReorderInsertionMethod){
    fromIndexPath = currentPath;
    toIndexPath = currentPath;
  }
  
  // we now have the final destination index path.  if it's not nil, update surrounding
  // cells to make room for the dragged cell
  if(currentPath != nil && fromIndexPath != nil && toIndexPath != nil){
    
    // begin animations
    if(animate){
      [TUIView beginAnimations:NSStringFromSelector(_cmd) context:NULL];
    }
    
    // update section headers
    for(NSInteger i = fromIndexPath.section; i <= toIndexPath.section; i++){
      TUIView *headerView;
      if(currentPath.section < i && i <= cell.indexPath.section){
        // the current index path is above this section and this section is at or
        // below the origin index path; shift our header down to make room
        if((headerView = [self headerViewForSection:i]) != nil){
          CGRect frame = [self rectForHeaderOfSection:i];
          headerView.frame = CGRectMake(frame.origin.x, frame.origin.y - cell.frame.size.height, frame.size.width, frame.size.height);
        }
      }else if(currentPath.section >= i && i > cell.indexPath.section){
        // the current index path is at or below this section and this section is
        // below the origin index path; shift our header up to make room
        if((headerView = [self headerViewForSection:i]) != nil){
          CGRect frame = [self rectForHeaderOfSection:i];
          headerView.frame = CGRectMake(frame.origin.x, frame.origin.y + cell.frame.size.height, frame.size.width, frame.size.height);
        }
      }else{
        // restore the header to it's normal position
        if((headerView = [self headerViewForSection:i]) != nil){
          headerView.frame = [self rectForHeaderOfSection:i];
        }
      }
    }
    
    // update rows
    [self enumerateIndexPathsFromIndexPath:fromIndexPath toIndexPath:toIndexPath withOptions:0 usingBlock:^(NSIndexPath *indexPath, BOOL *stop) {
      TUITableViewCell *displacedCell;
      if((displacedCell = [self cellForRowAtIndexPath:indexPath]) != nil && ![displacedCell isEqual:cell]){
        CGRect frame = [self rectForRowAtIndexPath:indexPath];
        CGRect target;
        
        if([indexPath isEqual:currentPath] && insertMethod == TUITableViewInsertionMethodAfterIndex){
          // the visited index path is the current index path and the insertion method is "after";
          // leave the cell where it is, the section header should shift out of the way instead
          target = frame;
        }else if([indexPath isEqual:currentPath] && insertMethod == TUITableViewInsertionMethodBeforeIndex){
          // the visited index path is the current index path and the insertion method is "before";
          // leave the cell where it is, the section header should shift out of the way instead
          target = frame;
        }else if([indexPath compare:currentPath] != NSOrderedAscending && [indexPath compare:cell.indexPath] == NSOrderedAscending){
          // the visited index path is above the origin and below the current index path;
          // shift the cell down by the height of the dragged cell
          target = CGRectMake(frame.origin.x, frame.origin.y - cell.frame.size.height, frame.size.width, frame.size.height);
        }else if([indexPath compare:currentPath] != NSOrderedDescending && [indexPath compare:cell.indexPath] == NSOrderedDescending){
          // the visited index path is below the origin and above the current index path;
          // shift the cell up by the height of the dragged cell
          target = CGRectMake(frame.origin.x, frame.origin.y + cell.frame.size.height, frame.size.width, frame.size.height);
        }else{
          // the visited cell is outside the affected range and should be returned to its
          // normal frame
          target = frame;
        }
        
        // only animate if we actually need to
        if(!CGRectEqualToRect(target, displacedCell.frame)){
          displacedCell.frame = target;
        }
        
      }
    }];
    
    // commit animations
    if(animate){
      [TUIView commitAnimations];
    }
    
  }
  
}

/**
 * @brief Finish dragging a cell
 */
-(void)__endDraggingCell:(TUITableViewCell *)cell offset:(CGPoint)offset location:(CGPoint)location {
  BOOL animate = TRUE;
  
  // cancel our continuous scroll
  [self endContinuousScrollAnimated:TRUE];
  
  // finalize drag to reorder if we have a drag index
  if(_currentDragToReorderIndexPath != nil){
    NSIndexPath *targetIndexPath;
    
    switch(_currentDragToReorderInsertionMethod){
      case TUITableViewInsertionMethodBeforeIndex:
        // insert "before" is equivalent to insert "at" as subsequent indexes are shifted down to
        // accommodate the insert.  the distinction is only useful for presentation.
        targetIndexPath = _currentDragToReorderIndexPath;
        break;
      case TUITableViewInsertionMethodAfterIndex:
        targetIndexPath = [NSIndexPath indexPathForRow:_currentDragToReorderIndexPath.row + 1 inSection:_currentDragToReorderIndexPath.section];
        break;
      case TUITableViewInsertionMethodAtIndex:
      default:
        targetIndexPath = _currentDragToReorderIndexPath;
        break;
    }
    
    // only update the data source if the drag ended on a different index path
    // than it started; otherwise just clean up the view
    if(![targetIndexPath isEqual:cell.indexPath]){
      // notify our data source that the row will be reordered
      if(self.dataSource != nil && [self.dataSource respondsToSelector:@selector(tableView:moveRowAtIndexPath:toIndexPath:)]){
        [self.dataSource tableView:self moveRowAtIndexPath:cell.indexPath toIndexPath:targetIndexPath];
      }
    }
    
    // compute the final cell destination frame
    CGRect frame = [self rectForRowAtIndexPath:_currentDragToReorderIndexPath];
    // adjust if necessary based on the insertion method
    switch(_currentDragToReorderInsertionMethod){
      case TUITableViewInsertionMethodBeforeIndex:
        frame = CGRectMake(frame.origin.x, frame.origin.y + cell.frame.size.height, frame.size.width, frame.size.height);
        break;
      case TUITableViewInsertionMethodAfterIndex:
        frame = CGRectMake(frame.origin.x, frame.origin.y - cell.frame.size.height, frame.size.width, frame.size.height);
        break;
      case TUITableViewInsertionMethodAtIndex:
      default:
        // do nothing. this case is just here to avoid complier complaints...
        break;
    }
    
    // move the cell to its final frame and layout to make sure all the internal caching/geometry
    // stuff is consistent.
    if(animate && !CGRectEqualToRect(cell.frame, frame)){
      // disable user interaction until the animation has completed and the table has reloaded
      [self setUserInteractionEnabled:FALSE];
      [TUIView animateWithDuration:0.2
        animations:^ { cell.frame = frame; }
        completion:^(BOOL finished) {
          // reload the table when we're done (implicitly restores z-position)
          if(finished) [self reloadData];
          // restore user interactivity
          [self setUserInteractionEnabled:TRUE];
        }
      ];
    }else{
      cell.frame = frame;
      cell.layer.zPosition = 0;
      [self reloadData];
    }
    
    // clear state
    _currentDragToReorderIndexPath = nil;
    
  }else{
    cell.layer.zPosition = 0;
  }
  
  _previousDragToReorderIndexPath = nil;
  
  // and clean up
  _dragToReorderCell = nil;
  
  _currentDragToReorderLocation = CGPointZero;
  _currentDragToReorderMouseOffset = CGPointZero;
  
}

@end

