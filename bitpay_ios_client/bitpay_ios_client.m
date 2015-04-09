//
//  bitpay_client.m
//  bitpay_client
//
//  Created by chrisk on 4/7/15.
//  Copyright (c) 2015 bitpay. All rights reserved.
//

#import "bitpay_ios_client.h"

@implementation BitPayIosClient

static const UInt8 publicKeyIdentifier[] = "com.bitpay.ios.publickey\0";
static const UInt8 privateKeyIdentifier[] = "com.bitpay.ios.privatekey\0";

+ (NSString *)generatePem {
    EC_KEY *eckey;
    BIO *out = NULL;
    eckey = [self createNewKey];
    out = BIO_new(BIO_s_mem());
    int i = PEM_write_bio_ECPrivateKey(out, eckey, NULL, NULL, 0, NULL, NULL);
    BUF_MEM *buf;
    BIO_get_mem_ptr(out, &buf);
    
    NSString *pem = [NSString stringWithCString:buf->data encoding:NSASCIIStringEncoding];
    EC_KEY_free(eckey);
    BIO_free(out);
    
    return pem;
};



+ (NSString *)getPublicKeyFromPem:(NSString *)pem {
    EC_KEY *eckey = NULL;
    EC_POINT *pub_key = NULL;
    const EC_GROUP *group = NULL;
    BIGNUM start;
    const BIGNUM *res;
    BN_CTX *ctx;
    
    BN_init(&start);
    ctx = BN_CTX_new(); // ctx is an optional buffer to save time from allocating and deallocating memory whenever required
    
    res = &start;
    
    /////////////////////////////////////////////////////////////////////////////////////////////////////////
    //get the private key from the pem
    
    const char *ptr = [pem cStringUsingEncoding:NSASCIIStringEncoding];
    BIO *in = BIO_new(BIO_s_mem());
    BIO_puts(in, ptr);
    EC_KEY *key = PEM_read_bio_ECPrivateKey(in, NULL, NULL, NULL);
    res = EC_KEY_get0_private_key(key);
    
    //end getting the private key from the pem
    /////////////////////////////////////////////////////////////////////////////////////////////////////////
    
    //build up the group
    eckey = EC_KEY_new_by_curve_name(NID_secp256k1);
    group = EC_KEY_get0_group(eckey);
    pub_key = EC_POINT_new(group);
    
    //set the private key in eckey
    EC_KEY_set_private_key(eckey, res);
    
    
    //error checking
    /* pub_key is a new uninitialized `EC_POINT*`.  priv_key res is a `BIGNUM*`. */
    if (!EC_POINT_mul(group, pub_key, res, NULL, NULL, ctx))
        printf("Error at EC_POINT_mul.\n");
    //end error checking
    
    
    int resultSetPubKey = EC_KEY_set_public_key(eckey, pub_key); //1 on success
    
    //cc should be the pub key in hex
    char *cc = EC_POINT_point2hex(group, pub_key, 4, ctx);
    
    NSString *pubKeyString = [NSString stringWithCString:cc encoding:NSASCIIStringEncoding];
    pubKeyString = [self compressKey: pubKeyString];

    BN_CTX_free(ctx);
    free(cc);

    return pubKeyString;
    
}

+ (NSString *)generateSinFromPem:(NSString *)pem {
    NSString *pubKeyString;
    pubKeyString = [self getPublicKeyFromPem: pem];
    
    NSString *sha256Hex = [self hexOfsha256: pubKeyString];
    NSString *ripe160Hex = [self hexOfRipe160: sha256Hex];

    NSString *prefix = @"0F02";
    NSString *versionType = [prefix stringByAppendingString:ripe160Hex];
    
    NSString *shaOnce = [self hexOfsha256:versionType];
    NSString *shaTwice = [self hexOfsha256:shaOnce];
    NSString *checkSum = [shaTwice substringToIndex:8];
    NSString *versionCheck = [versionType stringByAppendingString:checkSum];

    
    
    //base58 the versionCheck
    int i = 0;
    
    
    //    key = OpenSSL::PKey::EC.new pem
    //    key.public_key.group.point_conversion_form = :compressed
    //    public_key = key.public_key.to_bn.to_s(2)
    //    step_one = Digest::SHA256.hexdigest(public_key)
    //    step_two = Digest::RMD160.hexdigest([step_one].pack("H*"))
    //    step_three = "0F02" + step_two
    //    step_four_a = Digest::SHA256.hexdigest([step_three].pack("H*"))
    //    step_four = Digest::SHA256.hexdigest([step_four_a].pack("H*"))
    //    step_five = step_four[0..7]
    //    step_six = step_three + step_five
    //    encode_base58(step_six)
    return @"its the end of the world as we know it";
};

+ (void)sign:(NSString *)message withPem: (NSString *)pem {
    //    group = ECDSA::Group::Secp256k1
    //    digest = Digest::SHA256.digest(message)
    //    signature = nil
    //    while signature.nil?
    //        temp_key = 1 + SecureRandom.random_number(group.order - 1)
    //        signature = ECDSA.sign(group, privkey.to_i(16), digest, temp_key)
    //        return ECDSA::Format::SignatureDerString.encode(signature).unpack("H*").first
    //        end
    
};

