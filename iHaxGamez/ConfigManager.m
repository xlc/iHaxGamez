    //
    //  ConfigManager.m
    //  iHaxGamez
    //
    //  Created by Xiliang Chen on 11-12-15.
    //  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
    //

#import "ConfigManager.h"

#import "SearchWindowController.h"

static NSMutableArray *hotKeyConfigs;

OSStatus MyHotKeyHandler(EventHandlerCallRef nextHandler,EventRef theEvent,
                         void *userData)
{
    EventHotKeyID hkCom;
    GetEventParameter(theEvent,kEventParamDirectObject,typeEventHotKeyID,NULL,
                      sizeof(hkCom),NULL,&hkCom);
    
    HotKeyConfig *config = [hotKeyConfigs objectAtIndex:hkCom.id];
    id cls = [ConfigManager class];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [cls performSelector:config.selector];
#pragma clang diagnostic pop
    return noErr;
}

@implementation ConfigManager

+ (void)installHotKeys {
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
    if (firstTime) {
        config.enabled = YES;
            // cmd + shift + 1
        config.key = 0x12;
        config.modifiers = controlKey + shiftKey;
    }
    config.selector = @selector(openSearchWindow);
}

+ (NSArray *)hotKeyConfigs {
    return hotKeyConfigs;
}

+ (void)openSearchWindow {
    [[[SearchWindowController alloc] init] showWindow:self];
    ProcessSerialNumber PSN;
    GetCurrentProcess(&PSN);
    SetFrontProcess(&PSN);
}

@end

@implementation HotKeyConfig

@synthesize enabled = _enabled, modifiers = _modifiers, key = _key;
@synthesize name, selector;

- (id)initWithName:(NSString *)name_ {
    self = [super init];
    if (self) {
        
    }
    return self;
}

- (void)setName:(NSString *)name_ {
    name = name_;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.enabled = [userDefaults boolForKey:[self.name stringByAppendingString:@" - enabled"]];
    self.key = (UInt32)[userDefaults integerForKey:[self.name stringByAppendingString:@" - key"]];
    self.modifiers = (UInt32)[userDefaults integerForKey:[self.name stringByAppendingString:@" - modifiers"]];
}

- (void)setEnabled:(BOOL)enabled {
    _enabled = enabled;
    EventTypeSpec eventType;
    eventType.eventClass=kEventClassKeyboard;
    eventType.eventKind=kEventHotKeyPressed;
    InstallApplicationEventHandler(MyHotKeyHandler,1,&eventType,NULL,NULL);
    if (_enabled) {
        int i = (int)[hotKeyConfigs indexOfObject:self];
        _hotKeyID.signature = 'htk0' + i;
        _hotKeyID.id = i;
        RegisterEventHotKey(self.key, self.modifiers, _hotKeyID, 
                            GetApplicationEventTarget(), 0, &_hotKeyRef);
    } else {
        UnregisterEventHotKey(_hotKeyRef);
    }
    [[NSUserDefaults standardUserDefaults] setBool:_enabled forKey:[self.name stringByAppendingString:@" - enabled"]];
}

- (void)setKey:(UInt32)key {
    _key = key;
    [[NSUserDefaults standardUserDefaults] setInteger:_key forKey:[self.name stringByAppendingString:@" - key"]];
    if (_enabled) {
        self.enabled = NO;
        self.enabled = YES;
    }
}

- (void)setModifiers:(UInt32)modifiers {
    _modifiers = modifiers;
    [[NSUserDefaults standardUserDefaults] setInteger:_modifiers forKey:[self.name stringByAppendingString:@" - modifiers"]];
    if (_enabled) {
        self.enabled = NO;
        self.enabled = YES;
    }
}

@end
