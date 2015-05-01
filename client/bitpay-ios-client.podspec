Pod::Spec.new do |s|
s.name             = "bitpay-ios-client"
s.version          = "2.1.1"
s.summary          = "Powerful, flexible, lightweight interface to the BitPay Bitcoin Payment Gateway API for iOS."
s.description      = <<-DESC
## [Getting Started &raquo;](http://dev.bitpay.com/guides/ios.html)

## API Documentation

API Documentation is available on the [BitPay site](https://bitpay.com/api).

## Running the Tests

Before running the behavior tests, you will need a test.bitpay.com account and you will need to set the local constants.

To run unit tests:
> Open Xcode -> key commands are: Command + u

## Found a bug?
Let us know! Send a pull request or a patch. Questions? Ask! We're here to help. We will respond to all filed issues.

**BitPay Support:**

* [GitHub Issues](https://github.com/kleetus/bitpay-ios-client/issues)
* Open an issue if you are having issues with this library
* [Support](https://support.bitpay.com)
* BitPay merchant support documentation

Sometimes a download can become corrupted for various reasons.  However, you can verify that the release package you downloaded is correct by checking the md5 checksum "fingerprint" of your download against the md5 checksum value shown on the Releases page.  Even the smallest change in the downloaded release package will cause a different value to be shown!
* If you are using Windows, you can download a checksum verifier tool and instructions directly from Microsoft here: http://www.microsoft.com/en-us/download/details.aspx?id=11533
* If you are using Linux or OS X, you already have the software installed on your system.
* On Linux systems use the md5sum program.  For example:
* md5sum filename
* On OS X use the md5 program.  For example:
* md5 filename
DESC
s.homepage         = "https://github.com/kleetus/bitpay-ios-client"
s.license      = 'MIT'
s.author           = { "Chris Kleeschulte" => "chrisk@bitpay.com" }
s.source           = { :git => "https://github.com/kleetus/bitpay-ios-client.git", :tag => "v#{s.version}" }
s.platform     = :ios, '7.0'
s.requires_arc = true
s.public_header_files = "client/*.h"
s.source_files = 'client/*.{h,m}'
s.dependency 'bitpay-ios-sdk', '~> 2.0.1'
end
