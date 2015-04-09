//
//  BitPayClientTests.m
//  bitpay_client
//
//  Created by chrisk on 4/7/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "bitpay_ios_client.h"


@interface BitPayIosClientTests : XCTestCase
@end

@implementation BitPayIosClientTests

- (void)setUp {
    [super setUp];
    
}

- (void)tearDown {
    [super tearDown];
}

- (void)testCreateKeyWithPem {
    XCTAssert(YES, @"Pass");
}

- (void)testGeneratePem {
    NSString *pem = [BitPayIosClient generatePem];
    NSString *desired = @"^-----BEGIN EC PRIVATE KEY-----\nMHQC";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:desired options:0 error:nil];
    NSRange needleRange = [regex rangeOfFirstMatchInString:pem options:NSMatchingAnchored range:NSMakeRange(0, pem.length)];
    XCTAssertEqual(desired.length - 1, needleRange.length);
}

- (void)testCreatePem {
    XCTAssert(YES, @"Pass");
}

- (void)testgetPrivateKey {
    
    //[KeyUtils getPrivateKey];
}

- (void)testgetPublicKey {
//    struct key privKey;
//    memcpy(privKey.hexKey, (uint8_t*)[@"ACB4FD16982D30F78AC0E2BD952EA8F34DB039DBA80311AE77AA96AF37F676E5" UTF8String], 32);
//    NSString *pubKey = [BitPayIosClient getPublicKey: privKey];
//    XCTAssertEqual(pubKey, @"021023d27e40f23a7ae788271774c1c82c01ca54cfd5d3c3aeb7ced1c7aea9bc82");
}

- (void)testgetPrivateKeyFromPem {
    
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

- (void)testSign {
    XCTAssert(YES, @"Pass");
}

- (void)testencodeBase58 {
    XCTAssert(YES, @"Pass");
}

- (void)testPerformanceExample {
    
    [self measureBlock:^{
        
    }];
}

@end