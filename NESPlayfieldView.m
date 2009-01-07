//
//  NESPlayfieldView.m
//  Macifom
//
//  Created by Auston Stewart on 9/7/08.
//  Copyright 2008 Apple, Inc.. All rights reserved.
//

#import "NESPlayfieldView.h"


@implementation NESPlayfieldView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
		
        _videoBuffer = [[NSBitmapImageRep alloc] initWithBitmapDataPlanes:NULL pixelsWide:256 pixelsHigh:240 bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:YES colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
    }
    return self;
}

- (void)dealloc {

	[_videoBuffer release];
	
	[super dealloc];
}

/*
- (BOOL)isFlipped {

	return YES;
}
 */

- (NSBitmapImageRep *)videoBuffer
{
	return _videoBuffer;
}

- (void)drawRect:(NSRect)rect {
    
	// FIXME: Maybe I should get the bounds instead in the event of a partial redraw?
	[_videoBuffer drawInRect:rect];
}

@end
