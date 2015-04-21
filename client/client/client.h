//
//  client.h
//  client
//
//  Created by Chris Kleeschulte on 4/16/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "constants.h"
#import "keyutils.h"
#import "NSString+urlEncode.h"

typedef enum {
    POS, MERCHANT
} facade;

typedef enum {
    PAIRING, TOKEN
} codeType;

@interface BPBitPay : NSObject
@property NSString *name;
@property NSString *pem;
@property NSString *sin;
@property (nonatomic, retain, getter = getHost) NSString *host;
- (id) initWithName: (NSString *)name pem: (NSString *)pem;
- (NSString *) requestClientAuthorizationWithFacade: (facade)type error: (NSError **)error;
- (NSString *) authorizeClient: (NSString *)pairingCode error: (NSError **)error;
@end
