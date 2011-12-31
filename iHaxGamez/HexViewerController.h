//
//  HexViewerController.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-31.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HFController;

@interface HexViewerController : NSViewController {
@private
    HFController *_controller;
    NSView *_view;
}

- (void)setPID:(pid_t)pid address:(vm_address_t)address offset:(vm_offset_t)offset size:(vm_offset_t)size;

@end
