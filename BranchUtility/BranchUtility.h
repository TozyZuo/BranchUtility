//
//  TZBranch.h
//  BranchUtility
//
//  Created by TozyZuo on 16/5/13.
//  Copyright © 2016年 TozyZuo. All rights reserved.
//

#import <Foundation/Foundation.h>


@class BUCondition, BUSwitchCondition, BUTable, BUMatchResult;


@interface BranchUtility : NSObject
+ (BUCondition *(^)(BOOL (^block)(id object)))if_;
+ (BUCondition *(^)(NSString *object))switch_;
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
