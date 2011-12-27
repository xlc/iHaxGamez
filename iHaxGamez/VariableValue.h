//
//  VariableValue.h
//  iHaxGamez
//
//  Created by Xiliang Chen on 11-12-18.
//  Copyright (c) 2011年 Xiliang Chen. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    VariableTypeUnsignedInteger,
    VariableTypeInteger,
    VariableTypeFloat,
    VariableTypeDouble,
    VariableTypeASCII,
    VariableTypeUnicode,
} VariableType;

@interface VariableValue : NSObject {
@private
    VariableType _type;
    size_t _size;
    size_t _maxSize;
    void *_data[4];
    size_t _dataSize[2];
    BOOL _eightTimes;
}

@property (nonatomic, readonly) VariableType type;
@property (nonatomic, readonly) size_t size;
@property (nonatomic, readonly) size_t maxSize;
@property (nonatomic, readonly) void *data;
@property (nonatomic, readonly) BOOL eightTimes;

- (id)initWithStringValue:(NSString *)stringValue isTextType:(BOOL)textType;
- (id)initWithValue:(VariableValue *)value type:(VariableType)type;
- (id)initWithValue:(VariableValue *)value size:(size_t)size type:(VariableType)type;
- (id)initWithData:(void *)data size:(size_t)size type:(VariableType)type;
- (id)initWithData:(void *)data size:(size_t)size maxSize:(size_t)maxSize type:(VariableType)type;

- (BOOL)compareAtAddress:(void *)address minSize:(size_t)minSize maxSize:(size_t)maxSize matchedType:(VariableType *)matchedType;

- (VariableValue *)eightTimesValue;

@end

static inline BOOL VariableTypeIsNumeric(VariableType type) {
    switch (type) {
        case VariableTypeUnsignedInteger:
        case VariableTypeInteger:
        case VariableTypeFloat:
        case VariableTypeDouble:
            return YES;
        case VariableTypeASCII:
        case VariableTypeUnicode:
            return NO;
    }
}