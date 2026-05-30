#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void(^RXActivationCompletion)(BOOL success);

@interface RXActivationViewController : UIViewController

/// Показать поверх текущего окна
+ (void)presentIfNeededWithCompletion:(RXActivationCompletion)completion;

@end

NS_ASSUME_NONNULL_END
