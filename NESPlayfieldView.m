//
//  NESPlayfieldView.m
//  Macifom
//
//  Created by Auston Stewart on 9/7/08.
//  Copyright 2008 Apple, Inc.. All rights reserved.
//

#import "NESPlayfieldView.h"

void VideoBufferProviderReleaseData(void *info, const void *data, size_t size)
{
	free((void *)data);
}

@implementation NESPlayfieldView

- (id)initWithFrame:(NSRect)frame {
    
	CMProfileRef profile;
	self = [super initWithFrame:frame];
    
	if (self) {
		
		_videoBuffer = (uint_fast32_t *)malloc(sizeof(uint_fast32_t)*256*240);
		_provider = CGDataProviderCreateWithData(NULL, _videoBuffer, sizeof(uint_fast32_t)*256*240,VideoBufferProviderReleaseData);
		_controller1 = 0x0001FF00; // Should indicate one controller on $4016 per nestech.txt
		_controller2 = 0x0002FF00; // Should indicate one controller on $4017 per nestech.txt
		
		// There are reports that this can return fnf on Leopard, investigating...
		if (CMGetSystemProfile(&profile) == noErr) { 
			_colorSpace = CGColorSpaceCreateWithPlatformColorSpace(profile); 
			CMCloseProfile(profile); 
			NSLog(@"Obtained System colorspace. CG rendering will follow the fast path.");
		} 
		else _colorSpace = CGColorSpaceCreateDeviceRGB();
	}
	
    return self;
}

- (void)dealloc {

	CGColorSpaceRelease(_colorSpace); // Toss the color space.
	CGDataProviderRelease(_provider);
	
	[super dealloc];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSString *keysHit = [theEvent characters];
	
	if ([keysHit length] < 1) return;
	
	switch ([keysHit characterAtIndex:0]) {
	
		case 'w':
			_controller1 &= 0xFFFFFFCF; // FIXME: Currently, we clear up and down to prevent errors. Perhaps I should clear all directions?
			_controller1 |= 0x10; // Up
			break;
		case 'a':
			_controller1 &= 0xFFFFFF3F; // Clear left and right to prevent errors
			_controller1 |= 0x40; // Left
			break;
		case 's':
			_controller1 &= 0xFFFFFFCF;
			_controller1 |= 0x20; // Down
			break;
		case 'd':
			_controller1 &= 0xFFFFFF3F;
			_controller1 |= 0x80; // Right
			break;
		case 'k':
			_controller1 |= 0x1; // A button fire
			break;
		case 'l':
			_controller1 |= 0x2; // B button fire
			break;
		case 'g':
			_controller1 |= 0x4; // Select button fire
			break;
		case 'h':
			_controller1 |= 0x8; // Start button fire
			break;
	}
}

- (void)keyUp:(NSEvent *)theEvent
{
	NSString *keysHit = [theEvent characters];
	
	if ([keysHit length] < 1) return;
	
	switch ([keysHit characterAtIndex:0]) {
			
		case 'w':
			_controller1 &= 0xFFFFFFEF; // Clear up
			break;
		case 'a':
			_controller1 &= 0xFFFFFFBF; // Clear left
			break;
		case 's':
			_controller1 &= 0xFFFFFFDF; // Clear down
			break;
		case 'd':
			_controller1 &= 0xFFFFFF7F; // Clear right
			break;
		case 'k':
			_controller1 &= 0xFFFFFFFE; // A button release
			break;
		case 'l':
			_controller1 &= 0xFFFFFFFD; // B button release
			break;
		case 'g':
			_controller1 &= 0xFFFFFFFB; // Select button release
			break;
		case 'h':
			_controller1 &= 0xFFFFFFF7; // Start button release
			break;
	}
}

- (uint_fast32_t)readController1
{	
	return _controller1;
}

- (uint_fast32_t *)videoBuffer
{
	return _videoBuffer;
}

- (void)drawRect:(NSRect)rect {
    
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort]; // Obtain graphics port from the window
	CGImageRef screen = CGImageCreate(256, 240, 8, 32, 4 * 256, _colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host, _provider, NULL, false, kCGRenderingIntentDefault); // Create an image optimized for ARGB32.
	CGRect screenRect = NSRectToCGRect(rect); // This is just a typecast, I could probably do this myself.
	
	CGContextDrawImage(context, screenRect, screen); // All that work just to blit.

	CGImageRelease(screen); // Then toss the image.
}

@end
