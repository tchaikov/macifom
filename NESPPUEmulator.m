//
//  NESPPUEmulator.m
//  Innuendo
//
//  Created by Auston Stewart on 7/27/08.
//

#import "NESPPUEmulator.h"
#import "NESCartridgeEmulator.h"

static const uint8_t colorPalette[64][3] = { { 0x75, 0x27, 0x00, 0x47, 0x8F, 0xAB, 0xA7, 0x7F, 0x43, 0x00, 0x00, 0x00, 0x1B, 0x00, 0x00, 0x00,
												0xBC, 0x00, 0x23, 0x83, 0xBF, 0xE7, 0xDB, 0xCB, 0x8B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
												0xFF, 0x3F, 0x5F, 0xA7, 0xF7, 0xFF, 0xFF, 0xFF, 0xF3, 0x83, 0x4F, 0x58, 0x00, 0x00, 0x00, 0x00,
												0xFF, 0xAB, 0xC7, 0xD7, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE3, 0xAB, 0xB3, 0x9F, 0x00, 0x00, 0x00 },
											{ 0x75, 0x1B, 0x00, 0x00, 0x00, 0x00, 0x00, 0x0B, 0x2F, 0x47, 0x51, 0x3F, 0x3F, 0x00, 0x00, 0x00,
											   0xBC, 0x73, 0x3B, 0x00, 0x00, 0x00, 0x2B, 0x4F, 0x73, 0x97, 0xAB, 0x93, 0x83, 0x00, 0x00, 0x00,
											   0xFF, 0xBF, 0x97, 0x8B, 0x7B, 0x77, 0x77, 0x9B, 0xBF, 0xD3, 0xDF, 0xF8, 0xEB, 0x00, 0x00, 0x00,
											   0xFF, 0xAB, 0xC7, 0xD7, 0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xE3, 0xAB, 0xB3, 0x9F, 0x00, 0x00, 0x00 }, 
											{ 0x75, 0x8F, 0xAB, 0x9F, 0x77, 0x13, 0x00, 0x00, 0x00, 0x00, 0x00, 0x17, 0x5F, 0x00, 0x00, 0x00
											  0xBC, 0xEF, 0xEF, 0xF3, 0xBF, 0x5B, 0x00, 0x0F, 0x00, 0x00, 0x00, 0x3B, 0x8B, 0x00, 0x00, 0x00
											  0xFF, 0xFF, 0xFF, 0xFD, 0xFF, 0xB7, 0x63, 0x3B, 0x3F, 0x13, 0x4B, 0x98, 0xDB, 0x00, 0x00, 0x00
											  0xFF, 0xFF, 0xFF, 0xFF, 0xFF, 0xDB, 0xB3, 0xAB, 0xA3, 0xA3, 0xBF, 0xCF, 0xF3, 0x00, 0x00, 0x00 } };

@implementation NESPPUEmulator

- (uint8_t)_invalidPPURegisterAccessOnCycle:(uint_fast32_t)cycle
{
	return 0;
}

- (void)_invalidPPURegisterWriteWithByte:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	
}

