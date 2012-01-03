//
//  SearchWindowController.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-20.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PSMTabBarControl.h"

@class SearchResultViewController, HexViewerController, VirtualMemoryAddress;

@interface SearchWindowController : NSWindowController <PSMTabBarControlDelegate> {
@private
    __weak NSPopUpButton *_typeButton;
    __weak NSSearchField *_searchField;
    __weak NSButton *_timesEightModeButton;
    __weak PSMTabBarControl *_searchTabBarControl;
    __weak PSMTabBarControl *_viewerTabBarControl;
    
    pid_t _pid;
    NSString *_title;
    NSMutableArray *_resultControllers;
    NSMutableArray *_viewerControllers;
    SearchResultViewController *_currentSearchController;
    HexViewerController *_currentViewerController;
}

@property (weak) IBOutlet NSPopUpButton *_typeButton;
@property (weak) IBOutlet NSSearchField *_searchField;
@property (weak) IBOutlet NSButton *_timesEightModeButton;
@property (weak) IBOutlet PSMTabBarControl *_searchTabBarControl;
@property (weak) IBOutlet PSMTabBarControl *_viewerTabBarControl;

@property (nonatomic, readonly) pid_t pid;

- (id)initWithTitle:(NSString *)title pid:(pid_t)pid;

- (IBAction)clearSearchResult:(id)sender;
- (IBAction)refresh:(id)sender;
- (IBAction)showSearch:(id)sender;
- (IBAction)showHexViewer:(id)sender;
- (IBAction)showSettings:(id)sender;

- (void)openViewerForAddress:(VirtualMemoryAddress *)address;

@end
