//
//  clientTests.m
//  client
//
//  Created by chrisk on 4/16/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "client.h"

@interface ClientTests : XCTestCase

@end

@implementation ClientTests

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testInitWithName {
    
    NSString *expected = @"my name";
    BPBitPay *bp = [[BPBitPay alloc] initWithName:expected];
    NSString *actual = [bp name];
    XCTAssertEqual(actual, expected);
    
}

- (void)testPassingRequestClientAuthorization {
    
    NSError *error = nil;
    BPBitPay *bp = [[BPBitPay alloc] initWithName:@"some bp object"];
    NSString *pairingCode = [bp requestClientAuthorizationWithFacade: MERCHANT error: &error];
    NSLog(@"pairingCode is: %@", pairingCode);
    int actual = (int)[pairingCode length];
    int expected = 7;
    XCTAssertTrue(expected == actual, @"length was supposed to %d, but was %d, the returned value was: %@", expected, actual, pairingCode);
    XCTAssertNil(error, "Error is supposed to be nil, but was not");
    
}

- (void)testFailureRequestClientAuthorization {
    
    NSError *error = nil;
    BPBitPay *bp = [[BPBitPay alloc] initWithName:@"some other bp object"];
    //mock some server that returns an error here
    NSString *pairingCode = [bp requestClientAuthorizationWithFacade: MERCHANT error: &error];
    XCTAssertNil(pairingCode, "pairing code was supposed to be nil here, but was not");

    
}




@end
