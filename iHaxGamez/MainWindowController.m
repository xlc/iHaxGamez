/*
 iHaxHamez - External process memory search-and-replace tool for MAC OS X
 Copyright (C) <2007>  <Raymond Wilfong>
 
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

@implementation MainWindowController

- (id)init
{
    [super init];
    [self setSearchWindowArray:[NSMutableArray arrayWithCapacity:5]];

    // get current process info so we won't list it in our process list
    // NOTE: Searching this process would cause problems - finding a value would
	// allocate memory which would be found/allocated/found/ and so on....
    CurrentAppPSN.highLongOfPSN = 0L;
    CurrentAppPSN.lowLongOfPSN = 0L;
    GetCurrentProcess(&CurrentAppPSN);
    
    return self;
}

- (void)dealloc
{
    [searchWindowArray release];
    [super dealloc];
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

- (NSMutableArray *)searchWindowArray
{
    return searchWindowArray;
}

- (void)setSearchWindowArray:(NSMutableArray *)newSearchWindowArray
{
    [searchWindowArray autorelease];
    searchWindowArray = [newSearchWindowArray retain];
}

- (void)awakeFromNib
{
    [self resetProcessList];
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
    
    ProcessInfoRec MyProcessInfo;
    const int NameBufferLength = 1024;
    char MyProcNameBuffer[NameBufferLength];
    MyProcessInfo.processInfoLength = sizeof(ProcessInfoRec);
    MyProcessInfo.processName = (StringPtr)&MyProcNameBuffer;
    MyProcessInfo.processAppSpec = NULL;
    int LoopX;
    pid_t MyPID;
    while (GetNextProcess(&MyPSN) == 0)
    {
        if ((MyPSN.lowLongOfPSN != CurrentAppPSN.lowLongOfPSN) || (MyPSN.highLongOfPSN != CurrentAppPSN.highLongOfPSN))
        {
            // clear the string
            for (LoopX=0; LoopX<NameBufferLength ; LoopX++)
            {
                MyProcNameBuffer[LoopX] = (char)0;
            }
            
            // get the process information
            if (GetProcessInformation(&MyPSN,&MyProcessInfo) == 0)
            {
                GetProcessPID(&MyPSN,&MyPID);
                // Add string and set PID into Tag - we take the string from the second character because first "char" holds string length
                // We show the PID in the Title because there might be > 1 processes for the same program name
                [popupProcessList addItemWithTitle:[NSString stringWithFormat:@"%s (%u)",MyProcessInfo.processName + 1,MyPID]];
                [[popupProcessList lastItem] setTag:MyPID];
                if (PrevSelectedPid == MyPID)
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
    pid_t MyPid = [[popupProcessList itemAtIndex:[popupProcessList indexOfSelectedItem]] tag];
    SearchWindowController *MySearchWindow = [[[SearchWindowController alloc] initWithAppName:MyTitle PID:MyPid] autorelease];
    if ([MySearchWindow isWindowLoaded])
    {
        [searchWindowArray addObject:MySearchWindow]; // this will retain the WindowController for us
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(SearchWindowClosed:) name:NSWindowWillCloseNotification object:[MySearchWindow window]];
    }

    [self updateSearchWindowCount];
}

- (IBAction)popupProcessListAction:(id)sender
{
//    [btnSearch setTitle:[NSString stringWithFormat:@"%s - %d",[[popupProcessList title] cString],[popupProcessList selectedTag]]];
}

- (void)updateSearchWindowCount
{
    //I put this in for testing, but I figured it didn't hurt anything to leave it in 
    [textSearchCounter setStringValue:[NSString stringWithFormat:@"Currently maintaining %u searches",[searchWindowArray count]]];
}

// used to clean searchWindowArray when a search window closes
- (void)SearchWindowClosed:(NSNotification *)notification
{
    // Find windowController in array, remove it as per documentation - when Window has no Document, autorelease it.
    // Since removing from array sends release, we retain and autorelease it so that it doesn't go away until end of current
    // event loop.
    SearchWindowController *MyWindowController = [(NSWindow *)[notification object] windowController];
    if (NSNotFound != [searchWindowArray indexOfObjectIdenticalTo:MyWindowController])
    {
        [MyWindowController retain];
        [searchWindowArray removeObjectIdenticalTo:MyWindowController];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:NSWindowWillCloseNotification object:MyWindowController];
        [MyWindowController autorelease];
    }
    
    [self updateSearchWindowCount];
}

@end
