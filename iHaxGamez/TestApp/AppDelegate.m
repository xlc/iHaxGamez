//
//  AppDelegate.m
//  TestApp
//
//  Created by Xiliang Chen on 11-12-25.
//  Copyright (c) 2011年 __MyCompanyName__. All rights reserved.
//

#import "AppDelegate.h"

static uint64_t uiValue0;
static uint64_t uiValue1 = 1;
static uint64_t *uiValue[3] = {0, &uiValue0, &uiValue1};

static int64_t iValue0;
static int64_t iValue1 = 1;
static int64_t *iValue[3] = {0, &iValue0, &iValue1};

static float fValue0;
static float fValue1 = 1;
static float *fValue[3] = {0, &fValue0, &fValue1};

static double dValue0;
static double dValue1 = 1;
static double *dValue[3] = {0, &dValue0, &dValue1};

static char asciiValue0[20];
static char asciiValue1[20] = "abcde";
static char *asciiValue[3] = {0, (char *)&asciiValue0, (char *)&asciiValue1};

static unichar unicodeValue0[20];
static unichar unicodeValue1[20] = {'u', 'n', 'i', 'c', 'o', 'd', 'e'};
static unichar *unicodeValue[3] = {0, (unichar *)&unicodeValue0, (unichar *)&unicodeValue1};

static NSMutableString *stringValue;

@implementation AppDelegate

@synthesize window = _window, view = _view;

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    uiValue[0] = malloc(sizeof(uint64_t));
    iValue[0] = malloc(sizeof(int64_t));
    fValue[0] = malloc(sizeof(float));
    dValue[0] = malloc(sizeof(double));
    asciiValue[0] = malloc(sizeof(char) * 20);
    unicodeValue[0] = malloc(sizeof(unichar) * 20);
    stringValue = [[NSMutableString alloc] initWithString:@"qwert"];
}

- (IBAction)reloadData:(id)sender {
    NSTextField *textField;
    for (int i = 0; i < 3; i++) {
        textField = [_view viewWithTag:i+1];
        textField.stringValue = [NSString stringWithFormat:@"%lu", *(uiValue[i])];
        
        textField = [_view viewWithTag:i+4];
        textField.stringValue = [NSString stringWithFormat:@"%ld", *(iValue[i])];

        textField = [_view viewWithTag:i+7];
        textField.stringValue = [NSString stringWithFormat:@"%f", *(fValue[i])];
        
        textField = [_view viewWithTag:i+10];
        textField.stringValue = [NSString stringWithFormat:@"%lf", *(dValue[i])];
        
        textField = [_view viewWithTag:i+13];
        asciiValue[i][19] = '\0';
        textField.stringValue = [NSString stringWithFormat:@"%s", asciiValue[i]];
        
        textField = [_view viewWithTag:i+16];
        unicodeValue[i][19] = '\0';
        textField.stringValue = [[NSString alloc] initWithCharacters:unicodeValue[i] length:20];
    }
    textField = [_view viewWithTag:19];
    textField.stringValue = stringValue;
}

- (IBAction)saveData:(id)sender {
    NSTextField *textField;
    for (int i = 0; i < 3; i++) {
        textField = [_view viewWithTag:i+1];
        *uiValue[i] = [textField.stringValue longLongValue];
        
        textField = [_view viewWithTag:i+4];
        *iValue[i] = [textField.stringValue longLongValue];
        
        textField = [_view viewWithTag:i+7];
        *fValue[i] = [textField.stringValue floatValue];
        
        textField = [_view viewWithTag:i+10];
        *dValue[i] = [textField.stringValue doubleValue];
        
        textField = [_view viewWithTag:i+13];
        [textField.stringValue getCString:asciiValue[i] maxLength:20 encoding:NSASCIIStringEncoding];
        
        textField = [_view viewWithTag:i+16];
        [textField.stringValue getCharacters:unicodeValue[i] range:NSMakeRange(0, 20)];
    }
    textField = [_view viewWithTag:19];
    [stringValue setString:textField.stringValue];
}

@end
