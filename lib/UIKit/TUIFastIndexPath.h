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

#import <Foundation/Foundation.h>

#ifndef TUIFastIndexPath_DANGEROUS_ISEQUAL
// maybe default this to 0?
#define TUIFastIndexPath_DANGEROUS_ISEQUAL 1
#endif

#define TUIFastIndexPathFromNSIndexPath(indexPath)  (((indexPath) != nil) ? [TUIFastIndexPath indexPathForRow:(indexPath).row inSection:(indexPath).section] : nil)
#define NSIndexPathFromTUIFastIndexPath(indexPath)  (((indexPath) != nil) ? [NSIndexPath indexPathForRow:(indexPath).row inSection:(indexPath).section] : nil)

/**
 Note TUITableView uses this extensively, if you use want to use NSIndexPath to talk to table views you should turn TUIFastIndexPath_DANGEROUS_ISEQUAL to 0
 */
@interface TUIFastIndexPath : NSObject <NSCopying, NSCoding> // only supports 2-index sec/row, fast versions of -hash, -isEqual, etc
{
@public
	NSUInteger section;
	NSUInteger row;
}

+ (TUIFastIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section;

// duck type to NSIndexPath
@property(nonatomic, readonly) NSUInteger section;
@property(nonatomic, readonly) NSUInteger row;

- (NSComparisonResult)compare:(TUIFastIndexPath *)i;
- (BOOL)isEqual:(TUIFastIndexPath *)i;


@end
