//
//  TUIHostView.h
//  TwUI
//
//  Created by Justin Spahr-Summers on 17.07.12.
//
//  Portions of this code were taken from Velvet,
//  which is copyright (c) 2012 Bitswift, Inc.
//  See LICENSE.txt for more information.
//

#import <Foundation/Foundation.h>
#import "TUIBridgedView.h"

/**
 * Represents a view that can host views of other types (i.e., can bridge across
 * UI frameworks).
 */
@protocol TUIHostView <TUIBridgedView>
@required

/**
 * The view hosted by the receiver.
 *
 * Implementing classes may require that this property be of a more specific
 * type.
 *
 * When this property is set, the given view's [TUIBridgedView hostView]
 * property should automatically be set to the receiver.
 */
@property (nonatomic, strong) id<TUIBridgedView> rootView;

@end
