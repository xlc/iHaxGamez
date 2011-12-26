//
//  AppDelegate.h
//  TestApp
//
//  Created by Xiliang Chen on 11-12-25.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (weak) IBOutlet NSWindow *window;
@property (weak) IBOutlet NSView *view;

- (IBAction)reloadData:(id)sender;
- (IBAction)saveData:(id)sender;

@end
