/* NESCartridgeEmulator.m
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

#import "NESCartridgeEmulator.h"
#import "NESPPUEmulator.h"

#define SRAM_SIZE 8192

static const char *mapperDescriptions[256] = { "No mapper", "Nintendo MMC1", "UNROM switch", "CNROM switch", "Nintendo MMC3", "Nintendo MMC5", "FFE F4xxx", "AOROM switch",
												"FFE F3xxx", "Nintendo MMC2", "Nintendo MMC4", "ColorDreams", "FFE F6xxx", "CPROM switch", "Unknown Mapper", "100-in-1 switch",
												"Bandai", "FFE F8xxx", "Jaleco SS8806", "Namcot 106", "Nintendo DiskSystem", "Konami VRC4a", "Konami VRC2a (1)", "Konami VRC2a (2)",
												"Konami VRC6", "Konami VRC4b", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Irem G-101", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper",
												"Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper", "Unknown Mapper" };

@implementation NESCartridgeEmulator

@synthesize romFileDidLoad = _romFileDidLoad, hasTrainer = _hasTrainer, usesVerticalMirroring = _usesVerticalMirroring, usesBatteryBackedRAM = _usesBatteryBackedRAM, usesCHRRAM = _usesCHRRAM, usesFourScreenVRAMLayout = _usesFourScreenVRAMLayout, isPAL = _isPAL, mapperNumber = _mapperNumber, numberOfPRGROMBanks = _numberOfPRGROMBanks, numberOfCHRROMBanks = _numberOfCHRROM8KBBanks, numberOfRAMBanks = _numberOfRAMBanks;

- (void)_cleanUpPRGROMMemory
{
	uint_fast8_t bank;
	
	if (_prgromBanks == NULL) return;
	
	for (bank = 0; bank < _numberOfPRGROMBanks; bank++) {
	
		free(_prgromBanks[bank]);
	}
	
	free(_prgromBanks);
	_prgromBanks = NULL;
}

- (void)_cleanUpCHRROMMemory
{
	uint_fast8_t bank;
	uint_fast16_t tile; // Tile counter
	uint_fast16_t line; // Tile scanline counter
	
	if (_chrromBanks != NULL) {
	
		for (bank = 0; bank < _numberOfCHRROM8KBBanks; bank++) {
		
			free(_chrromBanks[bank]);
		}
	
		free(_chrromBanks);
		_chrromBanks = NULL;
	}
	
	if (_chrromCache != NULL) {
		
		for (bank = 0; bank < _numberOfCHRROM8KBBanks; bank++) {
		
			for (tile = 0; tile < 256; tile++) {
			
				for (line = 0; line < 8; line++) {
				
					free(_chrromCache[bank][tile][line]);
				}
				
				free(_chrromCache[bank][tile]);
			}
			
			free(_chrromCache[bank]);
		}
		
		free(_chrromCache);
		_chrromCache = NULL;
	}
}

- (void)_cleanUpTrainerMemory
{
	if (_trainer == NULL) return;
	free(_trainer);
	_trainer = NULL;
}

- (void)_cacheCHRROM
{	
	uint_fast16_t tile; // Tile counter
	uint_fast16_t line; // Tile scanline counter
	uint_fast8_t pixel; // Tile pixel counter
	uint_fast8_t indexingPixel;
	uint_fast8_t bank; // CHROM bank counter
	uint_fast8_t numberOf4KbCHRROMBanks = _numberOfCHRROM8KBBanks * 2;
	
	if (_numberOfCHRROM8KBBanks == 0) return;
	
	_chrromCache = (uint8_t ****)malloc(sizeof(uint8_t***) * numberOf4KbCHRROMBanks);
	
	for (bank = 0; bank < numberOf4KbCHRROMBanks; bank++) {
	
		_chrromCache[bank] = (uint8_t ***)malloc(sizeof(uint8_t**) * 256);
		
		for (tile = 0; tile < 256; tile++) {
			
			_chrromCache[bank][tile] = (uint8_t **)malloc(sizeof(uint8_t*)*8);
			
			for (line = 0; line < 8; line++) {
				
				_chrromCache[bank][tile][line] = (uint8_t *)malloc(sizeof(uint8_t)*8);
			}
		}
		
		for (tile = 0; tile < 256; tile++) {
		
			for (line = 0; line < 8; line++) {
			
				for (pixel = 0; pixel < 8; pixel++) {
				
					// FIXME: This logic is butchered to handle 8KB rom banks that go into 4KB switchable pattern table caches. Really I should just have 4KB in each bank.
					indexingPixel = 7 - pixel;
					_chrromCache[bank][tile][line][pixel] = ((_chrromBanks[bank/2][((tile << 4) | line) + (bank % 2)*4096] & (1 << (indexingPixel))) >> indexingPixel) | (((_chrromBanks[bank/2][((tile << 4) | (line + 8)) + (bank % 2)*4096] & (1 << (indexingPixel))) >> indexingPixel) << 1);
				}
			}
		}
	}
}

- (void)_resetCartridgeState
{
	_prgromBanks = NULL;
	_chrromBanks = NULL;
	_chrromCache = NULL;
	_prgromBank0 = NULL;
	_prgromBank1 = NULL;
	_patternTable0 = NULL;
	_patternTable1 = NULL;
	_trainer = NULL;
	
	_usesVerticalMirroring = NO;
	_usesCHRRAM = NO;
	_hasTrainer = NO;
	_usesBatteryBackedRAM = NO;
	_usesFourScreenVRAMLayout = NO;
	_isPAL = NO;
	_mapperReset = NO;
	
	_serialWriteCounter = 0;
	_register = 0;
	_mapperNumber = 0;
	_numberOfPRGROMBanks = 0;
	_numberOfCHRROM8KBBanks = 0;
	_chrromBank0Index = 0;
	_chrromBank1Index = 1;
	_numberOfRAMBanks = 0;
	_romFileDidLoad = NO;
	
	_mmc1ControlRegister = 0;
	_mmc1CHRROMBank0Register = 0;
	_mmc1CHRROMBank1Register = 0;
	_mmc1PRGROMBankRegister = 0;
	_mmc1Switch16KBPRGROMBanks = YES;
	_mmc1SwitchFirst16KBBank = YES;
	_mmc1Switch4KBCHRROMBanks = NO;
}

- (void)_setMMC1CHRROMBank0Register:(uint8_t)byte
{
	// NSLog(@"MMC1: Setting CHRROM Bank 0 register to 0x%2x.",byte);
	
	// CHRROM 4KB Bank 0 Swap
	if (_mmc1Switch4KBCHRROMBanks) {
		
		// NSLog(@"MMC1 Attempting 4KB CHRROM Bank 0 Swap.");
		
		if (!_usesCHRRAM) {
			
			// NSLog(@"Switching 4KB CHRROM Bank 0 to %d",byte);
			// FIXME: I have no idea what's actually going on here. Why's one 8KB and the other 4KB?
			_patternTable0 = _chrromBanks[byte >> 1] + ((byte & 0x1) * 4096);
			_chrromBank0Index = byte;
			_chrromBanksDidChange = YES;
		}
		else {
				
			// NSLog(@"MMC1: CHRRAM Game Attempted to Switch CHRROM Bank 0 to %d!",byte);
			[_ppu setCHRRAMBank0Index:(byte & 0x1)];
		}
	}
	else {
			
		if (!_usesCHRRAM) {
		
			// NSLog(@"Switching 8KB CHRROM Bank to %d.",byte >> 1);
			// 8KB CHRROM Switching Mode (LSB is ignored, thus the requiring the unintuitive logic below)
			_patternTable0 = _chrromBanks[byte >> 1];
			_patternTable1 = _chrromBanks[byte >> 1] + 4096;
			_chrromBank0Index = (byte >> 1) * 2;
			_chrromBank1Index = ((byte >> 1) * 2) + 1;
			_chrromBanksDidChange = YES;
		}
		else {
		
			// FIXME: I don't think this is supported, unless there are MMC1 games with more than 8KB of CHRRAM.
			// NSLog(@"MMC1: CHRRAM Game Attempted to Switch CHRROM Bank 0!");
		}
	}
	
	_mmc1CHRROMBank0Register = byte;
}

- (void)_setMMC1CHRROMBank1Register:(uint8_t)byte
{
	// NSLog(@"MMC1: Setting CHRROM Bank 1 register to 0x%2x.",byte);
	
	// CHRRROM 4KB Bank 1 Swap
	if (_mmc1Switch4KBCHRROMBanks) {
		
		// NSLog(@"MMC1 Attempting 4KB CHRROM Bank 1 Swap.");
		
		if (!_usesCHRRAM) {
		
			// NSLog(@"Switching 4KB CHRROM Bank 1 to %d",byte);
			// FIXME: I have no idea what's actually going on here. Why's one 8KB and the other 4KB?
			_patternTable1 = _chrromBanks[byte >> 1] + ((byte & 0x1) * 4096);
			_chrromBank1Index = byte;
			_chrromBanksDidChange = YES;
		}
		else {
			
			// NSLog(@"MMC1: CHRRAM Game Attempted to Switch CHRROM Bank 1 to %d!",byte);
			[_ppu setCHRRAMBank1Index:(byte & 0x1)];
		}
	}
	
	_mmc1CHRROMBank1Register = byte;
}

- (void)_setMMC1PRGROMBankRegister:(uint8_t)byte
{
	// NSLog(@"MMC1: Setting PRGROM Bank register to 0x%2x.",byte);
	
	// PRGROM Bank Swap
	if (_mmc1Switch16KBPRGROMBanks) {
		
		if (_mmc1SwitchFirst16KBBank) {
			
			_prgromBank0 = _prgromBanks[byte & 0xF];
			_prgromBank1 = _prgromBanks[_numberOfPRGROMBanks - 1];
			// NSLog(@"MMC1 Switching PRGROM Bank 0 to Index %d",byte & 0xF);
		}
		else {
			
			_prgromBank0 = _prgromBanks[0];
			_prgromBank1 = _prgromBanks[byte & 0xF];
			// NSLog(@"MMC1 Switching PRGROM Bank 1 to Index %d",byte & 0xF);
		}
	}
	else {
		
		// PRGROM 32KB Swap
		_prgromBank0 = _prgromBanks[byte & 0xE];
		_prgromBank1 = _prgromBanks[(byte & 0xE) + 1];
		// NSLog(@"MMC1 Switching PRGROM Banks 0 and 1 to Indices %d and %d",byte & 0xE,(byte & 0xE) + 1);
	}
	
	// FIXME: Bit 4 (0x10) Toggles PRGRAM on MMC1B and MMC1C (0: enabled; 1: disabled; ignored on MMC1A)
	
	_prgromBanksDidChange = YES;
	_mmc1PRGROMBankRegister = byte;
}

- (void)_setMMC1ControlRegister:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	// NSLog(@"MMC1: Setting control register to 0x%2x.",byte);
	
	
	// Set Mirroring Mode
	switch (byte & 0x3) {
			
		case 0:
			// Single-Screen Mirroring (Lower Bank)
			// NSLog(@"MMC1 Switcing to Single-Screen (Lower Bank) Mirroring Mode");
			[_ppu changeMirroringTypeTo:NESSingleScreenLowerMirroring onCycle:cycle];
			break;
		case 1:
			// Single-Screen Mirroring (Upper Bank)
			[_ppu changeMirroringTypeTo:NESSingleScreenUpperMirroring onCycle:cycle];
			break;
		case 2:
			// Vertical Mirroring
			// NSLog(@"MMC1 Switcing to Vertical Mirroring Mode");
			[_ppu changeMirroringTypeTo:NESVerticalMirroring onCycle:cycle];
			break;
		case 3:
			// Horizontal Mirroring
			// NSLog(@"MMC1 Switcing to Horizontal Mirroring Mode");
			[_ppu changeMirroringTypeTo:NESHorizontalMirroring onCycle:cycle];
			break;
	}
	
	// PRGROM Bank Switing Mode
	_mmc1Switch16KBPRGROMBanks = (byte & 0x8) ? YES : NO;
	/*
	if (_mmc1Switch16KBPRGROMBanks) NSLog(@"MMC1 Using 16KB PRGROM Banks");
	else NSLog(@"MMC1 Using 32KB PRGROM Banks"); 
	*/
	_mmc1SwitchFirst16KBBank = (byte & 0x4) ? YES : NO;
	/*
	if (_mmc1SwitchFirst16KBBank) NSLog(@"MMC1 Will Switch Lower PRGROM Bank in 16KB Bank Mode");
	else NSLog(@"MMC1 Will Switch Upper PRGROM Bank in 16KB Bank Mode");
	*/
	
	// CHRROM Bank Switching Mode
	_mmc1Switch4KBCHRROMBanks = (byte & 0x10) ? YES : NO;
	/*
	if (_mmc1Switch4KBCHRROMBanks) NSLog(@"MMC1 Using 4KB CHRROM Banks");
	else NSLog(@"MMC1 Using 8KB CHRROM Banks");
	*/
	
	// Store the current values
	_mmc1ControlRegister = byte;
	
	// Reset all pointers to reflect the changed settings
	[self _setMMC1CHRROMBank0Register:_mmc1CHRROMBank0Register];
	[self _setMMC1CHRROMBank1Register:_mmc1CHRROMBank1Register];
	[self _setMMC1PRGROMBankRegister:_mmc1PRGROMBankRegister];
}

