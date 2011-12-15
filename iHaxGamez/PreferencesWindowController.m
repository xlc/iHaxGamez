//
//  PreferencesWindowController.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-15.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "ConfigManager.h"

static PreferencesWindowController *sharedController;

@implementation PreferencesWindowController

+ (void)showWindow {
    if (!sharedController) {
        sharedController = [[self alloc] init];
    }
    [sharedController showWindow:nil];
}

- (id)init
{
    self = [self initWithWindowNibName:@"PreferencesWindow"];
    if (self) {
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - 

- (void)keyDown:(NSEvent *)theEvent {
    
}

- (void)keyUp:(NSEvent *)theEvent {
    
}

#pragma mark - NSTableViewDelegate, NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [[ConfigManager hotKeyConfigs] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    HotKeyConfig *config = [[ConfigManager hotKeyConfigs] objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
        return [NSNumber numberWithBool:config.enabled];
    } else if ([[tableColumn identifier] isEqualToString:@"name"]) {
        return config.name;
    } else if ([[tableColumn identifier] isEqualToString:@"hotkey"]) {
        return @"cmd + shift + 1";
    }
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    HotKeyConfig *config = [[ConfigManager hotKeyConfigs] objectAtIndex:row];
    if ([[tableColumn identifier] isEqualToString:@"enabled"]) {
        config.enabled = [object boolValue];
    } else if ([[tableColumn identifier] isEqualToString:@"hotkey"]) {

    }
}

@end
