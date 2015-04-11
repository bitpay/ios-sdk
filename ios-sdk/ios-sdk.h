//
//  ios-sdk.h
//
//  Created by Chris Kleeschulte on 4/7/15.
//  Copyright (c) 2015 BitPay. All rights reserved.
//
#import <Foundation/Foundation.h>

@interface IosSDK : NSObject

+ (NSString *)generatePem;
+ (NSString *)getPublicKeyFromPem:(NSString *)pem;
+ (NSString *)getPrivateKeyFromPem:(NSString *)pem;
+ (NSString *)generateSinFromPem:(NSString *)pem;
+ (NSString *)sign:(NSString *)message withPem:(NSString *)key;

@end