- (id)initWithPPU:(NESPPUEmulator *)ppuEmulator
{
	[super init];
	
	[self _resetCartridgeState];
	_ppu = ppuEmulator;
	
	return self;
}

- (void)dealloc
{
	[self clearROMdata];	
	[super dealloc];
}

- (void)clearROMdata
{
	[self _cleanUpPRGROMMemory];
	[self _cleanUpCHRROMMemory];
	[self _cleanUpTrainerMemory];
	[self _resetCartridgeState];
	[_lastROMPath release];
}

- (NSError *)_setROMPointers
{
	switch (_mapperNumber) {
	
		case 0:	
			
			// NROM (No Mapper)
			_prgromBank0 = _prgromBanks[0];
			_prgromBank1 = _prgromBanks[0];
			
			if (_numberOfPRGROMBanks > 1) {

				_prgromBank1 = _prgromBanks[1];
			}

			_patternTable0 = _chrromBanks[0];
			_patternTable1 = _chrromBanks[0] + 4096;
			
			// This should be acceptable as the iNES format dictates 8kB CHRROM segments
			if (_numberOfCHRROM8KBBanks > 0) {
				
				_chrromBank0Index = 0;
				_chrromBank1Index = 1;
			}
			else _usesCHRRAM = YES;
			
			break;
			
		case 1:
			
			// MMC1
			_prgromBank0 = _prgromBanks[0];
			_prgromBank1 = _prgromBanks[_numberOfPRGROMBanks - 1];
			
			// FIXME: I'm assuming that MMC1 will map in the lowest 8KB of CHRROM if present. Not sure if that's correct.
			if (_numberOfCHRROM8KBBanks > 0) {
			
				_patternTable0 = _chrromBanks[0];
				_patternTable1 = _chrromBanks[0] + 4096;
			
				// This should be acceptable as the iNES format dictates 8kB CHRROM segments
				_chrromBank0Index = 0;
				_chrromBank1Index = 1;
			}
			else {
			
				_usesCHRRAM = YES;
			}
			break;
		
		case 2:
			
			// UxROM
			_prgromBank0 = _prgromBanks[0];
			_prgromBank1 = _prgromBanks[_numberOfPRGROMBanks - 1];
			
			_usesCHRRAM = YES;
			break;
			
		case 3:
			
			// CNROM
			_prgromBank0 = _prgromBanks[0];
			_prgromBank1 = _prgromBanks[0];
			
			if (_numberOfPRGROMBanks > 1) {
				
				_prgromBank1 = _prgromBanks[1];
			}
			
			_patternTable0 = _chrromBanks[0];
			_patternTable1 = _chrromBanks[0] + 4096;
			
			// This should be acceptable as the iNES format dictates 8kB CHRROM segments
			_chrromBank0Index = 0;
			_chrromBank1Index = 1;
			break;
			
		case 7:
			
			// AOROM
			_prgromBank0 = _prgromBanks[0];
			_prgromBank1 = _prgromBanks[1];
			
			_usesCHRRAM = YES;
			break;
			
		default:
			return [NSError errorWithDomain:@"NESMapperErrorDomain" code:11 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"Unsupported iNES Mapper",NSLocalizedDescriptionKey,[NSString stringWithFormat:@"Macifom was unable to load the selected file as it specifies an unsupported iNES mapper: %@",[self mapperDescription]],NSLocalizedRecoverySuggestionErrorKey,nil]];
			break;
	}
	
	return nil;
}