- (id)initWithBuffer:(NSBitmapImageRep *)buffer;
{
	[super init];
	
	_buffer = [buffer retain]; // hold onto our rendering buffer
	
	_cyclesSinceVINT = 0;
	_VRAMAddress = 0;
	_temporaryVRAMAddress = 0;
	_fineHorizontalScroll = 0x7;
	_firstWriteOccurred = NO;
	
	_sprRAM = (uint8_t *)malloc(sizeof(uint8_t)*256);
	_palettes = (uint8_t *)malloc(sizeof(uint8_t)*32);
	_backgroundPalette = _palettes;
	_spritePalette = (_palettes + 0x10);
	_nameAndAttributeTables = (uint8_t *)malloc(sizeof(uint8_t)*4096);
	_nameTable0 = _nameAndAttributeTables;
	_nameTable1 = _nameAndAttributeTables + 0x400;
	_nameTable2 = _nameAndAttributeTables + 0x800;
	_nameTable3 = _nameAndAttributeTables + 0xC00;
	_registerReadMethods = (RegisterReadMethod *)malloc(sizeof(uint8_t (*)(id, SEL, uint_fast32_t))*8);
	_registerWriteMethods = (RegisterWriteMethod *)malloc(sizeof(void (*)(id, SEL, uint8_t, uint_fast32_t))*8);
	_nameAndAttributeWriteMethods = (NameAttributeWriteMethod *)malloc(sizeof(void (*)(id, SEL, uint8_t, uint_fast32_t))*4);
	
	// Readable Registers
	_registerReadMethods[0] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(_invalidPPURegisterAccessOnCycle:)];
	_registerReadMethods[1] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(_invalidPPURegisterAccessOnCycle:)];
	_registerReadMethods[2] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(readFromPPUStatusRegisterOnCycle:)];
	_registerReadMethods[3] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(_invalidPPURegisterAccessOnCycle:)];
	_registerReadMethods[4] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(readFromSPRRAMIORegisterOnCycle:)];
	_registerReadMethods[5] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(_invalidPPURegisterAccessOnCycle:)];
	_registerReadMethods[6] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(_invalidPPURegisterAccessOnCycle:)];
	_registerReadMethods[7] = (uint8_t (*)(id, SEL, uint_fast32_t))[self methodForSelector:@selector(readFromVRAMIORegisterOnCycle:)];
	
	// Writable Registers
	_registerWriteMethods[0] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(writeToPPUControlRegister1:onCycle:)];
	_registerWriteMethods[1] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(writeToPPUControlRegister2:onCycle:)];
	_registerWriteMethods[2] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(_invalidPPURegisterWriteWithByte:onCycle:)];
	_registerWriteMethods[3] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(writeToSPRRAMAddressRegister:onCycle:)];
	_registerWriteMethods[4] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(writeToSPRRAMIOControlRegister:onCycle:)];
	_registerWriteMethods[5] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(writeToVRAMAddressRegister1:onCycle:)];
	_registerWriteMethods[6] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(writeToVRAMAddressRegister2:onCycle:)];
	_registerWriteMethods[7] = (void (*)(id, SEL, uint8_t, uint_fast32_t))[self methodForSelector:@selector(writeToVRAMIORegister:onCycle:)];
	
	return self;
}

- (void)writeByte:(uint8_t)byte toHorizontallyMirroredNameOrAttributeTableAddress:(uint_fast32_t)address
{
	uint_fast32_t offset = address & 0x3FF;
	
	if (address & 0x800) {
		
		_nameTable3[offset] = _nameTable2[offset] = byte;
	}
	else {
	
		_nameTable1[offset] = _nameTable0[offset] = byte;
	}
}

- (void)writeByte:(uint8_t)byte toVerticallyMirroredNameOrAttributeTableAddress:(uint_fast32_t)address
{
	uint_fast32_t offset = address & 0x3FF;
	
	if (address & 0x400) {
		
		_nameTable3[offset] = _nameTable1[offset] = byte;
	}
	else {
		
		_nameTable2[offset] = _nameTable0[offset] = byte;
	}
}

- (void)writeByte:(uint8_t)byte toSingleScreenNameOrAttributeTableAddress:(uint_fast32_t)address
{
	uint_fast32_t offset = address & 0x3FF;
	
	_nameTable3[offset] = _nameTable2[offset] = _nameTable1[offset] = _nameTable0[offset] = byte;
}

- (void)writeByte:(uint8_t)byte toFourScreenNameOrAttributeTableAddress:(uint_fast32_t)address
{
	_nameAndAttributeTables[address] = byte;
}

- (void)setMirroringType:(NESMirroringType)type
{
	_writeToNameOrAttributeTable = _nameAndAttributeWriteMethods[type];
}

