/*  NESTxROMCartridge.m
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

#import "NESTxROMCartridge.h"
#import "NESPPUEmulator.h"

@implementation NESTxROMCartridge

- (void)_switch1KBCHRROMBank:(uint_fast32_t)bank toBank:(uint_fast32_t)index
{
	uint_fast32_t bankCounter;
	uint_fast32_t selected1KBBank = index * BANK_SIZE_1KB / CHRROM_BANK_SIZE;
	
	// Rebuild CHRROM indices
	for (bankCounter = 0; bankCounter < (BANK_SIZE_1KB / CHRROM_BANK_SIZE); bankCounter++) {
		
		_chrromBankIndices[bankCounter + (bank * BANK_SIZE_1KB / CHRROM_BANK_SIZE)] = selected1KBBank + bankCounter;
	}
}

- (void)_switch2KBCHRROMBank:(uint_fast32_t)bank toBank:(uint_fast32_t)index
{
	uint_fast32_t bankCounter;
	uint_fast32_t selected2KBBank = index * BANK_SIZE_1KB / CHRROM_BANK_SIZE;
	
	// Rebuild CHRROM indices
	for (bankCounter = 0; bankCounter < (BANK_SIZE_2KB / CHRROM_BANK_SIZE); bankCounter++) {
		
		_chrromBankIndices[bankCounter + (bank * BANK_SIZE_2KB / CHRROM_BANK_SIZE)] = selected2KBBank + bankCounter;
	}
}

- (void)_switch8KBPRGROMBank:(uint_fast32_t)bank toBank:(uint_fast32_t)index
{
	uint_fast32_t bankCounter;
	uint_fast32_t selected8KBBank = index * (BANK_SIZE_8KB / PRGROM_BANK_SIZE);
	
	// Establish PRGROM indices
	for (bankCounter = 0; bankCounter < (BANK_SIZE_8KB / PRGROM_BANK_SIZE); bankCounter++) {
		
		_prgromBankIndices[bankCounter + (bank * BANK_SIZE_8KB / PRGROM_BANK_SIZE)] = selected8KBBank + bankCounter;
	}
}

- (void)_updateCHRROMBankForRegister:(uint8_t)reg
{
	switch (reg) {
			
		case 0:
			// Select 2 KB CHR bank at PPU $0000-$07FF (or $1000-$17FF)
			[self _switch2KBCHRROMBank:(_mmc3LowCHRROMIn1kbBanks ? 2 : 0) toBank:_mmc3BankRegisters[0]];
			break;
		case 1:
			// Select 2 KB CHR bank at PPU $0800-$0FFF (or $1800-$1FFF)
			[self _switch2KBCHRROMBank:(_mmc3LowCHRROMIn1kbBanks ? 3 : 1) toBank:_mmc3BankRegisters[1]];
		case 2:
			// Select 1 KB CHR bank at PPU $1000-$13FF (or $0000-$03FF)
			[self _switch1KBCHRROMBank:(_mmc3LowCHRROMIn1kbBanks ? 0 : 4) toBank:_mmc3BankRegisters[2]];
			break;
		case 3:	
			// Select 1 KB CHR bank at PPU $1400-$17FF (or $0400-$07FF)
			[self _switch1KBCHRROMBank:(_mmc3LowCHRROMIn1kbBanks ? 1 : 5) toBank:_mmc3BankRegisters[3]];
			break;
		case 4:
			// Select 1 KB CHR bank at PPU $1800-$1BFF (or $0800-$0BFF)
			[self _switch1KBCHRROMBank:(_mmc3LowCHRROMIn1kbBanks ? 2 : 6) toBank:_mmc3BankRegisters[4]];
			break;
		case 5:
			// Select 1 KB CHR bank at PPU $1C00-$1FFF (or $0C00-$0FFF)
			[self _switch1KBCHRROMBank:(_mmc3LowCHRROMIn1kbBanks ? 3 : 7) toBank:_mmc3BankRegisters[5]];
			break;
		default:
			break;
	}	
}

- (void)_updatePRGROMBankForRegister:(uint8_t)reg
{
	switch (reg) {
	
		case 6:
			// Select 8 KB PRG bank at $8000-$9FFF (or $C000-$DFFF)
			[self _switch8KBPRGROMBank:(_mmc3HighPRGROMSwappable ? 2 : 0) toBank:_mmc3BankRegisters[6]];
			break;
		case 7:
			// Select 8 KB PRG bank at $A000-$BFFF
			[self _switch8KBPRGROMBank:1 toBank:_mmc3BankRegisters[7]];
			break;
		default:
			break;
	}
}

- (void)_updateCHRROMBanks
{
	uint_fast32_t registerIndex;
	
	for (registerIndex = 0; registerIndex < 6; registerIndex++) {
	
		[self _updateCHRROMBankForRegister:registerIndex];
	}
}

- (void)_updatePRGROMBanks
{
	[self _updateCHRROMBankForRegister:6];
	[self _updateCHRROMBankForRegister:7];
	
	// Either 0x8000-0x9FFF or 0xC000-0xDFFF is fixed to second-to-last 8KB PRGROM bank
	[self _switch8KBPRGROMBank:(_mmc3HighPRGROMSwappable ? 0 : 2) toBank:((_iNesFlags->prgromSize - BANK_SIZE_16KB) / BANK_SIZE_8KB)];
}

- (void)writeByte:(uint8_t)byte toPRGROMwithCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle
{
	BOOL oldCHRROMBankConfiguration;
	BOOL oldPRGROMBankConfiguration;
	
	if (address < 0xA000) {
	
		// 0x8000 - 0x9FFF: Bank Select / Bank Data
		if (address & 0x1) {
			
			// Bank Data
			_mmc3BankRegisters[_bankRegisterToUpdate] = byte;
			
			if (_bankRegisterToUpdate < 6) {
			
				// CHRROM Bank Update
				[_ppu runPPUUntilCPUCycle:cycle];
				[self _updateCHRROMBankForRegister:_bankRegisterToUpdate];
				[self rebuildCHRROMPointers];
			}
			else {
				
				// PRGROM Bank update
				[self _updatePRGROMBankForRegister:_bankRegisterToUpdate];
				[self rebuildPRGROMPointers];
			}
		}
		else {
			
			// Bank Select
			_bankRegisterToUpdate = byte & 0x7;
			
			oldCHRROMBankConfiguration = _mmc3LowCHRROMIn1kbBanks;
			oldPRGROMBankConfiguration = _mmc3HighPRGROMSwappable;
			
			_mmc3LowCHRROMIn1kbBanks = (byte & 0x80 ? YES : NO);
			_mmc3HighPRGROMSwappable = (byte & 0x40 ? YES : NO);
			
			if (_mmc3LowCHRROMIn1kbBanks != oldCHRROMBankConfiguration) {
			
				[_ppu runPPUUntilCPUCycle:cycle];
				[self _updateCHRROMBanks];
				[self rebuildCHRROMPointers];
			}
			
			if (_mmc3HighPRGROMSwappable != oldPRGROMBankConfiguration) {
				
				[self _updatePRGROMBanks];
				[self rebuildPRGROMPointers];
			}
		}
	}
	else if (address < 0xC000) {
		
		// 0xA000 - 0xBFFF: Mirroring / WRAM Protect
		if (address & 0x1) {
			
			// WRAM Protect
			_mmc3WRAMChipEnable = (byte & 0x80 ? YES : NO);
			_mmc3WRAMWriteDisable = (byte & 0x40 ? YES : NO);
		}
		else {
			
			// Mirroring
			[_ppu changeMirroringTypeTo:(byte & 0x1 ? NESHorizontalMirroring : NESVerticalMirroring) onCycle:cycle];
		}
	}
	else if (address < 0xE000) {
		
		// 0xC000 - 0xDFFF: IRQ Latch / IRQ Reload
		if (address & 0x1) {
			
			// IRQ Reload
			// Writing any value to this register clears the MMC3 IRQ counter so that it will be reloaded at the end of the current scanline.
			_mmc3IRQCounter = 0;
		}
		else {
			
			// IRQ Latch
			_mmc3IRQCounterReloadValue = byte;
		}
	}
	else {
		
		// 0xE000 - 0xFFFF: IRQ Disable / IRQ Enable
		if (address & 0x1) {
			
			// IRQ Enable
			_mmc3IRQEnabled = YES;
		}
		else {
			
			// IRQ Disable
			// Writing any value to this register will disable MMC3 interrupts AND acknowledge any pending interrupts.
			_mmc3IRQEnabled = NO;
			
			// FIXME: MMC3 interrupt handling is needed.
		}
	}
}

- (void)setInitialROMPointers
{	
	uint_fast32_t registerIndex;
		
	_mmc3IRQEnabled = NO;
	_mmc3HighPRGROMSwappable = NO;
	_mmc3LowCHRROMIn1kbBanks = NO;
	_mmc3WRAMWriteDisable = NO;
	_mmc3WRAMChipEnable = NO;
		
	_mmc3IRQCounter = 0;
	_mmc3IRQCounterReloadValue = 0;
	_bankRegisterToUpdate = 0;
		
	for (registerIndex = 0; registerIndex < 8; registerIndex++) {
			
		_mmc3BankRegisters[registerIndex] = 0;
	}
	
	// CPU $E000-$FFFF: 8 KB PRG ROM bank, fixed to the last bank
	[self _switch8KBPRGROMBank:3 toBank:((_iNesFlags->prgromSize - BANK_SIZE_8KB) / BANK_SIZE_8KB)];
	[self _updatePRGROMBanks];
	[self rebuildPRGROMPointers];
	
	[self _updateCHRROMBanks];
	[self rebuildCHRROMPointers];
	
	[_ppu observeA12RiseForTarget:self andSelector:@selector(ppuA12EdgeRose)];
}

- (void)ppuA12EdgeRose
{
	
}

@end
