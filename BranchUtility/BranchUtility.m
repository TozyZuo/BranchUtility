//
//  BranchUtility.m
//
//  Created by TozyZuo.
//

#import "BranchUtility.h"


static NSMethodSignature *NSMethodSignatureForBlock(id block);
id pmk_safely_call_block(id block, id arg);


@interface BUCondition ()
@property (nonatomic, copy) BOOL (^conditionBlock)(id);
@property (nonatomic, copy) id<NSCopying> object;
@end

@interface BUTable ()
@property (nonatomic, strong) NSDictionary  *table;
@property (nonatomic,  copy ) id condition;
@end

@interface BUSwitchTable : BUTable
@end

@interface BUMatchResult ()
@property (nonatomic, strong) id value;
@property (nonatomic, assign) BOOL match;
@end

@implementation BranchUtility

+ (BUCondition *(^)(BOOL (^)(id)))if_
{
    BUCondition *condition = [[BUCondition alloc] init];
    return ^(BOOL (^block)(id)) {
        condition.conditionBlock = block;
        return condition;
    };
}

+ (BUCondition *(^)(id<NSCopying>))switch_
{
    BUCondition *condition = [[BUCondition alloc] init];
    return ^(id<NSCopying> object) {
        condition.object = object;
        return condition;
    };
}

@end

@implementation BUCondition

- (void)dealloc
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (BUTable *(^)(NSDictionary *))table
{
    BUTable *table;
    if (self.object) {
        table = [[BUSwitchTable alloc] init];
        table.condition = self.object;
    } else {
        table = [[BUTable alloc] init];
        table.condition = self.conditionBlock;
    }
    return ^(NSDictionary *t) {
        table.table = t;
        return table;
    };
}

@end

@implementation BUTable

- (void)dealloc
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (BUMatchResult *(^)(id block))match
{
    BUMatchResult *matchResult = [[BUMatchResult alloc] init];

    __weak typeof(self) weakSelf = self;

    return ^(id matchBlock) {

        BOOL (^conditionBlock)(id) = weakSelf.condition;

        if (conditionBlock) {

            NSDictionary *table = weakSelf.table;

            for (id key in table) {
                if (conditionBlock(key)) {
                    matchResult.value = pmk_safely_call_block(matchBlock, table[key]);
                    matchResult.match = YES;
                    break;
                }
            }
        }

        return matchResult;
    };
}

@end

@implementation BUSwitchTable

- (BUMatchResult *(^)(id))match
{
    BUMatchResult *matchResult = [[BUMatchResult alloc] init];

    __weak typeof(self) weakSelf = self;

    return ^(id matchBlock) {

        id value = weakSelf.table[weakSelf.condition];

        if (value) {
            matchResult.value = pmk_safely_call_block(matchBlock, value);
            matchResult.match = YES;
        }

        return matchResult;
    };
}

@end

@implementation BUMatchResult

- (void)dealloc
{
//    NSLog(@"%s", __PRETTY_FUNCTION__);
}

- (BUMatchResult *(^)(id defaultBlock))default_
{
    __weak typeof(self) weakSelf = self;

    return ^(id defaultBlock) {

        if (!weakSelf.match) {
            weakSelf.value = pmk_safely_call_block(defaultBlock, nil);
        }

        return weakSelf;
    };
}

@end


#pragma mark - From PromiseKit

