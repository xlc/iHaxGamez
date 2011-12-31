//
//  SearchResultViewController.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-19.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SearchResultViewController : NSViewController <NSTableViewDelegate, NSTableViewDataSource> {
@private
    __weak NSTextField *_infoLabel;
    __weak NSProgressIndicator *_progressIndicator;
    __weak NSTableView *_tableView;
    
    pid_t _pid;
    BOOL _processing;
    NSArray *_results;
    NSInteger _option;
    BOOL _textType;
    NSInteger _searchCount;
}

@property (weak) IBOutlet NSTextField *_infoLabel;
@property (weak) IBOutlet NSProgressIndicator *_progressIndicator;
@property (weak) IBOutlet NSTableView *_tableView;

@property (nonatomic, readonly) BOOL isProcessing;
@property (nonatomic, readonly) NSInteger objectCount;
@property (nonatomic) NSInteger option;
@property (nonatomic) BOOL textType;

- (id)initWithPID:(pid_t)pid;
- (void)searchValue:(NSString *)stringValue;
- (void)clearResult;
- (IBAction)doubleClick:(id)sender;

@end
