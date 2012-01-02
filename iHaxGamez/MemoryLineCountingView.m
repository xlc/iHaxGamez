//
//  MemoryLineCountingView.m
//  iHaxGamez
//
//  Created by Xiliang Chen on 12-1-2.
//  Copyright (c) 2012年 Xiliang Chen. All rights reserved.
//

#import "MemoryLineCountingView.h"

@implementation MemoryLineCountingView

@synthesize begainAddress = _begainAddress;

- (void)drawLineNumbersWithClipStringDrawing:(NSRect)clipRect {
    CGFloat verticalOffset = (lineRangeToDraw.location - floorl(lineRangeToDraw.location));
    NSRect textRect = [self bounds];
    textRect.size.height = lineHeight;
    textRect.size.width -= 5;
    textRect.origin.y -= verticalOffset * lineHeight + 1;
    unsigned long long lineIndex = (floorl(lineRangeToDraw.location));
    unsigned long long lineValue = lineIndex * bytesPerLine + _begainAddress;
    NSUInteger linesRemaining = ((ceill(lineRangeToDraw.length + lineRangeToDraw.location) - floorl(lineRangeToDraw.location)));
    if (! textAttributes) {
        NSMutableParagraphStyle *mutableStyle = [[NSParagraphStyle defaultParagraphStyle] mutableCopy];
        [mutableStyle setAlignment:NSRightTextAlignment];
        NSParagraphStyle *paragraphStyle = [mutableStyle copy];
        textAttributes = [[NSDictionary alloc] initWithObjectsAndKeys:font, NSFontAttributeName, [NSColor colorWithCalibratedWhite:(CGFloat).1 alpha:(CGFloat).8], NSForegroundColorAttributeName, paragraphStyle, NSParagraphStyleAttributeName, nil];
    }
    
    char formatString[64];
    snprintf(formatString, sizeof(formatString), "0x%%0%lullX", (unsigned long)[[self representer] digitCount] - 2);
    while (linesRemaining--) {
        if (NSIntersectsRect(textRect, clipRect)) {
            char buff[256];
            int newStringLength = snprintf(buff, sizeof buff, formatString, lineValue);
            NSString *string = [[NSString alloc] initWithBytesNoCopy:buff length:newStringLength encoding:NSASCIIStringEncoding freeWhenDone:NO];
            [string drawInRect:textRect withAttributes:textAttributes];
        }
        textRect.origin.y += lineHeight;
        lineIndex++;
        if (linesRemaining > 0) lineValue += bytesPerLine; //we could do this unconditionally, but then we risk overflow
    }
}

@end
