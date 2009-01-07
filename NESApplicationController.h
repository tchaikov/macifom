//
//  NESApplicationController.h
//  Macifom
//
//  Created by Auston Stewart on 9/7/08.
//  Copyright 2008 Apple, Inc.. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NESPlayfieldView;
@class NES6502Interpreter;
@class NESPPUEmulator;
@class NESCartridgeEmulator;

@interface NESApplicationController : NSObject {

	uint_fast32_t ppuCyclesInLastFrame;
	NES6502Interpreter *cpuInterpreter;
	NESPPUEmulator *ppuEmulator;
	NESCartridgeEmulator *cartEmulator;
	NSArray *instructions;
	NSDictionary *cpuRegisters;
	NSTimer *gameTimer;
	
	NSMutableDictionary *_currentInstruction;
	
	IBOutlet NESPlayfieldView *playfieldView;
	IBOutlet NSTextField *peekField;
	IBOutlet NSTextField *peekLabel;
	IBOutlet NSTextField *pokeField;
}

- (IBAction)play:(id)sender;
- (IBAction)pause:(id)sender;
- (IBAction)run:(id)sender;
- (IBAction)setBreak:(id)sender;
- (IBAction)runUntilBreak:(id)sender;
- (IBAction)loadROM:(id)sender;
- (IBAction)resetCPU:(id)sender;
- (IBAction)advanceFrame:(id)sender;
- (IBAction)step:(id)sender;
- (IBAction)peek:(id)sender;
- (IBAction)poke:(id)sender;
- (IBAction)displayBackgroundTiles:(id)sender;
- (void)updatecpuRegisters;
- (NSDictionary *)cpuRegisters;
- (void)setCpuRegisters:(NSDictionary *)newRegisters;
- (void)updateInstructions;
- (NSArray *)instructions;
- (void)setInstructions:(NSArray *)newInstructions;

@end
