//
//  NESSUROMCartridge.h
//  Macifom
//
//  Created by Auston Stewart on 8/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "NESSxROMCartridge.h"

@interface NESSUROMCartridge : NESSxROMCartridge {

	uint_fast32_t _suromPRGROMBankOffset;
}

@end
