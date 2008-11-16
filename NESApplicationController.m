//
//  NESApplicationController.m
//  Macifom
//
//  Created by Auston Stewart on 9/7/08.
//  Copyright 2008 Apple, Inc.. All rights reserved.
//

#import "NESApplicationController.h"


@implementation NESApplicationController

- (void)dealloc
{
	
}

- (IBAction)loadROM:(id)sender
{
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	[openPanel setCanChooseFiles:YES];
	[openPanel setCanChooseDirectories:NO];
	[openPanel setAllowsMultipleSelection:NO];
	
	if (NSOKButton == [openPanel runModalForDirectory:nil file:nil types:[NSArray arrayWithObject:@"nes"]]) {
		
		[[nesEmulator cartridge] loadROMFileAtPath:[[openPanel filenames] objectAtIndex:0]];
	}
}

- (void)awakeFromNib
{
	
}

@end
