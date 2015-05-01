//
//  clientTestsFunctional.m
//  client
//
//  Created by Chris Kleeschulte on 4/20/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "client.h"

#import "constants.h" //<-------- please fill in your own pairing code

@interface clientTestsFunctional : XCTestCase
@property BPBitPay *bp;
@property NSString *host;
@end

@implementation clientTestsFunctional

//Feature: pairing with bitpay
//In order to access bitpay
//It is required that the library
//Is able to pair successfully
//
//Scenario: the client has a correct pairing code
//Given the user pairs with BitPay with a valid pairing code
//Then the user is paired with BitPay
//
//Scenario: the client initiates pairing
//Given the user requests a client-side pairing
//Then they will receive a claim code
//
//Scenario Outline: the client has a bad pairing code
//Given the user fails to pair with a semantically <valid> code <code>
//Then they will receive a <error> matching <message>
//Examples:
//| valid   | code       | error                 | message                       |
//| invalid | "a1b2c3d4" | BitPay::ArgumentError | "pairing code is not legal"   |
//
//Scenario: the client has a bad port configuration to a closed port
//When the fails to pair with BitPay because of an incorrect port
//Then they will receive a BitPay::ConnectionError matching "Connection refused"

- (void)setUp {
    [super setUp];
    NSString *pem = [BPKeyUtils generatePem];
    self.bp = [[BPBitPay alloc] initWithName:@"some bp object" pem: pem];
    self.bp.sin = [BPKeyUtils generateSinFromPem:self.bp.pem];
    self.bp.host = TEST_BITPAY_HOST;
}

- (void) testHasCorrectPairingCode {
    NSError *error = nil;
    NSString *token = [self.bp authorizeClient:PAIRING_CODE error: &error];
    NSLog(@"token is: %@", token);
    XCTAssertNil(error, "Error is supposed to be nil, but was not");
}

- (void) testInitiatesPairingTest {
    [NSTimer scheduledTimerWithTimeInterval:2 target:self selector:@selector(InitiatesPairingTest) userInfo:nil repeats:NO];
}

- (void) InitiatesPairingTest {
    
    NSError *error = nil;
    NSString *pairingCode = [self.bp requestClientAuthorizationWithFacade: POS error: &error];
    NSLog(@"pairingCode is: %@", pairingCode);
    int actual = (int)[pairingCode length];
    int expected = 7;
    XCTAssertTrue(expected == actual, @"length was supposed to %d, but was %d, the returned value was: %@", expected, actual, pairingCode);
    XCTAssertNil(error, "Error is supposed to be nil, but was not");
    NSLog(@"%ld", [error code]);
}

- (void) testThatPairingCodeIsBadFormat {

    NSError *error = nil;
    [self.bp authorizeClient: @"$%ABC12" error: &error];
    XCTAssertNotNil(error, "Error was supposed be NOT nil, but was nil anyway.");
    XCTAssertTrue([error code] == NSFormattingError);
    
    [self.bp authorizeClient: @"123456" error: &error];
    XCTAssertNotNil(error, "Error was supposed be NOT nil, but was nil anyway.");
    XCTAssertTrue([error code] == NSFormattingError);

}

- (void) testHasBadPairingCode {
    
    NSError *error = nil;
    NSString *token = [self.bp authorizeClient:@"a1b2c3d4" error: &error];
    XCTAssertNotNil(error, @"Error is supposed to be nil, but was nil anyway");
    XCTAssertEqual([error code], 2048); //this is a non-200 level response
    XCTAssertNil(token);
    
}

@end