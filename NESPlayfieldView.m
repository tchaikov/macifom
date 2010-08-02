/* NESPlayfieldView.h
 * 
 * Copyright (c) 2010 Auston Stewart
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#import "NESPlayfieldView.h"

void VideoBufferProviderReleaseData(void *info, const void *data, size_t size)
{
	free((void *)data);
}

static void GamePadValueChanged(void *context, IOReturn result, void *sender, IOHIDValueRef value)
{
	IOHIDElementRef element;
	CFIndex logicalValue;
	IOHIDElementCookie cookie;
	NESPlayfieldView *playfield = (NESPlayfieldView *)context;
	element = IOHIDValueGetElement(value);
	cookie = IOHIDElementGetCookie(element);
    logicalValue = IOHIDValueGetIntegerValue(value);
	
	// FIXME: These are hard-coded values for my Logitec Precision Gamepad
	switch ((uint32_t)cookie) {
			
		case 0x3:
			// Mapping to B button
			[playfield setButton:NESControllerButtonB forController:0 withBool:logicalValue ? YES : NO];
			break;
		case 0x4:
			// Mapping to A button
			[playfield setButton:NESControllerButtonA forController:0 withBool:logicalValue ? YES : NO];
			break;
		case 0xB:
			// Mapping to Select button
			[playfield setButton:NESControllerButtonSelect forController:0 withBool:logicalValue ? YES : NO];
			break;
		case 0xC:
			// Mapping to Start button
			[playfield setButton:NESControllerButtonStart forController:0 withBool:logicalValue ? YES : NO];
			break;
		case 0xF:
			// Mapping to Y Axis (Up/Down)
			if (logicalValue == 1) {
				
				[playfield setButton:NESControllerButtonUp forController:0 withBool:YES];
			}
			else if (logicalValue == 255) {
				
				[playfield setButton:NESControllerButtonDown forController:0 withBool:YES];
			}
			else {
				
				[playfield setButton:NESControllerButtonUp forController:0 withBool:NO];
				[playfield setButton:NESControllerButtonDown forController:0 withBool:NO];
			}
			break;
		case 0xE:
			// Mapping to X Axis (Left/Right)
			if (logicalValue == 1) {
				
				[playfield setButton:NESControllerButtonLeft forController:0 withBool:YES];
			}
			else if (logicalValue == 255) {
				
				[playfield setButton:NESControllerButtonRight forController:0 withBool:YES];
			}
			else {
				
				[playfield setButton:NESControllerButtonLeft forController:0 withBool:NO];
				[playfield setButton:NESControllerButtonRight forController:0 withBool:NO];
			}
			break;
		default:
			break;
	}
	
	// NSLog(@"In GamePadValueChanged: 0x%8.8x changed to %ld.",cookie,logicalValue);
}

// function to create matching dictionary
static CFMutableDictionaryRef hu_CreateDeviceMatchingDictionary(UInt32 inUsagePage, UInt32 inUsage)
{
    // create a dictionary to add usage page/usages to
    CFMutableDictionaryRef result = CFDictionaryCreateMutable(
															  kCFAllocatorDefault, 0, &kCFTypeDictionaryKeyCallBacks, &kCFTypeDictionaryValueCallBacks);
    if (result) {
        if (inUsagePage) {
            // Add key for device type to refine the matching dictionary.
            CFNumberRef pageCFNumberRef = CFNumberCreate(
														 kCFAllocatorDefault, kCFNumberIntType, &inUsagePage);
            if (pageCFNumberRef) {
                CFDictionarySetValue(result,
									 CFSTR(kIOHIDDeviceUsagePageKey), pageCFNumberRef);
                CFRelease(pageCFNumberRef);
				
                // note: the usage is only valid if the usage page is also defined
                if (inUsage) {
                    CFNumberRef usageCFNumberRef = CFNumberCreate(
																  kCFAllocatorDefault, kCFNumberIntType, &inUsage);
                    if (usageCFNumberRef) {
                        CFDictionarySetValue(result,
											 CFSTR(kIOHIDDeviceUsageKey), usageCFNumberRef);
                        CFRelease(usageCFNumberRef);
                    } else {
                        fprintf(stderr, "%s: CFNumberCreate(usage) failed.", __PRETTY_FUNCTION__);
                    }
                }
            } else {
                fprintf(stderr, "%s: CFNumberCreate(usage page) failed.", __PRETTY_FUNCTION__);
            }
        }
    } else {
        fprintf(stderr, "%s: CFDictionaryCreateMutable failed.", __PRETTY_FUNCTION__);
    }
    return result;
}   // hu_CreateDeviceMatchingDictionary

@implementation NESPlayfieldView

- (id)initWithFrame:(NSRect)frame {
    
	CMProfileRef profile;
	CFMutableArrayRef matchingCFArrayRef;
	IOReturn tIOReturn;
	CFSetRef tCFSetRef;
	CFIndex numMatchedDevices;
	void **usbHidDevices;
	
	self = [super initWithFrame:frame];
    
	if (self) {
		
		_videoBuffer = (uint_fast32_t *)malloc(sizeof(uint_fast32_t)*256*240);
		_provider = CGDataProviderCreateWithData(NULL, _videoBuffer, sizeof(uint_fast32_t)*256*240,VideoBufferProviderReleaseData);
		_controllers = (uint_fast32_t *)malloc(sizeof(uint_fast32_t)*2);
		_controllers[0] = 0x0001FF00; // Should indicate one controller on $4016 per nestech.txt
		_controllers[1] = 0x0002FF00; // Should indicate one controller on $4017 per nestech.txt
		_windowedRect.origin.x = 0;
		_windowedRect.origin.y = 0;
		_fullScreenRect.size.width = _windowedRect.size.width = 256;
		_fullScreenRect.size.height =_windowedRect.size.height = 240;
		_fullScreenRect.origin.y = 0;
		_fullScreenRect.origin.x = 32;
		_scale = 1;
		screenRect = &_windowedRect;
		
		// There are reports that this can return fnf on Leopard, investigating...
		if (CMGetSystemProfile(&profile) == noErr) { 
			_colorSpace = CGColorSpaceCreateWithPlatformColorSpace(profile); 
			CMCloseProfile(profile); 
			NSLog(@"Obtained System colorspace. CG rendering will follow the fast path.");
		} 
		else _colorSpace = CGColorSpaceCreateDeviceRGB();
		
		[[self window] useOptimizedDrawing:YES]; // Use optimized drawing in window as there are no overlapping subviews
	
		// Enumerate any attached USB joysticks and gamepads
		gIOHIDManagerRef = IOHIDManagerCreate(kCFAllocatorDefault,kIOHIDOptionsTypeNone);
		// create an array of matching dictionaries
		matchingCFArrayRef = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
		if (matchingCFArrayRef) {
			// create a device matching dictionary for joysticks
			CFDictionaryRef matchingCFDictRef =
			hu_CreateDeviceMatchingDictionary(kHIDPage_GenericDesktop, kHIDUsage_GD_Joystick);
			if (matchingCFDictRef) {
				// add it to the matching array
				CFArrayAppendValue(matchingCFArrayRef, matchingCFDictRef);
				CFRelease(matchingCFDictRef); // and release it
			} else {
				NSLog(@"hu_CreateDeviceMatchingDictionary(joystick) failed.");
			}
			
			// create a device matching dictionary for game pads
			matchingCFDictRef = hu_CreateDeviceMatchingDictionary(kHIDPage_GenericDesktop, kHIDUsage_GD_GamePad);
			if (matchingCFDictRef) {
				// add it to the matching array
				CFArrayAppendValue(matchingCFArrayRef, matchingCFDictRef);
				CFRelease(matchingCFDictRef); // and release it
			} else {
				NSLog(@"hu_CreateDeviceMatchingDictionary(game pad) failed.");
			}
		} else {
			NSLog(@"CFArrayCreateMutable failed.");
		}
		// set the HID device matching array
		IOHIDManagerSetDeviceMatchingMultiple(gIOHIDManagerRef, matchingCFArrayRef);
		
		// and then release it
		CFRelease(matchingCFArrayRef);
		
		// Schedule the HID Manager in the current runloop to allow for callbacks
		IOHIDManagerScheduleWithRunLoop(gIOHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
		
		// Open up the HID Manager
		tIOReturn = IOHIDManagerOpen(gIOHIDManagerRef, kIOHIDOptionsTypeNone);
		
		// Get the matched devices
		tCFSetRef = IOHIDManagerCopyDevices(gIOHIDManagerRef);
		if (tCFSetRef) {
			
			numMatchedDevices = CFSetGetCount(tCFSetRef);
			if (numMatchedDevices) {
			
				usbHidDevices = (void **)malloc(sizeof(void*)*numMatchedDevices);
				CFSetGetValues(tCFSetRef,(const void **)usbHidDevices);
				IOHIDDeviceRegisterInputValueCallback((IOHIDDeviceRef)usbHidDevices[0],GamePadValueChanged,self); // FIXME: I shouldn't just take the first device, we need full configuration here
			}
			else NSLog(@"No matching USB HID devices were found!");
		}
		else NSLog(@"No matching USB HID devices were found!");
	}
	
    return self;
}

- (void)dealloc {

	// Clean up HID Manager data
	IOHIDManagerUnscheduleFromRunLoop(gIOHIDManagerRef, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
	IOHIDManagerClose(gIOHIDManagerRef, kIOHIDOptionsTypeNone);
	CFRelease(gIOHIDManagerRef);
	
	// Clean up CG data
	CGColorSpaceRelease(_colorSpace); // Toss the color space.
	CGDataProviderRelease(_provider);
	
	[super dealloc];
}

- (BOOL)acceptsFirstResponder
{
    return YES;
}

- (void)setButton:(NESControllerButton)button forController:(int)index withBool:(BOOL)flag
{	
	switch (button) {
			
		case NESControllerButtonUp:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFFCF; // FIXME: Currently, we clear up and down to prevent errors. Perhaps I should clear all directions?
				_controllers[index] |= 0x10; // Up
			}
			else {
				_controllers[index] &= 0xFFFFFFEF; // Clear up
			}
			break;
		case NESControllerButtonLeft:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFF3F; // Clear left and right to prevent errors
				_controllers[index] |= 0x40; // Left
			}
			else {
				_controllers[index] &= 0xFFFFFFBF;
			}
			break;
		case NESControllerButtonDown:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFFCF;
				_controllers[index] |= 0x20; // Down
			}
			else {
				_controllers[index] &= 0xFFFFFFDF;
			}
			break;
		case NESControllerButtonRight:
			if (flag) {
				
				_controllers[index] &= 0xFFFFFF3F;
				_controllers[index] |= 0x80; // Right
			}
			else {
				_controllers[index] &= 0xFFFFFF7F;
			}
			break;
		case NESControllerButtonA:
			if (flag) {
				
				_controllers[index] |= 0x1; // A button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFFE; // A button release
			}
			break;
		case NESControllerButtonB:
			if (flag) {
				
				_controllers[index] |= 0x2; // B button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFFD; // B button release
			}
			break;
		case NESControllerButtonSelect:
			if (flag) {
				
				_controllers[index] |= 0x4; // Select button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFFB; // Select button fire
			}
			break;
		case NESControllerButtonStart:
			if (flag) {
				
				_controllers[index] |= 0x8; // Start button fire
			}
			else {
				_controllers[index] &= 0xFFFFFFF7; // Start button fire
			}
			break;
		default:
			break;
	}
}

- (void)keyboardKey:(char)key changedTo:(BOOL)flag
{
	// FIXME: This will be subject to user configuration shortly
	switch (key) {
			
		case 'w':
			[self setButton:NESControllerButtonUp forController:0 withBool:flag];
			break;
		case 'a':
			[self setButton:NESControllerButtonLeft forController:0 withBool:flag];
			break;
		case 's':
			[self setButton:NESControllerButtonDown forController:0 withBool:flag];
			break;
		case 'd':
			[self setButton:NESControllerButtonRight forController:0 withBool:flag];
			break;
		case 'l':
			[self setButton:NESControllerButtonA forController:0 withBool:flag];
			break;
		case 'k':
			[self setButton:NESControllerButtonB forController:0 withBool:flag];
			break;
		case 'g':
			[self setButton:NESControllerButtonSelect forController:0 withBool:flag];
			break;
		case 'h':
			[self setButton:NESControllerButtonStart forController:0 withBool:flag];
			break;
		default:
			break;
	}
}

- (void)keyDown:(NSEvent *)theEvent
{
	NSString *keysHit = [theEvent characters];
	
	if ([keysHit length] < 1) return;
	
	[self keyboardKey:[keysHit characterAtIndex:0] changedTo:YES];
}

- (void)keyUp:(NSEvent *)theEvent
{
	NSString *keysHit = [theEvent characters];
	
	if ([keysHit length] < 1) return;
	
	[self keyboardKey:[keysHit characterAtIndex:0] changedTo:NO];
}

- (uint_fast32_t)readController1
{	
	return _controllers[0];
}

- (uint_fast32_t)readController:(int)index
{
	return _controllers[index];
}

- (uint_fast32_t *)videoBuffer
{
	return _videoBuffer;
}

- (void)scaleForFullScreenDrawing
{
	_scale = 2;
	screenRect = &_fullScreenRect;
	
	// Set the preferred backing store to the card to get on the Quartz GL path
	[[self window] setPreferredBackingLocation:NSWindowBackingLocationVideoMemory];
	
	// Default background for the window appears to be white
	[[self window] setBackgroundColor:[NSColor blackColor]];
}

- (void)scaleForWindowedDrawing
{
	_scale = 1;
	screenRect = &_windowedRect;
	
	[[self window] makeFirstResponder:self];
}

- (void)drawRect:(NSRect)rect {
    
	CGContextRef context = [[NSGraphicsContext currentContext] graphicsPort]; // Obtain graphics port from the window
	CGImageRef screen = CGImageCreate(256, 240, 8, 32, 4 * 256, _colorSpace, kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host, _provider, NULL, false, kCGRenderingIntentDefault); // Create an image optimized for ARGB32.
	
	CGContextSetInterpolationQuality(context, kCGInterpolationNone);
	CGContextSetShouldAntialias(context, false);
	CGContextScaleCTM(context, _scale, _scale);
	CGContextDrawImage(context, *screenRect, screen); // All that work just to blit.
	CGImageRelease(screen); // Then toss the image.
}

@end
