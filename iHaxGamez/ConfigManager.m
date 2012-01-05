    //
    //  ConfigManager.m
    //  iHaxGamez
    //
    //  Created by Xiliang Chen on 11-12-15.
    //  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
    //

#import "ConfigManager.h"

#import "MainWindowController.h"
#import "SearchWindowController.h"
#import "SRCommon.h"

#import "SRValidator.h"

static NSMutableArray *hotKeyConfigs;
static BOOL hotkeyEnabled = YES;
static SRValidator *validator;

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
                         void *userData)
{
    EventHotKeyID hkCom;
    GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
                      sizeof(hkCom),NULL,&hkCom);
    HotKeyConfig *config = [hotKeyConfigs objectAtIndex:hkCom.id];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [ConfigManager performSelector:config.selector];
#pragma clang diagnostic pop
    return noErr;
}

@implementation ConfigManager

+ (void)installHotKeys {
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(MyHotKeyHandler,1,&eventType,NULL,NULL);
    
    validator = [[SRValidator alloc] init];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    BOOL firstTime;
    firstTime = ![userDefaults boolForKey:@"User Defaults Installed"];
    if (firstTime) {
        [userDefaults setBool:YES forKey:@"User Defaults Installed"];
    }
    firstTime = YES;
    HotKeyConfig *config;
    hotKeyConfigs = [NSMutableArray array];
    
    config = [[HotKeyConfig alloc] init];
    [hotKeyConfigs addObject:config];
    config.name = @"Open Search Window";
    if (firstTime) {    // defaults
            // control + shift + 1
        [config setModifiers:controlKey + shiftKey key:0x12];
        config.enabled = YES;
    }
    config.selector = @selector(openSearchWindow);
}

+ (void)disableHotKeys {
    hotkeyEnabled = NO;
    for (HotKeyConfig *config in hotKeyConfigs) {
        config.enabled = config.enabled;
    }
}

+ (void)enableHotKeys {
    hotkeyEnabled = YES;
    for (HotKeyConfig *config in hotKeyConfigs) {
        config.enabled = config.enabled;
    }
}

+ (NSArray *)hotKeyConfigs {
    return hotKeyConfigs;
}

+ (void)openSearchWindow {
    ProcessSerialNumber PSN;
    MASSERT_SOFT(GetFrontProcess(&PSN) == 0);
    [[MainWindowController sharedController] openSearchWindowForProcess:PSN];
    ProcessSerialNumber myPSN;
    MASSERT_SOFT(GetCurrentProcess(&myPSN) == 0);
    MASSERT_SOFT(SetFrontProcess(&myPSN) == 0);
}

@end

@implementation HotKeyConfig

@synthesize enabled = _enabled, modifiers = _modifiers, key = _key, keyDescription = _keyDescription;
@synthesize name, selector;

- (void)setName:(NSString *)name_ {
    name = name_;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    _key = (UInt32)[userDefaults integerForKey:[self.name stringByAppendingString:@" - key"]];
    _modifiers = (UInt32)[userDefaults integerForKey:[self.name stringByAppendingString:@" - modifiers"]];
    self.enabled = [userDefaults boolForKey:[self.name stringByAppendingString:@" - enabled"]];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    if (hotkeyEnabled && _enabled) {
        if (!_hotKeyRef) {
            int i = (int)[hotKeyConfigs indexOfObject:self];
            _hotKeyID.signature = 'htk0' + i;
            _hotKeyID.id = i;
            RegisterEventHotKey(self.key, self.modifiers, _hotKeyID, 
                                GetApplicationEventTarget(), 0, &_hotKeyRef);
        }
    } else {
        if (_hotKeyRef)
            UnregisterEventHotKey(_hotKeyRef);
        _hotKeyRef = NULL;
    }
    [[NSUserDefaults standardUserDefaults] setBool:_enabled forKey:[self.name stringByAppendingString:@" - enabled"]];
}

- (NSString *)keyDescription {
    if (!_keyDescription) {
        _keyDescription = SRStringForCarbonModifierFlagsAndKeyCode(_modifiers, _key);
        
    }
    return _keyDescription;
}

- (BOOL)setModifiers:(UInt32)modifiers key:(UInt32)key {
    if ([validator isKeyCode:key andFlagsTaken:modifiers error:NULL]) {
        return NO;
    }
    for (HotKeyConfig *config in hotKeyConfigs) {
        if (config != self) {
            if (config.modifiers == modifiers && config.key == key)
                return NO;
        }
    }
    
    _modifiers = modifiers;
    [[NSUserDefaults standardUserDefaults] setInteger:_modifiers forKey:[self.name stringByAppendingString:@" - modifiers"]];
    _key = key;
    [[NSUserDefaults standardUserDefaults] setInteger:_key forKey:[self.name stringByAppendingString:@" - key"]];
    if (_enabled) {
        self.enabled = NO;
        self.enabled = YES;
    }
    _keyDescription = nil;
    return YES;
}

@end
