//
//  ViewController.m
//  ios-sdk-example
//
//  Created by Christopher Kleeschulte on 4/10/15.
//  Copyright (c) 2015 Christopher Kleeschulte. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()
@property (readonly) NSString *key;
@property (readonly) NSString *sin;
@property (readonly) NSString *token;
@property (readonly) NSString *invoice;
@property (nonatomic, strong) NSMutableData *responseData;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)generateKeys:(id)sender {
    _key = [IosSDK generatePem];
    _keyText.text = _key;
}

- (IBAction)generateSin:(id)sender {
    if(_key == nil) {
        _sinText.text = @"Please generate a key in the previous step first.";
    } else {
        _sin = [IosSDK generateSinFromPem:_key];
        _sinText.text = _sin;
    }
}

- (IBAction)getToken:(id)sender {

    if(_pairText.text == nil) {
        _tokenText.text = @"Please get a pairing code from test.bitpay.com";
    } else {
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:@"https://test.bitpay.com/tokens"]];
        
        NSString *postString = [NSString stringWithFormat:@"id=%@&label=Test&pairingCode=%@", _sin, _pairText.text];

        [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
        [request setHTTPMethod:@"POST"];
        
        [NSURLConnection connectionWithRequest:request delegate:self];
    }
    
}

- (IBAction)testCreatInvoice:(id)sender {
    if(_token == nil) {
        _invoiceText.text = @"Please geneate a token before creating an invoice here.";
    } else {
        //create token
    }

}

#pragma mark NSURLConnection Delegate Methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    _responseData = [[NSMutableData alloc] init];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    [_responseData appendData:data];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection
                  willCacheResponse:(NSCachedURLResponse*)cachedResponse {
    return nil;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    NSError *error = nil;
    
    id object = [NSJSONSerialization
                 JSONObjectWithData:_responseData
                 options:0
                 error:&error];
    
    if(error) {
        _tokenText.text = @"There was an error from the api";
    }
    
    if([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *results = object;
        _tokenText.text = [results description];
    }

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
}

@end