- (BOOL)completeDrawingScanlineStoppingOnCycle:(uint_fast32_t)cycle
{
	uint_fast32_t cyclesPastPrimingScanline = _cyclesSinceVINT - ( _oddFrame ? 7160 : 7161);
	uint8_t currentScanline = cyclesPastPrimingScanline / 341;
	uint_fast32_t currentScanlineClockCycle = cyclesPastPrimingScanline % 341;
	uint_fast32_t endingCycle, cyclesToRun;
	BOOL didCompleteScanline = NO;
		
	if (!currentScanlineClockCycle) return YES; // Jump out if we're at the beginning of a scanline
	
	cyclesToRun = (cycle - ( _oddFrame ? 7160 : 7161)) - cyclesPastPrimingScanline;
	
	if (cyclesToRun >= (341 - currentScanlineClockCycle)) {
		
		endingCycle = 341;
		didCompleteScanline = YES;
	}
	else {
	
		endingCycle = cyclesToRun + currentScanlineClockCycle;
	}
	
	// Sprite Evaluation
	// Skip clearing of secondary OAM and start looking at sprites
	// FIXME: Make clearing of secondary OAM explicit
	if ((currentScanlineClockCycle) < 256 && (endingCycle >= 256)) {
	
		uint8_t counter, foundSprites = 0;
		int offsetFromCurrentScanline = 0;
		
		for (counter = 0; counter < 64; counter++) {
		
			offsetFromCurrentScanline = (int)currentScanline - _sprRAM[counter*4];
			if ((offsetFromCurrentScanline >= 0) && (offsetFromCurrentScanline <= 7)) {
			
				foundSprites++;
				
				if (foundSprites > 8) {
					
					_ppuStatusRegister | 0x20; // Register sprite overflow
					break;
				}
				
				_temporaryOAM[foundSprites*4] = _sprRAM[counter*4];
				_temporaryOAM[(foundSprites*4)+1] = _sprRAM[(counter*4)+1];
				_temporaryOAM[(foundSprites*4)+2] = _sprRAM[(counter*4)+2];
				_temporaryOAM[(foundSprites*4)+3] = _sprRAM[(counter*4)+3];
			}
		}
		// FIXME: A cycle-exact version should be used here
		/*
		 uint_fast32_t end = endingCycle < 256 ? endingCycle : 256;
		 BOOL oddCycle = counter & 0x1;
		 uint_fast32_t counter = (currentScanlineClockCycle < 64) ? 64 : (currentScanlineClockCycle - 64); // start at 0 or current
		 _sprRAMAddress = counter - 64;
		 
		while (counter < end) {
		
			if (oddCycle) {
			
				if (byteToEvaluate IS IN RANGE) {
					
					_temporaryOAM[availableTempOAMSlot++] = _sprRAM[_sprRAMAddress++];
			}
			else {
				
				byteToEvaluate = _sprRAM[_sprRAMAddress];
			}
			
			counter++;
		}
		 */
	}
	
	// Prime latches with sprite patterns
	// FIXME: This needs to by cycle-exact and potentially also model OAM reads in case SPRRAM IO is accessed
	if ((currentScanlineClockCycle) < 320 && (endingCycle >= 320)) {
	
		
	}
	
	// Drawing
		
	if (currentScanlineClockCycle < 256) {
		
	}
	
	_cyclesSinceVINT += cyclesToRun;
	
	return didCompleteScanline;
}

- (void)runPPUUntilCPUCycle:(uint_fast32_t)cycle
{
	uint_fast32_t endingCycle = cycle * 3;
	uint_fast32_t cyclesPastPrimingScanline;
	uint8_t endingScanline;
	
	// Just add cycles if we're still in VBLANK
	if (endingCycle < (341*20)) {
		
		_cyclesSinceVINT = endingCycle;
		return;
	}
	else {
	
		if (![self completePrimingScanlineStoppingOnCycle:endingCycle]) return;
	}
	
	cyclesPastPrimingScanline = _cyclesSinceVINT - ( _oddFrame ? 7160 : 7161);
	// complete the current unfinished scanline, if any, using cycle exact renderer
	if (cyclesPastPrimingScanline % 341) {
	
		if (![self completeDrawingScanlineStoppingOnCycle:endingCycle]) return;
	}
	else {
	
		// Determine last whole scanline to draw
		endingScanline = ((endingCycle  - ( _oddFrame ? 7160 : 7161)) / 341);
		endingScanline = endingScanline > 239 ? 239 : endingScanline;
		[self drawScanlines:(cyclesPastPrimingScanline / 341) through:endingScanline];
	}
	
	// complete next unfinished scanline, if any
	if (![self completeDrawingScanlineStoppingOnCycle:endingCycle]) return;
	
	if (endingCycle > (_oddFrame ? 89340 : 89341)) {
		
		// We're at the end of the frame.. we'll ignore the overage here, we really shouldn't call this method as-is for more than a frame
		
		_cyclesSinceVINT = _oddFrame ? 89341 : 89342; // Set such that we're at the end of the frame
		_ppuStatusRegister |= 0x80; // Set VLBANK flag
	}
	else {
	
		_cyclesSinceVINT = endingCycle;
	}
}

