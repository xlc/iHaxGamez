    //
    //  SearchResultViewController.m
    //  iHaxGamez
    //
    //  Created by Xiliang Chen on 11-12-19.
    //  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
    //

#import "SearchResultViewController.h"

#import "MemoryAccess.h"
#import "VirtualMemoryAddress.h"
#import "VariableValue.h"
#import "VirtualMemoryException.h"

@implementation SearchResultViewController
@synthesize _tableView;
@synthesize _progressIndicator;
@synthesize _infoLabel;

@synthesize isProcessing = _processing, textType = _textType, option = _option;

- (id)initWithPID:(pid_t)pid
{
    self = [super initWithNibName:@"SearchResultViewController" bundle:[NSBundle mainBundle]];
    if (self) {
        _pid = pid;
        _processing = NO;
        _option = SearchOptionLimitSizeRange;
        _textType = NO;
        _searchCount = 0;
    }
    
    return self;
}

- (NSInteger)objectCount {
    return [_results count];
}

#pragma mark -

- (void)searchValue:(NSString *)stringValue {
    VariableValue *value = [[VariableValue alloc] initWithStringValue:stringValue isTextType:_textType];
    _processing = YES;
    [_infoLabel setHidden:YES];
    [_progressIndicator setHidden:NO];
    
    void (^callback)(double percent, NSArray *result, BOOL done) =  ^(double percent, NSArray *result, BOOL done) {
        _results = result;
        _progressIndicator.doubleValue = percent;
        [_tableView reloadData];
        if (done) {
            _processing = NO;
            _infoLabel.stringValue = [NSString stringWithFormat:@"Search Results: %d Times %d Found", _searchCount, [_results count]];
            [_infoLabel setHidden:NO];
            [_progressIndicator setHidden:YES];
        }
    };
    
    if ([_results count] == 0) {
        _searchCount = 1;
        [MemoryAccess searchValue:value pid:_pid option:_option callback:callback];
    } else {
        _searchCount++;
        [MemoryAccess filterDatas:_results withValue:value callback:callback];
    }
}

- (void)clearResult {
    if (!_processing) {
        _searchCount = 0;
        _results = nil;
        [_tableView reloadData];
    } else {
            // TODO stop searching?
    }
}

#pragma mark -

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_results count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    @try {
        VirtualMemoryAddress *address = [_results objectAtIndex:row];
        if ([tableColumn.identifier isEqualToString:@"Address"]) {
            return [NSString stringWithFormat:@"0x%qX", address.address];
        } else if ([tableColumn.identifier isEqualToString:@"SignedInteger"]) {
            return [NSString stringWithFormat:@"%lld", address.signedIntegerValue];
        } else if ([tableColumn.identifier isEqualToString:@"UnsignedInteger"]) {
            return [NSString stringWithFormat:@"%llu", address.unsignedIntegerValue];
        } else if ([tableColumn.identifier isEqualToString:@"Float"]) {
            return [NSString stringWithFormat:@"%f", address.floatValue];
        } else if ([tableColumn.identifier isEqualToString:@"Double"]) {
            return [NSString stringWithFormat:@"%lf", address.doubleValue];
        } else if ([tableColumn.identifier isEqualToString:@"ASCIIText"]) {
            return address.asciiValue;
        } else if ([tableColumn.identifier isEqualToString:@"UnicodeText"]) {
            return address.unicodeValue;
        }
    }
    @catch (VirtualMemoryException *exception) {
        MILOG(@"ignore exception: %@", exception);
        return nil;
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    VirtualMemoryAddress *address = [_results objectAtIndex:row];
    NSString *stringValue = object;
    VariableValue *value = [[VariableValue alloc] initWithStringValue:stringValue isTextType:!VariableTypeIsNumeric(address.value.type)];
    [address updateValue:value];
}


@end
