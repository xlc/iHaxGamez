//
//  HexViewerController.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-31.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import "HexViewerController.h"

#import <HexFiend/HexFiend.h>

#import "VirtualMemoryByteArray.h"

@implementation HexViewerController

- (id)init {
    self = [super initWithNibName:@"HexViewerController" bundle:[NSBundle mainBundle]];
    if (self) {
        _controller = [[HFController alloc] init];
        [_controller setInOverwriteMode:YES];
        
        HFLayoutRepresenter *layoutRep = [[HFLayoutRepresenter alloc] init];
        HFHexTextRepresenter *hexRep = [[HFHexTextRepresenter alloc] init];
        HFStringEncodingTextRepresenter *asciiRep = [[HFStringEncodingTextRepresenter alloc] init];
        HFVerticalScrollerRepresenter *scrollRep = [[HFVerticalScrollerRepresenter alloc] init];
        HFLineCountingRepresenter *lineRep = [[HFLineCountingRepresenter alloc] init];
        
        [_controller addRepresenter:layoutRep];
        [_controller addRepresenter:hexRep];
        [_controller addRepresenter:asciiRep];
        [_controller addRepresenter:scrollRep];
        [_controller addRepresenter:lineRep];
        
        [layoutRep addRepresenter:hexRep];
        [layoutRep addRepresenter:asciiRep];
        [layoutRep addRepresenter:scrollRep];
        [layoutRep addRepresenter:lineRep];
        
        _view = layoutRep.view;
        _view.autoresizingMask = kCALayerHeightSizable | kCALayerWidthSizable;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    _view.frame = self.view.bounds;
    [self.view addSubview:_view];
}

- (void)setPID:(pid_t)pid address:(vm_address_t)address offset:(vm_offset_t)offset size:(vm_offset_t)size {
    self.title = [NSString stringWithFormat:@"%p", (void *)address+offset];
        // TODO use 0 for offset and set display range to show it on screen
    VirtualMemoryByteArray *byteArray = [[VirtualMemoryByteArray alloc] initWithPID:pid address:address offset:offset size:size];
    if (byteArray) {
        [_controller setByteArray:byteArray];
    }
}

@end
