//
//  SearchWindowController.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-20.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "SearchWindowController.h"

#import "SearchResultViewController.h"
#import "MemoryAccess.h"
#import "PSMTabBarControl.h"
#import "PSMRolloverButton.h"
#import "HexViewerController.h"
#import "VirtualMemoryAddress.h"

@interface SearchWindowController ()

- (void)searchValue:(id)sender;
- (void)addNewSearch;
- (void)addViewer;
- (void)changeSearchType:(id)sender;

@end

@implementation SearchWindowController
@synthesize _searchTabBarControl;
@synthesize _viewerTabBarControl;
@synthesize _timesEightModeButton;
@synthesize _searchField;
@synthesize _typeButton;

@synthesize pid = _pid;

- (id)initWithTitle:(NSString *)title pid:(pid_t)pid {
    self = [super initWithWindowNibName:@"SearchWindow"];
    if (self) {
        _title = [title copy];
        _pid = pid;
        _resultControllers = [NSMutableArray array];
        _viewerControllers = [NSMutableArray array];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    _searchTabBarControl.canCloseOnlyTab = NO;
    _searchTabBarControl.disableTabClose = NO;
    _searchTabBarControl.hideForSingleTab = NO;
    _searchTabBarControl.showAddTabButton = YES;
    _searchTabBarControl.useOverflowMenu = YES;
    _searchTabBarControl.allowsBackgroundTabClosing = YES;
    _searchTabBarControl.tearOffStyle = PSMTabBarTearOffMiniwindow;
        
    [[_searchTabBarControl addTabButton] setTarget:self];
    [[_searchTabBarControl addTabButton] setAction:@selector(addNewSearch)];
    _searchTabBarControl.delegate = self;
    
    _viewerTabBarControl.canCloseOnlyTab = NO;
    _viewerTabBarControl.disableTabClose = NO;
    _viewerTabBarControl.hideForSingleTab = NO;
    _viewerTabBarControl.showAddTabButton = NO;
    _viewerTabBarControl.useOverflowMenu = YES;
    _viewerTabBarControl.allowsBackgroundTabClosing = YES;
    _viewerTabBarControl.tearOffStyle = PSMTabBarTearOffMiniwindow;
    
    [[_viewerTabBarControl addTabButton] setTarget:self];
    [[_viewerTabBarControl addTabButton] setAction:@selector(addViewer)];
    
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchValue:)];
    
    [_typeButton setTarget:self];
    [_typeButton setAction:@selector(changeSearchType:)];
    
    self.window.title = _title;
    [self addNewSearch];
    [self showSearch:nil];
}



#pragma mark - IBAction

- (IBAction)clearSearchResult:(NSButtonCell *)sender {
    [_currentSearchController clearResult];
    [_typeButton setEnabled:YES];
}

- (IBAction)showSearch:(id)sender {
    [_searchTabBarControl setHidden:NO];
    [_searchTabBarControl.tabView setHidden:NO];
    [_viewerTabBarControl setHidden:YES];
    [_viewerTabBarControl.tabView setHidden:YES];
    [[self.window toolbar] setSelectedItemIdentifier:@"Search"];
}

- (IBAction)showHexViewer:(id)sender {
    [_searchTabBarControl setHidden:YES];
    [_searchTabBarControl.tabView setHidden:YES];
    [_viewerTabBarControl setHidden:NO];
    [_viewerTabBarControl.tabView setHidden:NO];
    [[self.window toolbar] setSelectedItemIdentifier:@"HexViewer"];
}

- (IBAction)showSettings:(id)sender {
        // TODO
}

#pragma mark -

- (void)addNewSearch {
    SearchResultViewController *resultController = [[SearchResultViewController alloc] initWithPID:_pid];
    [_resultControllers addObject:resultController];
    resultController.title = [NSString stringWithFormat:@"Search #%u", [_resultControllers count]];
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:resultController];
    item.label = resultController.title;
    item.view = resultController.view;
    [_searchTabBarControl.tabView addTabViewItem:item];
    [_searchTabBarControl.tabView selectTabViewItem:item];
}

- (void)addViewer {
    HexViewerController *viewerController = [[HexViewerController alloc] init];
    [_viewerControllers addObject:viewerController];
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:viewerController];
    item.label = viewerController.title;
    item.view = viewerController.view;
    [_viewerTabBarControl.tabView addTabViewItem:item];
    [_viewerTabBarControl.tabView selectTabViewItem:item];
}

- (void)searchValue:(id)sender {
    NSString *value = [_searchField stringValue];
    if ([value length] == 0)
        return;
    if (_timesEightModeButton.state == NSOnState) {
        _currentSearchController.option |= SearchOptionEightTimesMode;
    } else {
        _currentSearchController.option &= ~SearchOptionEightTimesMode;
    }
    [_currentSearchController searchValue:value];
    [_typeButton setEnabled:NO];
}

- (void)changeSearchType:(id)sender {
    _currentSearchController.textType = _typeButton.indexOfSelectedItem == 1;
}

- (void)openViewerForAddress:(VirtualMemoryAddress *)address {
    HexViewerController *viewerController = [[HexViewerController alloc] init];
    [viewerController setPID:_pid address:address.startAddress offset:address.offset size:address.size];
    [_viewerControllers addObject:viewerController];
    NSTabViewItem *item = [[NSTabViewItem alloc] initWithIdentifier:viewerController];
    item.label = viewerController.title;
    item.view = viewerController.view;
    [_viewerTabBarControl.tabView addTabViewItem:item];
    [_viewerTabBarControl.tabView selectTabViewItem:item];
    [self showHexViewer:nil];
}

#pragma mark - PSMTabBarControlDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    _currentSearchController = tabViewItem.identifier;
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    SearchWindowController *resultController = tabViewItem.identifier;
    [_resultControllers removeObject:resultController];
}

@end
