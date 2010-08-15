//
//  NESKeyboardResponder.h
//  Macifom
//
//  Created by Auston Stewart on 8/12/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class NESControllerInterface;

@interface NESKeyboardResponder : NSResponder {

	IBOutlet NESControllerInterface *controllerInterface;
}

- (void)keyDown:(NSEvent *)theEvent;
- (void)keyUp:(NSEvent *)theEvent;

@end
