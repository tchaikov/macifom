//
//  NESApplicationController.h
//  Macifom
//
//  Created by Auston Stewart on 9/7/08.
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
	CFDictionaryRef _fullScreenMode;
	
	NSMutableDictionary *_currentInstruction;
	
	IBOutlet NESPlayfieldView *playfieldView;
	IBOutlet NSTextField *peekField;
	IBOutlet NSTextField *peekLabel;
	IBOutlet NSTextField *pokeField;
	IBOutlet NSWindow *debuggerWindow;
	IBOutlet NSMenuItem *playPauseMenuItem;
	
	BOOL debuggerIsVisible;
	BOOL gameIsLoaded;
}

- (IBAction)play:(id)sender;
- (IBAction)run:(id)sender;
- (IBAction)setBreak:(id)sender;
- (IBAction)runUntilBreak:(id)sender;
- (IBAction)loadROM:(id)sender;
- (IBAction)resetCPU:(id)sender;
- (IBAction)advanceFrame:(id)sender;
- (IBAction)step:(id)sender;
- (IBAction)peek:(id)sender;
- (IBAction)poke:(id)sender;
- (IBAction)showAndHideDebugger:(id)sender;
- (IBAction)toggleFullScreenMode:(id)sender;
- (BOOL)gameIsLoaded;
- (void)setGameIsLoaded:(BOOL)flag;
- (void)updatecpuRegisters;
- (NSDictionary *)cpuRegisters;
- (void)setCpuRegisters:(NSDictionary *)newRegisters;
- (void)updateInstructions;
- (NSArray *)instructions;
- (void)setInstructions:(NSArray *)newInstructions;

@end
