/* NESApplicationController.m
 * 
 * Copyright (c) 2009 Auston Stewart
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

#import "NESApplicationController.h"
#import "NESPlayfieldView.h"
#import "NESPPUEmulator.h"
#import "NESCartridgeEmulator.h"
#import "NES6502Interpreter.h"

static const char *instructionNames[256] = { "BRK", "ORA", "$02", "$03", "$04", "ORA", "ASL", "$07",
"PHP", "ORA", "ASL", "$0B", "$0C", "ORA", "ASL", "$0F",
"BPL", "ORA", "$12", "$13", "$14", "ORA", "ASL", "$17",
"CLC", "ORA", "$1A", "$1B", "$1C", "ORA", "ASL", "$1F",
"JSR", "AND", "$22", "$23", "BIT", "AND", "ROL", "$27",
"PLP", "AND", "ROL", "$2B", "BIT", "AND", "ROL", "$2F",
"BMI", "AND", "$32", "$33", "$34", "AND", "ROL", "$37",
"SEC", "AND", "$3A", "$3B", "$3C", "AND", "ROL", "$3F",
"RTI", "EOR", "$42", "$43", "ADC", "EOR", "LSR", "$47",
"PHA", "EOR", "LSR", "$4B", "JMP", "EOR", "LSR", "$4F",
"BVC", "EOR", "$52", "$53", "$54", "EOR", "LSR", "$57",
"CLI", "EOR", "$5A", "$5B", "$5C", "EOR", "LSR", "$5F",
"RTS", "ADC", "$62", "$63", "$64", "ADC", "ROR", "$67",
"PLA", "ADC", "ROR", "$6B", "JMP", "ADC", "ROR", "$6F",
"BVS", "ADC", "$72", "$73", "$74", "ADC", "ROR", "$77",
"SEI", "ADC", "$7A", "$7B", "$7C", "ADC", "ROR", "$7F",
"$80", "STA", "$82", "$83", "STY", "STA", "STX", "$87",
"DEY", "$89", "TXA", "$8B", "STY", "STA", "STX", "$8F",
"BCC", "STA", "$92", "$93", "STY", "STA", "STX", "$97",
"TYA", "STA", "TXS", "$9B", "$9C", "STA", "$9E", "$9F",
"LDY", "LDA", "LDX", "$A3", "LDY", "LDA", "LDX", "$A7",
"TAY", "LDA", "TAX", "$AB", "LDY", "LDA", "LDX", "$AF",
"BCS", "LDA", "$B2", "$B3", "LDY", "LDA", "LDX", "$B7",
"CLV", "LDA", "TSX", "$BB", "LDY", "LDA", "LDX", "$BF",
"CPY", "CMP", "$C2", "$C3", "CPY", "CMP", "DEC", "$C7",
"INY", "CMP", "DEX", "$CB", "CPY", "CMP", "DEC", "$CF",
"BNE", "CMP", "$D2", "$D3", "$D4", "CMP", "DEC", "$D7",
"CLD", "CMP", "$DA", "$DB", "$DC", "CMP", "DEC", "$DF",
"CPX", "SBC", "$E2", "$E3", "CPX", "SBC", "INC", "$E7",
"INX", "SBC", "NOP", "$EB", "CPX", "SBC", "INC", "$EF",
"BEQ", "SBC", "$F2", "$F3", "$F4", "SBC", "INC", "$F7",
"SED", "SBC", "$FA", "$FB", "$FC", "SBC", "INC", "$FF" };

static const uint8_t instructionArguments[256] = { 0, 1, 0, 0, 0, 1, 1, 0, 
0, 1, 0, 0, 0, 2, 2, 0,
1, 1, 0, 0, 0, 1, 1, 0,
0, 2, 0, 0, 0, 2, 2, 0,
2, 1, 0, 0, 1, 1, 1, 0, 
0, 1, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 0, 1, 1, 0,
0, 2, 0, 0, 0, 2, 2, 0,
0, 1, 0, 0, 1, 1, 1, 0,
0, 1, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 0, 1, 1, 0,
0, 2, 0, 0, 0, 2, 2, 0,
0, 1, 0, 0, 0, 1, 1, 0,
0, 1, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 0, 1, 1, 0,
0, 2, 0, 0, 0, 2, 2, 0,
0, 1, 0, 0, 1, 1, 1, 0,
0, 0, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 1, 1, 1, 0,
0, 2, 0, 0, 0, 2, 0, 0,
1, 1, 1, 0, 1, 1, 1, 0,
0, 1, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 1, 1, 1, 0,
0, 2, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 1, 1, 1, 0,
0, 1, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 0, 1, 1, 0,
0, 2, 0, 0, 0, 2, 2, 0,
1, 1, 0, 0, 1, 1, 1, 0,
0, 1, 0, 0, 2, 2, 2, 0,
1, 1, 0, 0, 0, 1, 1, 0,
0, 2, 0, 0, 0, 2, 2, 0 };

static const char *instructionDescriptions[256] = { "Break (Implied)", "ORA Indirect,X", "Invalid Opcode $02", "Invalid Opcode $03", "Invalid Opcode $04", "ORA Zero Page", "ASL Zero Page", "Invalid Opcode $07",
"Push Processor Status", "ORA Immediate", "ASL Accumulator (Implied)", "Invalid Opcode $0B", "Invalid Opcode $0C", "ORA Absolute", "ASL Absolute", "Invalid Opcode $0F",
"Branch on Positive", "ORA Indirect,Y", "Invalid Opcode $12", "Invalid Opcode $13", "Invalid Opcode $14", "ORA Zero Page,X", "ASL Zero Page,X", "Invalid Opcode $17",
"Clear Carry", "ORA Absolute,Y", "Invalid Opcode $1A", "Invalid Opcode $1B", "Invalid Opcode $1C", "ORA Absolute,X", "ASL Absolute,X", "Invalid Opcode $1F",
"Jump to Subroutine", "AND Indirect,X", "Invalid Opcode $22", "Invalid Opcode $23", "BIT Zero Page", "AND Zero Page", "ROL Zero Page", "Invalid Opcode $27",
"Pull Processor Status", "AND Immediate", "ROL Accumulator", "Invalid Opcode $2B", "BIT Absolute", "AND Absolute", "ROL Absolute", "Invalid Opcode $2F",
"Branch on Negative", "AND Indirect,Y", "Invalid Opcode $32", "Invalid Opcode $33", "Invalid Opcode $34", "AND Zero Page,X", "ROL Zero Page,X", "Invalid Opcode $37",
"Set Carry", "AND Absolute,Y", "Invalid Opcode $3A", "Invalid Opcode $3B", "Invalid Opcode $3C", "AND Absolute,X", "ROL Absolute,X", "Invalid Opcode $3F",
"Return from Interrupt", "EOR Indirect,X", "Invalid Opcode $42", "Invalid Opcode $43", "ADC Immediate", "EOR Zero Page", "LSR Zero Page", "Invalid Opcode $47",
"Push Accumulator", "EOR Immediate", "LSR Accumulator", "Invalid Opcode $4B", "Jump Absolute", "EOR Absolute", "LSR Absolute", "Invalid Opcode $4F",
"Branch on Overflow Clear", "EOR Indirect,Y", "Invalid Opcode $52", "Invalid Opcode $53", "Invalid Opcode $54", "EOR Zero Page,X", "LSR Zero Page,X", "Invalid Opcode $57",
"Clear Interrupt", "EOR Absolute,Y", "Invalid Opcode $5A", "Invalid Opcode $5B", "Invalid Opcode $5C", "EOR Absolute,X", "LSR Absolute,X", "Invalid Opcode $5F",
"Return from Subroutine", "ADC Indirect,X", "Invalid Opcode $62", "Invalid Opcode $63", "Invalid Opcode $64", "ADC Zero Page", "ROR Zero Page", "Invalid Opcode $67",
"Pull Accumulator", "ADC Immediate", "ROR Accumulator", "Invalid Opcode $6B", "Jump Indirect", "ADC Absolute", "ROR Absolute", "Invalid Opcode $6F",
"Branch on Overflow Set", "ADC Indirect,Y", "Invalid Opcode $72", "Invalid Opcode $73", "Invalid Opcode $74", "ADC Zero Page,X", "ROR Zero Page,X", "Invalid Opcode $77",
"Set Interrupt", "ADC Absolute,Y", "Invalid Opcode $7A", "Invalid Opcode $7B", "Invalid Opcode $7C", "ADC Absolute,X", "ROR Absolute,X", "Invalid Opcode $7F",
"Invalid Opcode $80", "STA Indirect,X", "Invalid Opcode $82", "Invalid Opcode $83", "STY Zero Page", "STA Zero Page", "STX Zero Page", "Invalid Opcode $87",
"Decrement Y", "Invalid Opcode $89", "Transfer X to Accumulator", "Invalid Opcode $8B", "STY Absolute", "STA Absolute", "STX Absolute", "Invalid Opcode $8F",
"Branch on Carry Clear", "STA Indirect,Y", "Invalid Opcode $92", "Invalid Opcode $93", "STY Zero Page,X", "STA Zero Page,X", "STX Zero Page,Y", "Invalid Opcode $97",
"Transfer Y to Accumulator", "STA Absolute,Y", "Transfer X to Stack Pointer", "Invalid Opcode $9B", "Invalid Opcode $9C", "STA Absolute,X", "Invalid Opcode $9E", "Invalid Opcode $9F",
"LDY Immediate", "LDA Indirect,X", "LDX Immediate", "Invalid Opcode $A3", "LDY Zero Page", "LDA Zero Page", "LDX Zero Page", "Invalid Opcode $A7",
"Transfer Accumulator to Y", "LDA Immediate", "Transfer Accumulator to X", "Invalid Opcode $AB", "LDY Absolute", "LDA Absolute", "LDX Absolute", "Invalid Opcode $AF",
"Branch on Carry Set", "LDA Indirect,Y", "Invalid Opcode $B2", "Invalid Opcode $B3", "LDY Zero Page,X", "LDA Zero Page,X", "LDX Zero Page,Y", "Invalid Opcode $B7",
"Clear Overflow", "LDA Absolute,Y", "Transfer Stack Pointer to X", "Invalid Opcode $BB", "LDY Absolute,X", "LDA Absolute,X", "LDX Absolute,Y", "Invalid Opcode $BF",
"CPY Immediate", "CMP Indirect,X", "Invalid Opcode $C2", "Invalid Opcode $C3", "CPY Zero Page", "CMP Zero Page", "DEC Zero Page", "Invalid Opcode $C7",
"Increment Y", "CMP Immediate", "Decrement X", "Invalid Opcode $CB", "CPY Absolute", "CMP Absolute", "DEC Absolute", "Invalid Opcode $CF",
"Branch on Not Equal", "CMP Indirect,Y", "Invalid Opcode $D2", "Invalid Opcode $D3", "Invalid Opcode $D4", "CMP Zero Page,X", "DEC Zero Page,X", "Invalid Opcode $D7",
"Clear Decimal", "CMP Absolute,Y", "Invalid Opcode $DA", "Invalid Opcode $DB", "Invalid Opcode $DC", "CMP Absolute,X", "DEC Absolute,X", "Invalid Opcode $DF",
"CPX Immediate", "SBC Indirect,X", "Invalid Opcode $E2", "Invalid Opcode $E3", "CPX Zero Page", "SBC Zero Page", "INC Zero Page", "Invalid Opcode $E7",
"Increment X", "SBC Immediate", "NOP", "Invalid Opcode $EB", "CPX Absolute", "SBC Absolute", "INC Absolute", "Invalid Opcode $EF",
"Branch on Equal", "SBC Indirect,Y", "Invalid Opcode $F2", "Invalid Opcode $F3", "Invalid Opcode $F4", "SBC Zero Page,X", "INC Zero Page,X", "Invalid Opcode $F7",
"Set Decimal", "SBC Absolute,Y", "Invalid Opcode $FA", "Invalid Opcode $FB", "Invalid Opcode $FC", "SBC Absolute,X", "INC Absolute,X", "Invalid Opcode $FF" };

@implementation NESApplicationController

- (void)dealloc
{
	[cpuInterpreter release];
	[ppuEmulator release];
	[cartEmulator release];
	[cpuRegisters release];
	[instructions release];
	
	[super dealloc];
}

- (IBAction)loadROM:(id)sender
{
	NSError *propagatedError;
	NSAlert *errorDialog;
	NSOpenPanel *openPanel;
	
	if (gameIsLoaded) {
		
		if (gameTimer != nil) {
		
			[gameTimer invalidate];
			gameTimer = nil;
		}
	}
	
	openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	
	if (NSOKButton == [openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject:@"nes"]]) {
				
		// Reset the PPU
		[ppuEmulator resetPPUstatus];
		
		if (nil == (propagatedError = [cartEmulator loadROMFileAtPath:[[openPanel filenames] objectAtIndex:0]])) {
		
			// Friendly Debugging Info
			NSLog(@"Cartridge Information:");
			NSLog(@"Mapper #: %d\t\tDescription: %@",[cartEmulator mapperNumber],[cartEmulator mapperDescription]);
			NSLog(@"Trainer: %@\t\tVideo Type: %@",([cartEmulator hasTrainer] ? @"Yes" : @"No"),([cartEmulator isPAL] ? @"PAL" : @"NTSC"));
			NSLog(@"Mirroring: %@\tBackup RAM: %@",([cartEmulator usesVerticalMirroring] ? @"Vertical" : @"Horizontal"),([cartEmulator usesBatteryBackedRAM] ? @"Yes" : @"No"));
			NSLog(@"Four-Screen VRAM Layout: %@",([cartEmulator usesFourScreenVRAMLayout] ? @"Yes" : @"No"));
			NSLog(@"PRG-ROM Banks: %d x 16kB\tCHR-ROM Banks: %d x 8kB",[cartEmulator numberOfPRGROMBanks],[cartEmulator numberOfCHRROMBanks]);
			NSLog(@"Onboard RAM Banks: %d x 8kB",[cartEmulator numberOfRAMBanks]);
			
			// Allow CPU Interpreter to cache PRGROM pointers
			[cpuInterpreter setPRGROMPointers];
			
			// Reset the CPU to prepare for execution
			[cpuInterpreter reset];
			
			// Flip the bool to indicate that the game is loaded
			[self setGameIsLoaded:YES];
			
			// Start the game
			[self play:nil];
		}
		else {
		
			// There's no game loaded
			[self setGameIsLoaded:NO];
			
			// Throw an error
			errorDialog = [NSAlert alertWithError:propagatedError];
			[errorDialog runModal];
		}
	}
}

- (void)awakeFromNib {

	boolean_t exactMatch;
	
	ppuEmulator = [[NESPPUEmulator alloc] initWithBuffer:[playfieldView videoBuffer]];
	cartEmulator = [[NESCartridgeEmulator alloc] initWithPPU:ppuEmulator];
	cpuInterpreter = [[NES6502Interpreter alloc] initWithCartridge:cartEmulator	andPPU:ppuEmulator];
	_currentInstruction = nil;
	instructions = nil;
	debuggerIsVisible = NO;
	gameIsLoaded = NO;
	
	// FIXME: Should probably CGRelease this somewhere
	_fullScreenMode = CGDisplayBestModeForParameters(kCGDirectMainDisplay,32,640,480,&exactMatch);
}

- (IBAction)resetCPU:(id)sender {
	
	[cpuInterpreter reset];
	[self updatecpuRegisters];
	[self updateInstructions];
}

- (IBAction)setBreak:(id)sender {
	
	uint16_t address;
	unsigned int scannedValue;
	NSScanner *hexScanner = [NSScanner scannerWithString:[peekField stringValue]];
	[hexScanner scanHexInt:&scannedValue];
	address = scannedValue; // take just 16-bits for the address
	
	[cpuInterpreter setBreakpoint:address];
}

- (IBAction)runUntilBreak:(id)sender {

	[cpuInterpreter executeUntilBreak];
	[self updatecpuRegisters];
	[self updateInstructions];
}

- (void)_nextFrame {

	uint_fast32_t ppuCyclesToRun;
	uint_fast32_t cpuCyclesToRun = 29781 - [ppuEmulator cyclesSinceVINT] / 3;
	[cpuInterpreter setController1Data:[playfieldView readController1]]; // Pull latest controller data
	
	if ([ppuEmulator triggeredNMI]) [cpuInterpreter nmi];
	
	ppuCyclesToRun = [cpuInterpreter executeUntilCycle:cpuCyclesToRun];
	// NSLog(@"PPU Cycles to run: %d",ppuCyclesToRun * 3);
	[ppuEmulator runPPUUntilCPUCycle:ppuCyclesToRun];
	// NSLog(@"PPU failed to complete frame prior to render. Ran for %d cycles to end on cycle %d.",ppuCyclesToRun * 3,[ppuEmulator cyclesSinceVINT]);
	[cpuInterpreter resetCPUCycleCounter];
	[ppuEmulator resetCPUCycleCounter];
	[playfieldView setNeedsDisplay:YES];
}

- (IBAction)showAndHideDebugger:(id)sender
{
	if (debuggerIsVisible) {
	
		[debuggerWindow orderOut:nil];
		debuggerIsVisible = NO;
	}
	else {
	
		[self updatecpuRegisters];
		[self updateInstructions];
		[debuggerWindow makeKeyAndOrderFront:nil];
		debuggerIsVisible = YES;
	}
}

- (BOOL)gameIsLoaded
{
	return gameIsLoaded;
}

- (void)setGameIsLoaded:(BOOL)flag
{
	gameIsLoaded = flag;
	
	if (flag) {
	
		[playPauseMenuItem setEnabled:YES];
	}
	else {
		
		[playPauseMenuItem setTitle:@"Play"];
		[playPauseMenuItem setEnabled:NO];
	}
}

- (IBAction)toggleFullScreenMode:(id)sender
{	
	if ([playfieldView isInFullScreenMode]) {
		
		[playfieldView exitFullScreenModeWithOptions:nil];
		[playfieldView scaleForWindowedDrawing];
	}
	else {

		[playfieldView enterFullScreenMode:[NSScreen mainScreen] withOptions:[NSDictionary dictionaryWithObjectsAndKeys:(NSDictionary *)_fullScreenMode,NSFullScreenModeSetting,[NSNumber numberWithBool:NO],NSFullScreenModeAllScreens,nil]];
		[playfieldView scaleForFullScreenDrawing];
	}
}

- (IBAction)play:(id)sender {

	if (gameTimer == nil) {
		
		[playPauseMenuItem setTitle:@"Pause"];
		gameTimer = [NSTimer scheduledTimerWithTimeInterval:.017 target:self selector:@selector(_nextFrame) userInfo:nil repeats:YES];
	}
	else {
	
		[playPauseMenuItem setTitle:@"Play"];
		[gameTimer invalidate];
		gameTimer = nil;
		[self updatecpuRegisters];
		[self updateInstructions];
	}
}

- (IBAction)advanceFrame:(id)sender {

	[self _nextFrame];
	[self updatecpuRegisters];
	[self updateInstructions];
}

- (IBAction)run:(id)sender {
	
	uint_fast32_t ppuCyclesToRun;
	// uint_fast32_t cpuCyclesToRun = (89343 - [ppuEmulator cyclesSinceVINT]) / 3;
	uint_fast32_t cpuCyclesToRun;
	
	[cpuInterpreter reset];
	
	while (1) {
		cpuCyclesToRun = 29781 - [ppuEmulator cyclesSinceVINT] / 3;
		if ([ppuEmulator triggeredNMI]) [cpuInterpreter nmi];
		ppuCyclesToRun = [cpuInterpreter executeUntilCycle:cpuCyclesToRun];
		NSLog(@"PPU Cycles to run: %d",ppuCyclesToRun * 3);
		[ppuEmulator runPPUUntilCPUCycle:ppuCyclesToRun];
		[cpuInterpreter resetCPUCycleCounter];
		[playfieldView setNeedsDisplay:YES];
	}
}

- (IBAction)step:(id)sender {
	
	[cpuInterpreter interpretOpcode];
	[self updatecpuRegisters];
	[self updateInstructions];
}

- (IBAction)peek:(id)sender 
{
	uint16_t address;
	unsigned int scannedValue;
	NSScanner *hexScanner = [NSScanner scannerWithString:[peekField stringValue]];
	[hexScanner scanHexInt:&scannedValue];
	address = scannedValue; // take just 16-bits for the address
	
	[peekLabel setStringValue:[NSString stringWithFormat:@"0x%2.2x",[cpuInterpreter readByteFromCPUAddressSpace:address]]];
}

- (IBAction)poke:(id)sender
{
	uint16_t address;
	uint8_t value;
	unsigned int scannedAddress;
	unsigned int scannedValue;
	NSScanner *hexScanner = [NSScanner scannerWithString:[peekField stringValue]];
	[hexScanner scanHexInt:&scannedAddress];
	address = scannedAddress; // take just 16-bits for the address
	hexScanner = [NSScanner scannerWithString:[pokeField stringValue]];
	[hexScanner scanHexInt:&scannedValue];
	value = scannedValue; // take just 8 bits for the value
	
	[cpuInterpreter writeByte:value toCPUAddress:address];
}

- (void)updatecpuRegisters
{
	CPURegisters *registers = [cpuInterpreter cpuRegisters];
	
	[self setCpuRegisters:[NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"0x%2.2x",registers->accumulator],@"accumulator",
			 [NSString stringWithFormat:@"0x%2.2x",registers->indexRegisterX],@"indexRegisterX",
			 [NSString stringWithFormat:@"0x%2.2x",registers->indexRegisterY],@"indexRegisterY",
			 [NSString stringWithFormat:@"0x%4.4x",registers->programCounter],@"programCounter",
			 [NSString stringWithFormat:@"0x%2.2x",registers->stackPointer],@"stackPointer",
			 [NSString stringWithFormat:@"%d",registers->statusCarry],@"statusCarry",
			 [NSString stringWithFormat:@"%d",registers->statusZero],@"statusZero",
			 [NSString stringWithFormat:@"%d",registers->statusIRQDisable],@"irqDisable",
			 [NSString stringWithFormat:@"%d",registers->statusBreak],@"statusBreak",
			 [NSString stringWithFormat:@"%d",registers->statusOverflow],@"statusOverflow",
			 [NSString stringWithFormat:@"%d",registers->statusDecimal],@"statusDecimal",
			 [NSString stringWithFormat:@"%d",registers->statusNegative],@"statusNegative",nil]];
}

- (NSDictionary *)cpuRegisters
{
	return cpuRegisters;
}

- (void)setCpuRegisters:(NSDictionary *)newRegisters
{
	[newRegisters retain];
	[cpuRegisters release];
	cpuRegisters = newRegisters;
}

- (void)updateInstructions
{
	uint16_t edgeOfPage = 0x00FF | ([cpuInterpreter cpuRegisters]->programCounter & 0xFF00);
	uint16_t addressOfCurrentInstruction = [cpuInterpreter cpuRegisters]->programCounter;
	uint16_t currentInstr = addressOfCurrentInstruction;
	uint8_t currentOpcode;
	uint16_t address;
	uint8_t operand;
	NSMutableArray *instructionArray;
	
	int firstObject;
	int lastObject;
	int currentSearch;
	unsigned int currentSearchValue;
	unsigned int firstInstruction = [[[instructions objectAtIndex:0] objectForKey:@"address"] unsignedIntValue];
	unsigned int lastInstruction = [[[instructions lastObject] objectForKey:@"address"] unsignedIntValue];
	
	if (([cpuInterpreter cpuRegisters]->programCounter < firstInstruction) || ([cpuInterpreter cpuRegisters]->programCounter > lastInstruction)) {
		
		instructionArray = [NSMutableArray array];
		
		while (addressOfCurrentInstruction <= edgeOfPage) {
			
			currentOpcode = [cpuInterpreter readByteFromCPUAddressSpace:addressOfCurrentInstruction];
			
			if (instructionArguments[currentOpcode] == 2) {
				
				address = [cpuInterpreter readByteFromCPUAddressSpace:addressOfCurrentInstruction + 2] * 256;
				address |= [cpuInterpreter readByteFromCPUAddressSpace:addressOfCurrentInstruction + 1];
				
				[instructionArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%s",instructionNames[currentOpcode]],@"name",
											 [NSString stringWithFormat:@"0x%4.4x",address],@"argument",
											 [NSString stringWithFormat:@"%s",instructionDescriptions[[cpuInterpreter readByteFromCPUAddressSpace:addressOfCurrentInstruction]]],@"description",
											 [NSNumber numberWithUnsignedInt:addressOfCurrentInstruction],@"address",
											 nil]];
				addressOfCurrentInstruction += 3;
			}
			else if (instructionArguments[currentOpcode] == 1) {
				
				operand = [cpuInterpreter readByteFromCPUAddressSpace:addressOfCurrentInstruction + 1];
				
				[instructionArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%s",instructionNames[currentOpcode]],@"name",
											 [NSString stringWithFormat:@"0x%2.2x",operand],@"argument",
											 [NSString stringWithFormat:@"%s",instructionDescriptions[[cpuInterpreter readByteFromCPUAddressSpace:addressOfCurrentInstruction]]],@"description",
											 [NSNumber numberWithUnsignedInt:addressOfCurrentInstruction],@"address",
											 nil]];
				
				addressOfCurrentInstruction += 2;
			}
			else {
				
				[instructionArray addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:[NSString stringWithFormat:@"%s",instructionNames[currentOpcode]],@"name",
											 @"(Implied)",@"argument",
											 [NSString stringWithFormat:@"%s",instructionDescriptions[[cpuInterpreter readByteFromCPUAddressSpace:addressOfCurrentInstruction]]],@"description",
											 [NSNumber numberWithUnsignedInt:addressOfCurrentInstruction],@"address",
											 nil]];
				
				addressOfCurrentInstruction++;
			}
		}
		
		[self setInstructions:instructionArray];
	}
	else {
		
		//Remove current key of last instruction
		[_currentInstruction removeObjectForKey:@"current"];
	}
	
	// set current instruction
	currentSearch = firstObject = 0;
	lastObject = [instructions count] - 1;
	
	while ((currentSearchValue = [[[instructions objectAtIndex:currentSearch] objectForKey:@"address"] unsignedIntValue]) != currentInstr) {
	
		if (currentSearchValue < currentInstr) {
			
			firstObject = currentSearch;
			currentSearch = currentSearch == firstObject ? lastObject : (lastObject + currentSearch) / 2;
		}
		else {
			
			lastObject = currentSearch;
			currentSearch = (firstObject + currentSearch) / 2;
		}
	}
	
	_currentInstruction = [instructions objectAtIndex:currentSearch];
	[_currentInstruction setObject:[NSImage imageNamed:NSImageNameRightFacingTriangleTemplate] forKey:@"current"];
}

- (NSArray *)instructions
{
	return instructions;
}

- (void)setInstructions:(NSArray *)newInstructions
{
	[newInstructions retain];
	[instructions release];
	instructions = newInstructions;
}

@end