id pmk_safely_call_block(id block, id arg)
{
    if (!block) {
        return nil;
    }

    @try {
        NSMethodSignature *sig = NSMethodSignatureForBlock(block);
        const NSUInteger nargs = sig.numberOfArguments;
        if (nargs > 2) {
            @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BranchUtility: The provided block’s argument count is unsupported." userInfo:nil];
            return nil;
        }
        const char rtype = sig.methodReturnType[0];

#define call_block_with_rtype(type) ({^type{ \
        switch (nargs) { \
            case 1: \
                return ((type(^)(void))block)(); \
            case 2: { \
                return ((type(^)(id))block)(arg); \
            } \
            default: \
                @throw [NSException exceptionWithName:NSInvalidArgumentException reason:@"BranchUtility: The provided block’s argument count is unsupported." userInfo:nil]; \
        }}();})

        switch (rtype) {
            case 'v':
                call_block_with_rtype(void);
                return nil;
            case '@':
                return call_block_with_rtype(id) ?: nil;
            case '*': {
                char *str = call_block_with_rtype(char *);
                return str ? @(str) : nil;
            }
            case 'c': return @(call_block_with_rtype(char));
            case 'i': return @(call_block_with_rtype(int));
            case 's': return @(call_block_with_rtype(short));
            case 'l': return @(call_block_with_rtype(long));
            case 'q': return @(call_block_with_rtype(long long));
            case 'C': return @(call_block_with_rtype(unsigned char));
            case 'I': return @(call_block_with_rtype(unsigned int));
            case 'S': return @(call_block_with_rtype(unsigned short));
            case 'L': return @(call_block_with_rtype(unsigned long));
            case 'Q': return @(call_block_with_rtype(unsigned long long));
            case 'f': return @(call_block_with_rtype(float));
            case 'd': return @(call_block_with_rtype(double));
            case 'B': return @(call_block_with_rtype(_Bool));
            case '^':
                if (strcmp(sig.methodReturnType, "^v") == 0) {
                    call_block_with_rtype(void);
                    return nil;
                }
                // else fall through!
            default:
                @throw [NSException exceptionWithName:@"BranchUtility" reason:@"Unsupported method signature… Why not fork and fix?" userInfo:nil];
        }
    } @catch (id exception) {

        id userInfo = @{
                        NSUnderlyingErrorKey: exception,
                        NSLocalizedDescriptionKey: [exception isKindOfClass:[NSException class]]
                        ? [exception reason]
                        : [exception description]
                        };
        return [NSError errorWithDomain:@"BranchUtilityErrorDomain" code:1 userInfo:userInfo];
    }
}

#pragma mark Block

struct PMKBlockLiteral {
    void *isa; // initialized to &_NSConcreteStackBlock or &_NSConcreteGlobalBlock
    int flags;
    int reserved;
    void (*invoke)(void *, ...);
    struct block_descriptor {
        unsigned long int reserved;	// NULL
        unsigned long int size;         // sizeof(struct Block_literal_1)
        // optional helper functions
        void (*copy_helper)(void *dst, void *src);     // IFF (1<<25)
        void (*dispose_helper)(void *src);             // IFF (1<<25)
        // required ABI.2010.3.16
        const char *signature;                         // IFF (1<<30)
    } *descriptor;
    // imported variables
};

typedef NS_OPTIONS(NSUInteger, PMKBlockDescriptionFlags) {
    PMKBlockDescriptionFlagsHasCopyDispose = (1 << 25),
    PMKBlockDescriptionFlagsHasCtor = (1 << 26), // helpers have C++ code
    PMKBlockDescriptionFlagsIsGlobal = (1 << 28),
    PMKBlockDescriptionFlagsHasStret = (1 << 29), // IFF BLOCK_HAS_SIGNATURE
    PMKBlockDescriptionFlagsHasSignature = (1 << 30)
};

// It appears 10.7 doesn't support quotes in method signatures. Remove them
// via @rabovik's method. See https://github.com/OliverLetterer/SLObjectiveCRuntimeAdditions/pull/2
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
NS_INLINE const char * pmk_removeQuotesFromMethodSignature(const char *str){
    char *result = malloc(strlen(str) + 1);
    BOOL skip = NO;
    char *to = result;
    char c;
    while ((c = *str++)) {
        if ('"' == c) {
            skip = !skip;
            continue;
        }
        if (skip) continue;
        *to++ = c;
    }
    *to = '\0';
    return result;
}
#endif

static NSMethodSignature *NSMethodSignatureForBlock(id block) {
    if (!block)
        return nil;

    struct PMKBlockLiteral *blockRef = (__bridge struct PMKBlockLiteral *)block;
    PMKBlockDescriptionFlags flags = (PMKBlockDescriptionFlags)blockRef->flags;

    if (flags & PMKBlockDescriptionFlagsHasSignature) {
        void *signatureLocation = blockRef->descriptor;
        signatureLocation += sizeof(unsigned long int);
        signatureLocation += sizeof(unsigned long int);

        if (flags & PMKBlockDescriptionFlagsHasCopyDispose) {
            signatureLocation += sizeof(void(*)(void *dst, void *src));
            signatureLocation += sizeof(void (*)(void *src));
        }

        const char *signature = (*(const char **)signatureLocation);
#if defined(__MAC_OS_X_VERSION_MIN_REQUIRED) && __MAC_OS_X_VERSION_MIN_REQUIRED < __MAC_10_8
        signature = pmk_removeQuotesFromMethodSignature(signature);
        NSMethodSignature *nsSignature = [NSMethodSignature signatureWithObjCTypes:signature];
        free((void *)signature);

        return nsSignature;
#endif
        return [NSMethodSignature signatureWithObjCTypes:signature];
    }
    return 0;
}