- (NSError *)_loadiNESROMOptions:(NSData *)header
{
	if ([header length] < 16) {
	
		_romFileDidLoad = NO;
		return [NSError errorWithDomain:@"NESFileErrorDomain" code:4 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"iNES file is corrupt.",NSLocalizedDescriptionKey,@"Macifom was unable to parse the selected file as the iNES header is corrupt.",NSLocalizedRecoverySuggestionErrorKey,nil]];
	}
	
	uint8_t lowerOptionsByte = *((uint8_t *)[header bytes]+6);
	uint8_t higherOptionsByte = *((uint8_t *)[header bytes]+7);
	uint8_t ramBanksByte = *((uint8_t *)[header bytes]+8);
	uint8_t videoModeByte = *((uint8_t *)[header bytes]+9);
	uint8_t count, highBytesSum = 0;
	
	// Detect headers with junk in bytes 9-15 and zero out bytes 7 and higher, assuming earlier iNES format
	for (count = 10; count < 16; count++) highBytesSum += *((uint8_t *)[header bytes]+count);
	if (highBytesSum != 0) {
	
		higherOptionsByte = 0;
		ramBanksByte = 1; // Let's assume that this is in the earlier iNES format and 1kB of RAM is implied
		videoModeByte = 0;
	}
	
	_numberOfPRGROMBanks = *((uint_fast8_t *)[header bytes]+4);
	_numberOfCHRROM8KBBanks = *((uint_fast8_t *)[header bytes]+5);
	_numberOfRAMBanks = ramBanksByte; // Fayzullin's docs say to assume 1x8kB RAM when zero to account for earlier format
	
	_usesVerticalMirroring = (lowerOptionsByte & 1) ? YES : NO;
	_usesBatteryBackedRAM = (lowerOptionsByte & (1 << 1)) ? YES : NO;
	_hasTrainer = (lowerOptionsByte & (1 << 2)) ? YES : NO;
	_usesFourScreenVRAMLayout = (lowerOptionsByte & (1 << 3)) ? YES : NO;
	_isPAL = videoModeByte ? YES : NO;
	
	_mapperNumber = ((lowerOptionsByte & 0xF0) >> 4) + (higherOptionsByte & 0xF0);
	
	return nil;
}

