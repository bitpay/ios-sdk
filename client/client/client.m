//
//  client.m
//  client
//
//  Created by Chris Kleeschulte on 4/16/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import "client.h"

//TODO make the synchronuous calls take a completion block and making them asynchronuous (or call a delegate method)
@implementation BPBitPay


- (id)initWithName: (NSString *)name pem: (NSString *)pem {
    
    self = [super init];
    if(!self) return nil;
    _name = name;
    _pem = pem;
    _sin = [BPKeyUtils generateSinFromPem:_pem];
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
    
    NSString *bodyData = [NSString stringWithFormat:@"id=%@&label=ClientAuth&facade=%@", _sin, facade];

    NSError *apiError = nil;
    
    NSString *result = [self getCode: PAIRING withBodyData:bodyData error:&apiError];
    
    if(apiError) {
        *error = [NSError errorWithDomain: [apiError domain] code: [apiError code] userInfo:nil];
        return nil;
    }
    return result;
}


- (NSString *)authorizeClient:(NSString *)pairingCode error: (NSError **)error{
    
    
    if(![self isValidPairingCode: pairingCode]) {
        *error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFormattingError userInfo:nil];
        return nil;
    }
    
    NSError *apiError = nil;
    
    NSString *bodyData = [NSString stringWithFormat:@"id=%@&label=AuthClient&pairingCode=%@", _sin, pairingCode];
    
    NSString *result = [self getCode: TOKEN withBodyData:bodyData error:&apiError];

    if(apiError) {
        *error = [NSError errorWithDomain: [apiError domain] code: [apiError code] userInfo:nil];
        return nil;
    }
    
    return result;
}


#pragma mark privates
- (BOOL) isValidPairingCode: (NSString *)pairingCode {

    if([pairingCode length] != 7) {
        return NO;
    }
    
    NSCharacterSet *alphaSet = [NSCharacterSet alphanumericCharacterSet];
    return [[pairingCode stringByTrimmingCharactersInSet:alphaSet] isEqualToString:@""];
    
}

- (NSString *)getCode: (codeType)type withBodyData: (NSString *)bodyData error: (NSError **)error {
    
    NSString *code;
    
    switch(type) {
        case 0:
            code = @"pairingCode";
            break;
        case 1:
            code = @"token";
            break;
    }
    
    NSMutableURLRequest *request = [self buildRequestWithString:bodyData];
    
    NSError *requestError = nil;
    NSData *result = [self makeSynchronousRequest:request error:&requestError];
    
    if(requestError) {
        *error = [NSError errorWithDomain: [requestError domain] code: [requestError code] userInfo:nil];
        return nil;
    }
    
    NSError *parseError = nil;
    NSString *parsedResults = [self parseResult: result for: (NSString *)code error: &parseError];
    
    if(parseError) {
        *error = [NSError errorWithDomain: [parseError domain] code: [parseError code] userInfo:nil];
        return nil;
    }
    
    return parsedResults;

}

- (NSMutableURLRequest *) buildRequestWithString: (NSString *)string {

    NSString *urlString = [NSString stringWithFormat:@"%@/tokens", [self getHost]];
    NSURL *url = [NSURL URLWithString:urlString];
    return [self populateRequest:[[NSMutableURLRequest alloc] initWithURL: url] withString:string];
    
}

- (NSMutableURLRequest *) populateRequest: (NSMutableURLRequest *)request withString: (NSString *)string {

    [request setHTTPMethod:@"POST"];
    [request addValue:@"application/json" forHTTPHeaderField:@"accept"];
    [request setHTTPBody:[string dataUsingEncoding:NSUTF8StringEncoding]];
    return request;

}

- (NSData *) makeSynchronousRequest: (NSMutableURLRequest *) request error: (NSError **)error {
    
    NSURLResponse *response;
    NSError *apiError = nil;
    
    NSData *result = [NSURLConnection sendSynchronousRequest:request returningResponse:&response error:&apiError];

    if(apiError) {
        *error = [NSError errorWithDomain: [apiError domain] code: [apiError code] userInfo:nil];
        return nil;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
    int responseCode = (int)[httpResponse statusCode];
    
    if(responseCode < 200 || responseCode > 299) {
        *error = [NSError errorWithDomain: NSURLErrorDomain code: NSURLErrorBadServerResponse userInfo:nil];
        return nil;
    }
    
    return result;
}

- (NSString *) parseResult: (NSData *)data for: (NSString *)code error: (NSError **)error {
    
    NSError *parseError = nil;
    NSString *result = nil;
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:data
                 options:0
                 error:&parseError];
    
    if(parseError) {
        *error = [NSError errorWithDomain: [parseError domain] code: [parseError code] userInfo:nil];
        return nil;
    }
    
    if([object isKindOfClass:[NSDictionary class]]) {
        
        NSArray *dataMember = [object valueForKeyPath:@"data"];
        if (dataMember != nil && [dataMember count] > 0) {
            
            NSDictionary *mainDictionary = dataMember[0];
            result = [mainDictionary valueForKeyPath:code];
        }
    }
    
    if(!result) {
        
        //this means we got some kind of JSON data, just not what we were expecting
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: NSLocalizedString(@"Could not find information", nil),
                                   NSLocalizedFailureReasonErrorKey: NSLocalizedString([object description], nil),
                                   };

        *error = [NSError errorWithDomain: NSCocoaErrorDomain code: 0 userInfo:userInfo];
        
    }
    
    return result;
    
}

- (NSString *) getHost {
    
    return _host == nil ? BITPAY_HOST : _host;
    
}

@end
