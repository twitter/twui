//
//  TUINSImage.h
//  TwUI
//
//  A TUIImage subclass backed by an NSImage as it's first-priority data store instead of a CGImageRef
//  Intended for better support of multi-resolution images (i.e. PDF or @2x image resource files for Retina Display)
//  Created by Sasmito Adibowo on 07-08-12.
//
//

#import "TUIImage.h"

@interface TUINSImage : TUIImage

- (TUINSImage *)initWithNSImageNoCopy:(NSImage *)image;
+ (TUINSImage *)imageWithNSImage:(NSImage *)image;
+ (TUINSImage *)imageNamed:(NSString *)name cache:(BOOL)shouldCache;
+ (TUINSImage *)imageWithData:(NSData *)data;

@end


@interface TUINSImage (AppKit)
@property (nonatomic, readonly) id nsImage; // NSImage *
@end
