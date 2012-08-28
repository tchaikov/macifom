//
//  NESNamco106Cartridge.m
//  Macifom
//
//  Created by Kefu Chai on 28/08/12.
//
//

#import <Foundation/Foundation.h>

#import "NESNamco106Cartridge.h"
#import "NESPPUEmulator.h"

@implementation NESNamco106Cartridge

- (void)_switch8KBPRGROMBank:(uint_fast32_t)bank toBank:(uint_fast32_t)index
{
	uint_fast32_t selected8KBBank = (index & _prgromIndexMask) * (BANK_SIZE_8KB / PRGROM_BANK_SIZE);

	// Establish PRGROM indices
	for (uint_fast32_t bankCounter = 0; bankCounter < (BANK_SIZE_8KB / PRGROM_BANK_SIZE); bankCounter++) {
		_prgromBankIndices[bankCounter + (bank * BANK_SIZE_8KB / PRGROM_BANK_SIZE)] = selected8KBBank + bankCounter;
	}
}

- (void)_switch1KBCHRROMBank:(uint_fast32_t)bank toBank:(uint_fast32_t)index
{
	uint_fast32_t selected1KBBank = (index & _chrromIndexMask) * BANK_SIZE_1KB / CHRROM_BANK_SIZE;

	// Rebuild CHRROM indices
	for (uint_fast32_t bankCounter = 0; bankCounter < (BANK_SIZE_1KB / CHRROM_BANK_SIZE); bankCounter++) {
		_chrromBankIndices[bankCounter + (bank * BANK_SIZE_1KB / CHRROM_BANK_SIZE)] = selected1KBBank + bankCounter;
	}
}
- (void)writeByte:(uint8_t)byte toPRGROMwithCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle
{
    NSAssert(address >= 0x8000, @"neither CHRROM nor PROGROM space");
    if (address < 0xC000) {
        // Select 1K VROM bank at PPU $0000 ~ $1C00
        uint8_t bank = (address - 0x8000) >> 11;
        [_ppu runPPUUntilCPUCycle:cycle];
        [self _switch1KBCHRROMBank:bank toBank:byte];
        [self rebuildCHRROMPointers];
    }
    else if (address < 0xC800) {
        // Select 1K VROM bank at PPU $2000 ~ $2C00
        // A value of $E0 or above will use VRAM instead
        uint8_t bank = (address - 0x8000) >> 11;
        [_ppu runPPUUntilCPUCycle:cycle];
        if (byte < 0xE0) {
            // use CHR-SRAM
        } else {
            [self _switch1KBCHRROMBank:bank toBank:byte];
            [self rebuildCHRROMPointers];
        }
    }
    else if (address < 0xF800) {
        // Select 8K ROM bank at $8000 ~ $DFFF
        uint8_t prgrom_bank = (address - 0xE800) >> 11;
        [self _switch8KBPRGROMBank:prgrom_bank toBank:byte];
        [self rebuildPRGROMPointers];
    }
    else if (address == 0xF800) {
        // Expand I/O address register
    }
}

- (void)setInitialROMPointers
{
    [super setInitialROMPointers];

    _prgromIndexMask = (_iNesFlags->prgromSize / BANK_SIZE_8KB) - 1;
	_chrromIndexMask = (_iNesFlags->chrromSize / BANK_SIZE_1KB) - 1;

	// When the cart is first started, the first two 8K swappable ROM bank in the cart
    // is loaded into $8000.
    uint_fast32_t bank = 0;
    uint_fast32_t bankIndex = 0;

    [self _switch8KBPRGROMBank:bank toBank:bankIndex];
    [self _switch8KBPRGROMBank:bank+1 toBank:bankIndex+1];
	// and the last two 8K ROM bank is loaded into $C000. The last 8K of ROM is
    // permanently "hard-wired" and cannot be swapped.
    bank = BANK_SIZE_16KB / PRGROM_BANK_SIZE;
    bankIndex = (_iNesFlags->prgromSize - BANK_SIZE_16KB) / PRGROM_BANK_SIZE;
    [self _switch8KBPRGROMBank:bank toBank:bankIndex];
    [self _switch8KBPRGROMBank:bank+1 toBank:bankIndex+1];
    [self rebuildPRGROMPointers];

    // The last eight 1K VROM is swapped into PPU $0000 on reset, if it
    // is present.
    bank = BANK_SIZE_16KB / PRGROM_BANK_SIZE;
    bankIndex = (_iNesFlags->prgromSize - BANK_SIZE_16KB) / PRGROM_BANK_SIZE;
	for (uint_fast32_t bankCounter = 0;
         bankCounter < (CHRROM_APERTURE_SIZE / BANK_SIZE_1KB);
         bankCounter++) {
        [self _switch1KBCHRROMBank:bank + bankCounter
                            toBank:bankIndex + bankCounter];
	}
    [self rebuildCHRROMPointers];
}

@end
