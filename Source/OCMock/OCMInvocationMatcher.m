//---------------------------------------------------------------------------------------
//  Copyright (c) 2014 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <objc/runtime.h>
#import <OCMock/OCMArg.h>
#import <OCMock/OCMConstraint.h>
#import "OCMPassByRefSetter.h"
#import "NSInvocation+OCMAdditions.h"
#import "OCMInvocationMatcher.h"


@interface NSObject(HCMatcherDummy)
- (BOOL)matches:(id)item;
@end


@implementation OCMInvocationMatcher

- (void)setInvocation:(NSInvocation *)anInvocation;
{
    [recordedInvocation release];
    [anInvocation retainArguments];
    recordedInvocation = [anInvocation retain];
}

- (void)setRecordedAsClassMethod:(BOOL)flag
{
    recordedAsClassMethod = flag;
}

- (BOOL)recordedAsClassMethod
{
    return recordedAsClassMethod;
}

- (void)setIngoreNonObjectArgs:(BOOL)flag
{
    ignoreNonObjectArgs = flag;
}

- (NSString *)description
{
    return [recordedInvocation invocationDescription];
}

- (BOOL)matchesSelector:(SEL)sel
{
    return (sel == [recordedInvocation selector]);
}

- (BOOL)matchesInvocation:(NSInvocation *)anInvocation
{
    id target = [anInvocation target];
    BOOL isClassMethodInvocation = (target != nil) && (target == [target class]);
    if(isClassMethodInvocation != recordedAsClassMethod)
        return NO;

    if([anInvocation selector] != [recordedInvocation selector])
        return NO;

    NSMethodSignature *signature = [recordedInvocation methodSignature];
    int n = (int)[signature numberOfArguments];
    for(int i = 2; i < n; i++)
    {
        if(ignoreNonObjectArgs && strcmp([signature getArgumentTypeAtIndex:i], @encode(id)))
        {
            continue;
        }

        id recordedArg = [recordedInvocation getArgumentAtIndexAsObject:i];
        id passedArg = [anInvocation getArgumentAtIndexAsObject:i];

        if([recordedArg isProxy])
        {
            if(![recordedArg isEqual:passedArg])
                return NO;
            continue;
        }

        if([recordedArg isKindOfClass:[NSValue class]])
            recordedArg = [OCMArg resolveSpecialValues:recordedArg];

        if([recordedArg isKindOfClass:[OCMConstraint class]])
        {
            if([recordedArg evaluate:passedArg] == NO)
                return NO;
        }
        else if([recordedArg isKindOfClass:[OCMPassByRefSetter class]])
        {
            id valueToSet = [(OCMPassByRefSetter *)recordedArg value];
            // side effect but easier to do here than in handleInvocation
            if(![valueToSet isKindOfClass:[NSValue class]])
                *(id *)[passedArg pointerValue] = valueToSet;
            else
                [(NSValue *)valueToSet getValue:[passedArg pointerValue]];
        }
        else if([recordedArg conformsToProtocol:objc_getProtocol("HCMatcher")])
        {
            if([recordedArg matches:passedArg] == NO)
                return NO;
        }
        else
        {
            if(([recordedArg class] == [NSNumber class]) &&
                    ([(NSNumber*)recordedArg compare:(NSNumber*)passedArg] != NSOrderedSame))
                return NO;
            if(([recordedArg isEqual:passedArg] == NO) &&
                    !((recordedArg == nil) && (passedArg == nil)))
                return NO;
        }
    }
    return YES;
}
@end
