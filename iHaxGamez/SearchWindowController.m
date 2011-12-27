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

@implementation SearchWindowController
@synthesize _tabBarControl;
@synthesize _timesEightModeButton;
@synthesize _searchField;
@synthesize _typeButton;
@synthesize _progressIndicator;

@synthesize pid = _pid;

- (id)initWithTitle:(NSString *)title pid:(pid_t)pid {
    self = [super initWithWindowNibName:@"SearchWindow"];
    if (self) {
        _title = [title copy];
        _pid = pid;
        _resultControllers = [NSMutableArray array];
    }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    
    _tabBarControl.canCloseOnlyTab = NO;
    _tabBarControl.disableTabClose = NO;
    _tabBarControl.hideForSingleTab = NO;
    _tabBarControl.showAddTabButton = YES;
    _tabBarControl.useOverflowMenu = YES;
    _tabBarControl.allowsBackgroundTabClosing = YES;
    _tabBarControl.tearOffStyle = PSMTabBarTearOffMiniwindow;
    
    [[_tabBarControl addTabButton] setTarget:self];
    [[_tabBarControl addTabButton] setAction:@selector(addNewSearch)];
    _tabBarControl.delegate = self;
    
    [_searchField setTarget:self];
    [_searchField setAction:@selector(searchValue:)];
    
    self.window.title = _title;
    [self addNewSearch];
}



#pragma mark -

- (IBAction)clearSearchResult:(NSButtonCell *)sender {
    [_currentController clearResult];
}

- (IBAction)showSettings:(NSButtonCell *)sender {
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
    [_tabBarControl.tabView addTabViewItem:item];
    [_tabBarControl.tabView selectTabViewItem:item];
}

- (void)searchValue:(id)sender {
    NSString *value = [_searchField stringValue];
    if ([value length] == 0)
        return;
    if (_timesEightModeButton.state == NSOnState) {
        _currentController.option |= SearchOptionEightTimesMode;
    } else {
        _currentController.option &= ~SearchOptionEightTimesMode;
    }
    [_currentController searchValue:value];
}

#pragma mark - PSMTabBarControlDelegate

- (void)tabView:(NSTabView *)tabView didSelectTabViewItem:(NSTabViewItem *)tabViewItem {
    _currentController = tabViewItem.identifier;
}

- (void)tabView:(NSTabView *)aTabView didCloseTabViewItem:(NSTabViewItem *)tabViewItem {
    SearchWindowController *resultController = tabViewItem.identifier;
    [_resultControllers removeObject:resultController];
}

@end
