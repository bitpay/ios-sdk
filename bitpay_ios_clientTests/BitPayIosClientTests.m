//
//  BitPayClientTests.m
//  bitpay_client
//
//  Created by Chris Kleeschulte on 4/7/15.
//  Copyright (c) 2015 BitPay. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "bitpay_ios_client.h"


@interface BitPayIosClientTests : XCTestCase
@end

@implementation BitPayIosClientTests

- (void)testGeneratePem {
    NSString *pem = [BitPayIosClient generatePem];
    NSString *desired = @"^-----BEGIN EC PRIVATE KEY-----\nMHQC";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:desired options:0 error:nil];
    NSRange needleRange = [regex rangeOfFirstMatchInString:pem options:NSMatchingAnchored
                                                     range:NSMakeRange(0, pem.length)];
    XCTAssertEqual(desired.length - 1, needleRange.length);
}

- (void)testgetPublicKeyFromPem {
    NSString *pem = @"-----BEGIN EC PRIVATE KEY-----\nMHQCAQEEIPl0A5dA38Lev36IZ00WkNPUz4UGyh8rvsUjScJd7pImoAcGBSuBBAAK\noUQDQgAEp33x9JAzaAqSAycnjT2cGqHgM/tVAW4ZEc10qLm3Zw711wwunXEURZ0v\nz81iG6FLKSNb7KCWGGipxqFH/Y5fTw==\n-----END EC PRIVATE KEY-----\n";
    NSString *pub = @"03A77DF1F49033680A920327278D3D9C1AA1E033FB55016E1911CD74A8B9B7670E";
    NSString *getPub = [BitPayIosClient getPublicKeyFromPem: pem];
    XCTAssertEqualObjects(pub, getPub);
}

- (void)testgenerateSinFromPem {
    NSString *pem = @"-----BEGIN EC PRIVATE KEY-----\nMHQCAQEEIKy0/RaYLTD3isDivZUuqPNNsDnbqAMRrneqlq839nbloAcGBSuBBAAK\noUQDQgAEECPSfkDyOnrniCcXdMHILAHKVM/V08Out87Rx66pvIK+oB90k5DPvr6l\n3tVKTyBA97qTU1tN5nl7RXe8Eseb7g==\n-----END EC PRIVATE KEY-----\n";
    NSString *sin = @"TfHJPYBhV9ccDSQ8MjymfBDgkt6eBvF8XLp";
    NSString *gotsin = [BitPayIosClient generateSinFromPem: pem];
    XCTAssertEqualObjects(sin, gotsin);
}

- (void)testSignMessageWithPem {
    NSString *pem = @"-----BEGIN EC PRIVATE KEY-----\nMHQCAQEEIKy0/RaYLTD3isDivZUuqPNNsDnbqAMRrneqlq839nbloAcGBSuBBAAK\noUQDQgAEECPSfkDyOnrniCcXdMHILAHKVM/V08Out87Rx66pvIK+oB90k5DPvr6l\n3tVKTyBA97qTU1tN5nl7RXe8Eseb7g==\n-----END EC PRIVATE KEY-----\n";
    NSString *message = @"https://test.bitpay.com/invoices{\"currency\":\"USD\",\"price\":20,\"token\":\"WNtT61hp29VBs98rFG3u6w\"}";
    NSString *signedMessage = [BitPayIosClient sign: message withPem: pem];

    NSError *error = NULL;
    NSRegularExpression *regex = [NSRegularExpression
                                  regularExpressionWithPattern:@"^[a-f0-9]+$"
                                  options:NSRegularExpressionCaseInsensitive
                                  error:&error];
    NSArray *matches = [regex matchesInString:signedMessage options: NSMatchingWithoutAnchoringBounds range:NSMakeRange(0, [signedMessage length])];
    
    XCTAssert([matches count] == 1);
    
    NSString *expectedStart = @"30";
    NSString *actualStart = [signedMessage substringWithRange:NSMakeRange(0, 2)];
    XCTAssertEqualObjects(expectedStart, actualStart);
    XCTAssertTrue([signedMessage length] > 139 && [signedMessage length] < 145);
}

- (void)testGetPrivateKey {
    NSString *key = [BitPayIosClient getPrivateKeyFromPem: @"-----BEGIN EC PRIVATE KEY-----\nMHQCAQEEIKy0/RaYLTD3isDivZUuqPNNsDnbqAMRrneqlq839nbloAcGBSuBBAAK\noUQDQgAEECPSfkDyOnrniCcXdMHILAHKVM/V08Out87Rx66pvIK+oB90k5DPvr6l\n3tVKTyBA97qTU1tN5nl7RXe8Eseb7g==\n-----END EC PRIVATE KEY-----\n"];
    XCTAssertEqualObjects(@"ACB4FD16982D30F78AC0E2BD952EA8F34DB039DBA80311AE77AA96AF37F676E5", key);
}


- (void)testSignPerformance {
    
    [self measureBlock:^{
        [self testGeneratePem];
        [self testgetPublicKeyFromPem];
        [self testgenerateSinFromPem];
        [self testSignMessageWithPem];
        [self testGetPrivateKey];
    }];
}

@end