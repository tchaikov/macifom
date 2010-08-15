//
//  NESKeyboardResponder.m
//  Macifom
//
//  Created by Auston Stewart on 8/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "NESKeyboardResponder.h"
#import "NESControllerInterface.h"

@implementation NESKeyboardResponder

- (void)keyDown:(NSEvent *)theEvent
{
	[controllerInterface keyboardKey:[theEvent keyCode] changedTo:YES];
}

- (void)keyUp:(NSEvent *)theEvent
{
	[controllerInterface keyboardKey:[theEvent keyCode] changedTo:NO];
}

@end
