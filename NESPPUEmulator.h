/* NESPPUEmulator.h
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

typedef uint8_t (*RegisterReadMethod)(id, SEL, uint_fast32_t);
typedef void (*RegisterWriteMethod)(id, SEL, uint8_t, uint_fast32_t);
typedef uint16_t (*NametableMirroringMethod)(uint16_t);

typedef enum {

	NESHorizontalMirroring = 0,
	NESVerticalMirroring = 1,
	NESSingleScreenLowerMirroring = 2,
	NESSingleScreenUpperMirroring = 3
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
	uint8_t *_chrRAM;
	uint8_t *_chrRAMBank0;
	uint8_t *_chrRAMBank1;
	uint8_t *_spritePalette;
	uint8_t *_backgroundPalette;
	uint8_t ***_chrramTileCache;
	uint8_t ***_chrromBank0TileCache;
	uint8_t ***_chrromBank1TileCache;
	uint8_t ***_backgroundTileCache;
	uint8_t ***_spriteTileCache;
	uint8_t *_playfieldBuffer;
	uint_fast8_t _spritesOnCurrentScanline[8];
	uint_fast8_t _numberOfSpritesOnScanline;
	uint8_t _sprRAMAddress;
	uint8_t *_nameAndAttributeTables;
	uint8_t *_palettes;
	uint8_t *_chromBank0;
	uint8_t *_chromBank1;
	
	uint_fast32_t _sprite0HitCycle;
	uint_fast32_t _lastCPUCycle;
	uint_fast32_t _cyclesSinceVINT;
	uint_fast32_t _videoBufferIndex;
	uint_fast32_t _lastCycleOverage;
	
	uint16_t _VRAMAddress;
	uint16_t _temporaryVRAMAddress;
	
	uint8_t _fineHorizontalScroll;
	uint8_t _addressIncrement;
	uint8_t _colorIntensity;
	
	uint16_t _nameAndAttributeTablesMask;
	uint16_t *_nameAndAttributeTablesMasks;
	NametableMirroringMethod _nameTableMirroring;
	RegisterWriteMethod *_registerWriteMethods;
	RegisterReadMethod *_registerReadMethods;
	
	uint_fast32_t *_videoBuffer;
	
	BOOL _ppuDebugging;
	BOOL _sprite0Hit;
	BOOL _triggeredNMI;
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
	BOOL _patternTable0TileCacheIsInvalid;
	BOOL _patternTable1TileCacheIsInvalid;
	BOOL _usingCHRRAM;
	BOOL _frameEnded;
	BOOL _shortenPrimingScanline;
	uint16_t _chrRAMWriteHistory;
}

- (id)initWithBuffer:(uint_fast32_t *)buffer;
- (void)toggleDebugging:(BOOL)flag;
- (void)runPPU:(uint_fast32_t)cycles;
- (BOOL)runPPUUntilCPUCycle:(uint_fast32_t)cycle;
- (BOOL)triggeredNMI;
- (uint_fast32_t)cyclesSinceVINT;
- (void)resetCPUCycleCounter;
- (void)resetPPUstatus;
- (void)configureForCHRRAM;
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
- (void)writeByte:(uint8_t)byte toPPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle;
- (void)setMirroringType:(NESMirroringType)type;
- (void)changeMirroringTypeTo:(NESMirroringType)type onCycle:(uint_fast32_t)cycle;
- (void)setCHRROMTileCachePointersForBank0:(uint8_t ***)bankPointer0 bank1:(uint8_t ***)bankPointer1;
- (void)setCHRROMPointersForBank0:(uint8_t *)bankPointer0 bank1:(uint8_t *)bankPointer1;
- (void)setCHRRAMBank0Index:(uint8_t)index;
- (void)setCHRRAMBank1Index:(uint8_t)index;
- (void)displayBackgroundTiles;
- (uint_fast32_t)cpuCyclesUntilVblank;
- (uint_fast32_t)cpuCyclesUntilPrimingScanline;

@end
