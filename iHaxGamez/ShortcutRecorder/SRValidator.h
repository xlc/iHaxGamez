//
//  SRValidator.h
//  ShortcutRecorder
//
//  Copyright 2006-2007 Contributors. All rights reserved.
//
//  License: BSD
//
//  Contributors:
//      David Dauer
//      Jesper
//      Jamie Kirkpatrick

#import <Cocoa/Cocoa.h>

@protocol SRValidatorDelegate;
@interface SRValidator : NSObject {
    id<SRValidatorDelegate>  delegate;
}

- (id) initWithDelegate:(id)theDelegate;

- (BOOL) isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags error:(NSError **)error;
- (BOOL) isKeyCode:(NSInteger)keyCode andFlags:(NSUInteger)flags takenInMenu:(NSMenu *)menu error:(NSError **)error;

- (id<SRValidatorDelegate>) delegate;
- (void) setDelegate: (id<SRValidatorDelegate>) theDelegate;

@end

#pragma mark -

@protocol SRValidatorDelegate <NSObject>
- (BOOL) shortcutValidator:(SRValidator *)validator isKeyCode:(NSInteger)keyCode andFlagsTaken:(NSUInteger)flags reason:(NSString **)aReason;
@end
