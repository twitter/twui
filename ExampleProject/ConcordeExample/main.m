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

#import <Cocoa/Cocoa.h>
#import "TUIKit.h"

/*
 Notes:
 In your project, add NS_BUILD_32_LIKE_64 to your preprocessor flags
 */

int main(int argc, char *argv[])
{
	SInt32 major = 0;
	SInt32 minor = 0;
	Gestalt(gestaltSystemVersionMajor, &major);
	Gestalt(gestaltSystemVersionMinor, &minor);
	if((major == 10 && minor >= 7) || major >= 11) {
		AtLeastLion = YES;
	}

	return NSApplicationMain(argc, (const char **)argv);
}
