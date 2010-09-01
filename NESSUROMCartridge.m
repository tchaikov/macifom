//
//  NESSUROMCartridge.m
//  Macifom
//
//  Created by Auston Stewart on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NESSUROMCartridge.h"


@implementation NESSUROMCartridge

- (uint_fast32_t)_outerPRGROMBankSize
{
	return BANK_SIZE_256KB;
}

- (void)_switch16KBPRGROMBank:(uint_fast32_t)bank toBank:(uint_fast32_t)index
{
	uint_fast32_t bankCounter;
	uint_fast32_t selected16KBBank = index * (BANK_SIZE_16KB / PRGROM_BANK_SIZE);
	
	// Establish PRGROM indices
	for (bankCounter = 0; bankCounter < (BANK_SIZE_16KB / PRGROM_BANK_SIZE); bankCounter++) {
		
		_prgromBankIndices[bankCounter + (bank * BANK_SIZE_16KB / PRGROM_BANK_SIZE)] = _suromPRGROMBankOffset + selected16KBBank + bankCounter;
	}
}

- (void)_switch32KBPRGROMToBank:(uint_fast32_t)index
{
	uint_fast32_t bankCounter;
	uint_fast32_t selected32KBBank = index * (PRGROM_APERTURE_SIZE / PRGROM_BANK_SIZE);
	
	// Establish PRGROM indices
	for (bankCounter = 0; bankCounter < (PRGROM_APERTURE_SIZE / PRGROM_BANK_SIZE); bankCounter++) {
		
		_prgromBankIndices[bankCounter] = _suromPRGROMBankOffset + selected32KBBank + bankCounter;
	}
}

- (void)_setMMC1CHRROMBank0Register:(uint8_t)byte
{
	[super _setMMC1CHRROMBank0Register:byte];
	
	_suromPRGROMBankOffset = (byte & 0x10) ? BANK_SIZE_256KB / PRGROM_BANK_SIZE : 0;
	[self _setMMC1PRGROMBankRegister:_mmc1PRGROMBankRegister]; // Force an update to the PRGROM indices
}

- (void)_setMMC1CHRROMBank1Register:(uint8_t)byte
{
	[super _setMMC1CHRROMBank1Register:byte];
	
	if (_mmc1Switch4KBCHRROMBanks) {
		
		_suromPRGROMBankOffset = (byte & 0x10) ? BANK_SIZE_256KB / PRGROM_BANK_SIZE : 0;
		[self _setMMC1PRGROMBankRegister:_mmc1PRGROMBankRegister]; // Force an update to the PRGROM indices
	}
}

- (void)setInitialROMPointers
{
	_suromPRGROMBankOffset = 0;
	[super setInitialROMPointers];
}

@end
