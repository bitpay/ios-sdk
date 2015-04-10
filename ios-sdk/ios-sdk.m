//
//  ios-sdk.m
//
//  Created by Chris Kleeschulte on 4/7/15.
//  Copyright (c) 2015 BitPay. All rights reserved.
//

#import "ios-sdk.h"

@implementation IosSDK


+ (NSString *)generatePem {

    EC_KEY *eckey;
    BIO *out = NULL;
    BUF_MEM *buf;
    
    eckey = [self createNewKey];
    out = BIO_new(BIO_s_mem());
    PEM_write_bio_ECPrivateKey(out, eckey, NULL, NULL, 0, NULL, NULL);
    
    BIO_get_mem_ptr(out, &buf);
    
    NSString *pem = [NSString stringWithCString:buf->data encoding:NSASCIIStringEncoding];
    
    EC_KEY_free(eckey);
    BIO_free(out);
    
    return pem;
};



+ (NSString *)getPublicKeyFromPem: (NSString *)pem {
    
    EC_KEY *eckey = NULL;
    EC_KEY *key = NULL;
    EC_POINT *pub_key = NULL;
    BIO *in = NULL;
    const EC_GROUP *group = NULL;
    const char *cPem = NULL;
    char *hexPoint = NULL;
    
    BIGNUM start;
    const BIGNUM *res;
    BN_CTX *ctx;
    
    BN_init(&start);
    ctx = BN_CTX_new();
    
    res = &start;
    
    cPem = [pem cStringUsingEncoding:NSASCIIStringEncoding];
    in = BIO_new(BIO_s_mem());
    BIO_puts(in, cPem);
    key = PEM_read_bio_ECPrivateKey(in, NULL, NULL, NULL);
    res = EC_KEY_get0_private_key(key);
    
    eckey = EC_KEY_new_by_curve_name(NID_secp256k1);
    group = EC_KEY_get0_group(eckey);
    pub_key = EC_POINT_new(group);

    EC_KEY_set_private_key(eckey, res);
    
    if (!EC_POINT_mul(group, pub_key, res, NULL, NULL, ctx)) {
        raise(-1);
    }

    EC_KEY_set_public_key(eckey, pub_key); //1 on success
    
    hexPoint = EC_POINT_point2hex(group, pub_key, 4, ctx);
    
    NSString *pubKeyString = [NSString stringWithCString:hexPoint encoding:NSASCIIStringEncoding];
    pubKeyString = [self compressKey: pubKeyString];

    BN_CTX_free(ctx);
    free(hexPoint);

    return pubKeyString;
    
}

+ (NSString *)getPrivateKeyFromPem: (NSString *)pem {
    
    EC_KEY *key = NULL;
    BIO *in = NULL;
    const char *cPem = NULL;
    
    BIGNUM start;
    const BIGNUM *res;
    BN_CTX *ctx;
    
    BN_init(&start);
    ctx = BN_CTX_new();
    
    res = &start;
    
    cPem = [pem cStringUsingEncoding:NSASCIIStringEncoding];
    in = BIO_new(BIO_s_mem());
    BIO_puts(in, cPem);
    key = PEM_read_bio_ECPrivateKey(in, NULL, NULL, NULL);
    res = EC_KEY_get0_private_key(key);
    char *out = BN_bn2hex(res);

    NSString *privKeyString = [NSString stringWithCString:out encoding:NSASCIIStringEncoding];
    
    BN_CTX_free(ctx);
    free(out);
    
    return privKeyString;

}

+ (NSString *)generateSinFromPem: (NSString *)pem {

    NSString *pubKeyString = [self getPublicKeyFromPem: pem];
    NSString *sha256Hex = [self hexOfsha256: pubKeyString];
    NSString *ripe160Hex = [self hexOfRipe160: sha256Hex];

    NSString *prefix = @"0f02";
    NSString *versionType = [prefix stringByAppendingString:ripe160Hex];
    
    NSString *shaOnce = [self hexOfsha256:versionType];
    NSString *shaTwice = [self hexOfsha256:shaOnce];
    NSString *checkSum = [shaTwice substringToIndex:8];
    NSString *versionCheck = [versionType stringByAppendingString:checkSum];
    return [self encodeBase58: versionCheck];

};