- (void)finishRenderingFrame
{
	[self runPPUUntilCPUCycle:89342]; // Run PPU until the end of the frame
	_cyclesSinceVINT = 0; // Reset cycles since VINT
	[_playFieldView setNeedsDisplay:YES]; // Flag view with playfield image for redraw
}

- (uint8_t)readByteFromPPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle
{
	return 0;
}

- (void)writeByte:(uint8_t)byte toPPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle
{
	
}

- (uint8_t)readByteFromCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle
{
	return _registerReadMethods[address & 0x7](self,@selector(_invalidPPURegisterAccessOnCycle:),cycle);
}

- (void)writeByte:(uint8_t)byte toPPUFromCPUAddress:(uint16_t)address onCycle:(uint_fast32_t)cycle
{
	_registerWriteMethods[address & 0x7](self,@selector(_invalidPPURegisterWriteWithByte:onCycle:),byte,cycle);
}

// 0x2000
//
- (void)writeToPPUControlRegister1:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	_ppuControlRegister1 = byte;
	_temporaryVRAMAddress &= (0x73FF | ((byte & 0x3) << 10)); // Put selected nametable into temporary PPU address
	_addressIncrement = (_ppuControlRegister1 & 0x4) ? 32 : 1; // Increment on write to $2007 by 32 if true
	_spriteTable = (_ppuControlRegister1 & 0x8) ? _chrromBank1 : _chrromBank0; // Get base address for spriteTable
	_backgroundTable = (_ppuControlRegister1 & 0x10) ? _chrromBank1 : _chrromBank0;
	_8x16Sprites = (_ppuControlRegister1 & 0x20);
	_NMIOnVBlank = (_ppuControlRegister1 & 0x80);
}

// 0x2001
//
- (void)writeToPPUControlRegister2:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	_ppuControlRegister2 = byte;
	
	_monochrome = _ppuControlRegister2 & 0x1;
	_clipBackground = _ppuControlRegister2 & 0x2;
	_clipSprites = _ppuControlRegister2 & 0x4;
	_backgroundEnabled = _ppuControlRegister2 & 0x8;
	_spritesEnabled = _ppuControlRegister2 & 0x10;
	_colorIntensity = _ppuControlRegister2 & 0xE0; // Top three bits are color intensity
}

- (void)writeToVRAMAddressRegister1:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	if (_firstWriteOccurred) {
	
		// thus spake loopy:
		// 2005 first write:
		// t:0000000000011111=d:11111000
		// x=d:00000111
		
		_temporaryVRAMAddress &= 0x7FE0; // Clear lower five bytes
		_temporaryVRAMAddress |= (byte / 8); // OR in upper five bytes of operand as the horizontal scroll
		_fineHorizontalScroll = (7 - (byte & 0x7)); // Lower three bits represent the fine horizontal scroll value (0-7)
		// Revsering the fine horizontal scroll as we don't reverse it otherwise as a result of CRT drawing
		
		_firstWriteOccurred = NO; // Reset toggle
	}
	else {
	
		// the word of loopy:
		// 2005 second write:
		// t:0000001111100000=d:11111000
		// t:0111000000000000=d:00000111
		
		_temporaryVRAMAddress &= 0x7C1F;
		_temporaryVRAMAddress |= (byte / 8); // OR in upper five bytes of operand as the vertical scroll
		_temporaryVRAMAddress &= 0xFFF; // Clear bits 12-14
		_temporaryVRAMAddress |= ((byte & 0x7) << 12); // OR in the bits from the operand as the fine vertical scroll
		
		_firstWriteOccurred = YES; // Set toggle
	}
	
}

