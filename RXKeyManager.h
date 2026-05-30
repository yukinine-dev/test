#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, RXKeyValidationResult) {
    RXKeyValidationResultSuccess,       // Ключ валиден
    RXKeyValidationResultMaster,        // Мастер-ключ (пасхалка)
    RXKeyValidationResultInvalid,       // Неверный ключ
    RXKeyValidationResultExpired,       // Ключ истёк (для будущего)
};

@interface RXKeyManager : NSObject

+ (instancetype)sharedManager;

/// Проверить ключ. Возвращает результат валидации.
- (RXKeyValidationResult)validateKey:(NSString *)key;

/// Активирован ли мод (ключ уже введён ранее)
- (BOOL)isActivated;

/// Сохранить валидный ключ в Keychain
- (BOOL)saveKey:(NSString *)key;

/// Загрузить сохранённый ключ из Keychain
- (nullable NSString *)loadSavedKey;

/// Сбросить всё (для тестов / деактивации)
- (void)resetActivation;

@end

NS_ASSUME_NONNULL_END