- (NSError *)_loadiNESFileAtPath:(NSString *)path
{
	uint_fast8_t bank;
	NSData *rom;
	NSData *savedSram;
	NSError *propagatedError = nil;
	BOOL loadErrorOccurred = NO;
	NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:path];
	
	if (fileHandle == nil) {
		
		_romFileDidLoad = NO;
		return [NSError errorWithDomain:@"NESFileErrorDomain" code:1 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"File could not be opened.",NSLocalizedDescriptionKey,@"Macifom was unable to open the file selected.",NSLocalizedRecoverySuggestionErrorKey,path,NSFilePathErrorKey,nil]];
	}
	
	NSData *header = [fileHandle readDataOfLength:16]; // Attempt to load 16 byte iNES Header
	
	// File format validation, must be iNES
	// Should check if the file is 4 chars long, need to figure out fourth char in header format
	if ((*((const char *)[header bytes]) != 'N') || (*((const char *)[header bytes]+1) != 'E') || (*((const char *)[header bytes]+2) != 'S')) {
	
		_romFileDidLoad = NO;
		return [NSError errorWithDomain:@"NESFileErrorDomain" code:2 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"File is not in iNES format.",NSLocalizedDescriptionKey,@"Macifom was unable to parse the selected file as it does not appear to be in iNES format.",NSLocalizedRecoverySuggestionErrorKey,path,NSFilePathErrorKey,nil]];
	}
	
	// Blast existing memory
	[self clearROMdata];
	
	// Store path to rom
	_lastROMPath = [path retain];
	
	// Load ROM Options
	if (nil != (propagatedError = [self _loadiNESROMOptions:header])) {
	
		_romFileDidLoad = NO;
		return propagatedError;
	}
	
	// Extract Trainer If Present
	if (_hasTrainer) {
	
		if (_trainer == NULL) _trainer = (uint8_t *)malloc(sizeof(uint8_t)*512);
		NSData *trainer = [fileHandle readDataOfLength:512];
		[trainer getBytes:_trainer];
	}
	
	// Extract PRGROM Banks
	_prgromBanks = (uint8_t **)malloc(sizeof(uint8_t*)*_numberOfPRGROMBanks);
	for (bank = 0; bank < _numberOfPRGROMBanks; bank++) {
	
		_prgromBanks[bank] = (uint8_t *)malloc(sizeof(uint8_t)*16384);
		rom = [fileHandle readDataOfLength:16384]; // PRG-ROMs have 16kB banks
		if ([rom length] != 16384) loadErrorOccurred = YES;
		else [rom getBytes:_prgromBanks[bank]];
	}
	
	// Extract CHRROM Banks
	_chrromBanks = (uint8_t **)malloc(sizeof(uint8_t*)*_numberOfCHRROM8KBBanks);
	for (bank = 0; bank < _numberOfCHRROM8KBBanks; bank++) {
		
		_chrromBanks[bank] = (uint8_t *)malloc(sizeof(uint8_t)*8192);
		rom = [fileHandle readDataOfLength:8192]; // CHR-ROMs have 8kB banks
		if ([rom length] != 8192) loadErrorOccurred = YES;
		else [rom getBytes:_chrromBanks[bank]];
	}
	
	// FIXME: Always allocating SRAM, because I'm not sure how to detect it yet, this may just be leaked
	_sram = (uint8_t *)malloc(sizeof(uint8_t)*SRAM_SIZE);
	
	// Close ROM file
	[fileHandle closeFile];
	
	if (loadErrorOccurred) {
	
		_romFileDidLoad = NO;
		return [NSError errorWithDomain:@"NESFileErrorDomain" code:3 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ROM data could not be extracted.",NSLocalizedDescriptionKey,@"Macifom was unable to extract the ROM data from the selected file. This is likely due to file corruption or inaccurate header information.",NSLocalizedRecoverySuggestionErrorKey,path,NSFilePathErrorKey,nil]];
	}
	
	// Load SRAM data, if present
	if (_usesBatteryBackedRAM) {
	
		savedSram = [NSData dataWithContentsOfFile:[NSString stringWithFormat:@"%@.sav",[_lastROMPath stringByDeletingPathExtension]]];
		if (savedSram) {
		
			[savedSram getBytes:_sram length:SRAM_SIZE];
		}
	}
	
	// Cache CHRROM data if needed
	[self _cacheCHRROM];
	
	// Set ROM pointers
	if (nil != (propagatedError = [self _setROMPointers])) {
		
		_romFileDidLoad = NO;
		return propagatedError;
	}
	
	// Configure PPU
	// FIXME: Need to support 4-screen mirroring
	if (_usesVerticalMirroring) [_ppu setMirroringType:NESVerticalMirroring];
	else {
		
		// AxROM
		if (_mapperNumber == 7) [_ppu setMirroringType:NESSingleScreenLowerMirroring];
		else [_ppu setMirroringType:NESHorizontalMirroring];
	}
	
	if (_usesCHRRAM) [_ppu configureForCHRRAM];
	else {
		
		// Allow PPU Emulator to cache CHRROM tile cache pointers
		[_ppu setCHRROMTileCachePointersForBank0:[self pointerToCHRROMBank0TileCache] bank1:[self pointerToCHRROMBank1TileCache]];
		[_ppu setCHRROMPointersForBank0:[self pointerToCHRROMBank0] bank1:[self pointerToCHRROMBank1]];
	}
	
	return propagatedError;
}

