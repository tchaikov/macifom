//
//  NESPlayfieldView.h
//  Macifom
//
//  Created by Auston Stewart on 9/7/08.
//  Copyright 2008 Apple, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface NESPlayfieldView : NSView {

	uint_fast32_t *_videoBuffer;
	CGDataProviderRef _provider;
	CGColorSpaceRef _colorSpace;
	
	uint_fast32_t _controller1;
	uint_fast32_t _controller2;
}

- (uint_fast32_t *)videoBuffer;
- (uint_fast32_t)readController1;

@end
