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

#import "ABActiveRange.h"

@implementation ABFlavoredRange

@synthesize rangeValue;

+ (id)valueWithRange:(NSRange)r
{
	ABFlavoredRange *f = [[ABFlavoredRange alloc] init];
	f.rangeValue = r;
	return f;
}


- (id)copyWithZone:(NSZone *)zone
{
	return self; // these are immutable after creation
}

- (NSString *)description
{
	return [NSString stringWithFormat:@"<ABFlavoredRange %d %@ (%@)>", rangeFlavor, NSStringFromRange(rangeValue), displayString];
}

- (ABActiveTextRangeFlavor)rangeFlavor
{
	return rangeFlavor;
}

- (void)setRangeFlavor:(ABActiveTextRangeFlavor)f
{
	rangeFlavor = f;
}

- (NSString *)displayString
{
	return displayString;
}

- (void)setDisplayString:(NSString *)s
{
	displayString = [s copy];
}

@end
