#import "RXActivationViewController.h"
#import "RXKeyManager.h"

@interface RXActivationViewController () <UITextFieldDelegate>
@property (nonatomic, strong) UIVisualEffectView *blurView;
@property (nonatomic, strong) UIView             *card;
@property (nonatomic, strong) UILabel            *titleLabel;
@property (nonatomic, strong) UILabel            *subtitleLabel;
@property (nonatomic, strong) UITextField        *keyField;
@property (nonatomic, strong) UIButton           *activateButton;
@property (nonatomic, strong) UILabel            *statusLabel;
@property (nonatomic, copy)   RXActivationCompletion completion;
@end

@implementation RXActivationViewController

#pragma mark - Present

+ (void)presentIfNeededWithCompletion:(RXActivationCompletion)completion {
    if ([[RXKeyManager sharedManager] isActivated]) {
        if (completion) completion(YES);
        return;
    }

    UIWindow *window = UIApplication.sharedApplication.keyWindow;
    UIViewController *root = window.rootViewController;
    while (root.presentedViewController) root = root.presentedViewController;

    RXActivationViewController *vc = [[RXActivationViewController alloc] init];
    vc.completion = completion;
    vc.modalPresentationStyle = UIModalPresentationOverFullScreen;
    vc.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [root presentViewController:vc animated:YES completion:nil];
}

#pragma mark - Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setupBackground];
    [self setupCard];
    [self setupContent];
}

#pragma mark - UI Setup

- (void)setupBackground {
    self.view.backgroundColor = [UIColor colorWithWhite:0 alpha:0.6];

    UIBlurEffect *blur = [UIBlurEffect effectWithStyle:UIBlurEffectStyleSystemMaterialDark];
    self.blurView = [[UIVisualEffectView alloc] initWithEffect:blur];
    self.blurView.frame = self.view.bounds;
    self.blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.blurView];
}

- (void)setupCard {
    self.card = [[UIView alloc] init];
    self.card.backgroundColor = [UIColor colorWithWhite:0.12 alpha:1.0];
    self.card.layer.cornerRadius = 20;
    self.card.layer.shadowColor = UIColor.blackColor.CGColor;
    self.card.layer.shadowOpacity = 0.5;
    self.card.layer.shadowRadius = 20;
    self.card.layer.shadowOffset = CGSizeMake(0, 8);
    self.card.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:self.card];

    [NSLayoutConstraint activateConstraints:@[
        [self.card.centerXAnchor constraintEqualToAnchor:self.view.centerXAnchor],
        [self.card.centerYAnchor constraintEqualToAnchor:self.view.centerYAnchor],
        [self.card.widthAnchor constraintEqualToConstant:320],
    ]];
}

