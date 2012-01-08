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
#import "SearchWindowController.h"

@implementation SearchResultViewController
@synthesize _tableView;
@synthesize _progressIndicator;
@synthesize _infoLabel;

@synthesize isProcessing = _processing, type = _type, option = _option;

- (id)initWithPID:(pid_t)pid
{
    self = [super initWithNibName:@"SearchResultViewController" bundle:[NSBundle mainBundle]];
    if (self) {
        _pid = pid;
        _processing = NO;
        _option = SearchOptionNormal;
        _type = NO;
        _searchCount = 0;
    }
    
    return self;
}

- (NSInteger)objectCount {
    return [_results count];
}

#pragma mark -

- (void)searchValue:(NSString *)stringValue {
    if (_processing)
        return; // TODO say something?
    NSInteger option = _option;
    VariableValue *value;
    switch (_type) {
        case 0: // auto type
            value = [[VariableValue alloc] initWithStringValue:stringValue isTextType:NO];
            option |= SearchOptionLimitSizeRange;
            break;
        case 1: // text type
            value = [[VariableValue alloc] initWithStringValue:stringValue isTextType:YES];
            break;
        case 2: // 1 byte int
            value = [[VariableValue alloc] initWithStringValue:stringValue type:VariableTypeUnsignedInteger size:sizeof(uint8_t)];
            break;
        case 3: // 2 bypes int
            value = [[VariableValue alloc] initWithStringValue:stringValue type:VariableTypeUnsignedInteger size:sizeof(uint16_t)];
            break;
        case 4: // 4 bytes int
            value = [[VariableValue alloc] initWithStringValue:stringValue type:VariableTypeUnsignedInteger size:sizeof(uint32_t)];
            break;
        case 5: // 8 bytes int
            value = [[VariableValue alloc] initWithStringValue:stringValue type:VariableTypeUnsignedInteger size:sizeof(uint64_t)];
            break;
        case 6: // float
            value = [[VariableValue alloc] initWithStringValue:stringValue type:VariableTypeFloat size:sizeof(float)];
            break;
        case 7: // double
            value = [[VariableValue alloc] initWithStringValue:stringValue type:VariableTypeDouble size:sizeof(double)];
            break;
            
        default:
            MFAIL(@"invalid case: %d", _type);
    }
    _processing = YES;
    [_infoLabel setHidden:YES];
    [_progressIndicator setHidden:NO];
    clock_t start = clock();
    void (^callback)(double percent, NSArray *result, BOOL done) =  ^(double percent, NSArray *result, BOOL done) {
        _results = result;
        _progressIndicator.doubleValue = percent;
        [_tableView reloadData];
        if (done) {
            clock_t end = clock();
            double diff = (end - start) / (double)CLOCKS_PER_SEC;
            _processing = NO;
            _infoLabel.stringValue = [NSString stringWithFormat:@"Search Results: %d Times %d Found (%.4lf seconds)", _searchCount, [_results count], diff];
            [_infoLabel setHidden:NO];
            [_progressIndicator setHidden:YES];
        }
    };

    if ([_results count] == 0) {
        _searchCount = 1;
        [MemoryAccess searchValue:value pid:_pid option:option callback:callback];
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

- (void)refresh {
    [_tableView reloadData];
}

#pragma mark - IBAction

- (IBAction)doubleClick:(id)sender {
    SearchWindowController *controller = (SearchWindowController *)self.view.window.windowController;
    NSUInteger row = [_tableView selectedRow];
    VirtualMemoryAddress *address = [_results objectAtIndex:row];
    [controller openViewerForAddress:address];
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return [_results count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    @try {
        VirtualMemoryAddress *address = [_results objectAtIndex:row];
        if ([tableColumn.identifier isEqualToString:@"Locked"]) {
            return [NSNumber numberWithBool:address.locked];
        } else if ([tableColumn.identifier isEqualToString:@"Address"]) {
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
    if ([tableColumn.identifier isEqualToString:@"Locked"]) {
        NSNumber *number = object;
        address.locked = [number boolValue];
    } else {    // TODO add number foramtter to table text field cell
        NSString *stringValue = object;
        VariableValue *value = [[VariableValue alloc] initWithStringValue:stringValue isTextType:!VariableTypeIsNumeric(address.value.type)];
        [address updateValue:value];
    }
}


@end