- (NSError *)loadROMFileAtPath:(NSString *)path
{
	// Right now, only iNES format is supported
	return [self _loadiNESFileAtPath:path];
}

- (uint8_t)readByteFromPRGROM:(uint16_t)offset
{	
	if (offset < 0xC000) return _prgromBank0[offset-0x8000];
	return _prgromBank1[offset-0xC000];
}

- (uint16_t)readAddressFromPRGROM:(uint16_t)offset
{
	uint16_t address = [self readByteFromPRGROM:offset] + ((uint16_t)[self readByteFromPRGROM:offset+1] * 256); // Think little endian
	return address;
}

- (uint8_t)readByteFromCHRROM:(uint16_t)offset
{	
	if (offset < 0x1000) return _patternTable0[offset];
	return _patternTable1[offset-0x1000];
}

- (uint8_t)readByteFromSRAM:(uint16_t)address 
{
	// NSLog(@"Reading byte 0x%2.2x from SRAM address 0x%4.4x",_sram[address & 0x1FFF],address);
	return _sram[address & 0x1FFF];
}

- (uint8_t)readByteFromControlRegister:(uint16_t)address
{
	return 0;
}

- (void)writeByte:(uint8_t)byte toSRAMwithCPUAddress:(uint16_t)address
{
	_sram[address & 0x1FFF] = byte;
	// NSLog(@"Writing byte 0x%2.2x to SRAM address 0x%4.4x",byte,address);
}

