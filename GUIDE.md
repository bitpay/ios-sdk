# Using the BitPay iOS Client Library


## Prerequisites
You must have BitPay or test.bitpay merchant account to use this library. [Signing up for a merchant account](https://bitpay.com/start) 
or [Signing up for a test merchant account](https://test.bitpay.com/start) 
is free.

You must have Xcode 6.3.1 or above to be able to take advantage of the Swift examples. Having Xcode 6.3.1 requires Mac OS X Yosemite 10.10.

You must also start the individual example's workspace in order to build and run the example. An example of this would be to open ./Example/ios-example-objective-c/ios-sdk-example-objective-c.xcworkspace and -not- ios-sdk.workspace if you want to run the Objective-C example. Then run pod install inside the example's directory in order to gather the cocoapod dependencies. 
## Quick Start
### Installation

BitPay's iOS SDK client library was developed as a static library project in Xcode 6.x. It is written in Objective-C and C and depends on OpenSSL C headers (included in the project). Therefore, you can compile the static library for your Xcode project in Xcode and use the resulting .a static library. See the example project for more details about using the static library.

### Basic Usage

The bitpay library allows creating the crypto-related constructs needed for creating the crypto needed for interacting with the BitPay API. This includes creating 256 bit Koblitz elliptic curve public and private keys, creating a sin or an identity and creating signed messages. 

#### Handling your client private key

Each client paired with the BitPay server requires a public and private key.  This provides the security mechanism for all client interaction with the BitPay server. The public key is used to derive the specific client identity that is displayed on your BitPay dashboard.  The public key is also used for securely signing all API requests from the client.  See the [BitPay API](https://bitpay.com/api) for more information.

The private key should be stored in the client environment such that it cannot be compromised.  If your private key is compromised you should revoke the compromised client identity from the BitPay server and re-pair your client, see the [API tokens](https://bitpay.com/api-tokens) for more information.

This SDK provides the capability of internally storing the private key on the client local file system.  If the local file system is 

```objective-c
// Create the private key using the SDK, store it as required, and inject the private key into the SDK.
NSString *pem = [BPKeyUtils generatePem];
```

### Pairing

Before pairing with BitPay.com, you'll need to log in to your BitPay account and navigate to /api-tokens. Generate a new pairing code and use it in the next step. In this example, it's assumed that we are working against the bitpay test server and have generated the pairing code "abcdefg". You will use the pairing code to get a token. Pairing codes are one time use and expire 24 hours after creation. Once you've used the pairing code to get your token, they can be used without expiration. You must send the token in every request thereafter.

#### Server initiated pairing

Pairing is accomplished by obtaining a pairing code from the BitPay server.  The pairing code is then injected into your client (typically during client initialization/configuration).  Your interactive authentication at https://bitpay.com/login or https://test.bitpay.com/login provides the authentication needed to create finalize the client-server pairing request.

```objective-c
// Obtain a pairingCode from your BitPay account administrator. 
NSString *pairingCode = "abcdefg";
NSString *pem = [BPKeyUtils generatePem];
NSString *sin = [BPKeyUtils generateSinFromPem: pem];
NSString *labelForToken = @"MyLabel";
        
NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:@"https://test.bitpay.com/tokens"]];
        
NSString *postString = [NSString stringWithFormat:@"id=%@&label=%@&pairingCode=%@", sin, labelForToken, pairingCode];

[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
[request setHTTPMethod:@"POST"];

//set this class as the delegate for the NSURLConnectionDelegate protocol
[NSURLConnection connectionWithRequest:request delegate:self];
```
### Examples
#### Create an invoice

```objective-c
//the token comes from the last step called "server initiated pairing"
NSString *token;

//this comes from the last step called "server initiated pairing"
NSString *pem;

NSString *pubKey = [BPKeyUtils getPublicKeyFromPem:pem];

//the currency and price are, of course, variable to your needs
NSString *postString = [NSString stringWithFormat:@"{\"currency\":\"USD\",\"price\":20,\"token\":\"%@\"}", token];

NSString *message = [NSString stringWithFormat: @"https://test.bitpay.com/invoices%@", postString];

NSString *signedMessage = [BPKeyUtils sign:message withPem:pem];

NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL: [NSURL URLWithString:@"https://test.bitpay.com/invoices"]]];

[request setHTTPBody:[postString dataUsingEncoding:NSUTF8StringEncoding]];
[request addValue:@"application/json" forHTTPHeaderField:@"content-type"];
[request addValue:@"2.0.0" forHTTPHeaderField:@"x-accept-version"];
[request addValue:pubKey forHTTPHeaderField:@"x-identity"];
[request addValue:signedMessage forHTTPHeaderField:@"x-signature"];
[request setHTTPMethod:@"POST"];

//set this class as the delegate for the NSURLConnectionDelegate protocol
[NSURLConnection connectionWithRequest:request delegate:self];
```
