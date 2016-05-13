//
//  main.m
//  BranchUtility
//
//  Created by TozyZuo on 16/5/13.
//  Copyright © 2016年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BranchUtility.h"

typedef struct {
    int a;
    char b;
    CGFloat c;
}MyStruct;

MyStruct TestStructReturn(NSString *str)
{
    MyStruct s1 = {.a = 1, .b = 'A', .c = 3.14159f};
    MyStruct s2 = {.a = 2, .b = 'B', .c = 2.71828};
    MyStruct s3 = {.a = 3, .b = 'C', .c = 0};

    NSValue *value = BU.if_(^(id object) {
        return [str isEqualToString:object];
    }).table(@{
                      @"A": [NSValue value:&s1 withObjCType:@encode(MyStruct)],
                      @"B": [NSValue value:&s2 withObjCType:@encode(MyStruct)],
                      @"C": [NSValue value:&s3 withObjCType:@encode(MyStruct)],
    }).match(^(NSValue *object) {
        return object;
    }).default_(^() {
        MyStruct s = (MyStruct){};
        return [NSValue value:&s withObjCType:@encode(MyStruct)];
    }).value;

    MyStruct ret;
    [value getValue:&ret];
    return ret;
}

int TestIntReturn(NSString *str)
{
    return [BU.if_(^(NSString *object) {
        return [str isEqualToString:object];
    }).table(@{
                      @"A": @1,
                      @"B": @2,
                      @"C": @3,
    }).match(^(id object) {
        return object;
    }).default_(^() {
        return -1;
    }).value intValue];
}

void TestIF()
{
    __block NSString *a = @"non";

    int random = arc4random_uniform(5);

    if (random == 0) {
        a = @"a";
    } else if (random == 1) {
        a = @"b";
    } else if (random == 2) {
        a = @"c";
    } else if (random == 3) {
        a = @"d";
    } else if (random == 4) {
        a = @"e";
    }

    a = @"non";

//    random = 5;

    BU.if_(^(NSNumber *number) {
        return (BOOL)(random == [number intValue]);
    }).table(@{
                      @0: @"a",
                      @1: @"b",
                      @2: @"c",
                      @3: @"d",
                      @4: @"e",
    }).match(^(NSString *object) {
        a = object;
    }).default_(^() {
        a = @"Not found";
    });

    int n = TestIntReturn(@"A");
    @autoreleasepool {
        n = TestIntReturn(@"B");
    }
    @autoreleasepool {
        n = TestIntReturn(@"C");
    }

    MyStruct s = TestStructReturn(@"A");
    s = TestStructReturn(@"B");
    s = TestStructReturn(@"C");
    s = TestStructReturn(@"D");
}


void TestSwitch()
{
    __block int a = -10;

    BU.switch_(@"D")
    .table(@{
                 @"A": @1,
                 @"B": @2,
                 @"C": @3,
    }).match(^(NSNumber *num) {
        a = num.intValue;
    }).default_(^() {
        a = -1;
    });

    NSLog(@"%d", a);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        TestIF();
        TestSwitch();
    }
    return 0;
}
