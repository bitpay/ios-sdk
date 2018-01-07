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
@property (readonly) NSString *signedMessage;
@property (readonly) NSString *invoice;
@property (nonatomic, strong) NSMutableData *responseData;
@end

@implementation ViewController

NSString *genericErrorMessage = @"There was an error from the api";
NSString *bitpayUrl = @"https://test.bitpay.com";

- (void)viewDidLoad {
    [super viewDidLoad];
    _pairText.delegate = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (IBAction)generateKeys:(id)sender {
    _key = [BPKeyUtils generatePem];
    _keyText.text = _key;
    NSLog(@"pem key: %@", _key);
}

- (IBAction)generateSin:(id)sender {
    if(_key == nil) {
        _sinText.text = @"Please generate a key in the previous step first.";
    } else {
        _sin = [BPKeyUtils generateSinFromPem:_key];
        _sinText.text = _sin;
        NSLog(@"sin: %@", _sin);
    }
}

- (IBAction)getToken:(id)sender {

    if(_pairText.text == nil) {
        _tokenText.text = @"Please get a pairing code from test.bitpay.com";
    } else {
        
        NSLog(@"pairingCode: %@", _pairText.text);
        
        BPBitPay *bp = [[BPBitPay alloc] initWithName:@"BitPay" pem: _key];
        bp.host = bitpayUrl;
        
        NSError *error = nil;
        NSString *token = [bp authorizeClient:_pairText.text error: &error];
        
        if(error) {
            NSLog(@"%@", @"there was an error");
            _tokenText.text = @"there was an error";
            return;
        }
        
        _token = token;
        _tokenText.text = token;
        
    }
    
}

- (IBAction)testCreatInvoice:(id)sender {
    
    if(_token == nil || _key == nil || _sin == nil) {
        _invoiceText.text = @"Please geneate a key/sin/token before creating an invoice here.";
        return;
    }
    
    NSString *pubKey = [BPKeyUtils getPublicKeyFromPem:_key];
    NSLog(@"public key: %@", pubKey);
    NSLog(@"private key: %@", [BPKeyUtils getPrivateKeyFromPem:_key]);
    
    NSString *postString = [NSString stringWithFormat:@"{\"currency\":\"USD\",\"price\":20,\"token\":\"%@\"}", _token];
    
    NSString *message = [NSString stringWithFormat: @"%@/invoices%@", bitpayUrl, postString];
    
    _signedMessage = [BPKeyUtils sign:message withPem:_key];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:[NSString stringWithFormat:@"%@/invoices", bitpayUrl]]];
    
    [request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
    [request addValue:@"2.0.0" forHTTPHeaderField:@"x-accept-version"];
    [request addValue:@"application/json" forHTTPHeaderField:@"content-type"];
    [request addValue:pubKey forHTTPHeaderField:@"x-identity"];
    [request addValue:_signedMessage forHTTPHeaderField:@"x-signature"];
    [request setHTTPMethod:@"POST"];
    
    [NSURLConnection connectionWithRequest:request delegate:self];

}

#pragma mark UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
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
        _tokenText.text = genericErrorMessage;
    }
    
    if([object isKindOfClass:[NSDictionary class]]) {
        
        NSDictionary *results = object;
        NSString *error = [results objectForKey:@"error"];
        
        if(error) {
            NSLog(@"error: %@", error);
            _invoiceText.text = error;
            return;
        }
        
        NSDictionary *data = [results valueForKeyPath: @"data"];
        
        if(data) {
            id tokenId = [data valueForKeyPath: @"token"];
            if([tokenId isKindOfClass:[NSArray class]]) {
                NSArray *tokenArray = tokenId;
                _token = tokenArray[0];
                _tokenText.text = _token;
            }
            _invoiceText.text = [results description];
        } else {
            _invoiceText.text = [results description];
            NSLog(@"%@", [results description]);
            return;
        }
    }

}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"there was an error.");
}



@end
