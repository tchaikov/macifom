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

@end

static void _ADC(CPURegisters *cpuRegisters, uint8_t operand) {

	uint8_t oldAccumulator = cpuRegisters->accumulator;
	uint16_t result = (uint16_t)oldAccumulator + operand + cpuRegisters->statusCarry;
	cpuRegisters->accumulator = (uint8_t)result;
	cpuRegisters->statusCarry = result >> 8;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	// cpuRegisters->statusOverflow = (~((oldAccumulatorValue >> 7) ^ (operand >> 7))) & ((oldAccumulatorValue >> 7) ^ (cpuRegisters->statusNegative));
	cpuRegisters->statusOverflow = ((oldAccumulator ^ cpuRegisters->accumulator) & (operand ^ cpuRegisters->accumulator)) / 128;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static void _AND(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->accumulator &= operand;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static void _ASL(CPURegisters *cpuRegisters, uint8_t operand) {

	cpuRegisters->statusCarry = cpuRegisters->accumulator >> 7;
	cpuRegisters->accumulator <<= 1;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static uint8_t _ASL_RMW(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->statusCarry = operand >> 7;
	operand <<= 1;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
	
	return operand;
}

static void _BIT(CPURegisters *cpuRegisters, uint8_t operand) {

	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusOverflow = ((operand / 64) & 1);
	cpuRegisters->statusZero = !(cpuRegisters->accumulator & operand);
}

static void _CMP(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t result = cpuRegisters->accumulator - operand;
	cpuRegisters->statusCarry = (operand <= cpuRegisters->accumulator); // Should be an unsigned comparison
	cpuRegisters->statusNegative = result >> 7;
	cpuRegisters->statusZero = !result;
}

static void _CPX(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t result = cpuRegisters->indexRegisterX - operand;
	cpuRegisters->statusCarry = (operand <= cpuRegisters->indexRegisterX); // Should be an unsigned comparison
	cpuRegisters->statusNegative = result >> 7;
	cpuRegisters->statusZero = !result;
}

static void _CPY(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t result = cpuRegisters->indexRegisterY - operand;
	cpuRegisters->statusCarry = (operand <= cpuRegisters->indexRegisterY); // Should be an unsigned comparison
	cpuRegisters->statusNegative = result >> 7;
	cpuRegisters->statusZero = !result;
}

static uint8_t _DEC(CPURegisters *cpuRegisters, uint8_t operand) {

	operand--;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
	
	return operand;
}

static uint8_t _INC(CPURegisters *cpuRegisters, uint8_t operand) {
	
	operand++;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
	
	return operand;
}

static void _EOR(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->accumulator ^= operand;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}
																	 
static void _LDA(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->accumulator = operand;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
}

static void _LDX(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->indexRegisterX = operand;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
}

static void _LDY(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->indexRegisterY = operand;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
}

static void _LSR(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->statusCarry = (cpuRegisters->accumulator & 1);
	cpuRegisters->accumulator >>= 1;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static uint8_t _LSR_RMW(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->statusCarry = (operand & 1);
	operand >>= 1;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
	
	return operand;
}

static void _ORA(CPURegisters *cpuRegisters, uint8_t operand) {
	
	cpuRegisters->accumulator |= operand;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static void _ROL(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t oldCarry = cpuRegisters->statusCarry;
	cpuRegisters->statusCarry = cpuRegisters->accumulator >> 7;
	cpuRegisters->accumulator <<= 1;
	cpuRegisters->accumulator |= oldCarry;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static uint8_t _ROL_RMW(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t oldCarry = cpuRegisters->statusCarry;
	cpuRegisters->statusCarry = operand >> 7;
	operand <<= 1;
	operand |= oldCarry;
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
	
	return operand;
}

static void _ROR(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t oldCarry = cpuRegisters->statusCarry;
	cpuRegisters->statusCarry = (cpuRegisters->accumulator & 1);
	cpuRegisters->accumulator >>= 1;
	cpuRegisters->accumulator |= (oldCarry << 7);
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static uint8_t _ROR_RMW(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t oldCarry = cpuRegisters->statusCarry;
	cpuRegisters->statusCarry = (operand & 1);
	operand >>= 1;
	operand |= (oldCarry << 7);
	cpuRegisters->statusNegative = operand >> 7;
	cpuRegisters->statusZero = !operand;
	
	return operand;
}

static void _SBC(CPURegisters *cpuRegisters, uint8_t operand) {
	
	uint8_t oldAccumulator = cpuRegisters->accumulator;
	operand = ~operand; // invert operand bits, used to do this below but it must happen BEFORE promotion to uin16_t
	uint16_t result = (uint16_t)oldAccumulator + operand + cpuRegisters->statusCarry;
	cpuRegisters->accumulator = (uint8_t)result;
	cpuRegisters->statusCarry = result >> 8;
	cpuRegisters->statusNegative = cpuRegisters->accumulator >> 7;
	// cpuRegisters->statusOverflow = (~((oldAccumulatorValue >> 7) ^ (operand >> 7))) & ((oldAccumulatorValue >> 7) ^ (cpuRegisters->statusNegative));
	cpuRegisters->statusOverflow = ((oldAccumulator ^ cpuRegisters->accumulator) & (operand ^ cpuRegisters->accumulator)) / 128;
	cpuRegisters->statusZero = !cpuRegisters->accumulator;
}

static uint8_t _GetAccumulator(CPURegisters *cpuRegisters, uint8_t operand) {
	
	return cpuRegisters->accumulator;
}

static uint8_t _GetIndexRegisterX(CPURegisters *cpuRegisters, uint8_t operand) {
	
	return cpuRegisters->indexRegisterX;
}

static uint8_t _GetIndexRegisterY(CPURegisters *cpuRegisters, uint8_t operand) {
	
	return cpuRegisters->indexRegisterY;
}
