//
//  TUINSImage.m
//  TwUI
//
//  Created by Sasmito Adibowo on 07-08-12.
//
//

#import "TUINSImage.h"


#if !__has_feature(objc_arc)
#error Need automatic reference counting to compile this.
#endif
 

@implementation TUINSImage {
    NSImage* _backingImage;
}

-(void)dealloc
{

}

- (TUINSImage *)initWithNSImageNoCopy:(NSImage *)image
{
    if ((self = [super init])) {
        _backingImage = image;
    }
    return self;
}


- (id)initWithCGImage:(CGImageRef)imageRef
{
	if((self = [super initWithCGImage:imageRef])) {
        if (imageRef) {
            _backingImage = [[NSImage alloc] initWithCGImage:imageRef size:NSZeroSize];
        }
    }
	return self;
}



+ (TUINSImage *)imageWithNSImage:(NSImage *)image
{
    return [[self alloc] initWithNSImageNoCopy:[image copy]];
}


+ (TUINSImage *)imageNamed:(NSString *)name cache:(BOOL)shouldCache
{
    if(!name)
		return nil;

    static NSMutableDictionary *cache = nil;
	if(!cache && shouldCache) {
		cache = [[NSMutableDictionary alloc] init];
	}
	
	TUINSImage *image = [cache objectForKey:name];
	if(image) {
		return image;
    }
    
    NSImage* backingImage = [NSImage imageNamed:name];
    if (backingImage) {
        image = [[self alloc] initWithNSImageNoCopy:backingImage];
        if (shouldCache) {
            [cache setObject:image forKey:name];
        }
    }
	
	return image;
}


+ (TUINSImage *)imageWithData:(NSData *)data
{
    NSImage* backingImage = [[NSImage alloc] initWithData:data];
    if (backingImage) {
        return [[[self class] alloc] initWithNSImageNoCopy:backingImage];
    }
    return nil;
}


- (CGSize)size
{
	return [_backingImage size];
}


- (CGImageRef)CGImage
{
    if(!_imageRef) {
        _imageRef = [_backingImage CGImageForProposedRect:NULL context:NULL hints:nil];
        if(_imageRef) {
            CGImageRetain(_imageRef);
        }
    }
	return _imageRef;
}


@end



@implementation TUINSImage (AppKit)

- (id)nsImage
{
    // follow the convention of TUIImage that creates a new instance of NSImage.
	return [_backingImage copy];
}

@end

