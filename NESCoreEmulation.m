//
//  NESCoreEmulation.m
//  Innuendo
//
//  Created by Auston Stewart on 7/27/08.
//

#import "NESCoreEmulation.h"
#import "NES6502Interpreter.h"
#import "NESPPUEmulator.h"
#import "NESCartridgeEmulator.h"

@implementation NESCoreEmulation

- (id)initWithROM:(NSString *)path
{
	[super init];
	
	ppuEmulator = [[NESPPUEmulator alloc] init];
	cartEmulator = [[NESCartridgeEmulator alloc] initWithiNESFileAtPath:path];
	cpuInterpreter = [[NES6502Interpreter alloc] initWithCartridge:cartEmulator	andPPU:ppuEmulator];
	
	return self;
}

- (void)dealloc
{
	[cpuInterpreter release];
	[ppuEmulator release];
	[cartEmulator release];
	
	[super dealloc];
}

- (NES6502Interpreter *)cpu
{
	return cpuInterpreter;
}

- (NESPPUEmulator *)ppu
{
	return ppuEmulator;
}

- (NESCartridgeEmulator *)cartridge
{
	return cartEmulator;
}

- (uint_fast32_t)runUntilBreak
{
	return [cpuInterpreter executeUntilBreak];
}


@end
