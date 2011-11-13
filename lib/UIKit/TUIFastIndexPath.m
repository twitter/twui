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

#import "TUIFastIndexPath.h"

/**
 Twitter for Mac timelines only use 1-section table views, with <1000 tweets in a list at a time
 This pre-allocated hunk of instances is all we ever really need to touch.  Was a measurable win for us.
 */
#define CACHE_COMMON_INDEX_PATHS 1024

static struct TUIFastIndexPath_staticStruct {
	Class isa;
	NSInteger section;
	NSInteger row;
} CommonIndexPaths[CACHE_COMMON_INDEX_PATHS];

@interface TUIFastIndexPath_staticClass : TUIFastIndexPath
@end

@implementation TUIFastIndexPath_staticClass
@end

@implementation TUIFastIndexPath

+ (void)initialize
{
	if(self == [TUIFastIndexPath class]) {
		Class staticCls = [TUIFastIndexPath_staticClass class];
		for(int i = 0; i < CACHE_COMMON_INDEX_PATHS; ++i) {
			struct TUIFastIndexPath_staticStruct *f = &CommonIndexPaths[i];
			f->isa = staticCls;
			f->section = 0;
			f->row = i;
		}
	}
}

+ (TUIFastIndexPath *)indexPathForRow:(NSUInteger)row inSection:(NSUInteger)section
{
	if(section == 0) {
		if(row < CACHE_COMMON_INDEX_PATHS) {
			return (__bridge TUIFastIndexPath *)&CommonIndexPaths[row];
		}
	}
	
	// actually have to make one
	TUIFastIndexPath *f = [[TUIFastIndexPath alloc] init];
	f->row = row;
	f->section = section;
	return f;
}

- (id)copyWithZone:(NSZone *)zone
{
	return self;  // change me if we ever do mutable index paths
}

- (id)initWithCoder:(NSCoder *)coder
{
	self = [self init];
	section = [coder decodeIntegerForKey:@"s"];
	row = [coder decodeIntegerForKey:@"r"];
	return self;
}

- (void)encodeWithCoder:(NSCoder *)coder
{
	[coder encodeInteger:section forKey:@"s"];
	[coder encodeInteger:row forKey:@"r"];
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"[%d,%d]", section, row];
}

- (NSUInteger)section
{
	return section;
}

- (NSUInteger)row
{
	return row;
}

- (NSUInteger)hash
{
	return ((section << 28) ^ row); // assume we're going to have a lot more rows than sections
}

- (NSComparisonResult)compare:(TUIFastIndexPath *)i
{
	NSUInteger s = i->section;
	NSUInteger r = i->row;
	if(section < s)
		return NSOrderedAscending;
	if(section > s)
		return NSOrderedDescending;
	if(row < r)
		return NSOrderedAscending;
	if(row > r)
		return NSOrderedDescending;
	return NSOrderedSame;
}

- (BOOL)isEqual:(TUIFastIndexPath *)i
{
	if(!i)
		return NO;
#if TUIFastIndexPath_DANGEROUS_ISEQUAL
	return ((row == i->row) && (section == i->section)); // assume it's a TUIFastIndexPath - this may be stupid for your app
#else
	if([i isKindOfClass:[TUIFastIndexPath class]]
	   return ((row == i->row) && (section == i->section));
	else if([i isKindOfClass:[NSIndexPath class]]) // we never hit this in T2
	   return ((row == i.row) && (section == i.section));
	else
	   return NO;
#endif
}

@end
