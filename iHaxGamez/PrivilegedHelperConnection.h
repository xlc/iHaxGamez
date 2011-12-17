//
//  PrivilegedHelperConnection.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-17.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PrivilegedHelperConnection : NSObject {
@private
    NSMachPort *childReceiveMachPort;
}

+ (PrivilegedHelperConnection *)sharedConnection;
- (BOOL)launchAndConnect:(NSError **)error;
- (BOOL)connectIfNecessary;
- (BOOL)sayHello;

@end
