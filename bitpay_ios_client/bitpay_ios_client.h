//
//  bitpay_client.h
//  bitpay_client
//
//  Created by Chris Kleeschulte on 4/7/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <openssl/sha.h>
#import <openssl/ripemd.h>
#import <openssl/ecdsa.h>
#import <openssl/ec.h>
#import <openssl/pem.h>


@interface BitPayIosClient : NSObject

+ (NSString *)generatePem;
+ (NSString *)getPrivateKey: (NSString *)key;
+ (NSString *)getPublicKeyFromPem:(NSString *)pem;
+ (NSString *)generateSinFromPem:(NSString *)pem;
+ (void)sign:(NSString *)message withPem:(NSString *)key;

@end
