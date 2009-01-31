//
//  NESCartridgeEmulator.h
//  Macifom
//
//  Created by Auston Stewart on 7/27/08.
//

#import <Cocoa/Cocoa.h>

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
	
	uint_fast8_t _mapperNumber;
	uint_fast8_t _numberOfPRGROMBanks;
	uint_fast8_t _numberOfCHRROM8KBBanks;
	uint_fast8_t _numberOfRAMBanks;
	uint_fast8_t _chrromBank0Index;
	uint_fast8_t _chrromBank1Index;

	BOOL _romFileDidLoad;
}

- (id)initWithiNESFileAtPath:(NSString *)path;
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
