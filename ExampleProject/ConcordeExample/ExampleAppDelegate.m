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

#import "ExampleAppDelegate.h"
#import "ExampleView.h"
#import "ExampleScrollView.h"
#import "ExampleNestedScrollView.h"

@implementation ExampleAppDelegate

- (void)dealloc
{
	[tableViewWindow release];
	[scrollViewWindow release];
	[super dealloc];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	CGRect b = CGRectMake(0, 0, 500, 450);
	
	/** Table View */
	tableViewWindow = [[NSWindow alloc] initWithContentRect:b styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:NO];
	[tableViewWindow setReleasedWhenClosed:FALSE];
	[tableViewWindow setMinSize:NSMakeSize(300, 250)];
	[tableViewWindow center];
	
	/* TUINSView is the bridge between the standard AppKit NSView-based heirarchy and the TUIView-based heirarchy */
	TUINSView *tuiTableViewContainer = [[TUINSView alloc] initWithFrame:b];
	[tableViewWindow setContentView:tuiTableViewContainer];
	[tuiTableViewContainer release];
	
	ExampleView *tableExample = [[ExampleView alloc] initWithFrame:b];
	tuiTableViewContainer.rootView = tableExample;
	[tableExample release];
	
	/** Scroll View */
	scrollViewWindow = [[NSWindow alloc] initWithContentRect:b styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES];
	[scrollViewWindow setReleasedWhenClosed:FALSE];
	[scrollViewWindow setMinSize:NSMakeSize(300, 250)];
	[scrollViewWindow setFrameTopLeftPoint:[tableViewWindow cascadeTopLeftFromPoint:CGPointMake(tableViewWindow.frame.origin.x, tableViewWindow.frame.origin.y + tableViewWindow.frame.size.height)]];
	
	/* TUINSView is the bridge between the standard AppKit NSView-based heirarchy and the TUIView-based heirarchy */
	TUINSView *tuiScrollViewContainer = [[TUINSView alloc] initWithFrame:b];
	[scrollViewWindow setContentView:tuiScrollViewContainer];
	[tuiScrollViewContainer release];
	
	ExampleScrollView *scrollExample = [[ExampleScrollView alloc] initWithFrame:b];
	tuiScrollViewContainer.rootView = scrollExample;
	[scrollExample release];

    /** Scroll View */
	nestedScrollViewWindow = [[NSWindow alloc] initWithContentRect:b styleMask:NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask backing:NSBackingStoreBuffered defer:YES];
	[nestedScrollViewWindow setReleasedWhenClosed:FALSE];
	[nestedScrollViewWindow setMinSize:NSMakeSize(300, 250)];
	[nestedScrollViewWindow setFrameTopLeftPoint:[scrollViewWindow cascadeTopLeftFromPoint:CGPointMake(scrollViewWindow.frame.origin.x, scrollViewWindow.frame.origin.y + scrollViewWindow.frame.size.height)]];
	
	/* TUINSView is the bridge between the standard AppKit NSView-based heirarchy and the TUIView-based heirarchy */
	TUINSView *nestedScrollViewContainer = [[TUINSView alloc] initWithFrame:b];
	[nestedScrollViewWindow setContentView:nestedScrollViewContainer];
	[nestedScrollViewContainer release];

    ExampleNestedScrollView *nestedScrollView = [[ExampleNestedScrollView alloc] initWithFrame:b];
    nestedScrollViewContainer.rootView = nestedScrollView;
    [nestedScrollView release];

	[self showTableViewExampleWindow:nil];
	
}

/**
 * @brief Show the table view example
 */
-(IBAction)showTableViewExampleWindow:(id)sender {
	[tableViewWindow makeKeyAndOrderFront:sender];
}

/**
 * @brief Show the scroll view example
 */
-(IBAction)showScrollViewExampleWindow:(id)sender {
	[scrollViewWindow makeKeyAndOrderFront:sender];
}

/**
 * @brief show the nested sscroll view example
 */

-(IBAction)showNestedScrollViews:(id)sender
{
    [nestedScrollViewWindow makeKeyAndOrderFront:sender];
}

@end
