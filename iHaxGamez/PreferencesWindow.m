//
//  PreferencesWindow.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 12-1-5.
//  Copyright (c) 2012年 Xiliang Chen. All rights reserved.
//

#import "PreferencesWindow.h"

@implementation PreferencesWindow

- (void)sendEvent:(NSEvent *)theEvent {
    NSEventType type = [theEvent type];
    if (type == NSKeyDown || type == NSKeyUp) {
        if ([[self firstResponder] isKindOfClass:[NSTextView class]]) {
                // handle the event and not send it to text view
            if (type == NSKeyDown)
                [[self windowController] keyDown:theEvent];
            else
                [[self windowController] keyUp:theEvent];
            return;
        }
    }
    [super sendEvent:theEvent];
}

@end
