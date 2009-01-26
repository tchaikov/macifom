//
//  NESPPUEmulator.h
//  Macifom
//
//  Created by Auston Stewart on 7/27/08.
//

#import <Cocoa/Cocoa.h>

typedef uint8_t (*RegisterReadMethod)(id, SEL, uint_fast32_t);
typedef void (*RegisterWriteMethod)(id, SEL, uint8_t, uint_fast32_t);

typedef enum {

	NESHorizontalMirroring = 0,
	NESVerticalMirroring = 1,
	NESSingleScreenMirroring = 2,
	NESFourScreenMirroring = 3
} NESMirroringType;

@class NESCartridgeEmulator;

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
	uint8_t ***_chrromBank0TileCache;
	uint8_t ***_chrromBank1TileCache;
	uint8_t ***_backgroundTileCache;
	uint8_t ***_spriteTileCache;
	uint8_t *_playfieldBuffer;
	uint_fast32_t _scanlinePriorityBuffer[8][8];
	uint_fast8_t _spritesOnCurrentScanline[8];
	uint_fast8_t _numberOfSpritesOnScanline;
	uint8_t _sprRAMAddress;
	uint8_t *_nameAndAttributeTables;
	uint8_t *_nameTable0;
	uint8_t *_nameTable1;
	uint8_t *_nameTable2;
	uint8_t *_nameTable3;
	uint8_t *_palettes;
	uint8_t *_chromBank0;
	uint8_t *_chromBank1;
	
	uint_fast32_t _cyclesSinceVINT;
	uint_fast32_t _videoBufferIndex;
	
	uint16_t _VRAMAddress;
	uint16_t _temporaryVRAMAddress;
	
	uint8_t _fineHorizontalScroll;
	uint8_t _addressIncrement;
	uint8_t _colorIntensity;
	
	uint16_t _nameAndAttributeTablesMask;
	uint16_t *_nameAndAttributeTablesMasks;
	RegisterWriteMethod *_registerWriteMethods;
	RegisterReadMethod *_registerReadMethods;
	
	uint_fast32_t *_videoBuffer;
	
	BOOL _NMIOnVBlank;
	BOOL _8x16Sprites;
	BOOL _monochrome;
	BOOL _clipBackground;
	BOOL _clipSprites;
	BOOL _backgroundEnabled;
	BOOL _spritesEnabled;
	BOOL _firstWriteOccurred;
	BOOL _oddFrame;
	BOOL _verticalIncrement;
}

- (id)initWithBuffer:(uint_fast32_t *)buffer;
- (void)cacheCHROMFromCartridge:(NESCartridgeEmulator *)cartEmu;
- (void)runPPUForCPUCycles:(uint_fast32_t)cycle;
- (BOOL)triggeredNMI;
- (uint_fast32_t)cyclesSinceVINT;
- (void)resetPPUstatus;
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
- (void)DMAtransferToSPRRAM:(uint8_t *)bytes onCycle:(uint_fast32_t)cycle;
- (uint8_t)readFromVRAMIORegisterOnCycle:(uint_fast32_t)cycle;
- (uint8_t)readFromSPRRAMIORegisterOnCycle:(uint_fast32_t)cycle;
- (uint8_t)readByteFromPPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle;
- (void)writeByte:(uint8_t)byte toPPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle;
- (void)setMirroringType:(NESMirroringType)type;
- (void)displayBackgroundTiles;

@end