- (void)writeByte:(uint8_t)byte toPRGROMwithCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle
{
	switch (_mapperNumber) {
		case 1:
			if (byte & 0x80) {
			
				// NSLog(@"MMC1 Mapper Reset Triggered");
				[self _setMMC1ControlRegister:_mmc1ControlRegister | 0xC onCycle:cycle];
				_register = 0;
				_serialWriteCounter = 0;
			}
			else {
				
				_register |= ((byte & 0x1) << _serialWriteCounter++); // OR in next serial bit
			
				// NSLog(@"MMC1: Bit %d written to address 0x%4x on write #%d.",byte & 0x1,address,_serialWriteCounter);
				// Commit a change on the 5th Write
				if (_serialWriteCounter == 5) {
			
					// NSLog(@"MMC1: 5th write has occurred, setting register.");
					if (address < 0xA000) {
					
						// Control Register Write
						[self _setMMC1ControlRegister:_register onCycle:cycle];
					}
					else if (address < 0xC000) {
					
						[_ppu runPPUUntilCPUCycle:cycle];
						[self _setMMC1CHRROMBank0Register:_register];
					}
					else if (address < 0xE000) {
					
						[_ppu runPPUUntilCPUCycle:cycle];
						[self _setMMC1CHRROMBank1Register:_register];
					}
					else {
					
						[self _setMMC1PRGROMBankRegister:_register];
					}
					
					_register = 0;
					_serialWriteCounter = 0;
				}
			}
			break;
		case 2:
			// For UxROM, switch the lower PRGROM bank
			_prgromBank0 = _prgromBanks[byte & (_numberOfPRGROMBanks > 8 ? 0xF : 0x7)];
			_prgromBanksDidChange = YES;
			break;
		case 3:
			// If we're CNROM we need to switch the CHRROM banks
			_patternTable0 = _chrromBanks[byte & 0x3];
			_patternTable1 = _chrromBanks[byte & 0x3] + 4096;
			_chrromBank0Index = (byte & 0x3) * 2;
			_chrromBank1Index = ((byte & 0x3) * 2) + 1;
			_chrromBanksDidChange = YES;
			break;
		case 7:
			
			// For AxROM switch a 32KB PRGROM bank
			_prgromBank0 = _prgromBanks[(byte & 0x7) * 2];
			_prgromBank1 = _prgromBanks[((byte & 0x7) * 2) + 1];
			
			if (byte & 0x10) [_ppu changeMirroringTypeTo:NESSingleScreenUpperMirroring onCycle:cycle];
			else [_ppu changeMirroringTypeTo:NESSingleScreenLowerMirroring onCycle:cycle];
			
			_prgromBanksDidChange = YES;
			
			break;
		default:
			break;
	}
}