+ (NSString *) compressKey: (NSString *)key {
    NSString *xval, *yval;
    unsigned int yint;
    NSRange xRange = NSMakeRange(2, 64);
    xval = [key substringWithRange:xRange];
    yval = [key substringFromIndex:125];
    NSScanner *scanner = [NSScanner scannerWithString:yval];
    [scanner scanHexInt:&yint];
    NSString *resultString;
    if ((yint % 2) == 0) {
        resultString = @"02";
    } else {
        resultString = @"03";
    }
    return [resultString stringByAppendingString:xval];
}

+ (EC_KEY *)createNewKey {
    
    EC_KEY *eckey;
    eckey = EC_KEY_new();
    int asn1_flag = OPENSSL_EC_NAMED_CURVE;
    int form = POINT_CONVERSION_UNCOMPRESSED;
    EC_GROUP *group = EC_GROUP_new_by_curve_name(NID_secp256k1);
    EC_GROUP_set_asn1_flag(group, asn1_flag);
    EC_GROUP_set_point_conversion_form(group, form);
    EC_KEY_set_group(eckey, group);
    int resultFromKeyGen = EC_KEY_generate_key(eckey);
    if (resultFromKeyGen != 1){
        raise(1);
    }
    return eckey;
}

+ (void)encodeBase58:(NSString *) data {
    //    code_string = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    //    base = 58
    //    x = data.hex
    //    output_string = ""
    //
    //    while x > 0 do
    //        remainder = x % base
    //        x = x / base
    //        output_string << code_string[remainder]
    //        end
    //
    //        pos = 0
    //        while data[pos,2] == "00" do
    //            output_string << code_string[0]
    //            pos += 2
    //            end
    //
    //            output_string.reverse()
    //            end
    //
};

+ (NSData *)createDataWithHexString: (NSString *)inputString {
    NSUInteger inLength = [inputString length];
    
    unichar *inCharacters = alloca(sizeof(unichar) * inLength);
    [inputString getCharacters:inCharacters range:NSMakeRange(0, inLength)];
    
    UInt8 *outBytes = malloc(sizeof(UInt8) * ((inLength / 2) + 1));
    
    NSInteger i, o = 0;
    UInt8 outByte = 0;
    for (i = 0; i < inLength; i++) {
        UInt8 c = inCharacters[i];
        SInt8 value = -1;
        
        if      (c >= '0' && c <= '9') value =      (c - '0');
        else if (c >= 'A' && c <= 'F') value = 10 + (c - 'A');
        else if (c >= 'a' && c <= 'f') value = 10 + (c - 'a');
        
        if (value >= 0) {
            if (i % 2 == 1) {
                outBytes[o++] = (outByte << 4) | value;
                outByte = 0;
            } else {
                outByte = value;
            }
            
        } else {
            if (o != 0) break;
        }
    }
    
    return [[NSData alloc] initWithBytesNoCopy:outBytes length:o freeWhenDone:YES];
}
  // string DigestMethod string {
  // createData...
  // digest data
  // hexData(appropriateLength)
  // return the hexdata

+ (NSString *)hexOfsha256: (NSString *) pubKey{

    NSData *data = [self createDataWithHexString:pubKey];
    uint8_t buf[33];
    [data getBytes:buf length:[data length]];

    unsigned char result[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, buf, [data length]);
    SHA256_Final(result, &sha256);
    NSData *hexData = [[NSData alloc] initWithBytes:result length:SHA256_DIGEST_LENGTH];
    return [self hexItUp: hexData WithLength: SHA256_DIGEST_LENGTH];
}

+ (NSString *)hexOfRipe160: (NSString *) input {
    NSData *data = [self createDataWithHexString:input];
    uint8_t buf[[input length]];
    [data getBytes:buf length:[data length]];
    
    unsigned char ripResult[RIPEMD160_DIGEST_LENGTH];
    RIPEMD160_CTX ripe160;
    RIPEMD160_Init(&ripe160);
    RIPEMD160_Update(&ripe160, buf, [data length]);
    RIPEMD160_Final(ripResult, &ripe160);
    
    NSData *hexData = [[NSData alloc] initWithBytes:ripResult length:RIPEMD160_DIGEST_LENGTH];
    return [self hexItUp: hexData WithLength: RIPEMD160_DIGEST_LENGTH];
}


+ (NSString *)hexItUp: (NSData *)input WithLength: (int)length {
    
    uint8_t *byteData = (uint8_t*)malloc(length);
    memcpy(byteData, [input bytes], length);

    NSMutableString *outStrg = [NSMutableString string];
    unsigned int i;
    for (i = 0; i < length; i++) {
        [outStrg appendFormat:@"%02x", byteData[i]];
    }
    return [outStrg copy];
}


@end
