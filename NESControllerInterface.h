//
//  NESControllerInterface.h
//  Macifom
//
//  Created by Auston Stewart on 8/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include <IOKit/hid/IOHIDLib.h>

typedef enum {
	
	NESControllerButtonUp = 0,
	NESControllerButtonDown,
	NESControllerButtonLeft,
	NESControllerButtonRight,
	NESControllerButtonSelect,
	NESControllerButtonStart,
	NESControllerButtonA,
	NESControllerButtonB
} NESControllerButton;

@class NESKeyboardResponder;

@interface NESControllerInterface : NSObject {

	NSMutableArray *_controllerMappings;
	NSMutableArray *_inputDevices;
	NSMutableArray *_activeDevices;
	NSMutableArray *_knownDevices;
	IOHIDManagerRef gIOHIDManagerRef;
	
	uint_fast32_t *_controllers;
	
	IBOutlet NSWindow *propertiesWindow;
	IBOutlet NESKeyboardResponder *keyboardResponder;
	IBOutlet NSTableView *mappingTable;
	IBOutlet NSArrayController *mappingController;
	IBOutlet NSArrayController *controllerOneDeviceController;
	IBOutlet NSArrayController *controllerTwoDeviceController;
	
	NSNumber *_setMappingForController;
	NESControllerButton _setMappingForButton;
	NSUInteger _initialControllerOneDeviceIndex;
	NSUInteger _initialControllerTwoDeviceIndex;
	BOOL _listenForButton;
}

- (uint_fast32_t)readController:(int)index;
- (void)keyboardKey:(unsigned short)keyCode changedTo:(BOOL)state;
- (void)setButton:(NESControllerButton)button forController:(int)index withBool:(BOOL)flag;
- (void)startListeningForMapping:(id)sender;
- (void)stopListeningForMapping:(id)sender;
- (BOOL)listenForButton;
- (void)mapDevice:(NSMutableDictionary *)device button:(NESControllerButton)button toKeyCode:(NSNumber *)keyCode;
- (NSMutableDictionary *)_activeDeviceForController:(NSNumber *)controller;

@property (retain) NSMutableArray *controllerMappings;
@property (retain) NSMutableArray *inputDevices;
@property (retain) NSMutableArray *activeDevices;
@property (readonly) NSNumber *setMappingForController;
@property (readonly) NESControllerButton setMappingForButton;

@end
