//
//  NESCartridgeEmulator.m
//  Macifom
//
//  Created by Auston Stewart on 7/27/08.
//

#import "NESCartridgeEmulator.h"

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
	
	_mapperNumber = 0;
	_numberOfPRGROMBanks = 0;
	_numberOfCHRROM8KBBanks = 0;
	_chrromBank0Index = 0;
	_chrromBank0Index = 1;
	_numberOfRAMBanks = 0;
	_romFileDidLoad = NO;
}

- (id)init
{
	[super init];
	
	[self _resetCartridgeState];
	
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
			_chrromBank0Index = 0;
			_chrromBank1Index = 1;
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
	_sram = (uint8_t *)malloc(sizeof(uint8_t)*8192);
	
	// Close ROM file
	[fileHandle closeFile];
	
	if (loadErrorOccurred) {
	
		_romFileDidLoad = NO;
		return [NSError errorWithDomain:@"NESFileErrorDomain" code:3 userInfo:[NSDictionary dictionaryWithObjectsAndKeys:@"ROM data could not be extracted.",NSLocalizedDescriptionKey,@"Macifom was unable to extract the ROM data from the selected file. This is likely due to file corruption or inaccurate header information.",NSLocalizedRecoverySuggestionErrorKey,path,NSFilePathErrorKey,nil]];
	}
	
	// Cache CHRROM data if needed
	[self _cacheCHRROM];
	
	// Set ROM pointers
	propagatedError = [self _setROMPointers];
	
	return propagatedError;
}

- (id)initWithiNESFileAtPath:(NSString *)path
{
	[super init];
	
	_prgromBanks = NULL;
	_chrromBanks = NULL;
	_prgromBank0 = NULL;
	_prgromBank1 = NULL;
	_patternTable0 = NULL;
	_patternTable1 = NULL;
	_trainer = NULL;
	
	_usesVerticalMirroring = NO;
	_hasTrainer = NO;
	_usesBatteryBackedRAM = NO;
	_usesFourScreenVRAMLayout = NO;
	_isPAL = NO;
	
	_mapperNumber = 0;
	_numberOfPRGROMBanks = 0;
	_numberOfCHRROM8KBBanks = 0;
	_numberOfRAMBanks = 0;
	_romFileDidLoad = NO;
	_prgromBanksDidChange = NO;
	_chrromBanksDidChange = NO;
	
	return self;
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
	return _sram[address & 0x1FFF];
}

- (uint8_t)readByteFromControlRegister:(uint16_t)address
{
	return 0;
}

- (void)writeByte:(uint8_t)byte toSRAMwithCPUAddress:(uint16_t)address
{
	_sram[address & 0x1FFF] = byte;
	// NSLog(@"Writing byte to SRAM address 0x%4.4x",address);
}

- (void)writeByte:(uint8_t)byte toPRGROMwithCPUAddress:(uint16_t)address
{
	switch (_mapperNumber) {
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

@end
