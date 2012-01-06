//
//  PreferencesWindowController.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-15.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "PreferencesWindowController.h"
#import "ConfigManager.h"

#import "SRValidator.h"

static PreferencesWindowController *sharedController;

@implementation PreferencesWindowController
@synthesize _alignmentButton;
@synthesize _tableView;

+ (void)showWindow {
    if (!sharedController) {
        sharedController = [[self alloc] init]; // TODO set to nil/release after window closed
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
    
    NSInteger alignment = [[NSUserDefaults standardUserDefaults] integerForKey:@"MemoryAlignment"];
    [_alignmentButton selectItemWithTag:alignment];
}

#pragma mark - 

- (void)keyDown:(NSEvent *)theEvent {
    NSInteger row = [_tableView selectedRow];
    if (row >= 0) {
        UInt32 modifierKeys = 0;
        if ([theEvent modifierFlags] & NSControlKeyMask)
            modifierKeys |= controlKey;
        if ([theEvent modifierFlags] & NSCommandKeyMask)
            modifierKeys |= cmdKey;
        if ([theEvent modifierFlags] & NSAlternateKeyMask)
            modifierKeys |= optionKey;
        if (modifierKeys) {
            if ([theEvent modifierFlags] & NSShiftKeyMask)
                modifierKeys += shiftKey;
            HotKeyConfig *config = [[ConfigManager hotKeyConfigs] objectAtIndex:row];
            if ([config setModifiers:modifierKeys key:[theEvent keyCode]])
                [_tableView reloadData];
            else
                NSBeep();
        } else {
            NSBeep();
        }
    }
}

- (void)keyUp:(NSEvent *)theEvent {
    
}

#pragma mark - IBAction

- (IBAction)alignmentChanged:(id)sender {
    NSPopUpButton *button = sender;
    NSInteger alignment = [[button selectedItem] tag];
    [[NSUserDefaults standardUserDefaults] setInteger:alignment forKey:@"MemoryAlignment"];
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
        return config.keyDescription;
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

#pragma mark - NSWindowDelegate

- (void)windowDidResignKey:(NSNotification *)notification {
    [ConfigManager enableHotKeys];
}

- (void)windowDidBecomeKey:(NSNotification *)notification {
    [ConfigManager disableHotKeys];
}

@end
