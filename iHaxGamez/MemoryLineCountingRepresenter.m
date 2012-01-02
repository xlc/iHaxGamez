//
//  MemoryLineCountingRepresenter.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 12-1-1.
//  Copyright (c) 2012年 Xiliang Chen. All rights reserved.
//

#import "MemoryLineCountingRepresenter.h"

#import "MemoryLineCountingView.h"

@implementation MemoryLineCountingRepresenter

- (NSView *)createView {
    HFLineCountingView *result = [[MemoryLineCountingView alloc] initWithFrame:NSMakeRect(0, 0, 60, 10)];
    [result setRepresenter:self];
    [result setAutoresizingMask:NSViewHeightSizable];
    return result;
}

- (void)setBegainAddress:(NSUInteger)begainAddress {
    [(MemoryLineCountingView *)self.view setBegainAddress:begainAddress];
}

- (NSUInteger)begainAddress {
    return [(MemoryLineCountingView *)self.view begainAddress];
}

@end