- (void)writeToVRAMAddressRegister2:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	// 2006 first write:
	// t:0011111100000000=d:00111111
	// t:1100000000000000=0
	// 2006 second write:
	// t:0000000011111111=d:11111111
	// v=t
	if (_firstWriteOccurred) {
		
		_temporaryVRAMAddress &= 0xFF; // Clear upper byte
		_temporaryVRAMAddress |= ((byte & 0x3F) << 8); // OR in lower 6 bits as first six of upper byte
		
		_firstWriteOccurred = NO; // Reset toggle
	}
	else {
	
		_temporaryVRAMAddress &= 0xFF00; // Clear lower byte
		_temporaryVRAMAddress |= byte; // OR in lower byte
		_VRAMAddress = _temporaryVRAMAddress;
		
		_firstWriteOccurred = YES; // Set toggle
	}
	
}

- (uint8_t)readFromVRAMIORegisterOnCycle:(uint_fast32_t)cycle
{
	uint8_t valueToReturn = _bufferedVRAMRead;
	uint16_t effectiveAddress = _VRAMAddress & 0x3FFF; // addresses above 0x3FFF are mirrored
	
	if (effectiveAddress < 0x1000) { 
		
		// CHRROM Bank 0 Read
		_bufferedVRAMRead = _chrromBank0[effectiveAddress];
	}
	else if (effectiveAddress < 0x2000) { 
		
		// CHRROM Bank 1 Read
		_bufferedVRAMRead = _chrromBank1[effectiveAddress - 0x1000];
	}
	else if (effectiveAddress < 0x3F00) { 
		
		// Name or Attribute Table Read
		_bufferedVRAMRead = _nameAndAttributeTables[(effectiveAddress & 0x2FFF) - 0x2000];
	}
	else { 
		
		// Palette Read (Unbuffered)
		_bufferedVRAMRead = _nameAndAttributeTables[effectiveAddress - 0x1000]; // 0x3000 mirrors 0x2000
		valueToReturn = _palettes[effectiveAddress & 0x1F]; // modulo 32 as there are 32 entries
	}
		
	_VRAMAddress += _addressIncrement; // Increment VRAM address by either 1 or 32 depending on bit 2 of 0x2000
	
	return valueToReturn;
}

- (void)writeToVRAMIORegister:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	uint16_t effectiveAddress = _VRAMAddress & 0x3FFF; // addresses above 0x3FFF are mirrored
	
	if (effectiveAddress < 0x2000) {
		
		// Why are you writing to a pattern table?
	}
	else if (effectiveAddress < 0x3F00) { 
		
		// Name or Attribute Table Write
		_writeToNameOrAttributeTable(self,@selector(writeByte:toHorizontallyMirroredNameOrAttributeTableAddress:),byte,((effectiveAddress & 0x2FFF) - 0x2000));
	}
	else { 
		
		// Palette Write
		_palettes[effectiveAddress & 0x1F] = byte; // modulo 32 as there are 32 entries
	}
	
	_VRAMAddress += _addressIncrement; // Increment VRAM address by either 1 or 32 depending on bit 2 of 0x2000
}

- (void)DMAtransferToSPRRAM(uint8_t *)bytes onCycle:(uint_fast32_t)cycle
{
	memcpy(_sprRAM,bytes,sizeof(uint8_t)*256); // transfer 256 bytes
	
	// This takes 512 CPU cycles, run the PPU if this is mid-frame
}

- (void)writeToSPRRAMAddressRegister:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	_sprRAMAddress = byte;
}

- (void)writeToSPRRAMIOControlRegister:(uint8_t)byte onCycle:(uint_fast32_t)cycle
{
	_sprRAM[_sprRAMAddress] = byte;
	
	_sprRAMAddress++; // Increment SPRRAM Address on write
}

- (uint8_t)readFromSPRRAMIORegisterOnCycle:(uint_fast32_t)cycle
{
	return _sprRAM[_sprRAMAddress];
}

// 0x2002
- (uint8_t)readFromPPUStatusRegisterOnCycle:(uint_fast32_t)cycle
{
	uint8_t valueToReturn = _ppuStatusRegister;
	_firstWriteOccurred = NO; // Reset 0x2005 / 0x2006 read toggle
	_ppuStatusRegister &= 0x7F; // Clear the VBLANK flag
	
	return valueToReturn;
}

- (void)setPatternTableBank0:(uint8_t *)pointer
{
	// FIXME: Should run PPU before assigning
	_chrromBank0 = pointer;
}

- (void)setPatternTableBank1:(uint8_t *)pointer
{
	// FIXME: Should run PPU before assigning
	_chrromBank1 = pointer;
}

@end
