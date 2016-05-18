//
//  BranchUtility.h
//
//  Created by TozyZuo.
//
//  http://TozyZuo.github.io


/**************************************************************************

 INTRODUCTION:

 A way to replace large numbers of "if ... else if ..."

 USAGE:
 
 MODE 1. Non return value.

 Original:

    NSString *a = @"non";

    int random = arc4random_uniform(6);

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
    } else {
        a = @"Not found";
    }
 
 Now:
 
    Use "switch":

    __block NSString *a = @"non";

    BU.switch_(@(random))
    .table(@{
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
 
    Note: "object" is the value of the table.


    Use "if":
     
    __block NSString *a = @"non";

    BU.if_(^(NSNumber *number) {
        return (BOOL)(random == number.intValue);
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
 
    Note: "number" is the key of the table, "object" is the value of the table.

 MODE 2. Need return value.

 Original:

    - (NSInteger)typeByString:(NSString *)string
    {
        if ([string isEqualToString:@"A"]) {
            return 0;
        } else if ([string isEqualToString:@"B"]) {
            return 1;
        } else if ([string isEqualToString:@"C"]) {
            return 2;
        } else {
            return -1;
        }
    }
 
 Now:

    Use "switch":

    - (NSInteger)typeByString:(NSString *)string
    {
        return [BU.switch_(string)
        .table(@{
                 @"A": @0,
                 @"B": @1,
                 @"C": @2,
        }).match(^(NSNumber *object) {
            return object;
        }).default_(^() {
            return @(-1);
        }).value integerValue];
    }
 
    Note: "object" is the value of the table. Last ".value" is the return value of the "match/default" block.


    Use "if":

    - (NSInteger)typeByString:(NSString *)string
    {
        return [BU.if_(^(NSString *str) {
            return [string isEqualToString:str];
        }).table(@{
                   @"A": @0,
                   @"B": @1,
                   @"C": @2,
        }).match(^(NSNumber *object) {
            return object;
        }).default_(^() {
            return @(-1);
        }).value integerValue];
    }

    Note: "str" is the key of the table, "object" is the value of the table. Last ".value" is the return value of the "match/default" block.

 ***************************************************************************/




#import <Foundation/Foundation.h>


@class BUCondition, BUTable, BUMatchResult;


@interface BranchUtility : NSObject
+ (BUCondition *(^)(BOOL (^block)(id object)))if_;
+ (BUCondition *(^)(id<NSCopying> object))switch_;
@end
@compatibility_alias BU BranchUtility;


@interface BUCondition : NSObject
- (BUTable *(^)(NSDictionary *table))table;
@end


@interface BUTable : NSObject
- (BUMatchResult *(^)(id block))match;
@end


@interface BUMatchResult : NSObject
- (id)value;
- (BUMatchResult *(^)(id block))default_;
@end