+ (NSString *)sign:(NSString *)message withPem: (NSString *)pem {

    const unsigned char *buf = (const unsigned char *)strdup([message cStringUsingEncoding: NSASCIIStringEncoding]);
    
    unsigned char result[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, buf, [message length]);
    SHA256_Final(result, &sha256);
    NSData *messageHash = [[NSData alloc] initWithBytes:result length:SHA256_DIGEST_LENGTH];

    const char *charList = (const char *)[messageHash bytes];
    
    EC_KEY *key = NULL;
    BIO *in = NULL;
    const char *cPem = NULL;
    unsigned char *buffer = NULL;
    
    BIGNUM start;
    const BIGNUM *res;
    BN_CTX *ctx;
    
    BN_init(&start);
    ctx = BN_CTX_new();
    
    res = &start;
    
    cPem = [pem cStringUsingEncoding:NSASCIIStringEncoding];
    in = BIO_new(BIO_s_mem());
    BIO_puts(in, cPem);
    key = PEM_read_bio_ECPrivateKey(in, NULL, NULL, NULL);
    
    ECDSA_SIG *sig = ECDSA_do_sign((const unsigned char*)charList, SHA256_DIGEST_LENGTH, key);
    
    int verify = ECDSA_do_verify((const unsigned char*)charList, SHA256_DIGEST_LENGTH, sig, key);
    
    if(verify != 1) {
        raise(-1);
    }

    int buflen = ECDSA_size(key);
    buffer = OPENSSL_malloc(buflen);

    int derSigLen = i2d_ECDSA_SIG(sig, &buffer);

    NSData *hexData = [[NSData alloc] initWithBytes:(buffer-derSigLen) length:derSigLen];

    NSString *hexString = [self toHexString: hexData WithLength: derSigLen];
    
    EC_KEY_free(key);
    BN_CTX_free(ctx);
    return hexString;
    
};

+ (NSString *)compressKey: (NSString *)key {
    
    unsigned int yint;
    NSString *xval = [key substringWithRange:NSMakeRange(2, 64)];
    NSString *yval = [key substringFromIndex:125];
    NSScanner *scanner = [NSScanner scannerWithString:yval];
    [scanner scanHexInt:&yint];
    NSString *prefix = ((yint % 2) == 0) ? @"02" : @"03";
    
    return [prefix stringByAppendingString:xval];
    
}

+ (EC_KEY *)createNewKey {

    int asn1Flag = OPENSSL_EC_NAMED_CURVE;
    int form = POINT_CONVERSION_UNCOMPRESSED;
    EC_KEY *eckey = NULL;
    EC_GROUP *group = NULL;

    eckey = EC_KEY_new();
    group = EC_GROUP_new_by_curve_name(NID_secp256k1);
    EC_GROUP_set_asn1_flag(group, asn1Flag);
    EC_GROUP_set_point_conversion_form(group, form);
    EC_KEY_set_group(eckey, group);
    
    int resultFromKeyGen = EC_KEY_generate_key(eckey);
    if (resultFromKeyGen != 1){
        raise(-1);
    }
    return eckey;
}

+ (NSData *)createDataWithHexString: (NSString *)inputString {

    NSInteger i, o = 0;
    UInt8 outByte = 0;
    
    NSUInteger inLength = [inputString length];
    unichar *inCharacters = alloca(sizeof(unichar) * inLength);
    [inputString getCharacters:inCharacters range:NSMakeRange(0, inLength)];
    
    UInt8 *outBytes = malloc(sizeof(UInt8) * ((inLength / 2) + 1));
    
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

+ (NSString *)hexOfsha256: (NSString *) input{

    NSData *data = [self createDataWithHexString:input];
    uint8_t buf[[input length]];
    [data getBytes:buf length:[data length]];

    unsigned char result[SHA256_DIGEST_LENGTH];
    SHA256_CTX sha256;
    SHA256_Init(&sha256);
    SHA256_Update(&sha256, buf, [data length]);
    SHA256_Final(result, &sha256);
    NSData *hexData = [[NSData alloc] initWithBytes:result length:SHA256_DIGEST_LENGTH];
    return [self toHexString: hexData WithLength: SHA256_DIGEST_LENGTH];
    
}

+ (NSString *)hexOfRipe160: (NSString *)input {
    
    NSData *data = [self createDataWithHexString:input];
    uint8_t buf[[input length]];
    [data getBytes:buf length:[data length]];
    
    unsigned char ripResult[RIPEMD160_DIGEST_LENGTH];
    RIPEMD160_CTX ripe160;
    RIPEMD160_Init(&ripe160);
    RIPEMD160_Update(&ripe160, buf, [data length]);
    RIPEMD160_Final(ripResult, &ripe160);
    
    NSData *hexData = [[NSData alloc] initWithBytes:ripResult length:RIPEMD160_DIGEST_LENGTH];
    return [self toHexString: hexData WithLength: RIPEMD160_DIGEST_LENGTH];
}


+ (NSString *)toHexString: (NSData *)input WithLength: (int)length {
    
    uint8_t *byteData = (uint8_t*)malloc(length);
    memcpy(byteData, [input bytes], length);

    NSMutableString *outStrg = [NSMutableString string];
    unsigned int i;
    for (i = 0; i < length; i++) {
        [outStrg appendFormat:@"%02x", byteData[i]];
    }
    return [outStrg copy];
}


+ (NSString *)encodeBase58: (NSString *)string {

    BIGNUM *res = BN_new();
    const char *charList = [string UTF8String];
    BN_hex2bn(&res, charList);
    NSString *codeString = @"123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";
    
    NSMutableString *buildString = [NSMutableString string];
   
    while(BN_is_zero(res) != 1){
        
        int rem = BN_mod_word(res, 58);
        NSString *currentChar = [codeString substringWithRange:NSMakeRange(rem, 1)];
        [buildString insertString:currentChar atIndex:0];
        BN_div_word(res, 58);
        
    }

    return buildString;
    
}

@end
