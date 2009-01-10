//
//  NES6502Interpreter.h
//  Familiar
//
//  Created by Auston Stewart on 7/27/08.
//

#import <Cocoa/Cocoa.h>

@class NESCartridgeEmulator;
@class NESPPUEmulator;

typedef struct cpuregs {
	
	uint8_t accumulator;
	uint8_t indexRegisterX;
	uint8_t indexRegisterY;
	uint16_t programCounter;
	uint8_t stackPointer;
	
	uint8_t statusCarry;
	uint8_t statusZero;
	uint8_t statusIRQDisable;
	uint8_t statusDecimal;
	uint8_t statusBreak;
	uint8_t statusOverflow;
	uint8_t statusNegative;
	
} CPURegisters;

typedef void (*StandardOpPointer)(CPURegisters *,uint8_t);
typedef uint8_t (*WriteOpPointer)(CPURegisters *,uint8_t);
typedef uint_fast32_t (*OperationMethodPointer)(id, SEL, uint8_t);

@interface NES6502Interpreter : NSObject {

	CPURegisters *_cpuRegisters;
	
	uint8_t *_zeroPage;
	uint8_t *_stack;
	uint8_t *_cpuRAM;
	
	uint8_t *_prgRomBank0;
	uint8_t *_prgRomBank1;
	
	uint_fast32_t currentCPUCycle; // FIXME: Should be 0 or 1 indexed?
	uint16_t breakPoint;
	BOOL _encounteredUnsupportedOpcode;
	
	StandardOpPointer *_standardOperations;
	WriteOpPointer *_writeOperations;
	OperationMethodPointer *_operationMethods;
	SEL *_operationSelectors;
	
	NESCartridgeEmulator *cartridge;
	NESPPUEmulator *ppu;
}

- (id)initWithCartridge:(NESCartridgeEmulator *)cartEmu andPPU:(NESPPUEmulator *)ppuEmu;
- (void)reset;
- (void)resetCPUCycleCounter;
- (uint_fast32_t)executeUntilCycle:(uint_fast32_t)cycle;
- (uint_fast32_t)executeUntilBreak;
- (void)setBreakpoint:(uint16_t)counter;
- (uint8_t)currentOpcode;
- (CPURegisters *)cpuRegisters;
- (uint8_t)readByteFromCPUAddressSpace:(uint16_t)address;
- (uint16_t)readAddressFromCPUAddressSpace:(uint16_t)address;
- (void)writeByte:(uint8_t)byte toCPUAddress:(uint16_t)address;
- (uint_fast32_t)interpretOpcode;
- (void)setProgramCounter:(uint16_t)jump;
- (void)nmi;
- (void)setPRGROMPointers;

@end
