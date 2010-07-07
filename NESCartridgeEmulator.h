/* NESCartridgeEmulator.h
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

@class NESPPUEmulator;

@interface NESCartridgeEmulator : NSObject {

	uint8_t **_prgromBanks;
	uint8_t **_chrromBanks;
	uint8_t *_prgromBank0;
	uint8_t *_prgromBank1;
	uint8_t *_patternTable0;
	uint8_t *_patternTable1;
	uint8_t *_trainer;
	uint8_t *_sram;
	
	uint8_t ****_chrromCache;
	
	BOOL _usesVerticalMirroring;
	BOOL _usesCHRRAM;
	BOOL _hasTrainer;
	BOOL _usesBatteryBackedRAM;
	BOOL _usesFourScreenVRAMLayout;
	BOOL _isPAL;
	BOOL _prgromBanksDidChange;
	BOOL _chrromBanksDidChange;
	BOOL _mapperReset;
	BOOL _mmc1Switch16KBPRGROMBanks;
	BOOL _mmc1SwitchFirst16KBBank;
	BOOL _mmc1Switch4KBCHRROMBanks;
	
	uint_fast8_t _mapperNumber;
	uint_fast8_t _serialWriteCounter;
	uint8_t _register;
	uint8_t _mmc1ControlRegister;
	uint8_t _mmc1CHRROMBank0Register;
	uint8_t _mmc1CHRROMBank1Register;
	uint8_t _mmc1PRGROMBankRegister;
	uint_fast8_t _numberOfPRGROMBanks;
	uint_fast8_t _numberOfCHRROM8KBBanks;
	uint_fast8_t _numberOfRAMBanks;
	uint_fast8_t _chrromBank0Index;
	uint_fast8_t _chrromBank1Index;

	BOOL _romFileDidLoad;
	
	NESPPUEmulator *_ppu;
}

- (id)initWithPPU:(NESPPUEmulator *)ppuEmulator;
- (NSError *)loadROMFileAtPath:(NSString *)path;
- (uint8_t)readByteFromPRGROM:(uint16_t)address;
- (uint8_t)readByteFromCHRROM:(uint16_t)address;
- (uint8_t)readByteFromControlRegister:(uint16_t)address;
- (uint16_t)readAddressFromPRGROM:(uint16_t)address;
- (uint8_t)readByteFromSRAM:(uint16_t)address;
- (uint8_t *)pointerToPRGROMBank0;
- (uint8_t *)pointerToPRGROMBank1;
- (uint8_t *)pointerToCHRROMBank0;
- (uint8_t *)pointerToCHRROMBank1;
- (uint8_t ***)pointerToCHRROMBank0TileCache;
- (uint8_t ***)pointerToCHRROMBank1TileCache;
- (uint8_t *)pointerToSRAM;
- (BOOL)prgromBanksDidChange;
- (BOOL)chrromBanksDidChange;
- (void)writeByte:(uint8_t)byte toSRAMwithCPUAddress:(uint16_t)address;
- (void)writeByte:(uint8_t)byte toPRGROMwithCPUAddress:(uint16_t)address;
- (void)clearROMdata;
- (NSString *)mapperDescription;

@property(nonatomic, readonly) BOOL romFileDidLoad;
@property(nonatomic, readonly) BOOL hasTrainer;
@property(nonatomic, readonly) BOOL usesVerticalMirroring;
@property(nonatomic, readonly) BOOL usesBatteryBackedRAM;
@property(nonatomic, readonly) BOOL usesCHRRAM;
@property(nonatomic, readonly) BOOL usesFourScreenVRAMLayout;
@property(nonatomic, readonly) BOOL isPAL;
@property(nonatomic, readonly) uint8_t mapperNumber;
@property(nonatomic, readonly) uint8_t numberOfPRGROMBanks;
@property(nonatomic, readonly) uint8_t numberOfCHRROMBanks;
@property(nonatomic, readonly) uint8_t numberOfRAMBanks;

@end
