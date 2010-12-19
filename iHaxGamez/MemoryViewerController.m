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

#import "MemoryViewerController.h"
#import "AppAddressDataSource.h"
#import "AppAddressData.h"
#import "MemoryAccess.h"
#import <Security/AuthorizationTags.h>

@implementation MemoryViewerController

- (id)init
{
    return [self initWithAppName:@"Application Name Not Set" PID:0];
}

- (id)initWithAppName:(NSString *)AppName PID:(pid_t)PID
{
    [super init];    
    self = [self initWithWindowNibName:@"MemoryViewer"];
	
    AppPid = PID;
    
    if (self)
    {
        [self setApplicationName:AppName];
        [self showWindow:self];
        
        [self setAppAddressDS:[[[AppAddressDataSource alloc] init] autorelease]];
        [appAddressDS setSearchWindowController:self];

        // initialize our search with the PID of our desired process
        AttachedMemory = [[MemoryAccess alloc] initWithPID:AppPid];
    }
    
    return self;
}

- (void) windowDidLoad
{	
	// format the text box
	[txtOutput setFont:[NSFont fontWithName:@"Verdana" size:12]];
	
	
	// allocate the search value holders
	int8_t byteSearchVal=0;
	int16_t shortSearchVal=0;
    int32_t intSearchVal=0;
    int64_t longSearchVal=0;
    float floatSearchVal;
    double doubleSearchVal;
    Byte *searchValPointer;
    int searchValSize;
    NSString *ValueString;
    long long llVal;
	
	searchValSize = sizeof(floatSearchVal);
	floatSearchVal = [@"1337" floatValue];
	ValueString = [NSString stringWithFormat:@"%f",floatSearchVal];
	searchValPointer = (Byte *)&floatSearchVal; // we point to the entry byte of the value we want to compare 
	
	AttachedMemory = [[MemoryAccess alloc] initWithPID:AppPid];
	
	uint playerStart = 0x3AF3C00 - 0x460;
	uint gold = playerStart + 0x460 - 0x4;
	
	int data1 = [AttachedMemory readInt:gold withSize:4];
	int data2 = [AttachedMemory readInt:gold + 0x4 withSize:4];
	int data3 = [AttachedMemory readInt:gold + 0x8 withSize:4];
	int data4 = [AttachedMemory readInt:gold + 0xC withSize:4];
	

	[self displayOutput:[NSString stringWithFormat:@"%i", data1] startAddress:gold];
}

- (void) displayOutput:(NSString*)memoryData startAddress:(uint)addressValue
{
	NSMutableString* output = [[NSMutableString alloc] init];
	
	// loop through the memory
	int j;
	for (j = 0x0; j < 0x14 * 0xF; j += 0x10)
	{
		NSMutableString* address = [NSMutableString stringWithFormat:@"%X", addressValue + j];
		
		// insert leading 0's to make the address 8 characters
		while ([address length] < 8)
		{
			[address insertString:@"0" atIndex:0];
		}
		
		// append the address
		[output appendString:address];
		
		// append separator
		[output appendString:@"  "];
		
		// convert string to data
		NSData* stringData = [memoryData dataUsingEncoding:NSASCIIStringEncoding];
		
		// convert data to byte[]
		int len = (int)[stringData length];
		Byte *dataBytes = (Byte*)malloc(len);
		memcpy(dataBytes, [stringData bytes], len);
		
		// loop through the bytes
		int i;
		for (i = 0; i < len; i++)
		{
			Byte byteValue = dataBytes[i];
			
			[output appendString:@" "];
			[output appendFormat:@"%X", byteValue];
		}
		
		// append separator
		[output appendString:@"  "];
		
		// append read string
		[output appendString:memoryData];
		
		// append new line
		[output appendString:@"\n"];
	}
	
	// display the output
	[txtOutput setStringValue:output];
}

- (IBAction) updateOutput:(id)sender
{
}

- (void)dealloc
{
	[applicationName release];
    [appAddressDS release];
    [AttachedMemory release];
    [super dealloc];
}

- (NSString *)applicationName
{
    return applicationName;
}

- (void)setApplicationName:(NSString *)value
{
	if (applicationName != value)
	{
		[applicationName release];
		applicationName = [value copy];
	}
}

- (AppAddressDataSource *)appAddressDS
{
    return appAddressDS;
}

- (void)setAppAddressDS:(AppAddressDataSource *)newAppAddressDS
{
	if (appAddressDS != newAppAddressDS)
	{
		[appAddressDS release];
		appAddressDS = [newAppAddressDS retain];
	}
}

@end