- (NSString *)mapperDescription
{
	return [NSString stringWithCString:mapperDescriptions[_mapperNumber] encoding:NSASCIIStringEncoding];
}

- (uint8_t *)pointerToPRGROMBank0 
{
	return _prgromBank0;
}

- (uint8_t *)pointerToPRGROMBank1
{
	return _prgromBank1;
}

- (uint8_t *)pointerToCHRROMBank0
{
	return _patternTable0;
}

- (uint8_t *)pointerToCHRROMBank1
{
	return _patternTable1;
}

- (uint8_t ***)pointerToCHRROMBank0TileCache
{
	return _chrromCache[_chrromBank0Index];
}

- (uint8_t ***)pointerToCHRROMBank1TileCache
{
	return _chrromCache[_chrromBank1Index];
}

- (uint8_t *)pointerToSRAM
{
	return _sram;
}

- (BOOL)prgromBanksDidChange
{
	BOOL valueToReturn = _prgromBanksDidChange;
	_prgromBanksDidChange = NO;
	return valueToReturn;
}

- (BOOL)chrromBanksDidChange
{
	BOOL valueToReturn = _chrromBanksDidChange;
	_chrromBanksDidChange = NO;
	return valueToReturn;	
}

- (BOOL)writeSRAMToDisk
{
	NSData *sramData;
	
	if (_usesBatteryBackedRAM) {
		
		sramData = [NSData dataWithBytes:_sram length:SRAM_SIZE];
		return [sramData writeToFile:[NSString stringWithFormat:@"%@.sav",[_lastROMPath stringByDeletingPathExtension]] atomically:NO];
	}
	
	return NO;
}

@end
