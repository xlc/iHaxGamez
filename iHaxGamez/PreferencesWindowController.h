//
//  PreferencesWindowController.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-15.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface PreferencesWindowController : NSWindowController <NSTableViewDataSource, NSTableViewDelegate> {
@private
    UInt32 _modifierKey;
    UInt32 _key;
}

+ (void)showWindow;

@end
