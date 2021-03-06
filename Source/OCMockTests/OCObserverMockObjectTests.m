//---------------------------------------------------------------------------------------
//  $Id$
//  Copyright (c) 2009 by Mulle Kybernetik. See License file for details.
//---------------------------------------------------------------------------------------

#import <XCTest/XCTest.h>
#import <OCMock/OCMock.h>

static NSString *TestNotificationOne = @"TestNotificationOne";


@interface OCObserverMockObjectTest : XCTestCase
{
	NSNotificationCenter *center;
	id mock;
}

@end


@implementation OCObserverMockObjectTest

- (void)setUp
{
	center = [[NSNotificationCenter alloc] init];
	mock = [OCMockObject observerMock]; 
}

- (void)testAcceptsExpectedNotification
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
    [[mock expect] notificationWithName:TestNotificationOne object:[OCMArg any]];
    
    [center postNotificationName:TestNotificationOne object:self];
	
    [mock verify];
}

- (void)testAcceptsExpectedNotificationWithSpecifiedObjectAndUserInfo
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
	NSDictionary *info = [NSDictionary dictionaryWithObject:@"foo" forKey:@"key"];
    [[mock expect] notificationWithName:TestNotificationOne object:self userInfo:info];
    
    [center postNotificationName:TestNotificationOne object:self userInfo:info];
	
    [mock verify];
}

- (void)testAcceptsNotificationsInAnyOrder
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
	[[mock expect] notificationWithName:TestNotificationOne object:self];
    [[mock expect] notificationWithName:TestNotificationOne object:[OCMArg any]];
	
	[center postNotificationName:TestNotificationOne object:[NSString string]];
	[center postNotificationName:TestNotificationOne object:self];
}

- (void)testAcceptsNotificationsInCorrectOrderWhenOrderMatters
{
	[mock setExpectationOrderMatters:YES];

	[center addMockObserver:mock name:TestNotificationOne object:nil];
	[[mock expect] notificationWithName:TestNotificationOne object:self];
    [[mock expect] notificationWithName:TestNotificationOne object:[OCMArg any]];
	
	[center postNotificationName:TestNotificationOne object:self];
	[center postNotificationName:TestNotificationOne object:[NSString string]];
}

- (void)testRaisesExceptionWhenSequenceIsWrongAndOrderMatters
{
	[mock setExpectationOrderMatters:YES];
	
	[center addMockObserver:mock name:TestNotificationOne object:nil];
	[[mock expect] notificationWithName:TestNotificationOne object:self];
    [[mock expect] notificationWithName:TestNotificationOne object:[OCMArg any]];
	
	XCTAssertThrows([center postNotificationName:TestNotificationOne object:[NSString string]], @"Should have complained about sequence.");
}

- (void)testRaisesEvenThoughOverlappingExpectationsCouldHaveBeenSatisfied
{
	// this test demonstrates a shortcoming, not a feature
	[center addMockObserver:mock name:TestNotificationOne object:nil];
    [[mock expect] notificationWithName:TestNotificationOne object:[OCMArg any]];
	[[mock expect] notificationWithName:TestNotificationOne object:self];
	
	[center postNotificationName:TestNotificationOne object:self];
	XCTAssertThrows([center postNotificationName:TestNotificationOne object:[NSString string]]);
}

- (void)testRaisesExceptionWhenUnexpectedNotificationIsReceived
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
	
    XCTAssertThrows([center postNotificationName:TestNotificationOne object:self]);
}

- (void)testRaisesWhenNotificationWithWrongObjectIsReceived
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
    [[mock expect] notificationWithName:TestNotificationOne object:self];
	
	XCTAssertThrows([center postNotificationName:TestNotificationOne object:[NSString string]]);
}

- (void)testRaisesWhenNotificationWithWrongUserInfoIsReceived
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
    [[mock expect] notificationWithName:TestNotificationOne object:self 
							   userInfo:[NSDictionary dictionaryWithObject:@"foo" forKey:@"key"]];
	XCTAssertThrows([center postNotificationName:TestNotificationOne object:[NSString string] 
									   userInfo:[NSDictionary dictionaryWithObject:@"bar" forKey:@"key"]]);
}

- (void)testRaisesOnVerifyWhenExpectedNotificationIsNotSent
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
    [[mock expect] notificationWithName:TestNotificationOne object:[OCMArg any]];

	XCTAssertThrows([mock verify]);
}

- (void)testRaisesOnVerifyWhenNotAllNotificationsWereSent
{
	[center addMockObserver:mock name:TestNotificationOne object:nil];
    [[mock expect] notificationWithName:TestNotificationOne object:[OCMArg any]];
	[[mock expect] notificationWithName:TestNotificationOne object:self];

	[center postNotificationName:TestNotificationOne object:self];
	XCTAssertThrows([mock verify]);
}

- (void)testChecksNotificationNamesCorrectly
{
    NSString *notificationName = @"MyNotification";
    
    [center addMockObserver:mock name:notificationName object:nil];
    [[mock expect] notificationWithName:[notificationName mutableCopy] object:[OCMArg any]];
    
    [center postNotificationName:notificationName object:self];
    
    [mock verify];
}

@end
