//
//  clientTests.m
//  client
//
//  Created by Chris Kleeschulte on 4/16/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "client.h"
#import "Nocilla.h"

@interface ClientTests : XCTestCase
@property BPBitPay *bp;
@property NSString *host;
@end

@implementation ClientTests

+ (void)setUp {
    [super setUp];
    [[LSNocilla sharedInstance] start];
}

+ (void)tearDown {
    [[LSNocilla sharedInstance] stop];
    [super tearDown];
}

- (void)setUp {
    [super setUp];
    NSString *pem = [BPKeyUtils generatePem];
    self.bp = [[BPBitPay alloc] initWithName:@"some bp object" pem: pem];
    self.bp.sin = [BPKeyUtils generateSinFromPem:self.bp.pem];
    self.bp.host = TEST_BITPAY_HOST;
}

- (void)tearDown {
    [[LSNocilla sharedInstance] clearStubs];
    [super tearDown];
}

- (void)testInitWithName {
    
    NSString *expected = @"my name";
    BPBitPay *bp = [[BPBitPay alloc] initWithName:expected pem:[BPKeyUtils generatePem]];
    XCTAssertNotNil(self.bp);
    NSString *actual = [bp name];
    XCTAssertEqual(actual, expected);
    
}

- (void)testPassingRequestClientAuthorization {
    
    NSError *error = nil;
    
    NSString *jsonResults = @"{\"data\":[{\"pairingCode\":\"ABC1234\"}]}";
    NSData *results = [jsonResults dataUsingEncoding:NSUTF8StringEncoding];
    NSString *body = [NSString stringWithFormat: @"id=%@&label=ClientAuth&facade=merchant", self.bp.sin];
    
    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andReturn(201)
    .withBody(results);
    
    
    NSString *pairingCode = [self.bp requestClientAuthorizationWithFacade: MERCHANT error: &error];
    NSLog(@"pairingCode is: %@", pairingCode);
    int actual = (int)[pairingCode length];
    int expected = 7;
    XCTAssertTrue(expected == actual, @"length was supposed to %d, but was %d, the returned value was: %@", expected, actual, pairingCode);
    XCTAssertNil(error, "Error is supposed to be nil, but was not");
    
}

- (void)testHTTPCodeFailureRequestClientAuthorization {
    
    NSError *error = nil;
    
    NSString *body = [NSString stringWithFormat: @"id=%@&label=ClientAuth&facade=merchant", self.bp.sin];

    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andReturn(500);
    
    [self.bp requestClientAuthorizationWithFacade:MERCHANT error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual([error code], NSURLErrorBadServerResponse);
}


- (void)testBadResponseFailureRequestClientAuthorization {
    
    NSError *error = nil;
    
    NSString *jsonResults = @"some bad string";
    NSData *results = [jsonResults dataUsingEncoding:NSUTF8StringEncoding];
    NSString *body = [NSString stringWithFormat: @"id=%@&label=ClientAuth&facade=merchant", self.bp.sin];
    
    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andReturn(201)
    .withBody(results);
    
    [self.bp requestClientAuthorizationWithFacade:MERCHANT error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual([error code], 3840);
}

- (void) testNetworkNotAvailableFailureRequestClientAuthorization {
    
    NSError *error = nil;
    NSString *body = [NSString stringWithFormat: @"id=%@&label=ClientAuth&facade=merchant", self.bp.sin];

    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andFailWithError([NSError errorWithDomain:@"foo" code:123 userInfo:nil]);

    [self.bp requestClientAuthorizationWithFacade:MERCHANT error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual([error code], 123);
    
    
}


- (void) testPassingAuthorizeClient {
    
    NSError *error = nil;
    
    NSString *jsonResults = @"{\"data\":[{\"token\":\"ABC1234567890\"}]}";
    NSData *results = [jsonResults dataUsingEncoding:NSUTF8StringEncoding];
    NSString *body = [NSString stringWithFormat: @"id=%@&label=AuthClient&pairingCode=ABC1234", self.bp.sin];
    
    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andReturn(201)
    .withBody(results);
    
    
    NSString *token = [self.bp authorizeClient:@"ABC1234" error: &error];
    NSLog(@"token is: %@", token);
    XCTAssertNil(error, "Error is supposed to be nil, but was not");

}



- (void) testFailingHTTPCodeAuthorizeClient {
    
    NSError *error = nil;
    
    NSString *body = [NSString stringWithFormat: @"id=%@&label=AuthClient&pairingCode=ABC1234", self.bp.sin];
    
    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andReturn(500);
    
    [self.bp authorizeClient:@"ABC1234" error: &error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual([error code], NSURLErrorBadServerResponse);

    
    
}

- (void) testBadResponseFailureAuthorizeClient {
    
    NSError *error = nil;
    
    NSString *jsonResults = @"some bad string";
    NSData *results = [jsonResults dataUsingEncoding:NSUTF8StringEncoding];
    NSString *body = [NSString stringWithFormat: @"id=%@&label=AuthClient&pairingCode=ABC1234", self.bp.sin];
    
    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andReturn(201)
    .withBody(results);
    
    [self.bp authorizeClient:@"ABC1234" error:&error];
    
    XCTAssertNotNil(error);
    XCTAssertEqual([error code], 3840);
    
}

- (void) testNetworkNotAvailableAuthorizeClient {

    NSError *error = nil;
    NSString *body = [NSString stringWithFormat: @"id=%@&label=AuthClient&pairingCode=ABC1234", self.bp.sin];
    
    stubRequest(@"POST", [NSString stringWithFormat: @"%@/tokens", self.bp.host])
    .withHeader(@"accept", @"application/json")
    .withBody([body dataUsingEncoding:NSUTF8StringEncoding])
    .andFailWithError([NSError errorWithDomain:@"foo" code:123 userInfo:nil]);
    
    [self.bp authorizeClient:@"ABC1234" error:&error];
    XCTAssertNotNil(error);
    XCTAssertEqual([error code], 123);
    
}

@end
