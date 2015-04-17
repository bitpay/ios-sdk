//
//  client.m
//  client
//
//  Created by chrisk on 4/16/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import "client.h"


@implementation BPBitPay


- (id)initWithName: (NSString *)name {
    _name = name;
    return self;
}


- (NSString *) requestClientAuthorizationWithFacade: (facade)type error: (NSError **)error {
    
    NSString *facade;
    
    switch(type) {
        case 0:
            facade = @"pos";
            break;
        case 1:
            facade = @"merchant";
            break;
    }
    
    //url stuff
    NSString *urlString = [NSString stringWithFormat:@"%@/tokens", BITPAY_HOST];
    NSURL *url = [NSURL URLWithString:urlString];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: url];
    
    //generate a sin
    NSString *pem = [BPKeyUtils generatePem];
    NSString *sin = [BPKeyUtils generateSinFromPem:pem];
    
    //body data stuff
    NSString *bodyData = [NSString stringWithFormat:@"id=%@&label=ClientAuth&facade=%@", sin, facade];
    
    //build request
    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"accept"];
    [request setHTTPBody:[bodyData dataUsingEncoding:NSUTF8StringEncoding]];

    NSURLResponse *response;
    NSError *apiError = nil;
    //get result
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&apiError];
    
    if(apiError) {
        *error = [NSError errorWithDomain: [apiError domain] code: [apiError code] userInfo:nil];
        return nil;
    }
    
    int responseCode = (int)[((NSHTTPURLResponse *)response) statusCode];
    
    //would this be an error condition:: maybe the error is set here and we won't be getting here?
    if(responseCode < 200 || responseCode > 299) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code: NSURLErrorBadServerResponse userInfo:nil];
        return nil;
    }
    
    return [self parseResult: result];
}




- (NSString *) parseResult: (NSData *)data {
    
    
    NSError *error = nil;
    NSString *errorString = [NSString stringWithFormat: @"failed to parse: %@", [NSString stringWithUTF8String:[data bytes]]];
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&error];
    
    if(error) {
        return errorString;
    }
    
    NSArray *dataMember = [object valueForKeyPath:@"data"];
    if (dataMember != nil && [dataMember count] > 0) {
        
        NSDictionary *mainDictionary = dataMember[0];
        return [mainDictionary valueForKeyPath:@"pairingCode"];
        
    }
        
    return errorString;
}



@end
