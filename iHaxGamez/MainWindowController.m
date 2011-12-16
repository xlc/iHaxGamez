/*
 iHaxGamez - External process memory search-and-replace tool for MAC OS X
 Copyright (C) <2007>  <Raymond Wilfong and Glenn Hartmann>
 
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the Free Software
 Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 
 You may contact Raymond Wilfong by email at rwilfong@rewnet.com
 */

#import "MainWindowController.h"
#import "SearchWindowController.h"

static MainWindowController *sharedController;

@interface MainWindowController ()

- (void)updateSearchWindowCount;
- (void)openSearchWindowWithTitle:(NSString *)title pid:(pid_t)pid;

@end

@implementation MainWindowController

+ (MainWindowController *)sharedController {
    if (!sharedController) {
        sharedController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController"];
    }
    return sharedController;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    if (self) {
        _searchWindowControllers = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
        // List is already activated by awakeFromNib when this fires for the first time, so save a few milliseconds.
        // The reason for letting awakeFromNib handle this first is to keep popup list from flashing original value
        // when the window appears.
    static bool firstTime = true;
    if (firstTime)
    {
        firstTime = false;
    }
    else
    {
        [self resetProcessList];
    }
}

- (void)awakeFromNib
{
    [self resetProcessList];
}

- (void)openSearchWindowForProcess:(ProcessSerialNumber)psn {
    pid_t pid;
    GetProcessPID(&psn, &pid);
    
    SearchWindowController *controller = [_searchWindowControllers objectForKey:[NSNumber numberWithInt:pid]];
    if (controller) {
        [controller showWindow:nil];
    } else if (pid != getpid()) {
        CFStringRef name;
        if (CopyProcessName(&psn, &name) == 0) {
            NSString *title = [NSString stringWithFormat:@"%@ (%u)", name, pid];
            [self openSearchWindowWithTitle:title pid:pid];
        }
    }
}

- (void)openSearchWindowWithTitle:(NSString *)title pid:(pid_t)pid {
    SearchWindowController *searchWindowController = [[SearchWindowController alloc] initWithAppName:title PID:pid];
    searchWindowController.window.delegate = self;
    [searchWindowController showWindow:nil];
    [_searchWindowControllers setObject:searchWindowController forKey:[NSNumber numberWithInt:pid]];
    [self updateSearchWindowCount];
}

- (void)resetProcessList
{
        // remember the PID of the selected process
    pid_t PrevSelectedPid = -1;
    
    if ([popupProcessList selectedItem] != nil)
    {
        PrevSelectedPid = (pid_t)[[popupProcessList selectedItem] tag];
    }
    
        // Clear the popup
    [popupProcessList removeAllItems];
    
        // initialize a ProcessSerialNumber that we will use to get process and PID info
    ProcessSerialNumber MyPSN;
    MyPSN.highLongOfPSN = 0;
    MyPSN.lowLongOfPSN = kNoProcess;
    
    pid_t pid;
    pid_t appPID = getpid();
    CFStringRef name = nil;
    
    while (GetNextProcess(&MyPSN) == 0)
    {   
            // get the process information
        if (GetProcessPID(&MyPSN,&pid) == 0) {
            if (pid == appPID)
                continue;
            if (CopyProcessName(&MyPSN, &name) == 0)
            {
                    // Add string and set PID into Tag - we take the string from the second character because first "char" holds string length
                    // We show the PID in the Title because there might be > 1 processes for the same program name
                [popupProcessList addItemWithTitle:[NSString stringWithFormat:@"%@ (%u)", name, pid]];
                [[popupProcessList lastItem] setTag:pid];
                if (PrevSelectedPid == pid)
                {
                    [popupProcessList selectItem:[popupProcessList lastItem]];
                }
            }
        }
    }
}

- (IBAction)btnRefreshAction:(id)sender
{
    [self resetProcessList];
}

- (IBAction)btnSearchAction:(id)sender
{
        // create an instance of the search dialog and attach that instance to an object array
    NSString *MyTitle = [popupProcessList titleOfSelectedItem];
    pid_t MyPid = (pid_t)[[popupProcessList itemAtIndex:[popupProcessList indexOfSelectedItem]] tag];
    [self openSearchWindowWithTitle:MyTitle pid:MyPid];
}

- (void)updateSearchWindowCount
{
        //I put this in for testing, but I figured it didn't hurt anything to leave it in 
    [textSearchCounter setStringValue:[NSString stringWithFormat:@"Currently maintaining %u searches",[_searchWindowControllers count]]];
}

#pragma mark - NSWindowDelegate

- (void)windowWillClose:(NSNotification *)notification {
    SearchWindowController *controller = [(NSWindow *)[notification object] windowController];
    
    [_searchWindowControllers removeObjectForKey:[NSNumber numberWithInt:controller.appPID]];
    
    [self updateSearchWindowCount];
}

- (BOOL)windowShouldClose:(id)sender {
    return YES; // TODO ask user to conform close window or just hide it
}

@end