- (void)setupContent {
    // Иконка
    UILabel *icon = [[UILabel alloc] init];
    icon.text = @"🔑";
    icon.font = [UIFont systemFontOfSize:42];
    icon.textAlignment = NSTextAlignmentCenter;
    icon.translatesAutoresizingMaskIntoConstraints = NO;
    [self.card addSubview:icon];

    // Заголовок
    self.titleLabel = [[UILabel alloc] init];
    self.titleLabel.text = @"Активация";
    self.titleLabel.textColor = UIColor.whiteColor;
    self.titleLabel.font = [UIFont systemFontOfSize:22 weight:UIFontWeightBold];
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.card addSubview:self.titleLabel];

    // Подзаголовок
    self.subtitleLabel = [[UILabel alloc] init];
    self.subtitleLabel.text = @"Введите ключ активации";
    self.subtitleLabel.textColor = [UIColor colorWithWhite:0.6 alpha:1.0];
    self.subtitleLabel.font = [UIFont systemFontOfSize:14];
    self.subtitleLabel.textAlignment = NSTextAlignmentCenter;
    self.subtitleLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.card addSubview:self.subtitleLabel];

    // Поле ввода
    self.keyField = [[UITextField alloc] init];
    self.keyField.placeholder = @"RXXXX-XXXX-XXXX-XXXX";
    self.keyField.textColor = UIColor.whiteColor;
    self.keyField.tintColor = [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0];
    self.keyField.font = [UIFont monospacedSystemFontOfSize:15 weight:UIFontWeightMedium];
    self.keyField.textAlignment = NSTextAlignmentCenter;
    self.keyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.keyField.autocapitalizationType = UITextAutocapitalizationTypeAllCharacters;
    self.keyField.returnKeyType = UIReturnKeyDone;
    self.keyField.delegate = self;
    self.keyField.translatesAutoresizingMaskIntoConstraints = NO;

    UIView *fieldBg = [[UIView alloc] init];
    fieldBg.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
    fieldBg.layer.cornerRadius = 10;
    fieldBg.translatesAutoresizingMaskIntoConstraints = NO;
    [self.card addSubview:fieldBg];
    [fieldBg addSubview:self.keyField];

    // Статус
    self.statusLabel = [[UILabel alloc] init];
    self.statusLabel.text = @"";
    self.statusLabel.font = [UIFont systemFontOfSize:13];
    self.statusLabel.textAlignment = NSTextAlignmentCenter;
    self.statusLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [self.card addSubview:self.statusLabel];

    // Кнопка
    self.activateButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.activateButton setTitle:@"Активировать" forState:UIControlStateNormal];
    self.activateButton.titleLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightSemibold];
    [self.activateButton setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
    self.activateButton.backgroundColor = [UIColor colorWithRed:0.4 green:0.6 blue:1.0 alpha:1.0];
    self.activateButton.layer.cornerRadius = 12;
    self.activateButton.translatesAutoresizingMaskIntoConstraints = NO;
    [self.activateButton addTarget:self action:@selector(activateTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.card addSubview:self.activateButton];

    [NSLayoutConstraint activateConstraints:@[
        [icon.topAnchor constraintEqualToAnchor:self.card.topAnchor constant:28],
        [icon.centerXAnchor constraintEqualToAnchor:self.card.centerXAnchor],

        [self.titleLabel.topAnchor constraintEqualToAnchor:icon.bottomAnchor constant:10],
        [self.titleLabel.leadingAnchor constraintEqualToAnchor:self.card.leadingAnchor constant:20],
        [self.titleLabel.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-20],

        [self.subtitleLabel.topAnchor constraintEqualToAnchor:self.titleLabel.bottomAnchor constant:6],
        [self.subtitleLabel.leadingAnchor constraintEqualToAnchor:self.card.leadingAnchor constant:20],
        [self.subtitleLabel.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-20],

        [fieldBg.topAnchor constraintEqualToAnchor:self.subtitleLabel.bottomAnchor constant:20],
        [fieldBg.leadingAnchor constraintEqualToAnchor:self.card.leadingAnchor constant:20],
        [fieldBg.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-20],
        [fieldBg.heightAnchor constraintEqualToConstant:48],

        [self.keyField.leadingAnchor constraintEqualToAnchor:fieldBg.leadingAnchor constant:12],
        [self.keyField.trailingAnchor constraintEqualToAnchor:fieldBg.trailingAnchor constant:-12],
        [self.keyField.centerYAnchor constraintEqualToAnchor:fieldBg.centerYAnchor],

        [self.statusLabel.topAnchor constraintEqualToAnchor:fieldBg.bottomAnchor constant:8],
        [self.statusLabel.leadingAnchor constraintEqualToAnchor:self.card.leadingAnchor constant:20],
        [self.statusLabel.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-20],
        [self.statusLabel.heightAnchor constraintEqualToConstant:18],

        [self.activateButton.topAnchor constraintEqualToAnchor:self.statusLabel.bottomAnchor constant:12],
        [self.activateButton.leadingAnchor constraintEqualToAnchor:self.card.leadingAnchor constant:20],
        [self.activateButton.trailingAnchor constraintEqualToAnchor:self.card.trailingAnchor constant:-20],
        [self.activateButton.heightAnchor constraintEqualToConstant:48],
        [self.activateButton.bottomAnchor constraintEqualToAnchor:self.card.bottomAnchor constant:-24],
    ]];
}

#pragma mark - Actions

- (void)activateTapped {
    NSString *key = self.keyField.text;
    RXKeyValidationResult result = [[RXKeyManager sharedManager] validateKey:key];

    switch (result) {
        case RXKeyValidationResultSuccess:
        case RXKeyValidationResultMaster: {
            [[RXKeyManager sharedManager] saveKey:key];
            [self showStatus:@"✅ Активировано!" color:[UIColor colorWithRed:0.3 green:0.9 blue:0.4 alpha:1.0]];
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self dismissViewControllerAnimated:YES completion:^{
                    if (self.completion) self.completion(YES);
                }];
            });
            break;
        }
        case RXKeyValidationResultExpired:
            [self showStatus:@"⏳ Ключ истёк" color:[UIColor colorWithRed:1.0 green:0.7 blue:0.2 alpha:1.0]];
            break;
        case RXKeyValidationResultInvalid:
        default:
            [self showStatus:@"❌ Неверный ключ" color:[UIColor colorWithRed:1.0 green:0.35 blue:0.35 alpha:1.0]];
            [self shakeField];
            break;
    }
}

- (void)showStatus:(NSString *)text color:(UIColor *)color {
    self.statusLabel.text = text;
    self.statusLabel.textColor = color;
}

- (void)shakeField {
    CAKeyframeAnimation *shake = [CAKeyframeAnimation animationWithKeyPath:@"transform.translation.x"];
    shake.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
    shake.duration = 0.4;
    shake.values = @[@(-8), @(8), @(-6), @(6), @(-4), @(4), @0];
    [self.keyField.layer addAnimation:shake forKey:@"shake"];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [self activateTapped];
    return YES;
}

@end
