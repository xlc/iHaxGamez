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

#import "SearchWindowController.h"
#import "AppAddressDataSource.h"
#import "AppAddressData.h"
#import "MemoryAccess.h"
#import <math.h>
#import <Security/AuthorizationTags.h>
#import <AudioToolbox/AudioServices.h>

@implementation SearchWindowController

@synthesize applicationName, appAddressDS;
@synthesize appPID = AppPid;

- (id)init
{
    return [self initWithAppName:@"Application Name Not Set" PID:0];
}

- (id)initWithAppName:(NSString *)AppName PID:(pid_t)PID
{   
    self = [self initWithWindowNibName:@"SearchWindow"];
    if (self)
    {
        AppPid = PID;
        [self setApplicationName:AppName];
        
        [self setAppAddressDS:[[AppAddressDataSource alloc] init]];
        [appAddressDS setSearchWindowController:self];
        [tblResults setDataSource:appAddressDS];
        
        CurrentSearchField = textSearchValue;
            // initialize our search with the PID of our desired process
        AttachedMemory = [[MemoryAccess alloc] initWithPID:AppPid];
    }
    
    return self;
}

- (void)windowDidLoad
{    
    [textAppTitle setStringValue:[self applicationName]];
    [[self window] makeKeyAndOrderFront:self];
    [btnReset setFrame:[btnSearchOriginal frame]]; // reset button re-position
    
        // When editing the window in Interface builder, I can't see the indicator if it's not displayed when stopped
        // so here is where I alter some settings to make it invisible again.
    [progressInd setDisplayedWhenStopped:false];
    [progressInd setHidden:false];
    [tblResults setDataSource:appAddressDS];
    
    [self setEditMode:false];
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification
{
    [self refreshResults:false];
}

- (void)refreshResults:(bool)Forced
{
    if (Forced || (NSOnState == [btnAutoRefresh state]))
    {
        NSUInteger AddrCount = [[appAddressDS appAddresses] count];
        if ([btnSearchOriginal isHidden])
        {
            [progressInd startAnimation:self];
            
            AppAddressData *MyAppAddr;
            NSInteger SelectedIndex = [popupDataType indexOfSelectedItem];
            
                // Set the buffer size once only. It's not going to change even if we're looking at strings because strings are based
                // on the length of the original search string!!
            int BufSize;
            Byte *DataBuffer = nil;
			int8_t bVal = 0;
			int16_t sVal = 0;
            int32_t iVal = 0;
            int64_t lVal = 0;
            float fVal = 0.0f;
            double dVal = 0.0;
            unichar charVal[[[textSearchValue stringValue] length] + 1];
            switch(SelectedIndex)
            {
                case 0: // byte
                    BufSize = sizeof(int8_t);
                    DataBuffer = (Byte *)&bVal;
                    break;
                case 1: // int16
                    BufSize = sizeof(int16_t);
                    DataBuffer = (Byte *)&sVal;
                    break;
                case 2: // int32
                    BufSize = sizeof(int32_t);
                    DataBuffer = (Byte *)&iVal;
                    break;
				case 3: // int64
                    BufSize = sizeof(int64_t);
                    DataBuffer = (Byte *)&lVal;
                    break;
                case 4: // float
                    BufSize = sizeof(float);
                    DataBuffer = (Byte *)&fVal;
                    break;
                case 5: // double
                    BufSize = sizeof(double);
                    DataBuffer = (Byte *)&dVal;
                    break;
                case 6: // ASCII string
                    BufSize =(int)([[textSearchValue stringValue] length] * sizeof(char));
                    DataBuffer = (Byte *)charVal;
                    break;
                case 7: // UNICODE string
                default:
                    BufSize = (int)([[textSearchValue stringValue] length] * sizeof(unichar));
                    DataBuffer = (Byte *)charVal;
                    break;
            }
            
            vm_address_t Address;
            double PercentDone = 0.0;
            [progressBar setDoubleValue:0.0];
            [progressBar setHidden:false];
            [progressBar displayIfNeeded];
            
			NSUInteger x;
            for (x=0; x<AddrCount ; x++)
            {
                PercentDone = 100.0 * x / AddrCount;
                if (PercentDone - [progressBar doubleValue] > 1.0)
                {
                    [progressBar setDoubleValue:PercentDone];
                    [progressBar displayIfNeeded];
                }
                MyAppAddr = (AppAddressData *)[[appAddressDS appAddresses] objectAtIndex:x];
                Address = [MyAppAddr address];
                if ([AttachedMemory loadDataForAddress:Address Buffer:DataBuffer BufLength:BufSize])
                {
					if (NSOnState == [btnFlashTimesEightMode state])
					{
						bVal /= 8;
						sVal /= 8;
						iVal /= 8;
						lVal /= 8;
					}
					
					
                    switch(SelectedIndex)
                    {
                        case 0: // byte
                            [MyAppAddr setValue:[NSString stringWithFormat:@"%hu",0x00FF & bVal]];
                            break;
                        case 1: // int16
                            [MyAppAddr setValue:[NSString stringWithFormat:@"%hu",sVal]];
                            break;
                        case 2: // int32
                            [MyAppAddr setValue:[NSString stringWithFormat:@"%u",iVal]];
                            break;
                        case 3: // int64
                            [MyAppAddr setValue:[NSString stringWithFormat:@"%qu",lVal]];
                            break;
                        case 4: // float
                            [MyAppAddr setValue:[NSString stringWithFormat:@"%f",fVal]];
                            break;
                        case 5: // double
                            [MyAppAddr setValue:[NSString stringWithFormat:@"%f",dVal]];
                            break;
                        case 6: // ASCII string
                            charVal[[[textSearchValue stringValue] length]] = '\0';
                            [MyAppAddr setValue:[NSString stringWithCString:(char *)charVal encoding:NSASCIIStringEncoding]];
                            break;
                        case 7: // UNICODE string
                        default:
                            [MyAppAddr setValue:[NSString stringWithCharacters:charVal length:BufSize / sizeof(unichar)]];
                            break;
                    }
                }
                else
                {
                    [MyAppAddr setValue:@"Access Denied!"];
                }
            }
            [progressBar setHidden:true];
            [tblResults reloadData];
            [progressInd stopAnimation:self];
        }
		
		if ((NSOnState == [btnAutoRefresh state]))
		{
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			[self performSelector:@selector(refreshResults:) withObject:nil afterDelay:1];
		}
    }
}

- (void)changeValueAtRow:(NSInteger)row Value:(NSString*)val
{
    [progressInd startAnimation:self];
    
    int SelectedIndex = (int)[popupDataType indexOfSelectedItem];
    
    Byte *DataBuffer;
    int BufSize;
    vm_address_t Address;
	int8_t bVal=0;
	int16_t sVal=0;
    int32_t iVal=0;
    int64_t lVal=0;
	long long llVal=0;
    float fVal=0.0f;
    double dVal=0.0;
    unichar charVal[[[textSearchValue stringValue] length] + 1];
    
    
        // this is needed for integer based values - grabs a long long if possible, otherwise zero
	if (![[NSScanner scannerWithString:val] scanLongLong:&llVal])
	{
		llVal = 0;
	}
    
    switch(SelectedIndex)
    {
        case 0: // byte
            BufSize = sizeof(int8_t);
            bVal = (int8_t)llVal;
            DataBuffer = (Byte *)&bVal;
            break;
        case 1: // int16
            BufSize = sizeof(int16_t);
            sVal = (int16_t)llVal;
            DataBuffer = (Byte *)&sVal;
            break;
        case 2: // int32
            BufSize = sizeof(int32_t);
            iVal = (int32_t)llVal;
            DataBuffer = (Byte *)&iVal;
            break;
        case 3: // int64
            BufSize = sizeof(int64_t);
            lVal = (int64_t)llVal;
            DataBuffer = (Byte *)&lVal;
            break;
        case 4: // float
            BufSize = sizeof(float);
            fVal = [val floatValue];
            DataBuffer = (Byte *)&fVal;
            break;
        case 5: // double
            BufSize = sizeof(double);
            dVal = [val doubleValue];
            DataBuffer = (Byte *)&dVal;
            break;
        case 6: // ASCII string
            BufSize = (int)([[textSearchValue stringValue] length]);
            DataBuffer = (Byte *)charVal;
            
                // make sure the replacement string is not longer than the original search string
            if ([val length] > (uint)BufSize)
            {
                val = [val substringToIndex:BufSize];
            }
            
                // fill the buffer with the characters from the value string
            [val getCString:(char *)charVal maxLength:sizeof(charVal)/sizeof(char) encoding:NSASCIIStringEncoding];
            
                // pad buffer with trailing spaces so it will be the same size as the original search string
        {
            char *MyCharacterString = (char *)charVal;
            int x;
            for (x=(int)[val length]; x<BufSize; x++)
            {
                MyCharacterString[x] = ' ';
            }
        }
            
            BufSize *= (int)sizeof(char); // sizeof(char) should return 1, but just in case....
            break;
        case 7: // UNICODE string
        default:
            BufSize = (int)([[textSearchValue stringValue] length]);
            DataBuffer = (Byte *)charVal;
            
                // make sure the replacement string is not longer than the original search string
            if ([val length] > (uint)BufSize)
            {
                val = [val substringToIndex:BufSize];
            }
            
                // fill the buffer with the characters from the value string
            [val getCharacters:(unichar *)charVal];
            
                // pad buffer with trailing spaces so it will be the same size as the original search string
        {
            unichar *MyUnicodeString = charVal;
            int x;
            for (x=(int)[val length]; x<BufSize; x++)
            {
                MyUnicodeString[x] = ' ';
            }
        }
            
            BufSize *= (int)sizeof(unichar);
            break;
    }
	
	if (NSOnState == [btnFlashTimesEightMode state])
	{
		bVal *= 8;
		sVal *= 8;
		iVal *= 8;
		lVal *= 8;
	}
	
        // change the data located at Address to the value pointed to by DataBuffer
    Address = [(AppAddressData *)[[appAddressDS appAddresses] objectAtIndex:row] address];
    [AttachedMemory saveDataForAddress:Address Buffer:DataBuffer BufLength:BufSize];
    
    [progressInd stopAnimation:self];
    [self refreshResults:false];
}

- (void)valueChangedAtRow:(NSInteger)row
{
    [self changeValueAtRow:row Value:[(AppAddressData *)[[appAddressDS appAddresses] objectAtIndex:row] value]];
}

- (IBAction)RefreshChecked:(id)sender
{
    if ([btnManualRefresh isEnabled])
    {
        [self refreshResults:false];
    }
}

- (IBAction)RefreshClicked:(id)sender
{
    [self refreshResults:true];
}

- (IBAction)FilterStart:(id)sender
{
    if ([[textFilterValue stringValue] length] == 0 )
    {
        AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
    }
    else
    {
        [self searchAndFilter:true];
    }
}

- (IBAction)SearchReset:(id)sender
{
    [boxResults setTitle:@"Search Results:"];
    [self setEditMode:false];
}

- (IBAction)SearchStart:(id)sender
{
    if ([[textSearchValue stringValue] length] == 0 )
    {
        AudioServicesPlayAlertSound(kSystemSoundID_UserPreferredAlert);
    }
    else
    {
            // save them the trouble of searching for 0 (It takes a LONG time!!!) 
        NSInteger AlertResult = NSAlertAlternateReturn;
        if (([textSearchValue intValue] == 0) && ([popupDataType indexOfSelectedItem] < 6))
        {
            NSAlert *MyAlert =[NSAlert alertWithMessageText:@"Searching for 0 is a bad idea"
                                              defaultButton:@"Cancel"
                                            alternateButton:@"I Said Do It!"
                                                otherButton:@""
                                  informativeTextWithFormat:@"There are usually a lot of memory locations set to 0. Searching for 0 will often take a very LONG time. Perhaps you should cancel the search and look for another value."];
            AlertResult = [MyAlert runModal];
        }
        if (AlertResult != NSAlertDefaultReturn)
        {
            [self setEditMode:true];
            [self searchAndFilter:false];
        }
    }
}

- (IBAction)SearchTypeChanged:(id)sender
{
	[btnFlashTimesEightMode setEnabled:([popupDataType indexOfSelectedItem] < 4)];
	[btnFlashTimesEightMode setState:[btnFlashTimesEightMode isEnabled] && (NSOnState == [btnFlashTimesEightMode state])];
}

- (IBAction)ReplaceAllClicked:(id)sender
{
    NSAlert *MyAlert =[NSAlert alertWithMessageText:@"CAUTION"
                                      defaultButton:@"Cancel"
									alternateButton:@"I Said Do It!"
                                        otherButton:@""
                          informativeTextWithFormat:@"This can easily crash programs and corrupt memory. Only do this if you're SURE you know what you're doing."];
    NSInteger AlertResult = [MyAlert runModal];
    
    if (AlertResult == NSAlertDefaultReturn)
    {
        return;
    }
    
    NSString *val = [textReplaceAllValue stringValue];
    NSUInteger AddrCount = [[appAddressDS appAddresses] count];
    NSUInteger x;
    for (x=0; x<AddrCount ; x++)
    {
        [self changeValueAtRow:x Value:val];
    }
    [self refreshResults:true];
}

-(void)setEditMode:(BOOL)isEditMode
{
    [btnSearchOriginal setHidden:isEditMode];
    [btnReset setHidden:!isEditMode];
    [textSearchValue setEditable:!isEditMode];
    [popupDataType setEnabled:!isEditMode];
	[btnFlashTimesEightMode setEnabled:!isEditMode];
    [[tblResults tableColumnWithIdentifier:@"value"] setEditable:isEditMode];
    [textFilterValue setEditable:isEditMode];
    [textReplaceAllValue setEditable:isEditMode];
    [btnSearchFilter setEnabled:isEditMode];
    [btnReplaceAll setEnabled:isEditMode];
    [btnManualRefresh setEnabled:isEditMode];
    
    if (isEditMode)
    {
        CurrentSearchField = textFilterValue;
        [textFilterValue setStringValue:[textSearchValue stringValue]];
    }
    else
    {
        CurrentSearchField = textSearchValue;
        [textFilterValue setStringValue:@""];
    }
    
    [appAddressDS removeAllObjects];
    [tblResults reloadData];
}

- (void)searchAndFilter:(bool)isFilterMode
{
    [progressInd startAnimation:self];
    
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
	
        // Just in case we are looking for an ascii or unicode string, set up my buffer the lazy way (as auto instead of malloc)
        // Note: I set this as a unichar string even though I might use only half of its length when looking for a char string
        // Note: Also, the maximum length of the search can not exceed the length of the original string so we base this on textSearchValue
        // rather than CurrentSearchField
    unichar charSearchVal[[[textSearchValue stringValue] length] + 1];
    
        // this is needed for integer based values - grabs a long long if possible, otherwise zero
	if (![[NSScanner scannerWithString:[CurrentSearchField stringValue]] scanLongLong:&llVal])
	{
		llVal = 0;
	}
    
    
    int SelectedIndex = (int)[popupDataType indexOfSelectedItem];
    switch(SelectedIndex)
    {
        case 0: // byte
            searchValSize = sizeof(int8_t);
            byteSearchVal = (int8_t) llVal;
            ValueString = [NSString stringWithFormat:@"%hu",0x00FF & byteSearchVal];
            searchValPointer = (Byte *)&byteSearchVal; // we point to the entry byte of the value we want to compare 
            break;
        case 1: // int16
            searchValSize = sizeof(int16_t);
            shortSearchVal = (int16_t) llVal;
            ValueString = [NSString stringWithFormat:@"%hu",shortSearchVal];
            searchValPointer = (Byte *)&shortSearchVal; // we point to the entry byte of the value we want to compare 
            break;
        case 2: // int32
            searchValSize = sizeof(int32_t);
            intSearchVal = (int32_t) llVal;
            ValueString = [NSString stringWithFormat:@"%u",intSearchVal];
            searchValPointer = (Byte *)&intSearchVal; // we point to the entry byte of the value we want to compare 
            break;
        case 3: // int64
            searchValSize = sizeof(int64_t);
            longSearchVal = (int64_t) llVal;
            ValueString = [NSString stringWithFormat:@"%qu",longSearchVal];
            searchValPointer = (Byte *)&longSearchVal; // we point to the entry byte of the value we want to compare 
            break;
        case 4: // float
            searchValSize = sizeof(floatSearchVal);
            floatSearchVal = [CurrentSearchField floatValue];
            ValueString = [NSString stringWithFormat:@"%f",floatSearchVal];
            searchValPointer = (Byte *)&floatSearchVal; // we point to the entry byte of the value we want to compare 
            break;
        case 5: // double
            searchValSize = sizeof(doubleSearchVal);
            doubleSearchVal = [CurrentSearchField doubleValue];
            ValueString = [NSString stringWithFormat:@"%f",doubleSearchVal];
            searchValPointer = (Byte *)&doubleSearchVal; // we point to the entry byte of the value we want to compare 
            break;
        case 6: // ASCII string
            [self adjustFilterStringLength];
            searchValSize = (int)([[CurrentSearchField stringValue] length] * sizeof(char)); // sizeof(char) should be 1, but things change...
            [[CurrentSearchField stringValue] getCString:(char *)charSearchVal maxLength:searchValSize+1 encoding:NSASCIIStringEncoding];
            ValueString = [CurrentSearchField stringValue];
            searchValPointer = (Byte *)charSearchVal;
            break;
        case 7: // UNICODE string
        default: // treat unknowns as UNICODE string
            [self adjustFilterStringLength];
            searchValSize = (int)([[CurrentSearchField stringValue] length] * sizeof(unichar));
            [[CurrentSearchField stringValue] getCharacters:(unichar *)charSearchVal range:NSMakeRange(0, [[CurrentSearchField stringValue] length])];
            ValueString = [CurrentSearchField stringValue];
            searchValPointer = (Byte *)charSearchVal;
            break;
    }
    
	if (NSOnState == [btnFlashTimesEightMode state])
	{
		byteSearchVal *= 8;
		shortSearchVal *= 8;
		intSearchVal *= 8;
		longSearchVal *= 8;
	}
	
    if (isFilterMode)
    {
            // remove from appAddressDS where address does not contain filter value
        [appAddressDS setAppAddresses:[AttachedMemory getFilteredArray:searchValPointer ByteSize:searchValSize SoughtValueString:ValueString Addresses:[appAddressDS appAddresses] PrgBar:progressBar]];         
    }
    else
    {
            // Fill the appAddressDS with an array of addresses that contain the sought value
        [appAddressDS setAppAddresses:[AttachedMemory getSearchArray:searchValPointer ByteSize:searchValSize SoughtValueString:ValueString PrgBar:progressBar]];         
    }
    
    [boxResults setTitle:[NSString stringWithFormat:@"Search Results: (%u Found)",(uint)[appAddressDS numberOfRowsInTableView:nil]]];
    [tblResults reloadData];
    [progressInd stopAnimation:self];
}

- (void)adjustFilterStringLength
{
        // truncate the textFilterValue string if longer than textSearchValue
    int searchLength = (int)[[textSearchValue stringValue] length];
    int filterLength = (int)[[textFilterValue stringValue] length];
    
    if (filterLength > searchLength)
    {
        [textFilterValue setStringValue:[[textFilterValue stringValue] substringToIndex:searchLength]];
    }
}

@end
