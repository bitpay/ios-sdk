//
//  client.h
//  client
//
//  Created by Chris Kleeschulte on 4/16/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "constants.h"
#import "keyutils/keyutils.h"

typedef enum {
    POS, MERCHANT
} facade;

@interface BPBitPay : NSObject

@property NSString *name;

- (id) initWithName: (NSString *)name;
- (NSString *) requestClientAuthorizationWithFacade: (facade)type error: (NSError * __autoreleasing *) error;

@end
