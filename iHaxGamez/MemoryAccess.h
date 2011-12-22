//
//  MemoryAccess.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-20.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AppKit/Appkit.h>

enum {
    SearchOptionNormal = 0,
    SearchOptionLimitSizeRange = 1,
    SearchOptionEightTimesMode = 1 << 1,
};

@class VariableValue;

@interface MemoryAccess : NSObject

+ (void)searchValue:(VariableValue *)value pid:(pid_t)pid option:(NSInteger)option callback:(void (^)(double percent, NSArray *result, BOOL done))callback;
+ (void)filterDatas:(NSArray *)datas withValue:(VariableValue *)value callback:(void (^)(double percent, NSArray *result, BOOL done))callback;

+ (BOOL)checkProcessAlive:(pid_t)pid;

@end
