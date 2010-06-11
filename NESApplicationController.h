/* NESApplicationController.h
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

#import <Cocoa/Cocoa.h>

@class NESPlayfieldView;
@class NES6502Interpreter;
@class NESAPUEmulator;
@class NESPPUEmulator;
@class NESCartridgeEmulator;

@interface NESApplicationController : NSObject {

	uint_fast32_t ppuCyclesInLastFrame;
	int timingSequenceIndex;
	double lastTimingCorrection;
	NES6502Interpreter *cpuInterpreter;
	NESAPUEmulator *apuEmulator;
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
