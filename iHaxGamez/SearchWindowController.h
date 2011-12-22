//
//  SearchWindowController.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-20.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "PSMTabBarControl.h"

@class SearchResultViewController, PSMTabBarControl;

@interface SearchWindowController : NSWindowController <PSMTabBarControlDelegate> {
@private
    __weak NSPopUpButton *_typeButton;
    __weak NSProgressIndicator *_progressIndicator;
    __weak NSSearchField *_searchField;
    __weak NSButton *_timesEightModeButton;
    __weak PSMTabBarControl *_tabBarControl;
    
    pid_t _pid;
    NSString *_title;
    NSMutableArray *_resultControllers;
    SearchResultViewController *_currentController;
}

@property (weak) IBOutlet NSProgressIndicator *_progressIndicator;
@property (weak) IBOutlet NSPopUpButton *_typeButton;
@property (weak) IBOutlet NSSearchField *_searchField;
@property (weak) IBOutlet NSButton *_timesEightModeButton;
@property (weak) IBOutlet PSMTabBarControl *_tabBarControl;

@property (nonatomic, readonly) pid_t pid;

- (id)initWithTitle:(NSString *)title pid:(pid_t)pid;

- (IBAction)clearSearchResult:(NSButtonCell *)sender;
- (IBAction)showSettings:(NSButtonCell *)sender;

- (void)searchValue:(id)sender;
- (void)addNewSearch;

@end
