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

#import <Cocoa/Cocoa.h>

@class AppAddressDataSource;
@class AddressListDataSource;
@class MemoryAccess;

@interface SearchWindowController : NSWindowController
{
    IBOutlet NSButton *btnReset;
    IBOutlet NSButton *btnSearchOriginal;
    IBOutlet NSButton *btnSearchFilter;
    IBOutlet NSPopUpButton *popupDataType;
    IBOutlet NSTableView *tblResults;
    IBOutlet NSTextField *textAppTitle;
    IBOutlet NSTextField *textFilterValue;
    IBOutlet NSTextField *textReplaceAllValue;
    IBOutlet NSTextField *textSearchValue;
    IBOutlet NSBox *boxResults;
    IBOutlet NSProgressIndicator *progressInd;
    IBOutlet NSProgressIndicator *progressBar;
    IBOutlet NSButton *btnAutoRefresh;
    IBOutlet NSButton *btnManualRefresh;
	IBOutlet NSButton *btnFlashTimesEightMode;
    IBOutlet NSButton *btnReplaceAll;
	IBOutlet NSButton *btnClear;
	IBOutlet NSButton *btnAddAddress;
	IBOutlet NSTableView *tblAddressList;
	IBOutlet NSButton *btnRemoveSelected;
    
    NSString *applicationName;
    AppAddressDataSource *appAddressDS;
    AddressListDataSource *addressListDS;
    pid_t AppPid;
    MemoryAccess *AttachedMemory;
    NSTextField *CurrentSearchField;
}

- (id)init;
- (id)initWithAppName:(NSString *)AppName PID:(pid_t)PID;
- (void)dealloc;

- (void)windowDidLoad;
- (void)windowWillClose:(NSNotification *)aNotification;
- (void)windowDidBecomeKey:(NSNotification *)aNotification;
- (void)refreshResults:(bool)Forced;
- (void)refreshAddressList;
- (void)changeValueAtRow:(NSInteger)row Value:(NSString*)val;
- (void)valueChangedAtRow:(NSInteger)row;

- (NSString *)applicationName;
- (void)setApplicationName:(NSString *)Value;

- (AppAddressDataSource *)appAddressDS;
- (void)setAppAddressDS:(AppAddressDataSource *)newAppAddressDS;

- (AddressListDataSource *)addressListDS;
- (void)setAddressListDS:(AddressListDataSource *)newAddressListDS;

- (IBAction)RemoveAddress:(id)sender;
- (IBAction)AddAddress:(id)sender;
- (IBAction)ClearAddressList:(id)sender;
- (IBAction)RefreshChecked:(id)sender;
- (IBAction)RefreshClicked:(id)sender;
- (IBAction)FilterStart:(id)sender;
- (IBAction)SearchReset:(id)sender;
- (IBAction)SearchStart:(id)sender;
- (IBAction)SearchTypeChanged:(id)sender;
- (IBAction)ReplaceAllClicked:(id)sender;
- (void)setEditMode:(BOOL)isEditMode;
- (void)searchAndFilter:(bool)isFilterMode;
- (void)adjustFilterStringLength;

@end
