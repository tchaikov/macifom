//
//  NESPPUEmulator.h
//  Innuendo
//
//  Created by Auston Stewart on 7/27/08.
//

#import <Cocoa/Cocoa.h>

typedef uint8_t (*RegisterReadMethod)(id, SEL, uint_fast32_t);
typedef void (*RegisterWriteMethod)(id, SEL, uint8_t, uint_fast32_t);
typedef void (*NameAttributeWriteMethod)(id, SEL, uint8_t, uint_fast32_t);

typedef enum NESMirroringType {

	NESHorizontalMirroring = 0;
	NESVerticalMirroring = 1;
	NESSingleScreenMirroring = 2;
	NESFourScreenMirroring = 3;
};

@interface NESPPUEmulator : NSObject {

	uint8_t _ppuControlRegister1;
	uint8_t _ppuControlRegister2;
	uint8_t _ppuStatusRegister;
	uint8_t _bufferedVRAMRead;
	uint8_t *_backgroundTable;
	uint8_t *_spriteTable;
	uint8_t *_selectedNameTable;
	uint8_t *_sprRAM;
	uint8_t *_spritePalette;
	uint8_t *_backgroundPalette;
	uint8_t *_chrromBank0;
	uint8_t *_chrromBank1;
	uint8_t _sprRAMAddress;
	uint8_t *_nameAndAttributeTables;
	uint8_t *_nameTable0;
	uint8_t *_nameTable1;
	uint8_t *_nameTable2;
	uint8_t *_nameTable3;
	uint8_t *_palettes;
	uint_fast32_t _cyclesSinceVINT;
	
	uint16_t _VRAMAddress;
	uint16_t _temporaryVRAMAddress;
	
	uint8_t _fineHorizontalScroll;
	uint8_t _addressIncrement;
	uint8_t _colorIntensity;
	
	RegisterWriteMethod *_registerWriteMethods;
	RegisterReadMethod *_registerReadMethods;
	NameAttributeWriteMethod *_nameAndAttributeWriteMethods;
	NameAttributeWriteMethod *_writeToNameOrAttributeTable;
	
	NSBitmapImageRep *_buffer;
	
	BOOL _NMIOnVBlank;
	BOOL _8x16Sprites;
	BOOL _monochrome;
	BOOL _clipBackground;
	BOOL _clipSprites;
	BOOL _backgroundEnabled;
	BOOL _spritesEnabled;
	BOOL _firstWriteOccurred;
	
}

- (id)initWithBuffer:(NSBitmapImageRep *)buffer andCartridge:(NESCartridgeEmulator *)cartEmu;
- (void)finishRenderingFrame;
- (uint8_t)readByteFromCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle;
- (void)writeByte:(uint8_t)byte toPPUFromCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle;
- (void)writeToPPUControlRegister1:(uint8_t)byte onCycle:(uint_fast32_t)cycle;
- (void)writeToPPUControlRegister2:(uint8_t)byte onCycle:(uint_fast32_t)cycle;
- (void)writeToSPRRAMAddressRegister:(uint8_t)byte onCycle:(uint_fast32_t)cycle;
- (void)writeToSPRRAMIOControlRegister:(uint8_t)byte onCycle:(uint_fast32_t)cycle;
- (void)writeToVRAMAddressRegister1:(uint8_t)byte onCycle:(uint_fast32_t)cycle;
- (void)writeToVRAMAddressRegister2:(uint8_t)byte onCycle:(uint_fast32_t)cycle;
- (void)writeToVRAMIORegister:(uint8_t)byte onCycle:(uint_fast32_t)cycle;
- (uint8_t)readFromPPUStatusRegisterOnCycle:(uint_fast32_t)cycle;
- (void)DMAtransferToSPRRAM(uint8_t *)bytes onCycle:(uint_fast32_t)cycle;
- (uint8_t)readFromVRAMIORegisterOnCycle:(uint_fast32_t)cycle;
- (uint8_t)readFromSPRRAMIORegisterOnCycle:(uint_fast32_t)cycle;
- (uint8_t)readByteFromPPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle;
- (void)writeByte:(uint8_t)byte toPPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle;
- (void)setPatternTableBank0:(uint8_t *)pointer;
- (void)setPatternTableBank1:(uint8_t *)pointer;
- (void)setMirroringType:(NESMirroringType)type;
- (void)writeByte:(uint8_t)byte toHorizontallyMirroredNameOrAttributeTableAddress:(uint_fast32_t)address;
- (void)writeByte:(uint8_t)byte toVerticallyMirroredNameOrAttributeTableAddress:(uint_fast32_t)address;
- (void)writeByte:(uint8_t)byte toSingleScreenNameOrAttributeTableAddress:(uint_fast32_t)address;
- (void)writeByte:(uint8_t)byte toFourScreenNameOrAttributeTableAddress:(uint_fast32_t)address;

@end
