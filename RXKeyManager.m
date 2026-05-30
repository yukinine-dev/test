#import "RXKeyManager.h"
#import <Security/Security.h>
#import <CommonCrypto/CommonDigest.h>

// Мастер-ключ захеширован — в бинарнике не будет видна строка напрямую
// SHA256("TungTungTungSahur") — считается при компиляции
static NSString *const kMasterKeyHash = @"87d6540f1110d192590b5529c0ae4fd40252a7c37b85ddc6ced629549c28823e";

static NSString *const kKeychainService  = @"com.rx.modkeys";
static NSString *const kKeychainAccount  = @"activationKey";
static NSString *const kKeychainActivated = @"isActivated";

@implementation RXKeyManager

+ (instancetype)sharedManager {
    static RXKeyManager *instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

#pragma mark - Public

- (RXKeyValidationResult)validateKey:(NSString *)key {
    if (!key || key.length == 0) return RXKeyValidationResultInvalid;

    NSString *trimmed = [key stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];

    // Проверяем мастер-ключ через хеш
    if ([self hashString:trimmed]) {
        return RXKeyValidationResultMaster;
    }

    // Проверяем обычные ключи (формат: XXXX-XXXX-XXXX-XXXX)
    if ([self isValidKeyFormat:trimmed]) {
        return RXKeyValidationResultSuccess;
    }

    return RXKeyValidationResultInvalid;
}

- (BOOL)isActivated {
    // Сначала проверяем Keychain
    NSString *saved = [self loadSavedKey];
    if (!saved) return NO;

    RXKeyValidationResult result = [self validateKey:saved];
    return (result == RXKeyValidationResultSuccess || result == RXKeyValidationResultMaster);
}

- (BOOL)saveKey:(NSString *)key {
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];

    NSDictionary *query = @{
        (__bridge id)kSecClass:            (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:      kKeychainService,
        (__bridge id)kSecAttrAccount:      kKeychainAccount,
        (__bridge id)kSecValueData:        keyData,
        (__bridge id)kSecAttrAccessible:   (__bridge id)kSecAttrAccessibleAfterFirstUnlock,
    };

    // Удаляем старое если есть
    SecItemDelete((__bridge CFDictionaryRef)query);

    OSStatus status = SecItemAdd((__bridge CFDictionaryRef)query, NULL);
    return status == errSecSuccess;
}

- (nullable NSString *)loadSavedKey {
    NSDictionary *query = @{
        (__bridge id)kSecClass:            (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:      kKeychainService,
        (__bridge id)kSecAttrAccount:      kKeychainAccount,
        (__bridge id)kSecReturnData:       @YES,
        (__bridge id)kSecMatchLimit:       (__bridge id)kSecMatchLimitOne,
    };

    CFDataRef result = NULL;
    OSStatus status = SecItemCopyMatching((__bridge CFDictionaryRef)query, (CFTypeRef *)&result);

    if (status != errSecSuccess || !result) return nil;

    NSData *data = (__bridge_transfer NSData *)result;
    return [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
}

- (void)resetActivation {
    NSDictionary *query = @{
        (__bridge id)kSecClass:        (__bridge id)kSecClassGenericPassword,
        (__bridge id)kSecAttrService:  kKeychainService,
        (__bridge id)kSecAttrAccount:  kKeychainAccount,
    };
    SecItemDelete((__bridge CFDictionaryRef)query);
}

#pragma mark - Private

/// Возвращает YES если хеш строки совпадает с мастер-ключом
- (BOOL)hashString:(NSString *)input {
    NSData *data = [input dataUsingEncoding:NSUTF8StringEncoding];
    uint8_t digest[CC_SHA256_DIGEST_LENGTH];
    CC_SHA256(data.bytes, (CC_LONG)data.length, digest);

    NSMutableString *hex = [NSMutableString stringWithCapacity:CC_SHA256_DIGEST_LENGTH * 2];
    for (int i = 0; i < CC_SHA256_DIGEST_LENGTH; i++) {
        [hex appendFormat:@"%02x", digest[i]];
    }

    return [hex isEqualToString:kMasterKeyHash];
}

/// Формат обычного ключа: RXXX-XXXX-XXXX-XXXX (буквы + цифры)
- (BOOL)isValidKeyFormat:(NSString *)key {
    NSRegularExpression *regex = [NSRegularExpression
        regularExpressionWithPattern:@"^R[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}-[A-Z0-9]{4}$"
        options:0 error:nil];
    NSUInteger matches = [regex numberOfMatchesInString:key
                                                options:0
                                                  range:NSMakeRange(0, key.length)];
    return matches > 0;
}

@end
