//
//  NESNamco106Cartridge.h
//  Macifom
//
//  Created by Kefu Chai on 28/08/12.
//
//

#import <Foundation/Foundation.h>
#import "NESCartridge.h"

@interface NESNamco106Cartridge : NESCartridge {
	uint8_t _prgromIndexMask;
	uint8_t _chrromIndexMask;
}

@end
