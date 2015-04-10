# Using the BitPay iOS Client Library


## Prerequisites
You must have BitPay or test.bitpay merchant account to use this library. [Signing up for a merchant account](https://bitpay.com/start) is free.

## Quick Start
### Installation

BitPay's iOS SDK client library was developed as a static library project in Xcode 6.x. It is written in Objective-C and C and depends on OpenSSL C headers (included in the project). Therefore, you can compile the static library in your Xcode project and use the resulting .a static library.

### Basic Usage

The bitpay library allows creating the crypto-related constructs needed for constructing calls to the bitpay backend. This includes creating signing public and private keys, creating a sin, creating a signed messages. 
  
#### Pairing with Bitpay.com

Before pairing with BitPay.com, you'll need to log in to your BitPay account and navigate to /api-tokens. Generate a new pairing code and use it in the next step. In this example, it's assumed that we are working against the bitpay test server and have generated the pairing code "abcdefg".
