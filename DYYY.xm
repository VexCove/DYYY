//
//  DYYY
//
//  Copyright (c) 2024 huami. All rights reserved.
//  Channel: @huamidev
//  Created on: 2024/10/04
//
#import <QuartzCore/QuartzCore.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>
#import <dlfcn.h>
#import <float.h>
#import <math.h>
#import <objc/message.h>
#import <objc/runtime.h>
#import <os/lock.h>
#import <substrate.h>
#import <stdlib.h>
#import <string.h>
#import <syslog.h>

#import "AwemeHeaders.h"
#import "CityManager.h"
#import "DYYYBottomAlertView.h"
#import "DYYYGlassConfirmView.h"
#import "DYYYManager.h"

#import "AWMSafeDispatchTimer.h"
#import "DYYYConstants.h"
#import "DYYYFloatClearButton.h"
#import "DYYYFloatSpeedButton.h"
#import "DYYYLivePreStreamLayoutCoordinator.h"
#import "DYYYLoginBypassManager.h"
#import "DYYYLoginRepairHooks.h"
#import "DYYYHideMusicButtonHooks.h"
#import "DYYYHideShareContentViewHooks.h"
#import "DYYYHideMessageAndMinePageHooks.h"
#import "DYYYHideCommentAIAnalysisHooks.h"
#import "DYYYHideTemplateCollectionHooks.h"
#import "DYYYSearchKeyboardVoiceHooks.h"
#import "DYYYHighFPSHooks.h"
#import "DYYYFPSOverlay.h"
#import "DYYYHookManager.h"
#import "DYYYMiniProgramRewardBypass.h"
#import "DYYYPrivacyRecordUploadGuard.h"
#import "DYYYSettingViewController.h"
#import "DYYYToast.h"
#import "DYYYUtils.h"

static CGFloat gStartY = 0.0;
static CGFloat gStartVal = 0.0;
static DYEdgeMode gMode = DYEdgeModeNone;
static __weak UICollectionView *gFeedCV = nil;

static const CGFloat kInvalidAlpha = -1.0;
static const CGFloat kInvalidHeight = -1.0;
static CGFloat gGlobalTransparency = kInvalidAlpha;
static CGFloat gCurrentTabBarHeight = kInvalidHeight;
static CGFloat originalTabBarHeight = kInvalidHeight;
static NSString *const kDYYYGlobalTransparencyKey = @"DYYYGlobalTransparency";
static NSString *const kDYYYGlobalTransparencyDidChangeNotification = @"DYYYGlobalTransparencyDidChangeNotification";
static NSString *const kDYYYEnableLoginBypassKey = @"DYYYEnableLoginBypass";
static char kDYYYGlobalTransparencyBaseAlphaKey;
static NSInteger dyyyGlobalTransparencyMutationDepth = 0;

static BOOL DYYYLoginBypassEnabled(void) {
    return [DYYYLoginBypassManager isLoginBypassEnabled];
}

static BOOL DYYYShouldBlockVersionUpdateWorkflow(void) {
    return DYYYGetBool(@"DYYYNoUpdates") || DYYYLoginBypassEnabled();
}

static void DYYYLoginBypassInvokeCloseCallback(id callback) {
    if (!callback) {
        return;
    }

    void (^completionBlock)(void) = callback;
    completionBlock();
}

static NSString *DYYYLoginBypassReplacementBundleIdentifier(NSString *bundleIdentifier) {
    return [DYYYLoginBypassManager replacementBundleIdentifier:bundleIdentifier];
}

static NSString *DYYYLoginBypassHeaderValueByReplacingBundleIdentifier(NSString *value, NSString *field) {
    return [DYYYLoginBypassManager headerValueByReplacingBundleIdentifier:value field:field];
}

static NSDictionary *DYYYLoginBypassHeadersByReplacingBundleIdentifiers(NSDictionary *headers) {
    return [DYYYLoginBypassManager headersByReplacingBundleIdentifiers:headers];
}

static NSURL *DYYYLoginBypassURLByReplacingBundleIdentifier(NSURL *url) {
    return [DYYYLoginBypassManager URLByReplacingTargetBundleIdentifiers:url];
}

%group DYYYLoginBypassCore

%hook NSBundle
- (NSString *)bundleIdentifier {
    NSString *bundleIdentifier = %orig;
    return DYYYLoginBypassReplacementBundleIdentifier(bundleIdentifier);
}

- (NSDictionary *)infoDictionary {
    NSDictionary *infoDictionary = %orig;
    if (![infoDictionary isKindOfClass:[NSDictionary class]]) {
        return infoDictionary;
    }

    NSString *bundleIdentifier = infoDictionary[@"CFBundleIdentifier"];
    NSString *replacementIdentifier = DYYYLoginBypassReplacementBundleIdentifier(bundleIdentifier);
    if (![replacementIdentifier isKindOfClass:[NSString class]] || replacementIdentifier.length == 0 ||
        [replacementIdentifier isEqualToString:bundleIdentifier]) {
        return infoDictionary;
    }

    NSMutableDictionary *mutableInfoDictionary = [infoDictionary mutableCopy];
    mutableInfoDictionary[@"CFBundleIdentifier"] = replacementIdentifier;
    return mutableInfoDictionary;
}
%end

%hook NSURLRequest
- (NSURL *)URL {
    NSURL *url = %orig;
    return DYYYLoginBypassURLByReplacingBundleIdentifier(url);
}
%end

%hook NSMutableURLRequest
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    %orig(DYYYLoginBypassHeaderValueByReplacingBundleIdentifier(value, field), field);
}

- (void)addValue:(NSString *)value forHTTPHeaderField:(NSString *)field {
    %orig(DYYYLoginBypassHeaderValueByReplacingBundleIdentifier(value, field), field);
}

- (void)setURL:(NSURL *)url {
    %orig(DYYYLoginBypassURLByReplacingBundleIdentifier(url));
}
%end

%hook NSURLSessionConfiguration
- (NSDictionary *)HTTPAdditionalHeaders {
    return DYYYLoginBypassHeadersByReplacingBundleIdentifiers(%orig);
}

- (void)setHTTPAdditionalHeaders:(NSDictionary *)headers {
    %orig(DYYYLoginBypassHeadersByReplacingBundleIdentifiers(headers));
}
%end

%end

%group DYYYLoginBypassAccountLifecycle

%hook AWEUserServiceListener

- (void)didFinishLoginWithUid:(NSString *)userID {
    %orig(userID);
    [DYYYLoginBypassManager handleOfficialLoginCompletionWithUserID:userID];
}

%end

%end

%group DYYYLoginBypassAccountLogout

%hook AWEUserServiceListener

- (void)didFinishLogoutWithUid:(NSString *)userID {
    %orig(userID);
    [DYYYLoginBypassManager handleOfficialLogout];
}

%end

%end

%group DYYYLoginBypassAccountLifecycleDidFinishLogin

%hook AWEUserServiceListener

- (void)didFinishLogin:(id)user {
    %orig(user);
    [DYYYLoginBypassManager handleOfficialLoginCompletionWithUserID:user];
}

%end

%end

%group DYYYLoginBypassAccountMulticast

%hook TTAccountMulticast

- (void)broadcastLoginSuccess:(id)user platform:(id)platform reason:(long long)reason {
    %orig(user, platform, reason);
    [DYYYLoginBypassManager handleOfficialLoginCompletionWithUserID:user];
}

%end

%end

%group DYYYLoginBypassVersionUpdateAlert
%hook AWEVersionUpdateAlert
- (BOOL)canShow {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (BOOL)canShowWithUpgradeStatus {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (BOOL)isUpgradeStatusVersionValid {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (BOOL)versionCompareForNeedUpgrade {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (void)showWithCloseCallback:(id)closeCallback {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        DYYYLoginBypassInvokeCloseCallback(closeCallback);
        return;
    }
    %orig(closeCallback);
}

- (void)_showUpgradeModal {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}

- (void)showDialog {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}

- (void)requestNewVersion {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}
%end
%end

%group DYYYLoginBypassVersionUpdatePopup
%hook AWEVersionUpdatePopup
- (BOOL)isShowing {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (void)showDialog {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}

- (void)showInfoPanel {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}

- (void)p_showDialog {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}

- (void)p_showInfoPanel {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}
%end
%end

%group DYYYLoginBypassVersionUpdateWorkflow
%hook AWEVersionUpdateWorkflow
- (void)startVersionUpdateWorkflow:(id)request completion:(id)completion {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        DYYYLoginBypassInvokeCloseCallback(completion);
        return;
    }
    %orig(request, completion);
}

- (void)openAppStore {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}

- (void)showLoadingView {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}
%end
%end

%group DYYYLoginBypassTeenVersionUpdateManager
%hook AWETeenVersionUpdateManager
- (BOOL)canShow {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (void)showWithCloseCallback:(id)closeCallback {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        DYYYLoginBypassInvokeCloseCallback(closeCallback);
        return;
    }
    %orig(closeCallback);
}

- (void)p_showUpgradeAlert {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}

- (BOOL)versionCompareForUpgrade {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (void)requestNewVersion {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        return;
    }
    %orig;
}
%end
%end

%group DYYYLoginBypassPreLoginAlert
%hook AWEPreLoginAlertManager
- (BOOL)canShow {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (BOOL)canShowNow {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}
%end
%end

%group DYYYLoginBypassPreLoginFrequency
%hook AWEPreLoginAlertManager
- (BOOL)isShowFrequencySatisfied {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}

- (BOOL)isShowFrequencySatisfiedByLoginStrategy {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}
%end
%end

%group DYYYLoginBypassNewVersionAlert
%hook AWENewVersionAlertManager
- (BOOL)canShow {
    return DYYYShouldBlockVersionUpdateWorkflow() ? NO : %orig;
}
%end
%end

static void updateGlobalTransparencyCache() {
    NSString *transparentValue = DYYYGetString(kDYYYGlobalTransparencyKey);
    if (transparentValue.length > 0) {
        float alphaValue;
        NSScanner *scanner = [NSScanner scannerWithString:transparentValue];
        if ([scanner scanFloat:&alphaValue] && scanner.isAtEnd) {
            gGlobalTransparency = MIN(MAX(alphaValue, 0.0), 1.0);
            return;
        }
    }
    gGlobalTransparency = kInvalidAlpha;
}

static NSDictionary<NSString *, NSString *> *DYYYTopTabTitleMapping(void) {
    static NSString *cachedRawValue = nil;
    static NSDictionary<NSString *, NSString *> *cachedMapping = nil;

    NSString *currentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYModifyTopTabText"];
    BOOL rawValueChanged = (cachedRawValue != currentValue) && ![cachedRawValue isEqualToString:currentValue];

    if (!rawValueChanged) {
        return cachedMapping;
    }

    cachedRawValue = [currentValue copy];

    if (currentValue.length == 0) {
        cachedMapping = nil;
        return nil;
    }

    NSMutableDictionary<NSString *, NSString *> *mapping = [NSMutableDictionary dictionary];
    NSArray<NSString *> *titlePairs = [currentValue componentsSeparatedByString:@"#"];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];

    for (NSString *pair in titlePairs) {
        NSArray<NSString *> *components = [pair componentsSeparatedByString:@"="];
        if (components.count != 2) {
            continue;
        }

        NSString *originalTitle = [components[0] stringByTrimmingCharactersInSet:whitespace];
        NSString *newTitle = [components[1] stringByTrimmingCharactersInSet:whitespace];

        if (originalTitle.length == 0 || newTitle.length == 0) {
            continue;
        }

        mapping[originalTitle] = newTitle;
    }

    cachedMapping = mapping.count > 0 ? [mapping copy] : nil;
    return cachedMapping;
}

static NSString *DYYYCustomAssetsDirectory(void) {
    static NSString *customDirectory = nil;
    static dispatch_once_t onceToken;

    dispatch_once(&onceToken, ^{
      NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
      customDirectory = [documentsPath stringByAppendingPathComponent:@"DYYY"];
      [[NSFileManager defaultManager] createDirectoryAtPath:customDirectory withIntermediateDirectories:YES attributes:nil error:nil];
    });

    return customDirectory;
}

static NSString *DYYYCustomIconFileNameForButtonName(NSString *nameString) {
    if (nameString.length == 0) {
        return nil;
    }

    static NSDictionary<NSString *, NSString *> *prefixMapping = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      prefixMapping = @{
          @"icon_home_like_after" : @"like_after.png",
          @"icon_home_like_before" : @"like_before.png",
          @"icon_home_comment" : @"comment.png",
          @"icon_home_unfavorite" : @"unfavorite.png",
          @"icon_home_favorite" : @"favorite.png",
          @"iconHomeShareRight" : @"share.png"
      };
    });

    for (NSString *prefix in prefixMapping) {
        if ([nameString hasPrefix:prefix]) {
            return prefixMapping[prefix];
        }
    }

    if ([nameString containsString:@"_comment"]) {
        return @"comment.png";
    }
    if ([nameString containsString:@"_like"]) {
        BOOL isLikedState = [nameString containsString:@"_after"] || [nameString containsString:@"_liked"];
        return isLikedState ? @"like_after.png" : @"like_before.png";
    }
    if ([nameString containsString:@"_collect"]) {
        return @"unfavorite.png";
    }
    if ([nameString containsString:@"_share"]) {
        return @"share.png";
    }

    return nil;
}

static UIImage *DYYYLoadCustomImage(NSString *fileName, CGSize targetSize) {
    if (fileName.length == 0) {
        return nil;
    }

    static NSCache<NSString *, UIImage *> *imageCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      imageCache = [[NSCache alloc] init];
      imageCache.name = @"com.dyyy.customIcons.cache";
    });

    NSString *cacheKey = (targetSize.width > 0.0 && targetSize.height > 0.0) ? [NSString stringWithFormat:@"%@_%0.1f_%0.1f", fileName, targetSize.width, targetSize.height] : fileName;

    UIImage *cachedImage = [imageCache objectForKey:cacheKey];
    if (cachedImage) {
        return cachedImage;
    }

    NSString *fullPath = [DYYYCustomAssetsDirectory() stringByAppendingPathComponent:fileName];
    UIImage *sourceImage = [UIImage imageWithContentsOfFile:fullPath];
    if (!sourceImage) {
        return nil;
    }

    if (targetSize.width <= 0.0 || targetSize.height <= 0.0) {
        [imageCache setObject:sourceImage forKey:cacheKey];
        return sourceImage;
    }

    CGSize originalSize = sourceImage.size;
    if (originalSize.width <= 0.0 || originalSize.height <= 0.0) {
        return sourceImage;
    }

    CGFloat widthScale = targetSize.width / originalSize.width;
    CGFloat heightScale = targetSize.height / originalSize.height;
    CGFloat scale = fmin(widthScale, heightScale);

    if (fabs(1.0 - scale) <= FLT_EPSILON) {
        [imageCache setObject:sourceImage forKey:cacheKey];
        return sourceImage;
    }

    CGSize newSize = CGSizeMake(originalSize.width * scale, originalSize.height * scale);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [sourceImage drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    UIImage *resultImage = resizedImage ?: sourceImage;
    [imageCache setObject:resultImage forKey:cacheKey];
    return resultImage;
}

static __weak AWEPlayInteractionViewController *dyyyActivePlaybackInteractionController = nil;
static __weak UIViewController *dyyyActiveSpeedPlayerViewController = nil;
static __weak AWEDPlayerSpeedController *dyyyActiveDPlayerSpeedController = nil;
static __weak AWEDPlayerSpeedController *dyyyLongPressDPlayerSpeedController = nil;
static __weak AFDSpeedManager *dyyyActiveNativeSpeedManager = nil;
static __weak AWEAwemeModel *dyyyCurrentSpeedAweme = nil;
static NSString *dyyyCommittedSpeedAwemeIdentifier = nil;
static NSHashTable<_TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *> *dyyyCommentPauseViewModels = nil;
static __weak _TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *dyyyLastCommentPauseViewModel = nil;

static float DYYYConfiguredDefaultPlaybackSpeed(void) {
    float speed = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYDefaultSpeed"];
    return isfinite(speed) && speed > 0.0f ? speed : 1.0f;
}

static BOOL DYYYNativeLockedPlaybackSpeed(float *speedOut) {
    @try {
        AFDSpeedManager *speedManager = dyyyActiveNativeSpeedManager;
        if (!speedManager) {
            Class managerClass = NSClassFromString(@"AFDSpeedManager");
            if ([managerClass respondsToSelector:@selector(sharedInstance)]) {
                speedManager = [(id)managerClass sharedInstance];
            }
        }
        if (![speedManager respondsToSelector:@selector(isLockedSpeedAwemeID)] ||
            ![speedManager respondsToSelector:@selector(currentSpeed)]) {
            return NO;
        }

        NSString *lockedAwemeID = [speedManager isLockedSpeedAwemeID];
        if (![lockedAwemeID isKindOfClass:[NSString class]] || lockedAwemeID.length == 0) {
            return NO;
        }

        NSString *currentAwemeID = dyyyCurrentSpeedAweme.itemID;
        if (currentAwemeID.length > 0 && ![currentAwemeID isEqualToString:lockedAwemeID]) {
            return NO;
        }

        double speed = [speedManager currentSpeed];
        if (!isfinite(speed) || speed <= 0.0) {
            return NO;
        }

        if (speedOut) {
            *speedOut = (float)speed;
        }
        return YES;
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static float DYYYUnlockedNormalPlaybackSpeed(void) {
    if (isFloatSpeedButtonEnabled) {
        float speed = getCurrentSpeed();
        if (isfinite(speed) && speed > 0.0f && fabsf(speed - 1.0f) > FLT_EPSILON) {
            return speed;
        }
    }
    return DYYYConfiguredDefaultPlaybackSpeed();
}

static float DYYYNormalPlaybackSpeed(void) {
    float lockedSpeed = 0.0f;
    if (DYYYNativeLockedPlaybackSpeed(&lockedSpeed)) {
        return lockedSpeed;
    }
    return DYYYUnlockedNormalPlaybackSpeed();
}

static BOOL DYYYShouldHandleSpeedFeatures(void) {
    if (isFloatSpeedButtonEnabled) {
        return YES;
    }

    float defaultSpeed = DYYYConfiguredDefaultPlaybackSpeed();
    return fabsf(defaultSpeed - 1.0f) > FLT_EPSILON;
}

static BOOL DYYYSpeedMethodMatchesEncoding(id object, SEL selector, const char *expectedEncoding) {
    if (!object || !selector || !expectedEncoding) {
        return NO;
    }
    Method method = class_getInstanceMethod(object_getClass(object), selector);
    const char *actualEncoding = method ? method_getTypeEncoding(method) : NULL;
    return actualEncoding && strcmp(actualEncoding, expectedEncoding) == 0;
}

static BOOL DYYYIsVerifiedNativeDPlayerSpeedController(id object) {
    return object &&
           DYYYSpeedMethodMatchesEncoding(object, @selector(playbackRate), "f16@0:8") &&
           DYYYSpeedMethodMatchesEncoding(object, @selector(setPlaybackRate:), "v20@0:8f16") &&
           DYYYSpeedMethodMatchesEncoding(object, @selector(isInLongPressSpeed), "B16@0:8");
}

static BOOL DYYYNativeDPlayerLongPressIsActive(AWEDPlayerSpeedController *speedController) {
    if (!DYYYIsVerifiedNativeDPlayerSpeedController(speedController)) {
        return NO;
    }
    @try {
        return [speedController isInLongPressSpeed];
    } @catch (__unused NSException *exception) {
        return NO;
    }
}

static BOOL DYYYAnyNativeDPlayerLongPressIsActive(void) {
    return DYYYNativeDPlayerLongPressIsActive(dyyyLongPressDPlayerSpeedController) ||
           DYYYNativeDPlayerLongPressIsActive(dyyyActiveDPlayerSpeedController);
}

static BOOL DYYYApplyPlaybackRateToNativeDPlayer(AWEDPlayerSpeedController *speedController, double speed) {
    if (!DYYYIsVerifiedNativeDPlayerSpeedController(speedController) ||
        !isfinite(speed) ||
        speed <= 0.0 ||
        DYYYAnyNativeDPlayerLongPressIsActive() ||
        DYYYNativeDPlayerLongPressIsActive(speedController)) {
        return NO;
    }

    @try {
        dyyyActiveDPlayerSpeedController = speedController;
        [speedController setPlaybackRate:(float)speed];
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[DYYY][Speed397] native setPlaybackRate failed on %@: %@",
              NSStringFromClass([speedController class]),
              exception.reason);
        return NO;
    }
}

static CGFloat DYYYViewControllerVisibilityScore(UIViewController *viewController) {
    if (!viewController || !viewController.isViewLoaded) {
        return -1.0;
    }

    UIView *view = viewController.view;
    UIWindow *window = view.window;
    if (!window || view.hidden || view.alpha <= 0.01 || CGRectIsEmpty(view.bounds)) {
        return -1.0;
    }

    CGRect frameInWindow = [view convertRect:view.bounds toView:window];
    CGRect visibleFrame = CGRectIntersection(frameInWindow, window.bounds);
    if (CGRectIsNull(visibleFrame) || CGRectIsEmpty(visibleFrame)) {
        return -1.0;
    }

    CGFloat visibleArea = CGRectGetWidth(visibleFrame) * CGRectGetHeight(visibleFrame);
    CGFloat totalArea = CGRectGetWidth(frameInWindow) * CGRectGetHeight(frameInWindow);
    CGFloat visibleRatio = totalArea > 0.0 ? visibleArea / totalArea : 0.0;
    CGPoint windowCenter = CGPointMake(CGRectGetMidX(window.bounds), CGRectGetMidY(window.bounds));
    CGFloat centerBonus = CGRectContainsPoint(visibleFrame, windowCenter) ? 1000000000.0 : 0.0;
    return centerBonus + visibleRatio * 1000000.0 + visibleArea;
}

static BOOL DYYYAwemeModelsMatch(AWEAwemeModel *lhs, AWEAwemeModel *rhs) {
    if (!lhs || !rhs) {
        return NO;
    }
    if (lhs == rhs) {
        return YES;
    }

    NSString *lhsItemID = lhs.itemID;
    NSString *rhsItemID = rhs.itemID;
    return lhsItemID.length > 0 && rhsItemID.length > 0 && [lhsItemID isEqualToString:rhsItemID];
}

static AWEAwemeModel *DYYYSpeedAwemeFromObject(id object) {
    Class awemeClass = NSClassFromString(@"AWEAwemeModel");
    if (!object || !awemeClass) {
        return nil;
    }
    if ([object isKindOfClass:awemeClass]) {
        return (AWEAwemeModel *)object;
    }

    for (NSString *key in @[ @"model", @"awemeModel", @"currentAweme" ]) {
        @try {
            id value = [object valueForKey:key];
            if ([value isKindOfClass:awemeClass]) {
                return (AWEAwemeModel *)value;
            }
        } @catch (NSException *exception) {
        }
    }
    return nil;
}

static NSArray<UIViewController *> *DYYYViewControllersInHierarchy(UIViewController *rootViewController) {
    if (!rootViewController) {
        return @[];
    }

    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray arrayWithObject:rootViewController];
    for (UIViewController *childViewController in rootViewController.childViewControllers) {
        [viewControllers addObjectsFromArray:DYYYViewControllersInHierarchy(childViewController)];
    }
    return viewControllers;
}

static NSArray<UIViewController *> *DYYYViewControllersInActiveWindowHierarchy(void) {
    UIWindow *window = [DYYYUtils getActiveWindow];
    UIViewController *rootViewController = window.rootViewController;
    NSMutableOrderedSet<UIViewController *> *viewControllers = [NSMutableOrderedSet orderedSet];
    while (rootViewController) {
        [viewControllers addObjectsFromArray:DYYYViewControllersInHierarchy(rootViewController)];
        rootViewController = rootViewController.presentedViewController;
    }
    return viewControllers.array;
}

static NSArray<AWEPlayInteractionViewController *> *DYYYPlaybackInteractionControllers(AWEPlayInteractionViewController *preferredController) {
    NSMutableArray<AWEPlayInteractionViewController *> *controllers = [NSMutableArray array];
    Class interactionControllerClass = NSClassFromString(@"AWEPlayInteractionViewController");

    for (UIViewController *viewController in DYYYViewControllersInActiveWindowHierarchy()) {
        if (interactionControllerClass && [viewController isKindOfClass:interactionControllerClass]) {
            [controllers addObject:(AWEPlayInteractionViewController *)viewController];
        }
    }
    if (preferredController && ![controllers containsObject:preferredController]) {
        [controllers addObject:preferredController];
    }
    return controllers;
}

static AWEPlayInteractionViewController *DYYYResolvePlaybackInteractionController(AWEPlayInteractionViewController *preferredController,
                                                                                  AWEAwemeModel *targetAweme,
                                                                                  BOOL allowVisibleFallback) {
    AWEPlayInteractionViewController *bestModelMatch = nil;
    AWEPlayInteractionViewController *bestVisibleController = nil;
    CGFloat bestModelMatchScore = -1.0;
    CGFloat bestVisibleScore = -1.0;

    for (AWEPlayInteractionViewController *controller in DYYYPlaybackInteractionControllers(preferredController)) {
        CGFloat visibilityScore = DYYYViewControllerVisibilityScore(controller);
        if (visibilityScore < 0.0) {
            continue;
        }
        if (visibilityScore > bestVisibleScore) {
            bestVisibleScore = visibilityScore;
            bestVisibleController = controller;
        }
        if (targetAweme && DYYYAwemeModelsMatch(controller.model, targetAweme) && visibilityScore > bestModelMatchScore) {
            bestModelMatchScore = visibilityScore;
            bestModelMatch = controller;
        }
    }
    return bestModelMatch ?: (allowVisibleFallback ? bestVisibleController : nil);
}

static void DYYYEnsureFloatSpeedButton(AWEPlayInteractionViewController *preferredController) {
    AWEPlayInteractionViewController *currentController =
        DYYYResolvePlaybackInteractionController(preferredController ?: dyyyActivePlaybackInteractionController,
                                                 dyyyCurrentSpeedAweme,
                                                 YES);
    if (!currentController) {
        updateSpeedButtonVisibility();
        return;
    }

    dyyyActivePlaybackInteractionController = currentController;
    if (!dyyyCurrentSpeedAweme && currentController.model) {
        dyyyCurrentSpeedAweme = currentController.model;
    }
    dyyyInteractionViewVisible = YES;

    if (!isFloatSpeedButtonEnabled) {
        if (speedButton) {
            speedButton.hidden = YES;
        }
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    CGFloat configuredSize = [defaults floatForKey:@"DYYYSpeedButtonSize"];
    speedButtonSize = configuredSize > 0.0 ? configuredSize : 35.0;
    showSpeedX = [defaults boolForKey:@"DYYYSpeedButtonShowX"];

    UIWindow *keyWindow = [DYYYUtils getActiveWindow];
    if (!keyWindow) {
        return;
    }

    if (!speedButton) {
        CGRect windowBounds = keyWindow.bounds;
        CGFloat initialY = CGRectGetHeight(windowBounds) * (1.0 - 0.65) - speedButtonSize / 2.0;
        initialY = MAX(10.0, MIN(initialY, CGRectGetHeight(windowBounds) - speedButtonSize - 10.0));
        CGRect initialFrame = CGRectMake(CGRectGetWidth(windowBounds) - speedButtonSize - 10.0,
                                         initialY,
                                         speedButtonSize,
                                         speedButtonSize);
        speedButton = [[FloatingSpeedButton alloc] initWithFrame:initialFrame];
        speedButton.interactionController = currentController;
        updateSpeedButtonUI();
    } else {
        if (speedButton.interactionController != currentController) {
            speedButton.interactionController = currentController;
        }
        if (fabs(CGRectGetWidth(speedButton.frame) - speedButtonSize) > 0.5) {
            speedButton.frame = CGRectMake(0, 0, speedButtonSize, speedButtonSize);
            speedButton.layer.cornerRadius = speedButtonSize / 2.0;
            [speedButton loadSavedPosition];
        }
    }

    if (![speedButton isDescendantOfView:keyWindow]) {
        [keyWindow addSubview:speedButton];
        [speedButton loadSavedPosition];
        [speedButton dyyy_schedulePresentationTimersIfNeeded];
    }

    [keyWindow bringSubviewToFront:speedButton];
    updateSpeedButtonUI();
    updateSpeedButtonVisibility();
}

void DYYYRefreshFloatSpeedButton(void) {
    dispatch_block_t refreshBlock = ^{
      DYYYEnsureFloatSpeedButton(dyyyActivePlaybackInteractionController);
    };
    if ([NSThread isMainThread]) {
        refreshBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), refreshBlock);
    }
}

static id DYYYBestVisiblePlaybackRateTarget(id preferredTarget) {
    if ([preferredTarget isKindOfClass:UIViewController.class] &&
        [preferredTarget respondsToSelector:@selector(setVideoControllerPlaybackRate:)] &&
        DYYYViewControllerVisibilityScore((UIViewController *)preferredTarget) >= 0.0) {
        return preferredTarget;
    }

    UIViewController *activePlayerViewController = dyyyActiveSpeedPlayerViewController;
    if (activePlayerViewController &&
        [activePlayerViewController respondsToSelector:@selector(setVideoControllerPlaybackRate:)] &&
        DYYYViewControllerVisibilityScore(activePlayerViewController) >= 0.0) {
        return activePlayerViewController;
    }

    UIViewController *bestPlayerViewController = nil;
    CGFloat bestVisibilityScore = -1.0;
    for (UIViewController *viewController in DYYYViewControllersInActiveWindowHierarchy()) {
        if ([viewController isKindOfClass:NSClassFromString(@"AWEAwemePlayVideoViewController")] ||
            [viewController isKindOfClass:NSClassFromString(@"AWEDPlayerFeedPlayerViewController")] ||
            [viewController isKindOfClass:NSClassFromString(@"AWEDPlayerViewController_Merge")]) {
            CGFloat visibilityScore = DYYYViewControllerVisibilityScore(viewController);
            if (visibilityScore > bestVisibilityScore) {
                bestVisibilityScore = visibilityScore;
                bestPlayerViewController = viewController;
            }
        }
    }
    return bestPlayerViewController;
}

static AWEDPlayerSpeedController *DYYYNativeDPlayerSpeedControllerFromFastSpeedController(id fastSpeedController) {
    if (DYYYIsVerifiedNativeDPlayerSpeedController(fastSpeedController)) {
        return (AWEDPlayerSpeedController *)fastSpeedController;
    }
    if (!fastSpeedController ||
        !DYYYSpeedMethodMatchesEncoding(fastSpeedController, @selector(dPlayerSpeed), "@16@0:8")) {
        return nil;
    }

    @try {
        id candidate = [(AWEPlayInteractionDPlayerSpeedController *)fastSpeedController dPlayerSpeed];
        return DYYYIsVerifiedNativeDPlayerSpeedController(candidate) ? (AWEDPlayerSpeedController *)candidate : nil;
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static AWEDPlayerSpeedController *DYYYNativeDPlayerSpeedControllerFromInteractionControllerOptions(AWEPlayInteractionViewController *interactionController,
                                                                                                  BOOL allowCachedController) {
    if (allowCachedController && dyyyActiveDPlayerSpeedController) {
        return dyyyActiveDPlayerSpeedController;
    }
    if (!interactionController || ![interactionController respondsToSelector:@selector(controllerByProtocol:)]) {
        return nil;
    }

    Protocol *speedControllerProtocol = NSProtocolFromString(@"AWEFastSpeedControllerProtocol");
    if (!speedControllerProtocol) {
        return nil;
    }

    @try {
        id fastSpeedController = [interactionController controllerByProtocol:speedControllerProtocol];
        return DYYYNativeDPlayerSpeedControllerFromFastSpeedController(fastSpeedController);
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static AWEDPlayerSpeedController *DYYYNativeDPlayerSpeedControllerFromInteractionController(AWEPlayInteractionViewController *interactionController) {
    return DYYYNativeDPlayerSpeedControllerFromInteractionControllerOptions(interactionController, YES);
}

static BOOL DYYYSetPlaybackRateOnTarget(id target, double speed) {
    if (DYYYAnyNativeDPlayerLongPressIsActive() ||
        !target ||
        ![target respondsToSelector:@selector(setVideoControllerPlaybackRate:)]) {
        return NO;
    }

    @try {
        [(AWEAwemePlayVideoViewController *)target setVideoControllerPlaybackRate:speed];
        if ([target isKindOfClass:UIViewController.class]) {
            dyyyActiveSpeedPlayerViewController = (UIViewController *)target;
        }
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[DYYY][DefaultSpeed] apply failed on %@: %@", NSStringFromClass([target class]), exception.reason);
        return NO;
    }
}

static BOOL DYYYIsImageAlbumAweme(AWEAwemeModel *model) {
    return model && [model respondsToSelector:@selector(awemeType)] && model.awemeType == 68;
}

static BOOL DYYYInteractionUsesRichContent(AWEPlayInteractionViewController *interactionController) {
    if (!interactionController) {
        return NO;
    }

    AWEPlayInteractionContext *context = interactionController.context;
    if (context.isInRichContentContainer || context.richContentContainer || interactionController.richContentContainer) {
        return YES;
    }

    id videoDelegate = interactionController.videoDelegate ?: context.videoDelegate;
    return [videoDelegate respondsToSelector:@selector(setAlbumFastPlaySpeed:)];
}

static BOOL DYYYShouldUseImageAlbumSpeedPath(AWEPlayInteractionViewController *interactionController) {
    AWEAwemeModel *model = interactionController.model ?: dyyyCurrentSpeedAweme;
    return DYYYIsImageAlbumAweme(model) || DYYYInteractionUsesRichContent(interactionController);
}

static void DYYYSyncNativeSpeedManagerCurrentSpeed(double speed) {
    AFDSpeedManager *speedManager = dyyyActiveNativeSpeedManager;
    if (!speedManager) {
        Class managerClass = NSClassFromString(@"AFDSpeedManager");
        if ([managerClass respondsToSelector:@selector(sharedInstance)]) {
            speedManager = [(id)managerClass sharedInstance];
        }
    }
    if ([speedManager respondsToSelector:@selector(setCurrentSpeed:)]) {
        [speedManager setCurrentSpeed:speed];
    }
}

static BOOL DYYYApplySpeedToAFDSlidesView(AFDSlidesView *slidesView, double speed) {
    if (!slidesView || !isfinite(speed) || speed <= 0.0) {
        return NO;
    }

    @try {
        BOOL useFastRate = fabs(speed - 1.0) > 0.001;
        slidesView.fastPlaySpeed = useFastRate ? speed : 1.0;
        slidesView.needFastPlay = useFastRate;
        if ([slidesView isPlaying]) {
            [slidesView pauseTimer];
            [slidesView setupAndPlayTimer];
        } else {
            [slidesView playTimer];
        }
        return YES;
    } @catch (NSException *exception) {
        NSLog(@"[DYYY][Speed] AFDSlidesView fastPlay apply failed: %@", exception.reason);
        return NO;
    }
}

static BOOL DYYYApplySpeedToAFDSlidesViewsInHierarchy(UIView *rootView, double speed) {
    if (!rootView) {
        return NO;
    }

    Class slidesViewClass = NSClassFromString(@"AFDSlidesView");
    if (!slidesViewClass) {
        return NO;
    }

    BOOL applied = NO;
    NSMutableArray<UIView *> *queue = [NSMutableArray arrayWithObject:rootView];
    while (queue.count > 0) {
        UIView *view = queue.firstObject;
        [queue removeObjectAtIndex:0];
        if ([view isKindOfClass:slidesViewClass] &&
            DYYYApplySpeedToAFDSlidesView((AFDSlidesView *)view, speed)) {
            applied = YES;
        }
        for (UIView *subview in view.subviews) {
            [queue addObject:subview];
        }
    }
    return applied;
}

static BOOL DYYYApplySpeedToVisibleAFDSlidesViews(AWEPlayInteractionViewController *interactionController,
                                                  id albumTarget,
                                                  double speed) {
    BOOL applied = NO;
    if (DYYYApplySpeedToAFDSlidesViewsInHierarchy(interactionController.view, speed)) {
        applied = YES;
    }
    if ([albumTarget isKindOfClass:UIViewController.class] &&
        DYYYApplySpeedToAFDSlidesViewsInHierarchy([(UIViewController *)albumTarget view], speed)) {
        applied = YES;
    }
    // 图文 slides 常挂在 interaction 覆盖层的兄弟子树，向上扩一层父视图再找。
    UIView *parentView = interactionController.view.superview;
    for (NSInteger depth = 0; parentView && depth < 4; depth++) {
        if (DYYYApplySpeedToAFDSlidesViewsInHierarchy(parentView, speed)) {
            applied = YES;
            break;
        }
        parentView = parentView.superview;
    }
    return applied;
}

static id DYYYRichContentAlbumSpeedTarget(AWEPlayInteractionViewController *interactionController) {
    if (!interactionController) {
        return nil;
    }

    AWEPlayInteractionContext *context = interactionController.context;
    id target = interactionController.richContentContainer ?: context.richContentContainer;
    if (!target) {
        target = interactionController.videoDelegate ?: context.videoDelegate;
    }
    return [target respondsToSelector:@selector(setAlbumFastPlaySpeed:)] ? target : nil;
}

static BOOL DYYYApplyImageAlbumPlaybackSpeed(AWEPlayInteractionViewController *interactionController, double speed) {
    if (!interactionController || !isfinite(speed) || speed <= 0.0 ||
        !DYYYShouldUseImageAlbumSpeedPath(interactionController)) {
        return NO;
    }

    BOOL applied = NO;
    BOOL useFastRate = fabs(speed - 1.0) > 0.001;
    DYYYSyncNativeSpeedManagerCurrentSpeed(speed);

    // 图文必须从当前 interaction 解析，避免复用上一个视频残留的 DPlayerSpeedController。
    AWEDPlayerSpeedController *dplayerSpeedController =
        DYYYNativeDPlayerSpeedControllerFromInteractionControllerOptions(interactionController, NO);
    if (dplayerSpeedController && [dplayerSpeedController respondsToSelector:@selector(speedContainer)]) {
        @try {
            AWEDSpeedCoreContainer *coreContainer = [dplayerSpeedController speedContainer];
            if (coreContainer.albumContainer) {
                [coreContainer.albumContainer changeAlbumSpeed:speed];
                applied = YES;
            }
            [coreContainer changeSpeed:speed];
            applied = YES;
        } @catch (NSException *exception) {
            NSLog(@"[DYYY][Speed] native album speed apply failed: %@", exception.reason);
        }
    }

    id albumTarget = DYYYRichContentAlbumSpeedTarget(interactionController);
    if (albumTarget) {
        @try {
            if ([albumTarget respondsToSelector:@selector(setAlbumFastPlaySpeed:enterMethod:)]) {
                [(id<AFDRichContentAlbumContainerProtocol>)albumTarget setAlbumFastPlaySpeed:speed
                                                                                 enterMethod:@"speed_button"];
            } else {
                [(id<AFDRichContentAlbumContainerProtocol>)albumTarget setAlbumFastPlaySpeed:speed];
            }
            // 配置写入后必须真正启用/关闭图文快播。
            // forcePlay:YES 会触发长按快进转场（拉伸/停顿/回弹）；这里用 forcePlay:NO 只驱动速率。
            if ([albumTarget respondsToSelector:@selector(setAlbumFastPlay:forcePlay:)]) {
                [(id<AFDRichContentAlbumContainerProtocol>)albumTarget setAlbumFastPlay:useFastRate
                                                                             forcePlay:NO];
            } else if ([albumTarget respondsToSelector:@selector(setAlbumFastPlay:)]) {
                [(id<AFDRichContentAlbumContainerProtocol>)albumTarget setAlbumFastPlay:useFastRate];
            }
            applied = YES;
        } @catch (NSException *exception) {
            NSLog(@"[DYYY][Speed] rich content album speed apply failed on %@: %@",
                  NSStringFromClass([albumTarget class]),
                  exception.reason);
        }
    }

    if (DYYYApplySpeedToVisibleAFDSlidesViews(interactionController, albumTarget, speed)) {
        applied = YES;
    }

    return applied;
}

static BOOL DYYYApplyPlaybackSpeedThroughInteractionController(AWEPlayInteractionViewController *interactionController, double speed) {
    if (!isfinite(speed) || speed <= 0.0) {
        return NO;
    }

    interactionController = DYYYResolvePlaybackInteractionController(interactionController, dyyyCurrentSpeedAweme, YES);
    if (!interactionController) {
        return DYYYSetPlaybackRateOnTarget(DYYYBestVisiblePlaybackRateTarget(nil), speed);
    }

    if (DYYYShouldUseImageAlbumSpeedPath(interactionController)) {
        return DYYYApplyImageAlbumPlaybackSpeed(interactionController, speed);
    }

    Protocol *speedControllerProtocol = NSProtocolFromString(@"AWEFastSpeedControllerProtocol");
    if (speedControllerProtocol && [interactionController respondsToSelector:@selector(controllerByProtocol:)]) {
        @try {
            id speedController = [interactionController controllerByProtocol:speedControllerProtocol];
            AWEDPlayerSpeedController *nativeDPlayerSpeedController =
                DYYYNativeDPlayerSpeedControllerFromFastSpeedController(speedController);
            if (nativeDPlayerSpeedController) {
                if (DYYYNativeDPlayerLongPressIsActive(nativeDPlayerSpeedController)) {
                    return NO;
                }
                return DYYYApplyPlaybackRateToNativeDPlayer(nativeDPlayerSpeedController, speed);
            }
            if ([speedController respondsToSelector:@selector(playVideoViewController)] &&
                DYYYSetPlaybackRateOnTarget([(AWEPlayInteractionSpeedController *)speedController playVideoViewController], speed)) {
                return YES;
            }
            if ([speedController respondsToSelector:@selector(changeSpeed:)] &&
                !DYYYAnyNativeDPlayerLongPressIsActive()) {
                [(AWEPlayInteractionSpeedController *)speedController changeSpeed:speed];
                return YES;
            }
        } @catch (NSException *exception) {
            NSLog(@"[DYYY][Speed] apply through speedController failed: %@", exception.reason);
        }
    }
    if ([interactionController respondsToSelector:@selector(videoDelegate)] &&
        DYYYSetPlaybackRateOnTarget([interactionController videoDelegate], speed)) {
        return YES;
    }
    return DYYYSetPlaybackRateOnTarget(DYYYBestVisiblePlaybackRateTarget(nil), speed);
}

static void DYYYApplyNormalPlaybackSpeedToNativeDPlayer(AWEDPlayerSpeedController *speedController) {
    if (!DYYYShouldHandleSpeedFeatures() || !speedController) {
        return;
    }

    void (^applyBlock)(void) = ^{
      DYYYApplyPlaybackRateToNativeDPlayer(speedController, DYYYNormalPlaybackSpeed());
    };
    if ([NSThread isMainThread]) {
        applyBlock();
    } else {
        __weak AWEDPlayerSpeedController *weakSpeedController = speedController;
        dispatch_async(dispatch_get_main_queue(), ^{
          DYYYApplyPlaybackRateToNativeDPlayer(weakSpeedController, DYYYNormalPlaybackSpeed());
        });
    }
}

static BOOL DYYYHandleNormalPlaybackSpeedWithMatchingNativeController(AWEDPlayerSpeedController *speedController,
                                                                      id playerViewController) {
    if (!DYYYIsVerifiedNativeDPlayerSpeedController(speedController) || !playerViewController) {
        return NO;
    }

    id nativePlayerViewController = nil;
    @try {
        nativePlayerViewController = [speedController playerViewController];
    } @catch (__unused NSException *exception) {
    }
    if (nativePlayerViewController != playerViewController) {
        return NO;
    }

    DYYYApplyPlaybackRateToNativeDPlayer(speedController, DYYYNormalPlaybackSpeed());
    return YES;
}

static void DYYYApplyNormalPlaybackSpeedToPlayerFallback(id playerViewController) {
    if (!DYYYShouldHandleSpeedFeatures() || !playerViewController) {
        return;
    }

    void (^applyBlock)(void) = ^{
      AWEPlayInteractionViewController *visibleInteractionController =
          DYYYResolvePlaybackInteractionController(dyyyActivePlaybackInteractionController,
                                                   dyyyCurrentSpeedAweme,
                                                   YES);
      AWEDPlayerSpeedController *visibleNativeSpeedController =
          DYYYNativeDPlayerSpeedControllerFromInteractionController(visibleInteractionController);
      if (DYYYHandleNormalPlaybackSpeedWithMatchingNativeController(visibleNativeSpeedController,
                                                                    playerViewController) ||
          DYYYHandleNormalPlaybackSpeedWithMatchingNativeController(dyyyActiveDPlayerSpeedController,
                                                                    playerViewController)) {
          return;
      }
      if (DYYYAnyNativeDPlayerLongPressIsActive()) {
          return;
      }
      DYYYSetPlaybackRateOnTarget(playerViewController, DYYYNormalPlaybackSpeed());
    };

    if ([NSThread isMainThread]) {
        applyBlock();
    } else {
        __weak id weakPlayerViewController = playerViewController;
        dispatch_async(dispatch_get_main_queue(), ^{
          id strongPlayerViewController = weakPlayerViewController;
          if (strongPlayerViewController) {
              DYYYApplyNormalPlaybackSpeedToPlayerFallback(strongPlayerViewController);
          }
        });
    }
}

static NSObject *DYYYCommentPauseViewModelRegistryLock(void) {
    static NSObject *lock = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      lock = [NSObject new];
    });
    return lock;
}

static void DYYYRegisterCommentPauseViewModel(_TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *viewModel) {
    if (!viewModel) {
        return;
    }

    @synchronized(DYYYCommentPauseViewModelRegistryLock()) {
        if (!dyyyCommentPauseViewModels) {
            dyyyCommentPauseViewModels = [NSHashTable weakObjectsHashTable];
        }
        [dyyyCommentPauseViewModels addObject:viewModel];
    }
}

static NSArray<_TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *> *DYYYRegisteredCommentPauseViewModels(void) {
    @synchronized(DYYYCommentPauseViewModelRegistryLock()) {
        return dyyyCommentPauseViewModels.allObjects ?: @[];
    }
}

static BOOL DYYYCommentViewModelIsPlaying(_TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *viewModel) {
    if (!viewModel || ![viewModel respondsToSelector:@selector(isFeedVideoPlaying)]) {
        return NO;
    }

    @try {
        return [viewModel isFeedVideoPlaying];
    } @catch (NSException *exception) {
        return NO;
    }
}

static CGFloat DYYYCommentViewModelScore(_TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *viewModel) {
    CGFloat score = 0.0;
    id playerController = nil;
    @try {
        if ([viewModel respondsToSelector:@selector(feedVideoPlayerController)]) {
            playerController = [viewModel feedVideoPlayerController];
        }
    } @catch (NSException *exception) {
        return score;
    }

    AWEAwemeModel *viewModelAweme = DYYYSpeedAwemeFromObject(playerController);
    if (DYYYAwemeModelsMatch(viewModelAweme, dyyyCurrentSpeedAweme)) {
        score += 1000000000000.0;
    }
    if ([playerController isKindOfClass:[UIViewController class]]) {
        CGFloat visibilityScore = DYYYViewControllerVisibilityScore((UIViewController *)playerController);
        if (visibilityScore >= 0.0) {
            score += visibilityScore;
        }
    }
    return score;
}

static _TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *DYYYCurrentPlayingCommentViewModel(void) {
    _TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *bestViewModel = nil;
    CGFloat bestScore = -CGFLOAT_MAX;
    for (_TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *viewModel in DYYYRegisteredCommentPauseViewModels()) {
        if (!DYYYCommentViewModelIsPlaying(viewModel)) {
            continue;
        }

        CGFloat score = DYYYCommentViewModelScore(viewModel);
        if (viewModel == dyyyLastCommentPauseViewModel) {
            score += 1.0;
        }
        if (!bestViewModel || score > bestScore) {
            bestViewModel = viewModel;
            bestScore = score;
        }
    }
    return bestViewModel;
}

static void DYYYCommentPausePlaybackIfNeeded(void) {
    if (!dyyyCommentViewVisible || !DYYYGetBool(@"DYYYCommentPausePlayback")) {
        return;
    }

    _TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *viewModel = DYYYCurrentPlayingCommentViewModel();
    if (!viewModel || ![viewModel respondsToSelector:@selector(pauseVideoIfPlayingWithoutShowingPauseIcon)]) {
        return;
    }

    @try {
        // This native entry owns the comment pause state used by media-preview
        // parameters. Recovery remains with the original comment lifecycle.
        [viewModel pauseVideoIfPlayingWithoutShowingPauseIcon];
        dyyyLastCommentPauseViewModel = viewModel;
    } @catch (NSException *exception) {
        NSLog(@"[DYYY][CommentPause] native pause failed on %@: %@", NSStringFromClass([viewModel class]), exception.reason);
    }
}

static BOOL DYYYCommentContainerSkipsPanelLifecycle(AWECommentContainerViewController *commentViewController) {
    if (!commentViewController || ![commentViewController respondsToSelector:@selector(state)]) {
        return NO;
    }

    @try {
        _TtC33AWECommentPanelContainerSwiftImpl31CommentViewControllerStateModel *state = [commentViewController state];
        if (!state || ![state respondsToSelector:@selector(isSkipCommentPanelLifecycle)]) {
            return NO;
        }
        return [state isSkipCommentPanelLifecycle];
    } @catch (NSException *exception) {
        return NO;
    }
}

static void DYYYCommentRecoverPlaybackIfNeeded(_TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *viewModel) {
    if (!viewModel || ![viewModel respondsToSelector:@selector(recoverPlayIfPauseByComment)]) {
        return;
    }

    @try {
        [viewModel recoverPlayIfPauseByComment];
    } @catch (NSException *exception) {
        NSLog(@"[DYYY][CommentPause] native recovery failed on %@: %@", NSStringFromClass([viewModel class]), exception.reason);
    }

    if (dyyyLastCommentPauseViewModel == viewModel) {
        dyyyLastCommentPauseViewModel = nil;
    }
}

static BOOL DYYYCommentPauseOwnsPlayback(void) {
    return DYYYGetBool(@"DYYYCommentPausePlayback") && dyyyLastCommentPauseViewModel != nil;
}

static void DYYYHandleCurrentAwemeChanged(id aweme) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          DYYYHandleCurrentAwemeChanged(aweme);
        });
        return;
    }

    AWEAwemeModel *currentAweme = DYYYSpeedAwemeFromObject(aweme);
    if (currentAweme) {
        dyyyCurrentSpeedAweme = currentAweme;
    }
}

static void DYYYHandleCommittedSpeedAwemeChanged(id aweme) {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          DYYYHandleCommittedSpeedAwemeChanged(aweme);
        });
        return;
    }

    AWEAwemeModel *currentAweme = DYYYSpeedAwemeFromObject(aweme);
    if (!currentAweme) {
        return;
    }

    NSString *itemID = currentAweme.itemID;
    BOOL hasStableIdentifier = itemID.length > 0;
    BOOL isNewCommittedAweme = hasStableIdentifier
                                   ? ![dyyyCommittedSpeedAwemeIdentifier isEqualToString:itemID]
                                   : !DYYYAwemeModelsMatch(dyyyCurrentSpeedAweme, currentAweme);

    dyyyCurrentSpeedAweme = currentAweme;
    if (hasStableIdentifier) {
        dyyyCommittedSpeedAwemeIdentifier = [itemID copy];
    }

    if (isNewCommittedAweme) {
        if (isFloatSpeedButtonEnabled &&
            [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"]) {
            setCurrentSpeedIndex(0);
            updateSpeedButtonUI();
        }
    }
}

static void DYYYScheduleCurrentAwemeTracking(id source, id fallbackAweme) {
    __weak id weakSource = source;
    void (^trackingBlock)(void) = ^{
      AWEPlayInteractionViewController *visibleController = DYYYResolvePlaybackInteractionController(nil, nil, YES);
      if (!visibleController) {
          return;
      }
      AWEAwemeModel *candidateAweme = DYYYSpeedAwemeFromObject(weakSource);
      if (!DYYYAwemeModelsMatch(candidateAweme, visibleController.model)) {
          candidateAweme = DYYYSpeedAwemeFromObject(fallbackAweme);
      }
      if (DYYYAwemeModelsMatch(candidateAweme, visibleController.model)) {
          DYYYHandleCurrentAwemeChanged(candidateAweme);
      }
    };
    dispatch_async(dispatch_get_main_queue(), trackingBlock);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), trackingBlock);
}

@interface AWEFeedProgressSlider (DYYYProgressLabel)
- (NSString *)dyyy_formatTimeFromSeconds:(CGFloat)seconds;
- (CGFloat)dyyy_modelDurationInSeconds;
- (CGFloat)dyyy_scheduleVerticalOffset;
- (void)dyyy_removeScheduleLabels;
- (void)dyyy_updateScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration;
@end

@interface AWEPlayInteractionProgressController (DYYYProgressLabel)
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration;
@end

@interface AWEDProgressCoreContainer (DYYYProgressLabel)
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration;
@end

@interface UIView (DYYYProgressLabelLegacy)
- (void)dyyy_updateScheduleLabelsLegacyWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration model:(id)model;
@end

@implementation UIView (DYYYProgressLabelLegacy)

- (NSString *)dyyy_legacyFormatTimeFromSeconds:(CGFloat)seconds {
    CGFloat safeSeconds = seconds;
    if (safeSeconds < 0) {
        safeSeconds = 0;
    }

    NSInteger total = (NSInteger)floor(safeSeconds);
    NSInteger hours = total / 3600;
    NSInteger minutes = (total % 3600) / 60;
    NSInteger secs = total % 60;

    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
}

- (CGFloat)dyyy_legacyScheduleVerticalOffset {
    CGFloat verticalOffset = -12.5;
    NSString *offsetValueString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimelineVerticalPosition"];
    if (offsetValueString.length > 0) {
        CGFloat configuredOffset = [offsetValueString floatValue];
        if (configuredOffset != 0) {
            verticalOffset = configuredOffset;
        }
    }
    return verticalOffset;
}

- (CGFloat)dyyy_legacyModelDurationInSeconds:(id)model {
    if (!model || ![model respondsToSelector:@selector(videoDuration)]) {
        return 0;
    }

    CGFloat videoDurationMs = [[model valueForKey:@"videoDuration"] doubleValue];
    if (videoDurationMs <= 0) {
        return 0;
    }
    return videoDurationMs / 1000.0;
}

- (void)dyyy_updateScheduleLabelsLegacyWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration model:(id)model {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        UIView *parentView = self.superview;
        if (parentView) {
            [[parentView viewWithTag:10001] removeFromSuperview];
            [[parentView viewWithTag:10002] removeFromSuperview];
        }
        return;
    }

    if (![NSThread isMainThread]) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf dyyy_updateScheduleLabelsLegacyWithCurrentTime:currentTime totalDuration:totalDuration model:model];
        });
        return;
    }

    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }
    [parentView layoutIfNeeded];
    [self layoutIfNeeded];

    NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
    BOOL showRightRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
    BOOL showRightCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
    BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
    BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

    BOOL shouldShowLeftLabel = !showRightRemainingTime && !showRightCompleteTime;
    BOOL shouldShowRightLabel = !showLeftRemainingTime && !showLeftCompleteTime;

    CGFloat modelDuration = [self dyyy_legacyModelDurationInSeconds:model];
    CGFloat effectiveTotalDuration = totalDuration > 0 ? totalDuration : modelDuration;
    if (effectiveTotalDuration < 0) {
        effectiveTotalDuration = 0;
    }

    CGFloat effectiveCurrentTime = currentTime;
    if (effectiveCurrentTime < 0) {
        effectiveCurrentTime = 0;
    }
    if (effectiveTotalDuration > 0 && effectiveCurrentTime > effectiveTotalDuration) {
        effectiveCurrentTime = effectiveTotalDuration;
    }

    CGRect sliderFrameInParent = [self convertRect:self.bounds toView:parentView];
    if (CGRectGetWidth(sliderFrameInParent) <= 1.0 || CGRectGetHeight(sliderFrameInParent) <= 1.0) {
        return;
    }
    CGFloat labelYPosition = CGRectGetMinY(sliderFrameInParent) + [self dyyy_legacyScheduleVerticalOffset];
    CGFloat labelHeight = 15.0;
    UIFont *labelFont = [UIFont systemFontOfSize:8];
    NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];

    UILabel *leftLabel = (UILabel *)[parentView viewWithTag:10001];
    if (leftLabel && ![leftLabel isKindOfClass:[UILabel class]]) {
        [leftLabel removeFromSuperview];
        leftLabel = nil;
    }

    if (shouldShowLeftLabel) {
        if (!leftLabel) {
            leftLabel = [[UILabel alloc] init];
            leftLabel.backgroundColor = [UIColor clearColor];
            leftLabel.tag = 10001;
            [parentView addSubview:leftLabel];
        }
        leftLabel.font = labelFont;

        NSString *newLeftText = nil;
        if (showLeftRemainingTime) {
            newLeftText = [self dyyy_legacyFormatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showLeftCompleteTime) {
            newLeftText = [NSString stringWithFormat:@"%@/%@", [self dyyy_legacyFormatTimeFromSeconds:effectiveCurrentTime], [self dyyy_legacyFormatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newLeftText = [self dyyy_legacyFormatTimeFromSeconds:effectiveCurrentTime];
        }

        if (![leftLabel.text isEqualToString:newLeftText]) {
            leftLabel.text = newLeftText;
        }
        [leftLabel sizeToFit];
        leftLabel.frame = CGRectMake(CGRectGetMinX(sliderFrameInParent), labelYPosition, CGRectGetWidth(leftLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:leftLabel colorHexString:labelColorHex];
    } else {
        [leftLabel removeFromSuperview];
    }

    UILabel *rightLabel = (UILabel *)[parentView viewWithTag:10002];
    if (rightLabel && ![rightLabel isKindOfClass:[UILabel class]]) {
        [rightLabel removeFromSuperview];
        rightLabel = nil;
    }

    if (shouldShowRightLabel) {
        if (!rightLabel) {
            rightLabel = [[UILabel alloc] init];
            rightLabel.backgroundColor = [UIColor clearColor];
            rightLabel.tag = 10002;
            [parentView addSubview:rightLabel];
        }
        rightLabel.font = labelFont;

        NSString *newRightText = nil;
        if (showRightRemainingTime) {
            newRightText = [self dyyy_legacyFormatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showRightCompleteTime) {
            newRightText = [NSString stringWithFormat:@"%@/%@", [self dyyy_legacyFormatTimeFromSeconds:effectiveCurrentTime], [self dyyy_legacyFormatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newRightText = [self dyyy_legacyFormatTimeFromSeconds:effectiveTotalDuration];
        }

        if (![rightLabel.text isEqualToString:newRightText]) {
            rightLabel.text = newRightText;
        }
        [rightLabel sizeToFit];
        CGFloat rightLabelX = MAX(CGRectGetMaxX(sliderFrameInParent) - CGRectGetWidth(rightLabel.bounds), CGRectGetMinX(sliderFrameInParent));
        rightLabel.frame = CGRectMake(rightLabelX, labelYPosition, CGRectGetWidth(rightLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:rightLabel colorHexString:labelColorHex];
    } else {
        [rightLabel removeFromSuperview];
    }
}

@end

// 关闭不可见水印
%hook AWEHPChannelInvisibleWaterMarkModel

- (BOOL)isEnter {
    return NO;
}

- (BOOL)isAppear {
    return NO;
}

%end

// 长按复制个人简介
%hook AWEProfileMentionLabel

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYBioCopyText")) {
        return;
    }

    BOOL hasLongPressGesture = NO;
    for (UIGestureRecognizer *gesture in self.gestureRecognizers) {
        if ([gesture isKindOfClass:[UILongPressGestureRecognizer class]]) {
            hasLongPressGesture = YES;
            break;
        }
    }

    if (!hasLongPressGesture) {
        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPressGesture.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPressGesture];
        self.userInteractionEnabled = YES;
    }
}

%new
- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSString *bioText = self.text;
        if (bioText && bioText.length > 0) {
            [[UIPasteboard generalPasteboard] setString:bioText];
            [DYYYToast showSuccessToastWithMessage:@"个人简介已复制"];
        }
    }
}

%end

// 抖音 39.1.0 访问他人主页时会由详情组件直接上传访客记录
%hook AWEProfileUserDetailComponent

- (void)reportUserDetailVisitIfNeeded:(id)user {
    if ([DYYYPrivacyRecordUploadGuard isProfileVisitRecordUploadDisabled]) {
        return;
    }

    %orig;
}

%end

// 兼容旧版访客记录上传路径
%hook AWEProfileRecordHelper

+ (void)postProfileRecordWithParams:(id)params {
    if ([DYYYPrivacyRecordUploadGuard isProfileVisitRecordUploadDisabled]) {
        return;
    }

    %orig;
}

+ (void)postProfileRecordWithParams:(id)params completionBlock:(id)completionBlock {
    if ([DYYYPrivacyRecordUploadGuard isProfileVisitRecordUploadDisabled]) {
        return;
    }

    %orig;
}

+ (void)postProfileRecordWithKey:(id)key valueDic:(id)valueDic {
    if ([DYYYPrivacyRecordUploadGuard isProfileVisitRecordUploadDisabled]) {
        return;
    }

    %orig;
}

+ (void)postProfileRecordWithKey:(id)key valueDic:(id)valueDic completionBlock:(id)completionBlock {
    if ([DYYYPrivacyRecordUploadGuard isProfileVisitRecordUploadDisabled]) {
        return;
    }

    %orig;
}

%end

// 抖音 39.7.0：作品浏览记录由 AFDPlayerAndInteractionService 上报至
// /aweme/v1/familiar/video/stats/（scene 常见值 FeedVideoViewedDedicatedStats）
%hook AFDPlayerAndInteractionService

- (void)statisticsVideoViewedWithID:(NSString *)itemID scene:(NSString *)scene {
    if ([DYYYPrivacyRecordUploadGuard isAwemeViewRecordUploadDisabled]) {
        return;
    }

    %orig;
}

- (void)statisticsVideoViewedWithID:(NSString *)itemID
                           authorID:(NSString *)authorID
                       followStatus:(long long)followStatus
                     followerStatus:(long long)followerStatus
                            isStory:(BOOL)isStory
                  isRequestDirectly:(BOOL)isRequestDirectly
                              scene:(NSString *)scene {
    if ([DYYYPrivacyRecordUploadGuard isAwemeViewRecordUploadDisabled]) {
        return;
    }

    %orig;
}

%end

static BOOL DYYYTryBlockPrivacyNetworkRequest(NSString *URLString, id completion) {
    if (![DYYYPrivacyRecordUploadGuard shouldBlockURLString:URLString]) {
        return NO;
    }

    [DYYYPrivacyRecordUploadGuard invokeCancelledCompletionIfPossible:completion];
    return YES;
}

%hook AWENetworkService

+ (id)postWithURLString:(NSString *)URLString params:(id)params completion:(id)completion {
    if (DYYYTryBlockPrivacyNetworkRequest(URLString, completion)) {
        return nil;
    }
    return %orig;
}

+ (id)getWithURLString:(NSString *)URLString params:(id)params completion:(id)completion {
    if (DYYYTryBlockPrivacyNetworkRequest(URLString, completion)) {
        return nil;
    }
    return %orig;
}

+ (id)requestWithURLString:(NSString *)URLString params:(id)params method:(id)method completion:(id)completion {
    if (DYYYTryBlockPrivacyNetworkRequest(URLString, completion)) {
        return nil;
    }
    return %orig;
}

+ (id)postWithURLString:(NSString *)URLString params:(id)params headerField:(id)headerField completion:(id)completion {
    if (DYYYTryBlockPrivacyNetworkRequest(URLString, completion)) {
        return nil;
    }
    return %orig;
}

+ (id)getWithURLString:(NSString *)URLString params:(id)params headerField:(id)headerField completion:(id)completion {
    if (DYYYTryBlockPrivacyNetworkRequest(URLString, completion)) {
        return nil;
    }
    return %orig;
}

%end

%hook TTNetworkManager

- (id)requestForJSONWithURL:(NSString *)url
                     params:(id)params
                     method:(NSString *)method
           needCommonParams:(BOOL)needCommonParams
                headerField:(id)headerField
          requestSerializer:(Class)requestSerializerClass
         responseSerializer:(Class)responseSerializerClass
                 autoResume:(BOOL)autoResume
                   callback:(id)callback {
    if (DYYYTryBlockPrivacyNetworkRequest(url, callback)) {
        return nil;
    }
    return %orig;
}

- (id)requestForJSONWithResponse:(NSString *)url
                          params:(id)params
                          method:(NSString *)method
                needCommonParams:(BOOL)needCommonParams
                     headerField:(id)headerField
               requestSerializer:(Class)requestSerializerClass
              responseSerializer:(Class)responseSerializerClass
                      autoResume:(BOOL)autoResume
                        callback:(id)callback {
    if (DYYYTryBlockPrivacyNetworkRequest(url, callback)) {
        return nil;
    }
    return %orig;
}

- (id)requestForBinaryWithResponse:(NSString *)url
                            params:(id)params
                            method:(NSString *)method
                  needCommonParams:(BOOL)needCommonParams
                       headerField:(id)headerField
                          callback:(id)callback {
    if (DYYYTryBlockPrivacyNetworkRequest(url, callback)) {
        return nil;
    }
    return %orig;
}

%end

static BOOL DYYYShouldSkipPrivacyRecordTaskStart(id task) {
    BOOL shouldBlock = [DYYYPrivacyRecordUploadGuard isTaskMarkedForBlocking:task] ||
                       [DYYYPrivacyRecordUploadGuard shouldBlockRequestObject:task];
    if (!shouldBlock) {
        return NO;
    }

    // 即使任务对象不支持 cancel，也必须阻止原始启动，避免隐私请求继续发出。
    (void)[DYYYPrivacyRecordUploadGuard cancelTaskIfPossible:task];
    return YES;
}

%hook TTHttpTask

- (void)resume {
    if (DYYYShouldSkipPrivacyRecordTaskStart(self)) {
        return;
    }

    %orig;
}

%end

%hook TTHttpTaskChromium

- (void)runRequestFiltersAndStart {
    if (DYYYShouldSkipPrivacyRecordTaskStart(self)) {
        return;
    }

    %orig;
}

- (void)resume {
    if (DYYYShouldSkipPrivacyRecordTaskStart(self)) {
        return;
    }

    %orig;
}

%end

%hook TTConcurrentHttpTask

- (void)resume {
    if (DYYYShouldSkipPrivacyRecordTaskStart(self)) {
        return;
    }

    %orig;
}

%end

%hook NSURLSessionTask

- (void)resume {
    if (DYYYShouldSkipPrivacyRecordTaskStart(self)) {
        return;
    }

    %orig;
}

%end

%hook NSURLSession

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url {
    NSURLSessionDataTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:url];
    return task;
}

- (NSURLSessionDataTask *)dataTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURLSessionDataTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:url];
    return task;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request {
    NSURLSessionDataTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionDataTask *)dataTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURLSessionDataTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url {
    NSURLSessionDownloadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:url];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithURL:(NSURL *)url completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler {
    NSURLSessionDownloadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:url];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request {
    NSURLSessionDownloadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionDownloadTask *)downloadTaskWithRequest:(NSURLRequest *)request completionHandler:(void (^)(NSURL *location, NSURLResponse *response, NSError *error))completionHandler {
    NSURLSessionDownloadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData {
    NSURLSessionUploadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromData:(NSData *)bodyData completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURLSessionUploadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL {
    NSURLSessionUploadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionUploadTask *)uploadTaskWithRequest:(NSURLRequest *)request fromFile:(NSURL *)fileURL completionHandler:(void (^)(NSData *data, NSURLResponse *response, NSError *error))completionHandler {
    NSURLSessionUploadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

- (NSURLSessionUploadTask *)uploadTaskWithStreamedRequest:(NSURLRequest *)request {
    NSURLSessionUploadTask *task = %orig;
    [DYYYPrivacyRecordUploadGuard markTaskForBlockingIfNeeded:task requestObject:request];
    return task;
}

%end

@interface AWENowPlayingInfoCenter : NSObject
@property(nonatomic, weak) id playingPlayer;
@end

@interface MPNowPlayingInfoCenter : NSObject
@property(nonatomic, copy) NSDictionary *nowPlayingInfo;
+ (instancetype)defaultCenter;
@end

static BOOL dyyyClearingFeedNowPlayingSystemInfo = NO;
static CFTimeInterval dyyyLastFeedNowPlayingSystemClearTime = 0.0;

static void DYYYClearFeedNowPlayingSystemInfo(BOOL ignoreThrottle) {
    if (dyyyClearingFeedNowPlayingSystemInfo) {
        return;
    }

    CFTimeInterval currentTime = CFAbsoluteTimeGetCurrent();
    if (!ignoreThrottle && currentTime - dyyyLastFeedNowPlayingSystemClearTime < 0.25) {
        return;
    }
    dyyyLastFeedNowPlayingSystemClearTime = currentTime;

    Class nowPlayingInfoCenterClass = NSClassFromString(@"MPNowPlayingInfoCenter");
    if (!nowPlayingInfoCenterClass || ![nowPlayingInfoCenterClass respondsToSelector:@selector(defaultCenter)]) {
        return;
    }

    id center = ((id (*)(Class, SEL))objc_msgSend)(nowPlayingInfoCenterClass, @selector(defaultCenter));
    if (!center) {
        return;
    }

    dyyyClearingFeedNowPlayingSystemInfo = YES;
    @try {
        if ([center respondsToSelector:@selector(setNowPlayingInfo:)]) {
            ((void (*)(id, SEL, id))objc_msgSend)(center, @selector(setNowPlayingInfo:), nil);
        }

        SEL setPlaybackStateSelector = NSSelectorFromString(@"setPlaybackState:");
        if ([center respondsToSelector:setPlaybackStateSelector]) {
            ((void (*)(id, SEL, NSInteger))objc_msgSend)(center, setPlaybackStateSelector, 0);
        }
    } @catch (__unused NSException *exception) {
    } @finally {
        dyyyClearingFeedNowPlayingSystemInfo = NO;
    }
}

static void DYYYClearFeedNowPlayingSystemInfoThrottled(void) {
    if (!DYYYGetBool(DYYY_DISABLE_FEED_NOW_PLAYING_INFO_KEY)) {
        return;
    }

    DYYYClearFeedNowPlayingSystemInfo(NO);
}

static id DYYYSharedInstanceForClass(Class cls) {
    if (!cls) {
        return nil;
    }

    for (NSString *selectorName in @[ @"sharedManager", @"sharedInstance", @"defaultCenter", @"shared", @"defaultManager" ]) {
        SEL selector = NSSelectorFromString(selectorName);
        if ([cls respondsToSelector:selector]) {
            id instance = ((id (*)(Class, SEL))objc_msgSend)(cls, selector);
            if (instance) {
                return instance;
            }
        }
    }

    return nil;
}

static void DYYYRefreshFeedNowPlayingInfoFromDouyin(void) {
    for (NSString *className in @[ @"AWEFeedBackgroundPlayManager", @"AWENowPlayingInfoCenter", @"AWEAwemeBackgroundPlayModule" ]) {
        id instance = DYYYSharedInstanceForClass(NSClassFromString(className));
        if (!instance) {
            continue;
        }

        SEL forceRefreshSelector = @selector(refreshNowPlayingInfoIsForce:);
        if ([instance respondsToSelector:forceRefreshSelector]) {
            ((void (*)(id, SEL, BOOL))objc_msgSend)(instance, forceRefreshSelector, YES);
        }

        SEL refreshSelector = @selector(refreshNowPlayingInfo);
        if ([instance respondsToSelector:refreshSelector]) {
            ((void (*)(id, SEL))objc_msgSend)(instance, refreshSelector);
        }

        SEL refreshIfNeededSelector = @selector(refreshNowPlayingInfoIfNeeded);
        if ([instance respondsToSelector:refreshIfNeededSelector]) {
            ((void (*)(id, SEL))objc_msgSend)(instance, refreshIfNeededSelector);
        }

        SEL updatePlaybackSelector = @selector(updateNowPlayingInfoPlayback);
        if ([instance respondsToSelector:updatePlaybackSelector]) {
            ((void (*)(id, SEL))objc_msgSend)(instance, updatePlaybackSelector);
        }
    }
}

void DYYYApplyFeedNowPlayingSettingChange(BOOL disableNowPlayingInfo) {
    dispatch_async(dispatch_get_main_queue(), ^{
        if (disableNowPlayingInfo) {
            DYYYClearFeedNowPlayingSystemInfo(YES);
            return;
        }

        DYYYRefreshFeedNowPlayingInfoFromDouyin();
    });
}

static BOOL DYYYShouldBlockFeedNowPlayingSystemInfoWrite(void) {
    return DYYYGetBool(DYYY_DISABLE_FEED_NOW_PLAYING_INFO_KEY) && !dyyyClearingFeedNowPlayingSystemInfo;
}

%hook AWEAwemeBackgroundPlayModule

- (id)nowPlayingInfo {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return nil;
    }

    return %orig;
}

- (void)refreshNowPlayingInfoIfNeeded {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

- (void)updateNowPlayingInfoPlayback {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

%end

%hook AWEFeedBackgroundPlayManager

- (id)nowPlayingInfo {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return nil;
    }

    return %orig;
}

- (void)setNowPlayingInfo:(id)nowPlayingInfo {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

- (void)resetNowPlayingInfo:(id)model {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

- (void)refreshNowPlayingInfo {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

- (void)refreshNowPlayingInfoIsForce:(BOOL)isForce {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

- (void)updateNowPlayingInfoPlayback {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

%end

// 写入播放中心时清空系统 Now Playing，不再走宿主写入路径。
%hook AWENowPlayingInfoCenter

- (void)becomePlayingPlayer:(id)player {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

- (void)setNowPlayingInfo:(id)nowPlayingInfo {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

- (void)refreshNowPlayingInfo {
    if (DYYYGetBool(@"DYYYDisableFeedNowPlayingInfo")) {
        DYYYClearFeedNowPlayingSystemInfoThrottled();
        return;
    }

    %orig;
}

%end

// 耳机或系统媒体会话可能绕过抖音播放中心，最终都要写入 MPNowPlayingInfoCenter。
%hook MPNowPlayingInfoCenter

- (void)setNowPlayingInfo:(NSDictionary *)nowPlayingInfo {
    if (DYYYShouldBlockFeedNowPlayingSystemInfoWrite()) {
        %orig(nil);
        return;
    }

    %orig;
}

- (void)setPlaybackState:(NSInteger)playbackState {
    if (DYYYShouldBlockFeedNowPlayingSystemInfoWrite()) {
        %orig(0);
        return;
    }

    %orig;
}

%end

static BOOL DYYYShouldDisableAllHDR(void);
static NSArray *DYYYFilteredSDRBitrateModels(NSArray *models);
static NSArray *DYYYFilteredSDRRawBitrateData(NSArray *rawData);
static void DYYYStripHDRHintsFromBitrateModels(NSArray *models);

// 读取单个码率档位的比特率；档位类型不符或字段缺失时返回 -1，排序时会被沉到末尾。
static NSInteger DYYYBitrateForBitrateModel(id model) {
    Class bitrateModelClass = %c(AWEVideoBSModel);
    if (!bitrateModelClass || ![model isKindOfClass:bitrateModelClass]) {
        return -1;
    }

    id bitrateValue = [model bitrate];
    return bitrateValue ? [bitrateValue integerValue] : -1;
}

// 默认视频流最高画质
%hook AWEVideoModel

- (AWEURLModel *)playURL {
    if (!DYYYGetBoolCached(@"DYYYEnableVideoHighestQuality")) {
        return %orig;
    }

    // 获取比特率模型数组
    NSArray *bitrateModels = [self bitrateModels];
    if (!bitrateModels || bitrateModels.count == 0) {
        return %orig;
    }

    // 查找比特率最高的模型
    id highestBitrateModel = nil;
    NSInteger highestBitrate = 0;

    for (id model in bitrateModels) {
        NSInteger bitrate = DYYYBitrateForBitrateModel(model);
        if (bitrate >= 0 && bitrate > highestBitrate) {
            highestBitrate = bitrate;
            highestBitrateModel = model;
        }
    }

    // 如果找到了最高比特率模型，获取其播放地址
    if (highestBitrateModel) {
        id playAddr = [highestBitrateModel valueForKey:@"playAddr"];
        if (playAddr && [playAddr isKindOfClass:%c(AWEURLModel)]) {
            return playAddr;
        }
    }

    return %orig;
}

- (NSArray *)bitrateModels {
    NSArray *originalModels = %orig;

    if (DYYYShouldDisableAllHDR()) {
        NSArray *filteredModels = DYYYFilteredSDRBitrateModels(originalModels);
        DYYYStripHDRHintsFromBitrateModels(filteredModels);
        originalModels = filteredModels;
    }

    if (!DYYYGetBoolCached(@"DYYYEnableVideoHighestQuality")) {
        return originalModels;
    }

    if (originalModels.count < 2) {
        return originalModels;
    }

    // 按比特率降序排列，最高画质档位置于首位。
    // 这里刻意保留完整档位表而不裁剪成单档：只留最高码率会让播放器在带宽下滑时无档可退，
    // 只能停在原地反复重缓冲，表现为播放中途卡住。保留低码率档后仍可自适应降级。
    return [originalModels sortedArrayWithOptions:NSSortStable
                                  usingComparator:^NSComparisonResult(id lhs, id rhs) {
                                    NSInteger leftBitrate = DYYYBitrateForBitrateModel(lhs);
                                    NSInteger rightBitrate = DYYYBitrateForBitrateModel(rhs);
                                    if (leftBitrate == rightBitrate) {
                                        return NSOrderedSame;
                                    }
                                    return leftBitrate > rightBitrate ? NSOrderedAscending : NSOrderedDescending;
                                  }];
}

- (void)setBitrateModels:(NSArray *)bitrateModels {
    if (DYYYShouldDisableAllHDR()) {
        NSArray *filteredModels = DYYYFilteredSDRBitrateModels(bitrateModels);
        DYYYStripHDRHintsFromBitrateModels(filteredModels);
        %orig(filteredModels);
        return;
    }
    %orig;
}

- (void)setManualBitrateModels:(NSArray *)manualBitrateModels {
    if (DYYYShouldDisableAllHDR()) {
        NSArray *filteredModels = DYYYFilteredSDRBitrateModels(manualBitrateModels);
        DYYYStripHDRHintsFromBitrateModels(filteredModels);
        %orig(filteredModels);
        return;
    }
    %orig;
}

- (NSArray *)manualBitrateModels {
    NSArray *models = %orig;
    if (DYYYShouldDisableAllHDR()) {
        models = DYYYFilteredSDRBitrateModels(models);
        DYYYStripHDRHintsFromBitrateModels(models);
    }
    return models;
}

- (void)setBitrateRawData:(NSArray *)bitrateRawData {
    if (DYYYShouldDisableAllHDR()) {
        %orig(DYYYFilteredSDRRawBitrateData(bitrateRawData));
        return;
    }
    %orig;
}

- (NSArray *)bitrateRawData {
    NSArray *rawData = %orig;
    if (DYYYShouldDisableAllHDR()) {
        rawData = DYYYFilteredSDRRawBitrateData(rawData);
    }
    return rawData;
}

- (void)setHasFilterHDR:(BOOL)hasFilterHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : hasFilterHDR);
}

- (BOOL)hasFilterHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setIsSourceHDR:(NSInteger)isSourceHDR {
    %orig(DYYYShouldDisableAllHDR() ? 0 : isSourceHDR);
}

- (NSInteger)isSourceHDR {
    if (DYYYShouldDisableAllHDR()) {
        return 0;
    }
    return %orig;
}

%end

static NSString *const kDYYYHDRModeKey = @"DYYYHDRMode";
static NSString *const kDYYYHDRModeOff = @"关闭";
static NSString *const kDYYYHDRModeDisable = @"全局屏蔽HDR效果";
static NSString *const kDYYYHDRModeFilter = @"全局过滤HDR作品";
static char kDYYYHDRStrippedAwemeModelKey;
static char kDYYYHDRStrippedVideoModelKey;
static char kDYYYHDROnlyAwemeModelKey;
static char kDYYYHDROnlyVideoModelKey;

static void DYYYMigrateCombinedHDRModeIfNeeded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"DYYYHDRModeMigratedV1"]) {
            return;
        }

        NSString *mode = [defaults stringForKey:kDYYYHDRModeKey];
        BOOL hasValidMode = [mode isEqualToString:kDYYYHDRModeOff] ||
                            [mode isEqualToString:kDYYYHDRModeDisable] ||
                            [mode isEqualToString:kDYYYHDRModeFilter];
        if (!hasValidMode) {
            if ([defaults boolForKey:@"DYYYDisableAllHDR"]) {
                mode = kDYYYHDRModeDisable;
            } else if ([defaults boolForKey:@"DYYYFilterFeedHDR"]) {
                mode = kDYYYHDRModeFilter;
            } else {
                mode = kDYYYHDRModeOff;
            }
        }

        [defaults setObject:mode forKey:kDYYYHDRModeKey];
        [defaults removeObjectForKey:@"DYYYDisableAllHDR"];
        [defaults removeObjectForKey:@"DYYYFilterFeedHDR"];
        [defaults setBool:YES forKey:@"DYYYHDRModeMigratedV1"];
    });
}

static NSString *DYYYUserDefaultsStringValue(id value) {
    if ([value isKindOfClass:[NSString class]]) {
        return (NSString *)value;
    }
    if ([value isKindOfClass:[NSNumber class]]) {
        return [(NSNumber *)value stringValue];
    }
    return nil;
}

static NSString *DYYYMigratedVerticalOffsetString(id value) {
    NSString *stringValue = DYYYUserDefaultsStringValue(value);
    if (stringValue.length == 0) {
        return stringValue;
    }

    CGFloat offset = [stringValue floatValue];
    if (offset == 0.0f) {
        return stringValue;
    }

    return [NSString stringWithFormat:@"%g", -offset];
}

static void DYYYMigrateScaleAndSizeSettingsIfNeeded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"DYYYScaleAndSizeSettingsMigratedV1"]) {
            return;
        }

        NSString *nicknameScale = DYYYUserDefaultsStringValue([defaults objectForKey:@"DYYYNicknameScale"]);
        if (nicknameScale.length > 0 && [defaults objectForKey:@"DYYYDescriptionScale"] == nil) {
            [defaults setObject:nicknameScale forKey:@"DYYYDescriptionScale"];
        }

        id nicknameOffsetValue = [defaults objectForKey:@"DYYYNicknameVerticalOffset"];
        if (nicknameOffsetValue != nil) {
            NSString *migratedNicknameOffset = DYYYMigratedVerticalOffsetString(nicknameOffsetValue);
            if (migratedNicknameOffset.length > 0) {
                [defaults setObject:migratedNicknameOffset forKey:@"DYYYNicknameVerticalOffset"];
            }
        }

        id descriptionOffsetValue = [defaults objectForKey:@"DYYYDescriptionVerticalOffset"];
        if (descriptionOffsetValue != nil) {
            NSString *migratedDescriptionOffset = DYYYMigratedVerticalOffsetString(descriptionOffsetValue);
            if (migratedDescriptionOffset.length > 0) {
                [defaults setObject:migratedDescriptionOffset forKey:@"DYYYDescriptionVerticalOffset"];
            }
        }

        [defaults setBool:YES forKey:@"DYYYScaleAndSizeSettingsMigratedV1"];
    });
}

static void DYYYMigrateScaleAndSizeSettingsV2IfNeeded(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([defaults boolForKey:@"DYYYScaleAndSizeSettingsMigratedV2"]) {
            return;
        }

        NSString *nicknameScale = DYYYUserDefaultsStringValue([defaults objectForKey:@"DYYYNicknameScale"]);
        if (nicknameScale.length > 0 && [defaults objectForKey:@"DYYYIPLabelScale"] == nil) {
            [defaults setObject:nicknameScale forKey:@"DYYYIPLabelScale"];
        }

        [defaults setBool:YES forKey:@"DYYYScaleAndSizeSettingsMigratedV2"];
    });
}

// HDR 模式判定被 AVPlayerLayer、CALayer、UIImageView 等极高频钩子反复调用，
// 每次读取字符串偏好并比较的开销在滚动时不可忽略，这里按设置代际号缓存结果。
static BOOL DYYYShouldDisableAllHDR(void) {
    static uint32_t cachedGeneration = UINT32_MAX;
    static BOOL cachedValue = NO;

    uint32_t generation = gDYYYSettingsGeneration;
    if (cachedGeneration != generation) {
        cachedValue = [[[NSUserDefaults standardUserDefaults] stringForKey:kDYYYHDRModeKey] isEqualToString:kDYYYHDRModeDisable];
        cachedGeneration = generation;
    }
    return cachedValue;
}

static BOOL DYYYShouldFilterGlobalHDR(void) {
    static uint32_t cachedGeneration = UINT32_MAX;
    static BOOL cachedValue = NO;

    uint32_t generation = gDYYYSettingsGeneration;
    if (cachedGeneration != generation) {
        cachedValue = [[[NSUserDefaults standardUserDefaults] stringForKey:kDYYYHDRModeKey] isEqualToString:kDYYYHDRModeFilter];
        cachedGeneration = generation;
    }
    return cachedValue;
}

static id DYYYKVCValueIfPossible(id object, NSString *key) {
    if (!object || key.length == 0) {
        return nil;
    }

    @try {
        return [object valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static void DYYYSetKVCValueIfPossible(id object, NSString *key, id value) {
    if (!object || key.length == 0) {
        return;
    }

    @try {
        [object setValue:value forKey:key];
    } @catch (__unused NSException *exception) {
    }
}

static id DYYYIvarValueIfPossible(id object, const char *ivarName) {
    if (!object || !ivarName) {
        return nil;
    }

    Class cls = object_getClass(object);
    while (cls) {
        Ivar ivar = class_getInstanceVariable(cls, ivarName);
        if (ivar) {
            return object_getIvar(object, ivar);
        }
        cls = class_getSuperclass(cls);
    }

    return nil;
}

static id DYYYValuePreferringIvar(id object, const char *ivarName, NSString *key) {
    id ivarValue = DYYYIvarValueIfPossible(object, ivarName);
    if (ivarValue) {
        return ivarValue;
    }
    return DYYYKVCValueIfPossible(object, key);
}

static NSInteger DYYYIntegerValueForKeyIfPossible(id object, NSString *key, NSInteger fallback) {
    id value = DYYYKVCValueIfPossible(object, key);
    if ([value respondsToSelector:@selector(integerValue)]) {
        return [value integerValue];
    }
    return fallback;
}

static BOOL DYYYStringValueLooksHDR(id value) {
    if (![value isKindOfClass:[NSString class]]) {
        return NO;
    }

    NSString *lowercaseValue = [(NSString *)value lowercaseString];
    return [lowercaseValue containsString:@"hdr"] ||
           [lowercaseValue containsString:@"hlg"] ||
           [lowercaseValue containsString:@"dolby"] ||
           [lowercaseValue containsString:@"vivid"] ||
           [lowercaseValue isEqualToString:@"pq"] ||
           [lowercaseValue containsString:@"_pq"] ||
           [lowercaseValue containsString:@"pq_"];
}

static BOOL DYYYRawBitrateDictionaryLooksHDR(NSDictionary *dictionary);

static BOOL DYYYBitrateModelLooksHDR(id bitrateModel) {
    if (!bitrateModel) {
        return NO;
    }

    if ([bitrateModel isKindOfClass:[NSDictionary class]]) {
        return DYYYRawBitrateDictionaryLooksHDR((NSDictionary *)bitrateModel);
    }

    id hdrTypeValue = DYYYKVCValueIfPossible(bitrateModel, @"hdrType");
    id hdrBitValue = DYYYKVCValueIfPossible(bitrateModel, @"hdrBit");
    NSInteger hdrType = DYYYIntegerValueForKeyIfPossible(bitrateModel, @"hdrType", 0);
    NSInteger hdrBit = DYYYIntegerValueForKeyIfPossible(bitrateModel, @"hdrBit", 0);
    BOOL hasHdrType = DYYYIntegerValueForKeyIfPossible(bitrateModel, @"hasHdrType", 0) > 0;
    BOOL hasHdrBit = DYYYIntegerValueForKeyIfPossible(bitrateModel, @"hasHdrBit", 0) > 0;

    return hdrType > 0 ||
           hdrBit >= 10 ||
           hasHdrType ||
           hasHdrBit ||
           DYYYStringValueLooksHDR(hdrTypeValue) ||
           DYYYStringValueLooksHDR(hdrBitValue);
}

static BOOL DYYYStringKeyLooksVideoBitrateList(NSString *key) {
    NSString *lowercaseKey = key.lowercaseString;
    if (lowercaseKey.length == 0 || [lowercaseKey containsString:@"audio"]) {
        return NO;
    }

    return [lowercaseKey containsString:@"bit_rate"] ||
           [lowercaseKey containsString:@"bitrate"] ||
           [lowercaseKey containsString:@"bit_rate_model"] ||
           [lowercaseKey containsString:@"bitratemodel"];
}

static BOOL DYYYRawBitrateDictionaryLooksHDR(NSDictionary *dictionary) {
    if (![dictionary isKindOfClass:[NSDictionary class]]) {
        return NO;
    }

    for (id rawKey in dictionary) {
        id value = dictionary[rawKey];
        NSString *key = [[rawKey description] lowercaseString];
        NSInteger numericValue = [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : 0;

        if (([key isEqualToString:@"hdr_type"] ||
             [key isEqualToString:@"hdrtype"] ||
             [key isEqualToString:@"videohdrtype"] ||
             [key isEqualToString:@"video_hdr_type"] ||
             [key isEqualToString:@"source_hdr_type"]) && numericValue > 0) {
            return YES;
        }

        if (([key isEqualToString:@"hdr_bit"] ||
             [key isEqualToString:@"hdrbit"] ||
             [key isEqualToString:@"bit_depth"] ||
             [key isEqualToString:@"bitdepth"]) && numericValue >= 10) {
            return YES;
        }

        if (([key isEqualToString:@"is_source_hdr"] ||
             [key isEqualToString:@"source_hdr"] ||
             [key isEqualToString:@"is_hdr"] ||
             [key isEqualToString:@"ishdr"] ||
             [key isEqualToString:@"has_hdr"] ||
             [key isEqualToString:@"hashdr"] ||
             [key isEqualToString:@"has_filter_hdr"] ||
             [key isEqualToString:@"filter_hdr"] ||
             [key isEqualToString:@"has_hdr_type"] ||
             [key isEqualToString:@"hashdrtype"] ||
             [key isEqualToString:@"has_hdr_bit"] ||
             [key isEqualToString:@"hashdrbit"]) && numericValue > 0) {
            return YES;
        }

        if (DYYYStringValueLooksHDR(value)) {
            return YES;
        }
    }

    return NO;
}

static void DYYYCollectRawBitrateHDRStatus(id object, NSUInteger depth, BOOL *foundHDRBitrate, BOOL *foundSDRBitrate) {
    if (!object || depth > 8 || (foundSDRBitrate && *foundSDRBitrate)) {
        return;
    }

    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        for (id rawKey in dictionary) {
            id value = dictionary[rawKey];
            NSString *key = [rawKey description];

            if (DYYYStringKeyLooksVideoBitrateList(key) && [value isKindOfClass:[NSArray class]]) {
                for (id entry in (NSArray *)value) {
                    if (![entry isKindOfClass:[NSDictionary class]]) {
                        continue;
                    }

                    if (DYYYRawBitrateDictionaryLooksHDR((NSDictionary *)entry)) {
                        if (foundHDRBitrate) {
                            *foundHDRBitrate = YES;
                        }
                    } else if (foundSDRBitrate) {
                        *foundSDRBitrate = YES;
                        return;
                    }
                }
                continue;
            }

            if ([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) {
                DYYYCollectRawBitrateHDRStatus(value, depth + 1, foundHDRBitrate, foundSDRBitrate);
            }
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)object) {
            DYYYCollectRawBitrateHDRStatus(value, depth + 1, foundHDRBitrate, foundSDRBitrate);
        }
    }
}

static BOOL DYYYRawObjectHasOnlyHDRBitrateModels(id object) {
    BOOL foundHDRBitrate = NO;
    BOOL foundSDRBitrate = NO;
    DYYYCollectRawBitrateHDRStatus(object, 0, &foundHDRBitrate, &foundSDRBitrate);
    return foundHDRBitrate && !foundSDRBitrate;
}

static BOOL DYYYVideoModelHasOnlyHDRBitrateModels(id video) {
    if (!video) {
        return NO;
    }

    NSNumber *cachedResult = objc_getAssociatedObject(video, &kDYYYHDROnlyVideoModelKey);
    if (cachedResult) {
        return cachedResult.boolValue;
    }

    NSMutableArray *models = [NSMutableArray array];
    NSArray *bitrateModels = DYYYValuePreferringIvar(video, "_bitrateModels", @"bitrateModels");
    if ([bitrateModels isKindOfClass:[NSArray class]]) {
        [models addObjectsFromArray:bitrateModels];
    }

    NSArray *manualBitrateModels = DYYYValuePreferringIvar(video, "_manualBitrateModels", @"manualBitrateModels");
    if ([manualBitrateModels isKindOfClass:[NSArray class]]) {
        [models addObjectsFromArray:manualBitrateModels];
    }

    NSArray *bitrateRawData = DYYYValuePreferringIvar(video, "_bitrateRawData", @"bitrateRawData");
    if ([bitrateRawData isKindOfClass:[NSArray class]]) {
        [models addObjectsFromArray:bitrateRawData];
    }

    if (models.count == 0) {
        return NO;
    }

    BOOL onlyHDR = YES;
    for (id model in models) {
        if (!DYYYBitrateModelLooksHDR(model)) {
            onlyHDR = NO;
            break;
        }
    }

    objc_setAssociatedObject(video, &kDYYYHDROnlyVideoModelKey, @(onlyHDR), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    return onlyHDR;
}

static BOOL DYYYAwemeModelHasOnlyHDRBitrateModels(id aweme) {
    if (!aweme) {
        return NO;
    }

    NSNumber *cachedResult = objc_getAssociatedObject(aweme, &kDYYYHDROnlyAwemeModelKey);
    if (cachedResult) {
        return cachedResult.boolValue;
    }

    BOOL onlyHDR = NO;
    BOOL shouldCacheResult = NO;
    id video = DYYYValuePreferringIvar(aweme, "_video", @"video");
    if (video) {
        shouldCacheResult = YES;
    }
    if (DYYYVideoModelHasOnlyHDRBitrateModels(video)) {
        onlyHDR = YES;
    } else {
        NSArray *albumImages = DYYYValuePreferringIvar(aweme, "_albumImages", @"albumImages");
        if ([albumImages isKindOfClass:[NSArray class]]) {
            shouldCacheResult = shouldCacheResult || albumImages.count > 0;
            for (id imageModel in albumImages) {
                id clipVideo = DYYYValuePreferringIvar(imageModel, "_clipVideo", @"clipVideo");
                if (DYYYVideoModelHasOnlyHDRBitrateModels(clipVideo)) {
                    onlyHDR = YES;
                    break;
                }
            }
        }
    }

    if (shouldCacheResult || onlyHDR) {
        objc_setAssociatedObject(aweme, &kDYYYHDROnlyAwemeModelKey, @(onlyHDR), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return onlyHDR;
}

static NSArray *DYYYFilteredSDRRawBitrateData(NSArray *rawData) {
    if (![rawData isKindOfClass:[NSArray class]] || rawData.count == 0) {
        return rawData;
    }

    NSMutableArray *sdrData = [NSMutableArray arrayWithCapacity:rawData.count];
    NSUInteger hdrCount = 0;
    for (id entry in rawData) {
        if ([entry isKindOfClass:[NSDictionary class]] && DYYYRawBitrateDictionaryLooksHDR((NSDictionary *)entry)) {
            hdrCount++;
            continue;
        }
        [sdrData addObject:entry];
    }

    if (hdrCount == 0 || sdrData.count == 0) {
        return rawData;
    }

    return [sdrData copy];
}

static NSArray *DYYYFilteredSDRBitrateModels(NSArray *models) {
    if (![models isKindOfClass:[NSArray class]] || models.count == 0) {
        return models;
    }

    NSMutableArray *sdrModels = [NSMutableArray arrayWithCapacity:models.count];
    NSUInteger hdrCount = 0;
    for (id model in models) {
        if (DYYYBitrateModelLooksHDR(model)) {
            hdrCount++;
            continue;
        }
        [sdrModels addObject:model];
    }

    // 只有 HDR 档的作品在模型层过滤；这里不清空列表，避免播放器拿不到可播档导致有声黑屏。
    if (hdrCount == 0 || sdrModels.count == 0) {
        return models;
    }

    return [sdrModels copy];
}

static void DYYYStripHDRHintsFromBitrateModels(NSArray *models) {
    if (![models isKindOfClass:[NSArray class]]) {
        return;
    }

    for (id model in models) {
        DYYYSetKVCValueIfPossible(model, @"hdrType", @0);
        DYYYSetKVCValueIfPossible(model, @"hdrBit", @8);
        DYYYSetKVCValueIfPossible(model, @"hasHdrType", @NO);
        DYYYSetKVCValueIfPossible(model, @"hasHdrBit", @NO);
    }
}

static void DYYYStripHDRHintsFromVideoModel(id video) {
    if (!DYYYShouldDisableAllHDR() || !video) {
        return;
    }

    if (objc_getAssociatedObject(video, &kDYYYHDRStrippedVideoModelKey)) {
        return;
    }
    objc_setAssociatedObject(video, &kDYYYHDRStrippedVideoModelKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    if ([video respondsToSelector:@selector(setIsSourceHDR:)]) {
        ((void (*)(id, SEL, NSInteger))objc_msgSend)(video, @selector(setIsSourceHDR:), 0);
    }
    if ([video respondsToSelector:@selector(setHasFilterHDR:)]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(video, @selector(setHasFilterHDR:), NO);
    }

    NSArray *bitrateModels = DYYYKVCValueIfPossible(video, @"bitrateModels");
    NSArray *filteredBitrateModels = DYYYFilteredSDRBitrateModels(bitrateModels);
    if (filteredBitrateModels && filteredBitrateModels != bitrateModels) {
        DYYYSetKVCValueIfPossible(video, @"bitrateModels", filteredBitrateModels);
        bitrateModels = filteredBitrateModels;
    }
    DYYYStripHDRHintsFromBitrateModels(bitrateModels);

    NSArray *manualBitrateModels = DYYYKVCValueIfPossible(video, @"manualBitrateModels");
    NSArray *filteredManualBitrateModels = DYYYFilteredSDRBitrateModels(manualBitrateModels);
    if (filteredManualBitrateModels && filteredManualBitrateModels != manualBitrateModels) {
        DYYYSetKVCValueIfPossible(video, @"manualBitrateModels", filteredManualBitrateModels);
        manualBitrateModels = filteredManualBitrateModels;
    }
    DYYYStripHDRHintsFromBitrateModels(manualBitrateModels);

    NSArray *bitrateRawData = DYYYValuePreferringIvar(video, "_bitrateRawData", @"bitrateRawData");
    NSArray *filteredBitrateRawData = DYYYFilteredSDRRawBitrateData(bitrateRawData);
    if (filteredBitrateRawData && filteredBitrateRawData != bitrateRawData) {
        DYYYSetKVCValueIfPossible(video, @"bitrateRawData", filteredBitrateRawData);
    }
}

static void DYYYStripHDRHintsFromAwemeModel(id aweme) {
    if (!DYYYShouldDisableAllHDR() || !aweme) {
        return;
    }

    if (objc_getAssociatedObject(aweme, &kDYYYHDRStrippedAwemeModelKey)) {
        return;
    }
    objc_setAssociatedObject(aweme, &kDYYYHDRStrippedAwemeModelKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    id video = DYYYValuePreferringIvar(aweme, "_video", @"video");
    DYYYStripHDRHintsFromVideoModel(video);

    NSArray *albumImages = DYYYValuePreferringIvar(aweme, "_albumImages", @"albumImages");
    if ([albumImages isKindOfClass:[NSArray class]]) {
        for (id imageModel in albumImages) {
            DYYYStripHDRHintsFromVideoModel(DYYYValuePreferringIvar(imageModel, "_clipVideo", @"clipVideo"));
        }
    }
}

static id DYYYStandardCADynamicRange(void) {
    static id standardDynamicRange = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *symbol = dlsym(RTLD_DEFAULT, "CADynamicRangeStandard");
        if (symbol) {
            id __unsafe_unretained *value = (id __unsafe_unretained *)symbol;
            standardDynamicRange = *value;
        }
    });
    return standardDynamicRange;
}

static id DYYYToneMapModeIfSupported(void) {
    static id toneMapMode = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        void *symbol = dlsym(RTLD_DEFAULT, "CAToneMapModeIfSupported");
        if (symbol) {
            id __unsafe_unretained *value = (id __unsafe_unretained *)symbol;
            toneMapMode = *value;
        }
    });
    return toneMapMode;
}

static void DYYYApplySDRDynamicRangeToImageView(UIImageView *imageView) {
    if (!DYYYShouldDisableAllHDR() || !imageView) {
        return;
    }

    if (@available(iOS 17.0, *)) {
        imageView.preferredImageDynamicRange = UIImageDynamicRangeStandard;
    }
}

// 头像加号可能由异步动画重建图层，需要在 CALayer 写入点继续压制。
static BOOL DYYYShouldForceHideAvatarActionLayer(CALayer *layer);
static BOOL DYYYShouldClearAvatarActionLayer(CALayer *layer);
static void DYYYPrepareAvatarActionSublayer(CALayer *parentLayer, CALayer *sublayer);

// 收藏按钮在部分视频中会异步重建图片/动画图层，标记后在写入点继续压制。
static char kDYYYFeedVideoCollectButtonHiddenViewKey;
static char kDYYYFeedVideoCollectButtonHiddenLayerKey;
static char kDYYYFeedVideoCollectButtonDeferredApplyKey;

static BOOL DYYYShouldForceHideFeedVideoCollectButtonLayer(CALayer *layer);
static BOOL DYYYShouldClearFeedVideoCollectButtonLayer(CALayer *layer);
static void DYYYPrepareFeedVideoCollectButtonSublayer(CALayer *parentLayer, CALayer *sublayer);
static BOOL DYYYShouldForceHideFeedVideoCollectButtonView(UIView *view);
static void DYYYMarkFeedVideoCollectButtonViewHidden(UIView *view);

static void DYYYDisableExtendedRangeForLayer(CALayer *layer) {
    if (!DYYYShouldDisableAllHDR() || !layer) {
        return;
    }

    SEL setWantsEDRSelector = @selector(setWantsExtendedDynamicRangeContent:);
    if ([layer respondsToSelector:setWantsEDRSelector]) {
        ((void (*)(id, SEL, BOOL))objc_msgSend)(layer, setWantsEDRSelector, NO);
    }

    id toneMapMode = DYYYToneMapModeIfSupported();
    SEL setToneMapModeSelector = @selector(setToneMapMode:);
    if (toneMapMode && [layer respondsToSelector:setToneMapModeSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(layer, setToneMapModeSelector, toneMapMode);
    }

    id standardDynamicRange = DYYYStandardCADynamicRange();
    SEL setPreferredDynamicRangeSelector = @selector(setPreferredDynamicRange:);
    if (standardDynamicRange && [layer respondsToSelector:setPreferredDynamicRangeSelector]) {
        ((void (*)(id, SEL, id))objc_msgSend)(layer, setPreferredDynamicRangeSelector, standardDynamicRange);
    }

    if (@available(iOS 16.0, *)) {
        if ([layer isKindOfClass:[CAMetalLayer class]]) {
            ((CAMetalLayer *)layer).EDRMetadata = nil;
        }
    }
}

static void DYYYDisableExtendedRangeForMetalLayer(CAMetalLayer *metalLayer) {
    if (!DYYYShouldDisableAllHDR() || !metalLayer) {
        return;
    }

    DYYYDisableExtendedRangeForLayer(metalLayer);
}

static void DYYYDisableAVPlayerItemHDRMetadata(AVPlayerItem *item) {
    if (!DYYYShouldDisableAllHDR() || !item) {
        return;
    }

    if (@available(iOS 14.0, *)) {
        item.appliesPerFrameHDRDisplayMetadata = NO;
    }
}

// 保留 HDR 解码及原生 HDR -> SDR 转换，只关闭亮度增强、SDR -> HDR 和最终 EDR 输出。

%hook AVPlayer

+ (AVPlayerHDRMode)availableHDRModes {
    if (DYYYShouldDisableAllHDR()) {
        return 0;
    }
    return %orig;
}

+ (BOOL)eligibleForHDRPlayback {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (instancetype)playerWithURL:(NSURL *)URL {
    AVPlayer *player = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(player.currentItem);
    return player;
}

+ (instancetype)playerWithPlayerItem:(AVPlayerItem *)item {
    DYYYDisableAVPlayerItemHDRMetadata(item);
    return %orig;
}

- (instancetype)initWithURL:(NSURL *)URL {
    self = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(self.currentItem);
    return self;
}

- (instancetype)initWithPlayerItem:(AVPlayerItem *)item {
    DYYYDisableAVPlayerItemHDRMetadata(item);
    return %orig;
}

- (void)replaceCurrentItemWithPlayerItem:(AVPlayerItem *)item {
    DYYYDisableAVPlayerItemHDRMetadata(item);
    %orig;
}

%end

%hook AVPlayerItem

+ (instancetype)playerItemWithURL:(NSURL *)URL {
    AVPlayerItem *item = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(item);
    return item;
}

+ (instancetype)playerItemWithAsset:(AVAsset *)asset {
    AVPlayerItem *item = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(item);
    return item;
}

+ (instancetype)playerItemWithAsset:(AVAsset *)asset automaticallyLoadedAssetKeys:(NSArray<NSString *> *)automaticallyLoadedAssetKeys {
    AVPlayerItem *item = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(item);
    return item;
}

- (instancetype)initWithURL:(NSURL *)URL {
    self = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(self);
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset {
    self = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(self);
    return self;
}

- (instancetype)initWithAsset:(AVAsset *)asset automaticallyLoadedAssetKeys:(NSArray<NSString *> *)automaticallyLoadedAssetKeys {
    self = %orig;
    DYYYDisableAVPlayerItemHDRMetadata(self);
    return self;
}

- (void)setAppliesPerFrameHDRDisplayMetadata:(BOOL)appliesPerFrameHDRDisplayMetadata {
    %orig(DYYYShouldDisableAllHDR() ? NO : appliesPerFrameHDRDisplayMetadata);
}

- (BOOL)appliesPerFrameHDRDisplayMetadata {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook AVPlayerLayer

- (void)setPlayer:(AVPlayer *)player {
    DYYYDisableAVPlayerItemHDRMetadata(player.currentItem);
    %orig;
    DYYYDisableExtendedRangeForLayer(self);
}

- (void)layoutSublayers {
    %orig;
    DYYYDisableAVPlayerItemHDRMetadata(self.player.currentItem);
    DYYYDisableExtendedRangeForLayer(self);
}

%end

%hook AWEKnowledgeABTestSettings

+ (BOOL)enableHDRAutomaticIdentification {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook AWEFeedABSettings

+ (BOOL)enableHDRBrightnessOpt {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)enableProfilePreloadHDRBrightnessFilter {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)enableDynamicGaussianBlurHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)enableHDRFullModelAdaptation {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)hdrAutomaticIdentification {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook AWEFeedABTestServiceObjc

+ (BOOL)enableProfilePreloadHDRBrightnessFilter {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook BDSimPlayerBizConfig

- (BOOL)enableHDRBrightnessOpt {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (BOOL)enableHDRFullModelAdaptation {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (BOOL)hdrAutomaticIdentification {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook AWEBDSimPlayerBizConfig

- (BOOL)enableHDRBrightnessOpt {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (BOOL)enableHDRFullModelAdaptation {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (BOOL)hdrAutomaticIdentification {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook AWEVideoPlayerConfiguration

+ (void)setHDRBrightnessStrategy:(id)strategy {
    if (!DYYYShouldDisableAllHDR()) {
        %orig;
    }
}

+ (double)getHDRBrightnessOffset:(id)configuration brightness:(double)brightness {
    if (DYYYShouldDisableAllHDR()) {
        return 0.0;
    }
    return %orig;
}

%end

%hook AWEDPlayerVideoDisplayOptState

- (BOOL)enableHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setEnableHDR:(BOOL)enableHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : enableHDR);
}

%end

%hook AWEPlayVideoPlayerContext

- (BOOL)enableHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setEnableHDR:(BOOL)enableHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : enableHDR);
}

%end

%hook AWEDPlayerVideoModel

- (BOOL)awe_isHDRVideo {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setAwe_isHDRVideo:(BOOL)awe_isHDRVideo {
    %orig(DYYYShouldDisableAllHDR() ? NO : awe_isHDRVideo);
}

%end

%hook AWEPlayVideoViewController

- (BOOL)enableHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setEnableHDR:(BOOL)enableHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : enableHDR);
}

- (BOOL)awe_isCurrentVideoHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setPlayerLutFilter:(id)lutFilter HDRLutImage:(id)HDRLutImage {
    %orig(lutFilter, DYYYShouldDisableAllHDR() ? nil : HDRLutImage);
}

%end

%hook AWEDPlayerBrightnessContainer

- (BOOL)awe_isCurrentVideoHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook AWEVideoPlayerScreenBrightnessManager

- (BOOL)isHDRVideo {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setIsHDRVideo:(BOOL)isHDRVideo {
    // 播放器复用时会重新写入当前作品的 HDR 状态，需同时清除写入值和读取结果。
    %orig(DYYYShouldDisableAllHDR() ? NO : isHDRVideo);
}

%end

%hook ALMOwnPlayerWrapper

- (void)setLutFilter:(id)lutFilter HDRLutImage:(id)HDRLutImage {
    %orig(lutFilter, DYYYShouldDisableAllHDR() ? nil : HDRLutImage);
}

%end

%hook ALMSysPlayerWrapper

- (void)setLutFilter:(id)lutFilter HDRLutImage:(id)HDRLutImage {
    %orig(lutFilter, DYYYShouldDisableAllHDR() ? nil : HDRLutImage);
}

%end

%hook ALMVideoPlayerConfig

+ (void)setPlayerEffectHDRLutImageEnable:(BOOL)enable {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable);
}

%end

%hook IESVideoPlayerConfig

+ (void)setPlayerEffectHDRLutImageEnable:(BOOL)enable {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable);
}

%end

%hook AWEIMModuleService

- (BOOL)im_forceHDRToSDR {
    if (DYYYShouldDisableAllHDR()) {
        return YES;
    }
    return %orig;
}

%end

%hook IESIMVideoPlayerWrapper

- (void)setupHDREnable:(BOOL)enable {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable);
}

%end

%hook AWEIMVideoBrowserCollectionViewCell

- (void)setEnablePlayHDR:(BOOL)enable {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable);
}

%end

%hook AWEECOMIMAppSettingsService

+ (BOOL)enableVideoPreviewSupportHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook IESLiveAudienceHDRController

+ (BOOL)currentHDRStatusForRoomID:(id)roomID {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)isCurrentRoomSupportHDR:(id)roomID roomModel:(id)roomModel {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)isFeedCanEnableHDRFeature {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)isInnerFeedCanEnableHDRFeature {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)isUserEnableHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (BOOL)p_isHDRFeatureEnable {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

+ (void)setUserEnableHDR:(BOOL)enableHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : enableHDR);
}

+ (BOOL)shouldShowHDRSwitchForRoom:(id)room {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook IESLivePlayerController

- (BOOL)isVideoSDR2HDRSupport {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setEnableVideoSDR2HDR:(BOOL)enable callTrace:(id)callTrace {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable, callTrace);
}

- (BOOL)enableCloseSDR2HDR {
    if (DYYYShouldDisableAllHDR()) {
        return YES;
    }
    return %orig;
}

%end

%hook AWELivePreStreamPlayer

- (void)changeSDR2HDRWithStrategy {
    if (!DYYYShouldDisableAllHDR()) {
        %orig;
    }
}

%end

%hook HTSLiveStreamPlayer

- (void)setEnableVideoSDR2HDR:(BOOL)enable callTrace:(id)callTrace {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable, callTrace);
}

- (void)changeSDR2HDRWithStrategy {
    if (!DYYYShouldDisableAllHDR()) {
        %orig;
    }
}

%end

%hook IESLiveStreamPlayerVideoAudioEffectPlugin

- (void)setEnableVideoSDR2HDR:(BOOL)enable callTrace:(id)callTrace {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable, callTrace);
}

- (void)changeSDR2HDRWithStrategy {
    if (!DYYYShouldDisableAllHDR()) {
        %orig;
    }
}

%end

%hook TVLManager

- (BOOL)shouldForbidHDR10Render {
    if (DYYYShouldDisableAllHDR()) {
        return YES;
    }
    return %orig;
}

- (void)setShouldForbidHDR10Render:(BOOL)shouldForbid {
    %orig(DYYYShouldDisableAllHDR() ? YES : shouldForbid);
}

- (void)setupVideoSDR2HDR:(id)config {
    if (!DYYYShouldDisableAllHDR()) {
        %orig;
    }
}

%end

%hook TVLPlayerItemPreferences

- (BOOL)forbidSDR2HDRInPreview {
    if (DYYYShouldDisableAllHDR()) {
        return YES;
    }
    return %orig;
}

- (void)setForbidSDR2HDRInPreview:(BOOL)forbid {
    %orig(DYYYShouldDisableAllHDR() ? YES : forbid);
}

- (BOOL)enableUseSDR2HDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setEnableUseSDR2HDR:(BOOL)enable {
    %orig(DYYYShouldDisableAllHDR() ? NO : enable);
}

%end

%hook TVLSettingsManager

- (BOOL)enableMetalRenderHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook IESFiltersManager

- (void)setHDRIndensity:(double)intensity {
    %orig(DYYYShouldDisableAllHDR() ? 0.0 : intensity);
}

%end

%hook BDImageDecoderFactory

+ (BOOL)isHDRImageData:(id)data withHeifDecoderClass:(Class)decoderClass {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

%end

%hook BDImageDecoderImageIO

- (BOOL)isHDRCGImage:(CGImageRef)image decodedToHDR:(BOOL)decodedToHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (id)hdrOptionsFor:(id)image decodedToHDR:(BOOL *)decodedToHDR {
    if (DYYYShouldDisableAllHDR()) {
        if (decodedToHDR) {
            *decodedToHDR = NO;
        }
        return nil;
    }
    return %orig;
}

%end

%hook BDImageDecoderHeic

+ (BOOL)isHDRData:(id)data {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (BOOL)isHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setIsHDR:(BOOL)isHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : isHDR);
}

%end

%hook BDImageDecoderBVC2

- (BOOL)isHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setIsHDR:(BOOL)isHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : isHDR);
}

%end

%hook BDImageDecoderWebP

- (BOOL)isHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setIsHDR:(BOOL)isHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : isHDR);
}

%end

%hook BDImage

- (BOOL)isHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setIsHDR:(BOOL)isHDR {
    %orig(DYYYShouldDisableAllHDR() ? NO : isHDR);
}

%end

%hook HDRMTUIImageView

- (instancetype)initWithFrame:(CGRect)frame hdrEnabled:(BOOL)hdrEnabled {
    return %orig(frame, DYYYShouldDisableAllHDR() ? NO : hdrEnabled);
}

- (BOOL)hdrEnabled {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setHdrEnabled:(BOOL)hdrEnabled {
    %orig(DYYYShouldDisableAllHDR() ? NO : hdrEnabled);
}

- (void)setImage:(UIImage *)image {
    if (DYYYShouldDisableAllHDR()) {
        self.hdrEnabled = NO;
    }
    DYYYApplySDRDynamicRangeToImageView(self);
    %orig;
    DYYYApplySDRDynamicRangeToImageView(self);
}

%end

%hook HDRMTImageView

- (void)setMetalLayer:(CAMetalLayer *)metalLayer {
    %orig;
    DYYYDisableExtendedRangeForMetalLayer(metalLayer);
}

- (void)setUpEnv {
    %orig;
    DYYYDisableExtendedRangeForMetalLayer(self.metalLayer);
}

- (void)layoutSubviews {
    %orig;
    DYYYDisableExtendedRangeForMetalLayer(self.metalLayer);
}

%end

%hook HDRMTButton

- (void)configHDRContent {
    %orig;
    DYYYApplySDRDynamicRangeToImageView(self.hdrmtImageView);
}

%end

%hook CAMetalLayer

- (void)setWantsExtendedDynamicRangeContent:(BOOL)wantsExtendedDynamicRangeContent {
    %orig(DYYYShouldDisableAllHDR() ? NO : wantsExtendedDynamicRangeContent);
}

- (BOOL)wantsExtendedDynamicRangeContent {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setEDRMetadata:(CAEDRMetadata *)EDRMetadata {
    %orig(DYYYShouldDisableAllHDR() ? nil : EDRMetadata);
}

- (CAEDRMetadata *)EDRMetadata {
    if (DYYYShouldDisableAllHDR()) {
        return nil;
    }
    return %orig;
}

%end

%hook CALayer

- (void)setHidden:(BOOL)hidden {
    BOOL shouldForceHidden = DYYYShouldForceHideAvatarActionLayer(self) || DYYYShouldForceHideFeedVideoCollectButtonLayer(self);
    %orig(shouldForceHidden ? YES : hidden);
}

- (void)setContents:(id)contents {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? nil : contents);
}

- (void)setBackgroundColor:(CGColorRef)backgroundColor {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? UIColor.clearColor.CGColor : backgroundColor);
}

- (void)setOpaque:(BOOL)opaque {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? NO : opaque);
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? 0.0 : borderWidth);
}

- (void)setBorderColor:(CGColorRef)borderColor {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? UIColor.clearColor.CGColor : borderColor);
}

- (void)setShadowOpacity:(float)shadowOpacity {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? 0.0f : shadowOpacity);
}

- (void)setShadowColor:(CGColorRef)shadowColor {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? UIColor.clearColor.CGColor : shadowColor);
}

- (void)addSublayer:(CALayer *)layer {
    DYYYPrepareAvatarActionSublayer(self, layer);
    DYYYPrepareFeedVideoCollectButtonSublayer(self, layer);
    %orig(layer);
}

- (void)insertSublayer:(CALayer *)layer atIndex:(unsigned int)index {
    DYYYPrepareAvatarActionSublayer(self, layer);
    DYYYPrepareFeedVideoCollectButtonSublayer(self, layer);
    %orig(layer, index);
}

- (void)insertSublayer:(CALayer *)layer below:(CALayer *)sibling {
    DYYYPrepareAvatarActionSublayer(self, layer);
    DYYYPrepareFeedVideoCollectButtonSublayer(self, layer);
    %orig(layer, sibling);
}

- (void)insertSublayer:(CALayer *)layer above:(CALayer *)sibling {
    DYYYPrepareAvatarActionSublayer(self, layer);
    DYYYPrepareFeedVideoCollectButtonSublayer(self, layer);
    %orig(layer, sibling);
}

- (void)setSublayers:(NSArray<CALayer *> *)sublayers {
    for (CALayer *layer in sublayers) {
        DYYYPrepareAvatarActionSublayer(self, layer);
        DYYYPrepareFeedVideoCollectButtonSublayer(self, layer);
    }
    %orig(sublayers);
}

- (void)setWantsExtendedDynamicRangeContent:(BOOL)wantsExtendedDynamicRangeContent {
    %orig(DYYYShouldDisableAllHDR() ? NO : wantsExtendedDynamicRangeContent);
}

- (BOOL)wantsExtendedDynamicRangeContent {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)setPreferredDynamicRange:(id)preferredDynamicRange {
    id standardDynamicRange = DYYYStandardCADynamicRange();
    %orig(DYYYShouldDisableAllHDR() && standardDynamicRange ? standardDynamicRange : preferredDynamicRange);
}

- (id)preferredDynamicRange {
    id preferredDynamicRange = %orig;
    if (DYYYShouldDisableAllHDR()) {
        id standardDynamicRange = DYYYStandardCADynamicRange();
        if (standardDynamicRange) {
            return standardDynamicRange;
        }
    }
    return preferredDynamicRange;
}

%end

%hook CAShapeLayer

- (void)setFillColor:(CGColorRef)fillColor {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? UIColor.clearColor.CGColor : fillColor);
}

- (void)setStrokeColor:(CGColorRef)strokeColor {
    BOOL shouldClearLayer = DYYYShouldClearAvatarActionLayer(self) || DYYYShouldClearFeedVideoCollectButtonLayer(self);
    %orig(shouldClearLayer ? UIColor.clearColor.CGColor : strokeColor);
}

%end

// 直播间真实人数
%hook IESLiveUserSeqlistFragment

- (void)refreshVerticalUserCount:(id)arg1 horizontalUserCount:(id)arg2 trueValue:(NSInteger)trueValue {
    if ( trueValue > 0 && DYYYGetBool(@"DYYYEnableLiveRealCount") ) {
        NSString *realStr = [NSString stringWithFormat:@"%ld", (long)trueValue];
        %orig(realStr, realStr, trueValue);
    } else {
        %orig;
    }
}

%end

// 评论具体时间
%hook AWEDateTimeFormatter

+ (id)formattedDateForTimestamp:(double)timestamp {
    if (!DYYYGetBool(@"DYYYCommentExactTime")) return %orig(timestamp);
    return [NSString stringWithFormat:@"%.0f ", timestamp];
}

%end

%hook AWERLVirtualLabel

- (void)setText:(NSString *)text {
    if (!DYYYGetBool(@"DYYYCommentExactTime") || !text || text.length == 0) {
        %orig(text);
        return;
    }

    if ([text isEqualToString:@"回复"]) {
        %orig(@"");
        return;
    }

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d{10,13})([\\s\\S]*)" options:0 error:&error];

    NSTextCheckingResult *match = [regex firstMatchInString:text options:0 range:NSMakeRange(0, text.length)];

    if (match) {
        NSString *rawTs = [text substringWithRange:[match rangeAtIndex:1]];
        NSString *suffix = [text substringWithRange:[match rangeAtIndex:2]];

        long long ts = [rawTs longLongValue];

        if (ts > 100000000000) {
            ts = ts / 1000;
        }

        NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *formattedDate = [formatter stringFromDate:date];

        NSString *newText = [NSString stringWithFormat:@"%@%@", formattedDate, suffix];
        %orig(newText);
    } else {
        %orig(text);
    }
}

%end

%group DYYYCommentExactTimeGroup
%hook AWECommentSwiftBizUI_CommentInteractionBaseLabel

- (void)setText:(NSString *)text {
    %orig(text); // 先让系统把文本赋上去

    if (!DYYYGetBool(@"DYYYCommentExactTime")) {
        return;
    }

    UILabel *label = (UILabel *)self;
    if (!text || text.length == 0) return;

    // --- 1. 拦截翻译文本，将其绝对定位在屏幕右侧 100 像素 ---
    if ([text isEqualToString:@"翻译"] || [text isEqualToString:@"隐藏翻译"]) {
        CGRect currentFrame = label.frame;
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        // 重新计算 X 坐标：屏幕宽度 - 100 - 标签自身宽度
        currentFrame.origin.x = screenWidth - 100.0 - currentFrame.size.width;
        label.frame = currentFrame;
        return;
    }

    // --- 2. 拦截时间文本，如果不够宽则扩充宽度 ---
    UIFont *font = label.font;
    if (font) {
        CGFloat expectedWidth = ceilf([text sizeWithAttributes:@{NSFontAttributeName: font}].width);
        CGRect currentFrame = label.frame;

        // 如果当前宽度不够，并且不是尚未初始化的状态（>0），则强行修改并重新赋值
        if (currentFrame.size.width < expectedWidth && currentFrame.size.width > 0) {
            currentFrame.size.width = expectedWidth;
            label.frame = currentFrame;
            label.clipsToBounds = NO;
        }
    }
}

- (void)setFrame:(CGRect)frame {
    if (!DYYYGetBool(@"DYYYCommentExactTime") || ![self respondsToSelector:@selector(text)]) {
        %orig(frame);
        return;
    }

    UILabel *label = (UILabel *)self;
    NSString *text = label.text;

    if (text && text.length > 0) {
        // --- 1. 拦截翻译文本，将其绝对定位在屏幕右侧 100 像素 ---
        if ([text isEqualToString:@"翻译"] || [text isEqualToString:@"隐藏翻译"]) {
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            frame.origin.x = screenWidth - 100.0 - frame.size.width;
        }
        // --- 2. 拦截时间文本，如果不够宽则扩充宽度 ---
        else if ([self respondsToSelector:@selector(font)]) {
            UIFont *font = label.font;
            if (font) {
                CGFloat expectedWidth = ceilf([text sizeWithAttributes:@{NSFontAttributeName: font}].width);
                if (frame.size.width < expectedWidth && frame.size.width > 0) {
                    frame.size.width = expectedWidth;
                    label.clipsToBounds = NO;
                }
            }
        }
    }

    %orig(frame);
}

%end
%end

// 前面的AWEDateTimeFormatter会导致图文视频展开时间文本变成时间戳，这里处理下
%hook YYLabel

// 1. Hook 富文本赋值方法 (核心)
- (void)setAttributedText:(NSAttributedString *)attributedText {
    if (!DYYYGetBool(@"DYYYCommentExactTime") || !attributedText || attributedText.length == 0) {
        %orig(attributedText);
        return;
    }

    NSString *plainText = [attributedText string];

    NSError *error = nil;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"^(\\d{10,13})" options:0 error:&error];
    NSTextCheckingResult *match = [regex firstMatchInString:plainText options:0 range:NSMakeRange(0, plainText.length)];

    if (match) {
        NSString *rawTs = [plainText substringWithRange:[match rangeAtIndex:1]];
        long long ts = [rawTs longLongValue];

        if (ts > 100000000000) {
            ts = ts / 1000;
        }

        NSDate *date = [NSDate dateWithTimeIntervalSince1970:ts];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        NSString *formattedDate = [formatter stringFromDate:date];

        NSMutableAttributedString *newAttrStr = [attributedText mutableCopy];
        [newAttrStr replaceCharactersInRange:[match rangeAtIndex:1] withString:formattedDate];

        %orig(newAttrStr);
    } else {
        %orig(attributedText);
    }
}

%end

// 禁用自动进入直播间
%hook AWELiveGuideElement

- (BOOL)enableAutoEnterRoom {
    if (DYYYGetBool(@"DYYYDisableAutoEnterLive")) {
        return NO;
    }
    return %orig;
}

- (BOOL)enableNewAutoEnter {
    if (DYYYGetBool(@"DYYYDisableAutoEnterLive")) {
        return NO;
    }
    return %orig;
}

%end

%hook AWEFeedChannelManager

- (void)reloadChannelWithChannelModels:(id)arg1 currentChannelIDList:(id)arg2 reloadType:(id)arg3 selectedChannelID:(id)arg4 {
    NSArray *channelModels = arg1;
    NSMutableArray *newChannelModels = [NSMutableArray array];
    NSArray *currentChannelIDList = arg2;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableArray *newCurrentChannelIDList = [NSMutableArray arrayWithArray:currentChannelIDList];

    if (!arg1 || !arg2) {
        %orig(arg1, arg2, arg3, arg4);
        return;
    }

    if (![channelModels isKindOfClass:[NSArray class]] || ![currentChannelIDList isKindOfClass:[NSArray class]]) {
        %orig(arg1, arg2, arg3, arg4);
        return;
    }

    if (channelModels.count == 0) {
        %orig(arg1, arg2, arg3, arg4);
        return;
    }

    for (AWEHPTopTabItemModel *tabItemModel in channelModels) {
        NSString *channelID = tabItemModel.channelID;
        BOOL isHideChannel = NO;

        if ([channelID isEqualToString:@"homepage_hot_container"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideHotContainer"];
        } else if ([channelID isEqualToString:@"homepage_follow"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideFollow"];
        } else if ([channelID isEqualToString:@"homepage_mall"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideMall"];
        } else if ([channelID isEqualToString:@"homepage_nearby"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideNearby"];
        } else if ([channelID isEqualToString:@"homepage_groupon"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideGroupon"];
        } else if ([channelID isEqualToString:@"homepage_tablive"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideTabLive"];
        } else if ([channelID isEqualToString:@"homepage_pad_hot"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHidePadHot"];
        } else if ([channelID isEqualToString:@"homepage_hangout"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideHangout"];
        } else if ([channelID isEqualToString:@"homepage_familiar"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideFriend"];
        } else if ([channelID isEqualToString:@"homepage_playlet_stream"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHidePlaylet"];
        } else if ([channelID isEqualToString:@"homepage_pad_cinema"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideCinema"];
        } else if ([channelID isEqualToString:@"homepage_pad_kids_v2"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideKidsV2"];
        } else if ([channelID isEqualToString:@"homepage_pad_game"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideGame"];
        } else if ([channelID isEqualToString:@"homepage_mediumvideo"]) {
            isHideChannel = [defaults boolForKey:@"DYYYHideMediumVideo"];
        }

        if (!isHideChannel) {
            [newChannelModels addObject:tabItemModel];
        } else {
            [newCurrentChannelIDList removeObject:channelID];
        }
    }

    %orig(newChannelModels, newCurrentChannelIDList, arg3, arg4);
}

%end

%hook AWELandscapeFeedViewController
- (void)viewDidLoad {
    %orig;

    // 尝试优先走属性
    gFeedCV = self.collectionView;

    // 保险起见再fallback,遍历 subviews
    if (!gFeedCV) {
        gFeedCV = [DYYYUtils findSubviewOfClass:[UICollectionView class] inContainer:self.view];
    }
}
%end

%hook UICollectionView

// 拦截手指拖动
- (void)handlePan:(UIPanGestureRecognizer *)pan {
    /* 仅处理横屏Feed列表。其余collectionView直接走系统逻辑 */
    if (self != gFeedCV || !DYYYGetBool(@"DYYYVideoGesture")) {
        %orig;
        return;
    }

    /* 取触点坐标、手势状态 */
    CGPoint loc = [pan locationInView:self];
    CGFloat w = self.bounds.size.width;
    CGFloat xPct = loc.x / w; // 0.0 ~ 1.0
    UIGestureRecognizerState st = pan.state;

    /* BEGAN：判定左右 20 % 区域 → 进入亮度 / 音量模式 */
    if (st == UIGestureRecognizerStateBegan) {
        gStartY = loc.y;

        if (xPct <= 0.20) { // 左边缘 → 亮度
            gMode = DYEdgeModeBrightness;
            gStartVal = [UIScreen mainScreen].brightness;
        } else if (xPct >= 0.80) { // 右边缘 → 音量
            gMode = DYEdgeModeVolume;
            gStartVal = [[objc_getClass("AVSystemController") sharedAVSystemController] volumeForCategory:@"Audio/Video"];
        } else {
            gMode = DYEdgeModeNone; // 中间区域走原逻辑
        }
    }

    /* 调节阶段：左右边缘时吞掉滚动、修改亮度/音量 */
    if (gMode != DYEdgeModeNone) {
        if (st == UIGestureRecognizerStateChanged) {
            CGFloat delta = (gStartY - loc.y) / self.bounds.size.height; // ↑ 为正
            const CGFloat kScale = 2.0;                                  // 灵敏度
            float newVal = gStartVal + delta * kScale;
            newVal = fminf(fmaxf(newVal, 0.0), 1.0); // Clamp 0~1

            if (gMode == DYEdgeModeBrightness) {
                [UIScreen mainScreen].brightness = newVal;
                // 弹系统亮度 HUD
                [[%c(SBHUDController) sharedInstance] presentHUDWithIcon:@"Brightness" level:newVal];
            } else { // DYEdgeModeVolume
                // iOS 18 音量控制 + 系统音量 HUD
                [[objc_getClass("AVSystemController") sharedAVSystemController] setVolumeTo:newVal forCategory:@"Audio/Video"];
            }

            // 吞掉滚动：归零 translation，防止内容位移
            [pan setTranslation:CGPointZero inView:self];
        }

        /* 结束／取消：状态复位 */
        if (st == UIGestureRecognizerStateEnded || st == UIGestureRecognizerStateCancelled || st == UIGestureRecognizerStateFailed) {
            gMode = DYEdgeModeNone;
        }

        return; // 左右边缘：彻底阻断 %orig，避免翻页
    }

    /* 中间区域：直接执行原先翻页逻辑 */
    %orig;
}

%end

%hook AWELeftSideBarAddChildTransitionObject

- (void)handleShowSliderPanGesture:(id)gr {
    if (DYYYGetBool(@"DYYYDisableSidebarGesture")) {
        return;
    }
    %orig(gr);
}

%end

// 关注二次确认：弹窗关闭后再触发原逻辑，且不再传入已失效的手势对象。
static void DYYYRunDeferredFollowConfirm(void (^action)(void)) {
    if (!action) {
        return;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            action();
        });
    });
}

%hook AWEPlayInteractionUserAvatarElement
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
    if (DYYYGetBool(@"DYYYFollowTips")) {
        // 获取用户信息
        AWEUserModel *author = nil;
        NSString *nickname = @"";
        NSString *signature = @"";
        NSString *avatarURL = @"";

        if ([self respondsToSelector:@selector(model)]) {
            id model = [self model];
            if ([model isKindOfClass:NSClassFromString(@"AWEAwemeModel")]) {
                author = [model valueForKey:@"author"];
            }
        }

        if (author) {
            // 获取昵称
            if ([author respondsToSelector:@selector(nickname)]) {
                nickname = [author valueForKey:@"nickname"] ?: @"";
            }

            // 获取签名
            if ([author respondsToSelector:@selector(signature)]) {
                signature = [author valueForKey:@"signature"] ?: @"";
            }

            // 获取头像URL
            if ([author respondsToSelector:@selector(avatarThumb)]) {
                AWEURLModel *avatarThumb = [author valueForKey:@"avatarThumb"];
                if (avatarThumb && avatarThumb.originURLList.count > 0) {
                    avatarURL = avatarThumb.originURLList.firstObject;
                }
            }
        }

        NSMutableString *messageContent = [NSMutableString string];
        if (signature.length > 0) {
            [messageContent appendFormat:@"%@", signature];
        }

        NSString *title = nickname.length > 0 ? nickname : @"关注确认";

        [DYYYBottomAlertView showAlertWithTitle:title
                                        message:messageContent
                                      avatarURL:avatarURL
                               cancelButtonText:@"取消"
                              confirmButtonText:@"关注"
                                   cancelAction:nil
                                    closeAction:nil
                                  confirmAction:^{
                                    DYYYRunDeferredFollowConfirm(^{
                                        %orig(nil);
                                    });
                                  }];
    } else {
        %orig;
    }
}

%end

%hook AWEPlayInteractionUserAvatarFollowController
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
    if (DYYYGetBool(@"DYYYFollowTips")) {
        // 获取用户信息
        AWEUserModel *author = nil;
        NSString *nickname = @"";
        NSString *signature = @"";
        NSString *avatarURL = @"";

        if ([self respondsToSelector:@selector(model)]) {
            id model = [self model];
            if ([model isKindOfClass:NSClassFromString(@"AWEAwemeModel")]) {
                author = [model valueForKey:@"author"];
            }
        }

        if (author) {
            // 获取昵称
            if ([author respondsToSelector:@selector(nickname)]) {
                nickname = [author valueForKey:@"nickname"] ?: @"";
            }

            // 获取签名
            if ([author respondsToSelector:@selector(signature)]) {
                signature = [author valueForKey:@"signature"] ?: @"";
            }

            // 获取头像URL
            if ([author respondsToSelector:@selector(avatarThumb)]) {
                AWEURLModel *avatarThumb = [author valueForKey:@"avatarThumb"];
                if (avatarThumb && avatarThumb.originURLList.count > 0) {
                    avatarURL = avatarThumb.originURLList.firstObject;
                }
            }
        }

        NSMutableString *messageContent = [NSMutableString string];
        if (signature.length > 0) {
            [messageContent appendFormat:@"%@", signature];
        }

        NSString *title = nickname.length > 0 ? nickname : @"关注确认";

        [DYYYBottomAlertView showAlertWithTitle:title
                                        message:messageContent
                                      avatarURL:avatarURL
                               cancelButtonText:@"取消"
                              confirmButtonText:@"关注"
                                   cancelAction:nil
                                    closeAction:nil
                                  confirmAction:^{
                                    DYYYRunDeferredFollowConfirm(^{
                                        %orig(nil);
                                    });
                                  }];
    } else {
        %orig;
    }
}

%end

static BOOL DYYYIsFollowRelationToastText(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) {
        return NO;
    }
    return [text containsString:@"已取消关注"] || [text containsString:@"关注成功"] || [text isEqualToString:@"已关注"] ||
           [text containsString:@"取消关注成功"];
}

// 统一到视频页「已取消关注」高度：安全区顶部 + 76pt（对齐用户参考图1）
static const CGFloat kDYYYFollowToastTopOffset = 76.0;

static UIWindow *DYYYToastReferenceWindow(void) {
    UIWindow *window = [DYYYUtils getActiveWindow];
    if (!window) {
        window = UIApplication.sharedApplication.windows.firstObject;
    }
    return window;
}

static CGPoint DYYYTopToastCenterPointInView(UIView *view) {
    UIWindow *window = DYYYToastReferenceWindow();
    if (!window) {
        return CGPointMake(UIScreen.mainScreen.bounds.size.width / 2.0, kDYYYFollowToastTopOffset);
    }

    CGFloat safeTop = 0.0;
    if (@available(iOS 11.0, *)) {
        safeTop = window.safeAreaInsets.top;
    }
    CGPoint windowPoint = CGPointMake(CGRectGetMidX(window.bounds), safeTop + kDYYYFollowToastTopOffset);

    if (view && view != window) {
        return [view convertPoint:windowPoint fromView:window];
    }
    return windowPoint;
}

%hook DUXToast
+ (void)showText:(NSString *)text {
    if (DYYYIsFollowRelationToastText(text) && [self respondsToSelector:@selector(showText:withCenterPoint:)]) {
        [self showText:text withCenterPoint:DYYYTopToastCenterPointInView(nil)];
        return;
    }
    %orig;
}

+ (void)showText:(NSString *)text withCenterPoint:(CGPoint)centerPoint {
    if (DYYYIsFollowRelationToastText(text)) {
        centerPoint = DYYYTopToastCenterPointInView(nil);
    }
    %orig(text, centerPoint);
}

+ (void)showText:(NSString *)text onView:(UIView *)view {
    if (DYYYIsFollowRelationToastText(text) && [self respondsToSelector:@selector(showText:onView:withCenterPoint:)]) {
        [self showText:text onView:view withCenterPoint:DYYYTopToastCenterPointInView(view)];
        return;
    }
    %orig;
}

+ (void)showText:(NSString *)text onView:(UIView *)view withCenterPoint:(CGPoint)centerPoint {
    if (DYYYIsFollowRelationToastText(text)) {
        centerPoint = DYYYTopToastCenterPointInView(view);
    }
    %orig(text, view, centerPoint);
}

- (void)show {
    NSString *text = nil;
    if ([self respondsToSelector:@selector(text)]) {
        text = [(id)self text];
    }
    if (DYYYIsFollowRelationToastText(text) && [self respondsToSelector:@selector(showWithCenterPoint:)]) {
        [(id)self showWithCenterPoint:DYYYTopToastCenterPointInView(nil)];
        return;
    }
    %orig;
}

- (void)showOnView:(UIView *)view {
    NSString *text = nil;
    if ([self respondsToSelector:@selector(text)]) {
        text = [(id)self text];
    }
    if (DYYYIsFollowRelationToastText(text) && [self respondsToSelector:@selector(showOnView:withCenterPoint:)]) {
        [(id)self showOnView:view withCenterPoint:DYYYTopToastCenterPointInView(view)];
        return;
    }
    %orig;
}

- (void)showWithCenterPoint:(CGPoint)centerPoint {
    NSString *text = nil;
    if ([self respondsToSelector:@selector(text)]) {
        text = [(id)self text];
    }
    if (DYYYIsFollowRelationToastText(text)) {
        centerPoint = DYYYTopToastCenterPointInView(nil);
    }
    %orig(centerPoint);
}

- (void)showOnView:(UIView *)view withCenterPoint:(CGPoint)centerPoint {
    NSString *text = nil;
    if ([self respondsToSelector:@selector(text)]) {
        text = [(id)self text];
    }
    if (DYYYIsFollowRelationToastText(text)) {
        centerPoint = DYYYTopToastCenterPointInView(view);
    }
    %orig(view, centerPoint);
}
%end

static BOOL DYYYProfileFollowConfirmIsShowing = NO;

static id DYYYUserModelFromProfileHeaderContext(id headerContext) {
    if (!headerContext) {
        return nil;
    }
    if ([headerContext respondsToSelector:@selector(userModel)]) {
        return [headerContext userModel];
    }
    return nil;
}

static void DYYYShowProfileFollowGlassConfirm(id user, void (^confirmAction)(void)) {
    if (!confirmAction || DYYYProfileFollowConfirmIsShowing) {
        return;
    }

    NSString *nickname = @"";
    NSString *signature = @"";
    if (user) {
        if ([user respondsToSelector:@selector(nickname)]) {
            nickname = [user valueForKey:@"nickname"] ?: @"";
        }
        if ([user respondsToSelector:@selector(signature)]) {
            signature = [user valueForKey:@"signature"] ?: @"";
        }
    }

    NSString *title = nickname.length > 0 ? nickname : @"关注确认";
    NSString *message = signature.length > 0 ? signature : @"确定要关注该用户吗？";

    DYYYProfileFollowConfirmIsShowing = YES;
    [DYYYGlassConfirmView showWithTitle:title
                                message:message
                       cancelButtonText:@"取消"
                      confirmButtonText:@"确定"
                            cancelAction:^{
                              DYYYProfileFollowConfirmIsShowing = NO;
                            }
                           confirmAction:^{
                              DYYYProfileFollowConfirmIsShowing = NO;
                              DYYYRunDeferredFollowConfirm(confirmAction);
                            }];
}

%hook AWEProfileFollowAreaFollowComponent
- (void)handleFollowEventWithHeaderContext:(id)headerContext
                               enterMethod:(id)enterMethod
                             fromTopButton:(BOOL)fromTopButton
                                completion:(id)completion {
    if (DYYYGetBool(@"DYYYFollowTips")) {
        id user = DYYYUserModelFromProfileHeaderContext(headerContext);
        DYYYShowProfileFollowGlassConfirm(user, ^{
          %orig(headerContext, enterMethod, fromTopButton, completion);
        });
        return;
    }

    %orig;
}
%end

%hook AWEProfileHeaderFollowAreaCell
- (void)p_follow:(id)sender {
    if (DYYYGetBool(@"DYYYFollowTips")) {
        id user = DYYYUserModelFromProfileHeaderContext(self.context);
        DYYYShowProfileFollowGlassConfirm(user, ^{
          %orig(sender);
        });
        return;
    }

    %orig;
}

- (void)followUser {
    if (DYYYGetBool(@"DYYYFollowTips")) {
        id user = DYYYUserModelFromProfileHeaderContext(self.context);
        DYYYShowProfileFollowGlassConfirm(user, ^{
          %orig;
        });
        return;
    }

    %orig;
}
%end

%hook AWEFeedTopBarContainer
- (void)didMoveToSuperview {
    %orig;
    applyTopBarTransparency(self);
}
- (void)setAlpha:(CGFloat)alpha {
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTopBarTransparent"];
    if (transparentValue && transparentValue.length > 0) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            CGFloat finalAlpha = (alphaValue < 0.011) ? 0.011 : alphaValue;
            %orig(finalAlpha);
        } else {
            %orig(1.0);
        }
    } else {
        %orig(1.0);
    }
}
%end

// 设置修改顶栏标题
%hook AWEHPTopTabItemTextContentView

- (void)layoutSubviews {
    %orig;
    NSDictionary<NSString *, NSString *> *titleMapping = DYYYTopTabTitleMapping();
    if (titleMapping.count == 0) {
        return;
    }

    NSString *accessibilityLabel = nil;
    if ([self.superview respondsToSelector:@selector(accessibilityLabel)]) {
        accessibilityLabel = self.superview.accessibilityLabel;
    }
    if (accessibilityLabel.length == 0) {
        return;
    }

    NSString *newTitle = titleMapping[accessibilityLabel];
    if (newTitle.length == 0) {
        return;
    }

    if ([self respondsToSelector:@selector(setContentText:)]) {
        [self setContentText:newTitle];
    } else {
        [self setValue:newTitle forKey:@"contentText"];
    }
}

%end

%hook AWEDanmakuContentLabel
- (void)setTextColor:(UIColor *)textColor {
    if (DYYYGetBool(@"DYYYEnableDanmuColor")) {
        NSString *danmuColor = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDanmuColor"];
        if (DYYYGetBool(@"DYYYDanmuRainbowRotating")) {
            danmuColor = @"rainbow_rotating";
        }
        [DYYYUtils applyColorSettingsToLabel:self colorHexString:danmuColor];
    } else {
        %orig(textColor);
    }
}

- (void)setStrokeWidth:(double)strokeWidth {
    if (DYYYGetBool(@"DYYYEnableDanmuColor")) {
        %orig(FLT_MIN);
    } else {
        %orig(strokeWidth);
    }
}

- (void)setStrokeColor:(UIColor *)strokeColor {
    if (DYYYGetBool(@"DYYYEnableDanmuColor")) {
        %orig(nil);
    } else {
        %orig(strokeColor);
    }
}

%end

%hook XIGDanmakuPlayerView

- (id)initWithFrame:(CGRect)frame {
    id orig = %orig;

    ((UIView *)orig).tag = DYYY_IGNORE_GLOBAL_ALPHA_TAG;

    return orig;
}

- (void)setAlpha:(CGFloat)alpha {
    if (DYYYGetBool(@"DYYYCommentShowDanmaku") && alpha == 0.0) {
        return;
    } else {
        %orig(alpha);
    }
}

%end

%hook DDanmakuPlayerView

- (void)setAlpha:(CGFloat)alpha {
    if (DYYYGetBool(@"DYYYCommentShowDanmaku") && alpha == 0.0) {
        return;
    } else {
        %orig(alpha);
    }
}

%end

%hook AWEFeedAnchorPOIConfig

+ (BOOL)hasAnchorViewDataWithAwemeModelForFeed:(id)awemeModel extraInfo:(id)extraInfo {
    if (DYYYGetBool(@"DYYYHideLocation")) {
        return NO;
    }
    return %orig(awemeModel, extraInfo);
}

%end

%hook AWEFeedAnchorPOITradeConfig

+ (BOOL)hasAnchorViewDataWithAwemeModelForFeed:(id)awemeModel extraInfo:(id)extraInfo {
    if (DYYYGetBool(@"DYYYHideLocation")) {
        return NO;
    }
    return %orig(awemeModel, extraInfo);
}

%end

static char kDYYYFeedLocationContainerManagedHiddenKey;
static char kDYYYFeedLocationContainerOriginalHiddenKey;
static char kDYYYFeedAnchorArrangedManagedHiddenKey;
static char kDYYYFeedAnchorArrangedOriginalHiddenKey;

static void DYYYApplyPlayInteractionElementLayout(UIView *view, NSString *fallbackClassName);
static void DYYYSyncHiddenFeedAnchorArrangedView(UIView *inner);

%hook AWEFeedAnchorContainerView

- (void)layoutSubviews {
    %orig;

    BOOL containsLocationAnchor = NO;
    Class poiEntryClass = NSClassFromString(@"AWEPOIEntryAnchorView");
    Class poiTradeEntryClass = NSClassFromString(@"AWEPOITradeEntryAnchorView");
    if ((poiEntryClass && [DYYYUtils containsSubviewOfClass:poiEntryClass inContainer:self]) ||
        (poiTradeEntryClass && [DYYYUtils containsSubviewOfClass:poiTradeEntryClass inContainer:self])) {
        containsLocationAnchor = YES;
    }

    if (!containsLocationAnchor) {
        Class templateAnchorV2Class = NSClassFromString(@"AWEFeedTemplateAnchorViewV2");
        NSArray<UIView *> *templateAnchorViews = [DYYYUtils findAllSubviewsOfClass:templateAnchorV2Class inContainer:self];
        for (AWEFeedTemplateAnchorViewV2 *templateAnchorView in templateAnchorViews) {
            AWECodeGenCommonAnchorBasicInfoModel *anchorInfo = templateAnchorView.templateAnchorInfo;
            if ([anchorInfo.name isEqualToString:@"poi_poi"]) {
                containsLocationAnchor = YES;
                break;
            }
        }
    }

    NSNumber *managedHidden = objc_getAssociatedObject(self, &kDYYYFeedLocationContainerManagedHiddenKey);
    if (DYYYGetBool(@"DYYYHideLocation") && containsLocationAnchor) {
        if (![managedHidden boolValue]) {
            objc_setAssociatedObject(self, &kDYYYFeedLocationContainerOriginalHiddenKey, @(self.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &kDYYYFeedLocationContainerManagedHiddenKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        self.hidden = YES;
        return;
    }

    DYYYSyncHiddenFeedAnchorArrangedView(self);
    if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
        return;
    }

    if ([managedHidden boolValue]) {
        NSNumber *originalHidden = objc_getAssociatedObject(self, &kDYYYFeedLocationContainerOriginalHiddenKey);
        objc_setAssociatedObject(self, &kDYYYFeedLocationContainerManagedHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &kDYYYFeedLocationContainerOriginalHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        self.hidden = originalHidden ? originalHidden.boolValue : NO;
    }

    // 定位/特效锚点未必是左侧栏的直接子项，这里补一次跟随昵称的缩放与 Y 轴
    UIViewController *anchorViewController = [DYYYUtils firstAvailableViewControllerFromView:self];
    if ([anchorViewController isKindOfClass:%c(AWEPlayInteractionViewController)]) {
        DYYYApplyPlayInteractionElementLayout(self, @"AWEPlayInteractionAnchorElement");
    }
}

%end

%hook AWEMarkView

- (void)layoutSubviews {
    %orig;

    Class poiConfigClass = NSClassFromString(@"AWEFeedAnchorPOIConfig");
    Class poiTradeConfigClass = NSClassFromString(@"AWEFeedAnchorPOITradeConfig");
    SEL feedVisibilitySelector = @selector(hasAnchorViewDataWithAwemeModelForFeed:extraInfo:);
    BOOL supportsPOIConfigVisibility =
        (poiConfigClass && class_getClassMethod(poiConfigClass, feedVisibilitySelector)) ||
        (poiTradeConfigClass && class_getClassMethod(poiTradeConfigClass, feedVisibilitySelector));
    if (DYYYGetBool(@"DYYYHideLocation") && !supportsPOIConfigVisibility) {
        self.hidden = YES;
        return;
    }
}

%end

%group DYYYSettingsGesture

%hook UIWindow
- (instancetype)initWithFrame:(CGRect)frame {
    UIWindow *window = %orig(frame);
    if (window) {
        UILongPressGestureRecognizer *doubleFingerLongPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleFingerLongPressGesture:)];
        doubleFingerLongPressGesture.numberOfTouchesRequired = 2;
        [window addGestureRecognizer:doubleFingerLongPressGesture];
    }
    return window;
}

%new
- (void)handleDoubleFingerLongPressGesture:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        UIViewController *rootViewController = self.rootViewController;
        if (rootViewController) {
            UIViewController *settingVC = [[DYYYSettingViewController alloc] init];

            if (settingVC) {
                BOOL isIPad = UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad;
                if (@available(iOS 15.0, *)) {
                    if (!isIPad) {
                        settingVC.modalPresentationStyle = UIModalPresentationPageSheet;
                    } else {
                        settingVC.modalPresentationStyle = UIModalPresentationFullScreen;
                    }
                } else {
                    settingVC.modalPresentationStyle = UIModalPresentationFullScreen;
                }

                if (settingVC.modalPresentationStyle == UIModalPresentationFullScreen) {
                    UIButton *closeButton = [UIButton buttonWithType:UIButtonTypeSystem];
                    [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
                    closeButton.translatesAutoresizingMaskIntoConstraints = NO;

                    [settingVC.view addSubview:closeButton];

                    [NSLayoutConstraint activateConstraints:@[
                        [closeButton.trailingAnchor constraintEqualToAnchor:settingVC.view.trailingAnchor constant:-10],
                        [closeButton.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:40], [closeButton.widthAnchor constraintEqualToConstant:80],
                        [closeButton.heightAnchor constraintEqualToConstant:40]
                    ]];

                    [closeButton addTarget:self action:@selector(closeSettings:) forControlEvents:UIControlEventTouchUpInside];
                }

                UIView *handleBar = [[UIView alloc] init];
                handleBar.backgroundColor = [UIColor whiteColor];
                handleBar.layer.cornerRadius = 2.5;
                handleBar.translatesAutoresizingMaskIntoConstraints = NO;
                [settingVC.view addSubview:handleBar];

                [NSLayoutConstraint activateConstraints:@[
                    [handleBar.centerXAnchor constraintEqualToAnchor:settingVC.view.centerXAnchor], [handleBar.topAnchor constraintEqualToAnchor:settingVC.view.topAnchor constant:8],
                    [handleBar.widthAnchor constraintEqualToConstant:40], [handleBar.heightAnchor constraintEqualToConstant:5]
                ]];

                [rootViewController presentViewController:settingVC animated:YES completion:nil];
            }
        }
    }
}

%new
- (void)closeSettings:(UIButton *)button {
    [button.superview.window.rootViewController dismissViewControllerAnimated:YES completion:nil];
}

%end

%end

%hook AWEBaseListViewController
- (void)viewDidLayoutSubviews {
    %orig;
    [self applyBlurEffectIfNeeded];
}

%new
- (void)applyBlurEffectIfNeeded {
    if (DYYYGetBool(@"DYYYEnableCommentBlur") && [self isKindOfClass:NSClassFromString(@"AWECommentPanelContainerSwiftImpl.CommentContainerInnerViewController")]) {
        // 动态获取用户设置的透明度
        float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
        if (userTransparency <= 0 || userTransparency > 1) {
            userTransparency = 0.9;
        }

        // 应用毛玻璃效果
        [DYYYUtils applyBlurEffectToView:self.view transparency:userTransparency blurViewTag:999];
    }
}
%end

static BOOL DYYYFeedVideoCollectButtonHideEnabled(void) {
    return DYYYGetBoolCached(@"DYYYHideCollectButton");
}

static NSString *DYYYObjectStringForSelector(id object, SEL selector) {
    if (!object || !selector || ![object respondsToSelector:selector]) {
        return nil;
    }

    id value = nil;
    @try {
        value = ((id (*)(id, SEL))objc_msgSend)(object, selector);
    } @catch (__unused NSException *exception) {
        value = nil;
    }

    return [value isKindOfClass:[NSString class]] ? (NSString *)value : nil;
}

static BOOL DYYYFeedVideoCollectKeywordMatches(NSString *value) {
    if (value.length == 0) {
        return NO;
    }

    NSString *lowercaseValue = value.lowercaseString;
    return [value containsString:@"收藏"] ||
           [lowercaseValue containsString:@"favorite"] ||
           [lowercaseValue containsString:@"collect"] ||
           [lowercaseValue containsString:@"collection"];
}

static BOOL DYYYIsFeedVideoCollectButton(id button) {
    if (!button) {
        return NO;
    }

    Class feedVideoButtonClass = NSClassFromString(@"AWEFeedVideoButton");
    if (!feedVideoButtonClass || ![button isKindOfClass:feedVideoButtonClass]) {
        return NO;
    }

    NSString *accessibilityLabel = DYYYObjectStringForSelector(button, @selector(accessibilityLabel));
    if (DYYYFeedVideoCollectKeywordMatches(accessibilityLabel)) {
        return YES;
    }

    NSString *accessibilityIdentifier = DYYYObjectStringForSelector(button, @selector(accessibilityIdentifier));
    if (DYYYFeedVideoCollectKeywordMatches(accessibilityIdentifier)) {
        return YES;
    }

    NSString *imageNameString = DYYYObjectStringForSelector(button, @selector(imageNameString));
    return DYYYFeedVideoCollectKeywordMatches(imageNameString);
}

static void DYYYMarkFeedVideoCollectButtonLayerHidden(CALayer *layer) {
    if (!layer) {
        return;
    }

    objc_setAssociatedObject(layer, &kDYYYFeedVideoCollectButtonHiddenLayerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    layer.hidden = YES;
    layer.contents = nil;
    layer.opacity = 0.0f;
    layer.backgroundColor = UIColor.clearColor.CGColor;
    layer.borderWidth = 0.0;
    layer.borderColor = UIColor.clearColor.CGColor;
    layer.shadowOpacity = 0.0f;
    layer.shadowColor = UIColor.clearColor.CGColor;
    if ([layer isKindOfClass:[CAShapeLayer class]]) {
        CAShapeLayer *shapeLayer = (CAShapeLayer *)layer;
        shapeLayer.fillColor = UIColor.clearColor.CGColor;
        shapeLayer.strokeColor = UIColor.clearColor.CGColor;
    }

    for (CALayer *sublayer in [layer.sublayers copy]) {
        DYYYMarkFeedVideoCollectButtonLayerHidden(sublayer);
    }
}

// CALayer 的各个 setter 属于渲染最热路径，而关联对象查询需要经过 runtime 全局表。
// 先判定开关（命中缓存后近乎零开销），关闭时直接短路，避免无谓的关联对象查找。
static BOOL DYYYShouldForceHideFeedVideoCollectButtonLayer(CALayer *layer) {
    return layer && DYYYFeedVideoCollectButtonHideEnabled() && objc_getAssociatedObject(layer, &kDYYYFeedVideoCollectButtonHiddenLayerKey);
}

static BOOL DYYYShouldClearFeedVideoCollectButtonLayer(CALayer *layer) {
    return DYYYShouldForceHideFeedVideoCollectButtonLayer(layer);
}

static void DYYYPrepareFeedVideoCollectButtonSublayer(CALayer *parentLayer, CALayer *sublayer) {
    if (!parentLayer || !sublayer) {
        return;
    }

    if (DYYYFeedVideoCollectButtonHideEnabled() && objc_getAssociatedObject(parentLayer, &kDYYYFeedVideoCollectButtonHiddenLayerKey)) {
        DYYYMarkFeedVideoCollectButtonLayerHidden(sublayer);
    }
}

static BOOL DYYYShouldForceHideFeedVideoCollectButtonView(UIView *view) {
    return view && DYYYFeedVideoCollectButtonHideEnabled() && objc_getAssociatedObject(view, &kDYYYFeedVideoCollectButtonHiddenViewKey);
}

static void DYYYClearFeedVideoCollectImageView(UIImageView *imageView) {
    if (!imageView) {
        return;
    }

    imageView.image = nil;
    imageView.highlightedImage = nil;
    imageView.animationImages = nil;
    imageView.highlightedAnimationImages = nil;
}

static void DYYYMarkFeedVideoCollectButtonViewHidden(UIView *view) {
    if (!view) {
        return;
    }

    objc_setAssociatedObject(view, &kDYYYFeedVideoCollectButtonHiddenViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    view.hidden = YES;
    view.alpha = 0.0;
    view.userInteractionEnabled = NO;
    view.accessibilityElementsHidden = YES;
    view.backgroundColor = UIColor.clearColor;
    if ([view isKindOfClass:[UIImageView class]]) {
        DYYYClearFeedVideoCollectImageView((UIImageView *)view);
    }
    DYYYMarkFeedVideoCollectButtonLayerHidden(view.layer);

    for (UIView *subview in [view.subviews copy]) {
        DYYYMarkFeedVideoCollectButtonViewHidden(subview);
    }
}

static void DYYYSetFeedVideoButtonLabelsHidden(UIView *view, BOOL hidden) {
    if (!view) {
        return;
    }

    if ([view isKindOfClass:[UILabel class]]) {
        view.hidden = hidden;
    }

    for (UIView *subview in [view.subviews copy]) {
        DYYYSetFeedVideoButtonLabelsHidden(subview, hidden);
    }
}

static void DYYYApplyFeedVideoCollectButtonSettings(AWEFeedVideoButton *button) {
    if (!DYYYIsFeedVideoCollectButton(button)) {
        return;
    }

    if (DYYYFeedVideoCollectButtonHideEnabled()) {
        DYYYMarkFeedVideoCollectButtonViewHidden(button);
        [button removeFromSuperview];
        return;
    }

    if (DYYYGetBool(@"DYYYHideCollectLabel")) {
        DYYYSetFeedVideoButtonLabelsHidden(button, YES);
    }
}

static void DYYYApplyFeedVideoCollectButtonSettingsWithRetry(AWEFeedVideoButton *button) {
    if (!DYYYIsFeedVideoCollectButton(button)) {
        return;
    }

    DYYYApplyFeedVideoCollectButtonSettings(button);
    if (!DYYYFeedVideoCollectButtonHideEnabled() || objc_getAssociatedObject(button, &kDYYYFeedVideoCollectButtonDeferredApplyKey)) {
        return;
    }

    objc_setAssociatedObject(button, &kDYYYFeedVideoCollectButtonDeferredApplyKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak AWEFeedVideoButton *weakButton = button;
    dispatch_async(dispatch_get_main_queue(), ^{
      AWEFeedVideoButton *strongButton = weakButton;
      if (!strongButton) {
          return;
      }
      DYYYApplyFeedVideoCollectButtonSettings(strongButton);
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        AWEFeedVideoButton *delayedButton = weakButton;
        if (!delayedButton) {
            return;
        }
        DYYYApplyFeedVideoCollectButtonSettings(delayedButton);
        objc_setAssociatedObject(delayedButton, &kDYYYFeedVideoCollectButtonDeferredApplyKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      });
    });
}

%hook AWEFeedVideoButton
- (id)touchUpInsideBlock {
    id r = %orig;

    // 只有收藏按钮才显示确认弹窗
    if (DYYYGetBool(@"DYYYCollectTips") && DYYYIsFeedVideoCollectButton(self)) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [DYYYBottomAlertView showAlertWithTitle:@"收藏确认"
                                          message:@"是否确认/取消收藏？"
                                        avatarURL:nil
                                 cancelButtonText:nil
                                confirmButtonText:nil
                                     cancelAction:nil
                                      closeAction:nil
                                    confirmAction:^{
                                      if (r && [r isKindOfClass:NSClassFromString(@"NSBlock")]) {
                                          ((void (^)(void))r)();
                                      }
                                    }];
        });

        return nil;
    }

    return r;
}
%end

%hook AWEPlayInteractionProgressContainerView
- (void)layoutSubviews {
    %orig;
    DYYYApplyFloatClearProgressStateToView(self);

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFullScreen"]) {
        return;
    }

    static char kDYProgressBgKey;
    NSArray *bgViews = objc_getAssociatedObject(self, &kDYProgressBgKey);
    if (!bgViews) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview class] == [UIView class]) {
                [tmp addObject:subview];
            }
        }
        bgViews = [tmp copy];
        objc_setAssociatedObject(self, &kDYProgressBgKey, bgViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *v in bgViews) {
        v.backgroundColor = [UIColor clearColor];
    }
}

%end

%hook AWEFeedProgressSlider

- (void)layoutSubviews {
    %orig;
    DYYYApplyFloatClearProgressStateToView(self);
}

- (void)setAlpha:(CGFloat)alpha {
    if (DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        if (DYYYGetBool(@"DYYYHideVideoProgress")) {
            %orig(0);
        } else {
            %orig(1.0);
        }
    } else {
        %orig;
    }
}

%new
- (NSString *)dyyy_formatTimeFromSeconds:(CGFloat)seconds {
    CGFloat safeSeconds = seconds;
    if (safeSeconds < 0) {
        safeSeconds = 0;
    }

    NSInteger total = (NSInteger)floor(safeSeconds);
    NSInteger hours = total / 3600;
    NSInteger minutes = (total % 3600) / 60;
    NSInteger secs = total % 60;

    if (hours > 0) {
        return [NSString stringWithFormat:@"%02ld:%02ld:%02ld", (long)hours, (long)minutes, (long)secs];
    }
    return [NSString stringWithFormat:@"%02ld:%02ld", (long)minutes, (long)secs];
}

%new
- (CGFloat)dyyy_modelDurationInSeconds {
    id delegate = self.progressSliderDelegate;
    if (!delegate || ![delegate respondsToSelector:@selector(model)]) {
        return 0;
    }

    id model = [delegate valueForKey:@"model"];
    if (!model || ![model respondsToSelector:@selector(videoDuration)]) {
        return 0;
    }

    CGFloat videoDurationMs = [[model valueForKey:@"videoDuration"] doubleValue];
    if (videoDurationMs <= 0) {
        return 0;
    }
    return videoDurationMs / 1000.0;
}

%new
- (CGFloat)dyyy_scheduleVerticalOffset {
    CGFloat verticalOffset = -12.5;
    NSString *offsetValueString = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTimelineVerticalPosition"];
    if (offsetValueString.length > 0) {
        CGFloat configuredOffset = [offsetValueString floatValue];
        if (configuredOffset != 0) {
            verticalOffset = configuredOffset;
        }
    }
    return verticalOffset;
}

%new
- (void)dyyy_removeScheduleLabels {
    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }
    [parentView layoutIfNeeded];
    [self layoutIfNeeded];
    [[parentView viewWithTag:10001] removeFromSuperview];
    [[parentView viewWithTag:10002] removeFromSuperview];
}

%new
- (void)dyyy_updateScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        [self dyyy_removeScheduleLabels];
        return;
    }

    if (![NSThread isMainThread]) {
        __weak __typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          [weakSelf dyyy_updateScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
        });
        return;
    }

    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }
    [parentView layoutIfNeeded];
    [self layoutIfNeeded];

    NSString *scheduleStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
    BOOL showRightRemainingTime = [scheduleStyle isEqualToString:@"进度条右侧剩余"];
    BOOL showRightCompleteTime = [scheduleStyle isEqualToString:@"进度条右侧完整"];
    BOOL showLeftRemainingTime = [scheduleStyle isEqualToString:@"进度条左侧剩余"];
    BOOL showLeftCompleteTime = [scheduleStyle isEqualToString:@"进度条左侧完整"];

    BOOL shouldShowLeftLabel = !showRightRemainingTime && !showRightCompleteTime;
    BOOL shouldShowRightLabel = !showLeftRemainingTime && !showLeftCompleteTime;

    CGFloat modelDuration = [self dyyy_modelDurationInSeconds];
    CGFloat effectiveTotalDuration = totalDuration > 0 ? totalDuration : modelDuration;
    if (effectiveTotalDuration < 0) {
        effectiveTotalDuration = 0;
    }

    CGFloat effectiveCurrentTime = currentTime;
    if (effectiveCurrentTime < 0) {
        effectiveCurrentTime = 0;
    }
    if (effectiveTotalDuration > 0 && effectiveCurrentTime > effectiveTotalDuration) {
        effectiveCurrentTime = effectiveTotalDuration;
    }

    CGRect sliderFrameInParent = [self convertRect:self.bounds toView:parentView];
    if (CGRectGetWidth(sliderFrameInParent) <= 1.0 || CGRectGetHeight(sliderFrameInParent) <= 1.0) {
        return;
    }
    CGFloat labelYPosition = CGRectGetMinY(sliderFrameInParent) + [self dyyy_scheduleVerticalOffset];
    CGFloat labelHeight = 15.0;
    UIFont *labelFont = [UIFont systemFontOfSize:8];
    NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYProgressLabelColor"];

    UILabel *leftLabel = (UILabel *)[parentView viewWithTag:10001];
    if (leftLabel && ![leftLabel isKindOfClass:[UILabel class]]) {
        [leftLabel removeFromSuperview];
        leftLabel = nil;
    }

    if (shouldShowLeftLabel) {
        if (!leftLabel) {
            leftLabel = [[UILabel alloc] init];
            leftLabel.backgroundColor = [UIColor clearColor];
            leftLabel.tag = 10001;
            [parentView addSubview:leftLabel];
        }

        leftLabel.font = labelFont;
        NSString *newLeftText = nil;
        if (showLeftRemainingTime) {
            newLeftText = [self dyyy_formatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showLeftCompleteTime) {
            newLeftText = [NSString stringWithFormat:@"%@/%@", [self dyyy_formatTimeFromSeconds:effectiveCurrentTime], [self dyyy_formatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newLeftText = [self dyyy_formatTimeFromSeconds:effectiveCurrentTime];
        }

        if (![leftLabel.text isEqualToString:newLeftText]) {
            leftLabel.text = newLeftText;
        }
        [leftLabel sizeToFit];
        leftLabel.frame = CGRectMake(CGRectGetMinX(sliderFrameInParent), labelYPosition, CGRectGetWidth(leftLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:leftLabel colorHexString:labelColorHex];
    } else {
        [leftLabel removeFromSuperview];
    }

    UILabel *rightLabel = (UILabel *)[parentView viewWithTag:10002];
    if (rightLabel && ![rightLabel isKindOfClass:[UILabel class]]) {
        [rightLabel removeFromSuperview];
        rightLabel = nil;
    }

    if (shouldShowRightLabel) {
        if (!rightLabel) {
            rightLabel = [[UILabel alloc] init];
            rightLabel.backgroundColor = [UIColor clearColor];
            rightLabel.tag = 10002;
            [parentView addSubview:rightLabel];
        }

        rightLabel.font = labelFont;
        NSString *newRightText = nil;
        if (showRightRemainingTime) {
            newRightText = [self dyyy_formatTimeFromSeconds:MAX(effectiveTotalDuration - effectiveCurrentTime, 0)];
        } else if (showRightCompleteTime) {
            newRightText = [NSString stringWithFormat:@"%@/%@", [self dyyy_formatTimeFromSeconds:effectiveCurrentTime], [self dyyy_formatTimeFromSeconds:effectiveTotalDuration]];
        } else {
            newRightText = [self dyyy_formatTimeFromSeconds:effectiveTotalDuration];
        }

        if (![rightLabel.text isEqualToString:newRightText]) {
            rightLabel.text = newRightText;
        }
        [rightLabel sizeToFit];
        CGFloat rightLabelX = MAX(CGRectGetMaxX(sliderFrameInParent) - CGRectGetWidth(rightLabel.bounds), CGRectGetMinX(sliderFrameInParent));
        rightLabel.frame = CGRectMake(rightLabelX, labelYPosition, CGRectGetWidth(rightLabel.bounds), labelHeight);
        [DYYYUtils applyColorSettingsToLabel:rightLabel colorHexString:labelColorHex];
    } else {
        [rightLabel removeFromSuperview];
    }
}

- (void)setLimitUpperActionArea:(BOOL)arg1 {
    %orig;
    __weak __typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      [weakSelf dyyy_updateScheduleLabelsWithCurrentTime:0 totalDuration:0];
    });
}

- (void)setHidden:(BOOL)hidden {
    %orig;
    BOOL hideVideoProgress = DYYYGetBool(@"DYYYHideVideoProgress");
    BOOL showScheduleDisplay = DYYYGetBool(@"DYYYShowScheduleDisplay");
    if (hideVideoProgress && showScheduleDisplay && !hidden) {
        self.alpha = 0;
    }
}

%end

static CGFloat DYYYGetUserVerticalOffsetY(NSString *key) {
    NSString *value = [[NSUserDefaults standardUserDefaults] objectForKey:key];
    if (value.length == 0) {
        return 0.0;
    }
    // 设置项约定：上移为正数，下移为负数；UIKit 坐标系中 Y 轴向下为正。
    return -[value floatValue];
}

static CGFloat DYYYGetNicknameVerticalOffset(void) {
    return DYYYGetUserVerticalOffsetY(@"DYYYNicknameVerticalOffset");
}

static CGFloat DYYYGetDescriptionVerticalOffset(void) {
    return DYYYGetUserVerticalOffsetY(@"DYYYDescriptionVerticalOffset");
}

static BOOL DYYYStackViewContainsElementClassName(UIView *stackView, NSString *className) {
    if (!stackView || className.length == 0) {
        return NO;
    }

    for (UIView *sub in [stackView.subviews copy]) {
        if ([sub respondsToSelector:@selector(elementClassName)]) {
            NSString *elementClassName = [sub performSelector:@selector(elementClassName)];
            if ([elementClassName isEqualToString:className]) {
                return YES;
            }
        }
    }
    return NO;
}

static CGFloat DYYYScaleValueForKey(NSString *key) {
    NSString *scaleValue = DYYYUserDefaultsStringValue([[NSUserDefaults standardUserDefaults] objectForKey:key]);
    if (scaleValue.length == 0) {
        return 1.0;
    }
    CGFloat scale = [scaleValue floatValue];
    return scale > 0.0 ? scale : 1.0;
}

static BOOL DYYYIsLeftStackArrangedElementView(UIView *view) {
    return view.superview != nil && [view.superview isKindOfClass:%c(AWEElementStackView)];
}

static UIView *DYYYRawElementViewFromElement(id element) {
    if (!element) {
        return nil;
    }

    UIView *elementView = nil;
    @try {
        id value = [element valueForKey:@"elementView"];
        if ([value isKindOfClass:[UIView class]]) {
            elementView = value;
        }
    } @catch (__unused NSException *exception) {
        elementView = nil;
    }

    if (!elementView) {
        @try {
            id value = [element valueForKey:@"view"];
            if ([value isKindOfClass:[UIView class]]) {
                elementView = value;
            }
        } @catch (__unused NSException *exception) {
            elementView = nil;
        }
    }

    if (!elementView && [element isKindOfClass:[UIView class]]) {
        elementView = (UIView *)element;
    }
    return elementView;
}

// transform 的写入必须脱离当前动画上下文，否则锚点展开等动画会把 1.0 -> scale 的变化插值出来，
// 表现为特效临时由大变小、以及昵称/文案/属地跟着轻微膨胀一下
static void DYYYSetViewTransformWithoutAnimation(UIView *view, CGAffineTransform transform) {
    if (!view || CGAffineTransformEqualToTransform(view.transform, transform)) {
        return;
    }

    [UIView performWithoutAnimation:^{
      [CATransaction begin];
      [CATransaction setDisableActions:YES];
      view.transform = transform;
      [CATransaction commit];
    }];
}

// 绕左边缘缩放并叠加平移：左缘默认不动，可再叠加受控的 extraTx
static void DYYYApplyLeftAlignedScaleAndOffsetXY(UIView *view, CGFloat scale, CGFloat extraTx, CGFloat verticalOffset) {
    if (!view) {
        return;
    }

    BOOL shouldScale = scale > 0.0 && fabs(scale - 1.0) > 0.0001;
    if (!shouldScale) {
        if (fabs(extraTx) <= 0.0001 && fabs(verticalOffset) <= 0.0001) {
            DYYYSetViewTransformWithoutAnimation(view, CGAffineTransformIdentity);
        } else {
            DYYYSetViewTransformWithoutAnimation(view, CGAffineTransformMakeTranslation(extraTx, verticalOffset));
        }
        return;
    }

    CGFloat width = CGRectGetWidth(view.bounds);
    if (width <= 0.0) {
        return;
    }

    CGFloat leftTx = -width * (1.0 - scale) / 2.0 + extraTx;
    DYYYSetViewTransformWithoutAnimation(view, CGAffineTransformMake(scale, 0.0, 0.0, scale, leftTx, verticalOffset));
}

static void DYYYApplyLeftAlignedScaleAndOffset(UIView *view, CGFloat scale, CGFloat verticalOffset) {
    DYYYApplyLeftAlignedScaleAndOffsetXY(view, scale, 0.0, verticalOffset);
}

static BOOL DYYYIsNicknameElementClassName(NSString *elementClassName) {
    return [elementClassName isEqualToString:@"AWEPlayInteractionAuthorElement"] ||
           [elementClassName isEqualToString:@"AWEPlayInteractionStandardAuthorElement"];
}

static BOOL DYYYIsDanmakuElementClassName(NSString *elementClassName) {
    return [elementClassName isEqualToString:@"AWEPlayInteractionDanmakuElement"];
}

// 仅识别明确的左侧昵称附属块；禁止过宽模糊匹配，避免误伤其它元素导致乱飞
static BOOL DYYYIsAnchorElementClassName(NSString *elementClassName) {
    if (elementClassName.length == 0) {
        return NO;
    }
    if (![elementClassName hasPrefix:@"AWEPlayInteraction"]) {
        return NO;
    }
    return [elementClassName containsString:@"Anchor"] || [elementClassName containsString:@"POI"] ||
           [elementClassName containsString:@"Sticker"] || [elementClassName containsString:@"Chapter"] ||
           [elementClassName containsString:@"RecommendToFeed"] || [elementClassName containsString:@"MultiQueue"] ||
           [elementClassName containsString:@"EffectDetail"] || [elementClassName containsString:@"SocialTags"] ||
           [elementClassName containsString:@"DistanceTag"] || [elementClassName containsString:@"TagsElement"] ||
           [elementClassName containsString:@"DarenCard"] || [elementClassName containsString:@"ECommerce"] ||
           [elementClassName containsString:@"GoodsCard"] || [elementClassName containsString:@"GoodsElement"];
}

static BOOL DYYYIsNicknameFollowElementClassName(NSString *elementClassName) {
    return DYYYIsAnchorElementClassName(elementClassName) || DYYYIsDanmakuElementClassName(elementClassName);
}

static BOOL DYYYIsShopFollowElementClassName(NSString *elementClassName) {
    if (elementClassName.length == 0) {
        return NO;
    }
    return [elementClassName containsString:@"ECommerce"] || [elementClassName containsString:@"DarenCard"] ||
           [elementClassName containsString:@"GoodsCard"] || [elementClassName containsString:@"GoodsElement"];
}

static NSArray<NSString *> *DYYYAnchorContentClassNames(void) {
    static NSArray<NSString *> *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      names = @[
          @"AWEFeedAnchorContainerView", @"AWEPlayInteractionSearchAnchorView", @"AWEFeedTemplateAnchorView",
          @"AWEFeedTemplateAnchorViewV2", @"AWEPOIEntryAnchorView", @"AWEPOITradeEntryAnchorView"
      ];
    });
    return names;
}

static NSArray<NSString *> *DYYYShopContentClassNames(void) {
    static NSArray<NSString *> *names = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      names = @[ @"AWEECommerceEntryView" ];
    });
    return names;
}

static NSArray<UIView *> *DYYYShopContentViewsInContainer(UIView *container) {
    if (!container) {
        return @[];
    }
    NSMutableArray<UIView *> *shopViews = [NSMutableArray array];
    for (NSString *className in DYYYShopContentClassNames()) {
        Class shopClass = NSClassFromString(className);
        if (!shopClass) {
            continue;
        }
        if ([container isKindOfClass:shopClass]) {
            [shopViews addObject:container];
        }
        [shopViews addObjectsFromArray:[DYYYUtils findAllSubviewsOfClass:shopClass inContainer:container]];
    }
    return shopViews;
}

static NSArray<UIView *> *DYYYAnchorContentViewsInContainer(UIView *container) {
    if (!container) {
        return @[];
    }

    NSMutableArray<UIView *> *anchorViews = [NSMutableArray array];
    for (NSString *className in DYYYAnchorContentClassNames()) {
        Class anchorClass = NSClassFromString(className);
        if (!anchorClass) {
            continue;
        }
        if ([container isKindOfClass:anchorClass]) {
            [anchorViews addObject:container];
        }
        [anchorViews addObjectsFromArray:[DYYYUtils findAllSubviewsOfClass:anchorClass inContainer:container]];
    }
    return anchorViews;
}

// 锚点被隐藏时不跟随（隐藏视频锚点开关、隐藏定位导致容器 hidden、或整体不可见）
static BOOL DYYYShouldSkipAnchorFollowLayout(UIView *target) {
    if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
        return YES;
    }
    if (!target || target.hidden || target.alpha <= 0.01 || CGRectIsEmpty(target.bounds)) {
        return YES;
    }

    NSArray<UIView *> *anchorViews = DYYYAnchorContentViewsInContainer(target);
    if (anchorViews.count == 0) {
        return NO;
    }

    for (UIView *anchorView in anchorViews) {
        if (!anchorView.hidden && anchorView.alpha > 0.01 && !CGRectIsEmpty(anchorView.bounds)) {
            return NO;
        }
    }
    return YES;
}

static UIView *DYYYFeedAnchorArrangedView(UIView *inner) {
    if (!inner) {
        return nil;
    }
    Class stackClass = %c(AWEElementStackView);
    UIView *arranged = inner;
    while (arranged.superview && stackClass && ![arranged.superview isKindOfClass:stackClass]) {
        arranged = arranged.superview;
    }
    if (stackClass && arranged.superview && [arranged.superview isKindOfClass:stackClass]) {
        return arranged;
    }
    return inner;
}

static void DYYYLogFeedAnchorHookOnce(NSString *event) {
    static NSMutableSet<NSString *> *loggedEvents = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      loggedEvents = [NSMutableSet set];
    });
    @synchronized(loggedEvents) {
        if ([loggedEvents containsObject:event]) {
            return;
        }
        [loggedEvents addObject:event];
    }
    NSLog(@"[DYYY][RuntimeHook][FeedAnchor] %@", event);
}

static void DYYYSyncHiddenFeedAnchorArrangedView(UIView *inner) {
    UIView *arranged = DYYYFeedAnchorArrangedView(inner);
    if (!arranged) {
        return;
    }

    NSNumber *managed = objc_getAssociatedObject(arranged, &kDYYYFeedAnchorArrangedManagedHiddenKey);
    if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
        if (![managed boolValue]) {
            objc_setAssociatedObject(arranged, &kDYYYFeedAnchorArrangedOriginalHiddenKey, @(arranged.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(arranged, &kDYYYFeedAnchorArrangedManagedHiddenKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            DYYYLogFeedAnchorHookOnce(@"Hook 已安装");
            DYYYLogFeedAnchorHookOnce(@"collapsed arranged view");
        }
        arranged.hidden = YES;
        return;
    }

    if ([managed boolValue]) {
        NSNumber *originalHidden = objc_getAssociatedObject(arranged, &kDYYYFeedAnchorArrangedOriginalHiddenKey);
        objc_setAssociatedObject(arranged, &kDYYYFeedAnchorArrangedManagedHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(arranged, &kDYYYFeedAnchorArrangedOriginalHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        arranged.hidden = originalHidden ? originalHidden.boolValue : NO;
    }
}

static BOOL DYYYShouldSkipDanmakuFollowLayout(UIView *target) {
    if (DYYYGetBool(@"DYYYHideDanmuButton")) {
        return YES;
    }
    return !target || target.hidden || target.alpha <= 0.01 || CGRectIsEmpty(target.bounds);
}

static UIView *DYYYFindParentElementStackView(UIView *view) {
    Class stackClass = %c(AWEElementStackView);
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if (stackClass && [ancestor isKindOfClass:stackClass]) {
            return ancestor;
        }
    }
    return nil;
}

static NSString *DYYYReportedElementClassName(UIView *view);
static NSString *DYYYLeftStackElementClassNameForSubview(UIView *sub);

// 截断相邻两项的相对偏移，使缩放后的可视区域不重叠（不额外外推，只削弱相向侵占）
// minGap：基础 1pt 间隙，随属地缩放变为 1*属地缩放（如 0.8 → 0.8pt）
static void DYYYClampAdjacentVerticalPair(CGFloat upperMinY, CGFloat upperMaxY, CGFloat upperScale, CGFloat *upperOffset,
                                          CGFloat lowerMinY, CGFloat lowerMaxY, CGFloat lowerScale, CGFloat *lowerOffset,
                                          CGFloat minGap) {
    if (!upperOffset || !lowerOffset) {
        return;
    }

    CGFloat upperHeight = upperMaxY - upperMinY;
    CGFloat lowerHeight = lowerMaxY - lowerMinY;
    if (upperHeight <= 0.0 || lowerHeight <= 0.0) {
        return;
    }

    if (minGap < 0.0) {
        minGap = 0.0;
    }

    CGFloat maxUpperMinusLower =
        (lowerMinY + lowerHeight * (1.0 - lowerScale) / 2.0) - (upperMaxY - upperHeight * (1.0 - upperScale) / 2.0) - minGap;
    CGFloat excess = (*upperOffset - *lowerOffset) - maxUpperMinusLower;
    if (excess <= 0.0) {
        return;
    }

    BOOL upperMovedDown = *upperOffset > 0.0;
    BOOL lowerMovedUp = *lowerOffset < 0.0;
    if (upperMovedDown && lowerMovedUp) {
        CGFloat upperShare = excess * 0.5;
        *upperOffset -= upperShare;
        *lowerOffset += (excess - upperShare);
    } else if (upperMovedDown) {
        *upperOffset -= excess;
    } else if (lowerMovedUp) {
        *lowerOffset += excess;
    } else {
        *upperOffset -= excess;
    }
}

static BOOL DYYYLeftStackTextItemIsUsable(UIView *view) {
    return view && !view.hidden && view.alpha > 0.01 && !CGRectIsEmpty(view.bounds) && CGRectGetHeight(view.frame) > 0.5;
}

// 基于左侧栏未变换 frame，对昵称/文案/属地的 Y 偏移做自动防重叠截断
static void DYYYClampLeftTextVerticalOffsets(UIView *stackView, CGFloat *nickOffset, CGFloat *descOffset, CGFloat *ipOffset) {
    if (nickOffset) {
        *nickOffset = DYYYGetNicknameVerticalOffset();
    }
    if (descOffset) {
        *descOffset = DYYYGetDescriptionVerticalOffset();
    }
    if (ipOffset) {
        *ipOffset = DYYYGetUserVerticalOffsetY(@"DYYYIPLabelVerticalOffset");
    }
    if (!stackView || !nickOffset || !descOffset || !ipOffset) {
        return;
    }

    UIView *nicknameView = nil;
    UIView *descriptionView = nil;
    UIView *ipView = nil;
    NSMutableArray<UIView *> *measuredViews = [NSMutableArray array];
    NSMutableArray<NSValue *> *savedTransforms = [NSMutableArray array];

    for (UIView *sub in [stackView.subviews copy]) {
        NSString *className = DYYYReportedElementClassName(sub);
        if (className.length == 0) {
            className = DYYYLeftStackElementClassNameForSubview(sub);
        }
        if (DYYYIsNicknameElementClassName(className)) {
            nicknameView = sub;
        } else if ([className isEqualToString:@"AWEPlayInteractionDescriptionElement"]) {
            descriptionView = sub;
        } else if ([className isEqualToString:@"AWEPlayInteractionTimestampElement"]) {
            ipView = sub;
        }
    }

    void (^prepareMeasure)(UIView *) = ^(UIView *view) {
        if (!view) {
            return;
        }
        [measuredViews addObject:view];
        [savedTransforms addObject:[NSValue valueWithCGAffineTransform:view.transform]];
        DYYYSetViewTransformWithoutAnimation(view, CGAffineTransformIdentity);
    };
    prepareMeasure(nicknameView);
    prepareMeasure(descriptionView);
    prepareMeasure(ipView);

    BOOL hasNickname = DYYYLeftStackTextItemIsUsable(nicknameView);
    BOOL hasDescription = DYYYLeftStackTextItemIsUsable(descriptionView);
    BOOL hasIP = DYYYLeftStackTextItemIsUsable(ipView);

    CGFloat nickScale = DYYYScaleValueForKey(@"DYYYNicknameScale");
    CGFloat descScale = DYYYScaleValueForKey(@"DYYYDescriptionScale");
    CGFloat ipScale = DYYYScaleValueForKey(@"DYYYIPLabelScale");
    CGFloat minGap = 1.0 * ipScale; // 默认 1pt，随属地缩放（0.8 → 0.8pt）

    for (NSInteger pass = 0; pass < 4; pass++) {
        if (hasNickname && hasDescription) {
            if (CGRectGetMinY(nicknameView.frame) <= CGRectGetMinY(descriptionView.frame)) {
                DYYYClampAdjacentVerticalPair(CGRectGetMinY(nicknameView.frame), CGRectGetMaxY(nicknameView.frame), nickScale, nickOffset,
                                              CGRectGetMinY(descriptionView.frame), CGRectGetMaxY(descriptionView.frame), descScale, descOffset,
                                              minGap);
            } else {
                DYYYClampAdjacentVerticalPair(CGRectGetMinY(descriptionView.frame), CGRectGetMaxY(descriptionView.frame), descScale, descOffset,
                                              CGRectGetMinY(nicknameView.frame), CGRectGetMaxY(nicknameView.frame), nickScale, nickOffset,
                                              minGap);
            }
        }
        if (hasDescription && hasIP) {
            if (CGRectGetMinY(descriptionView.frame) <= CGRectGetMinY(ipView.frame)) {
                DYYYClampAdjacentVerticalPair(CGRectGetMinY(descriptionView.frame), CGRectGetMaxY(descriptionView.frame), descScale, descOffset,
                                              CGRectGetMinY(ipView.frame), CGRectGetMaxY(ipView.frame), ipScale, ipOffset, minGap);
            } else {
                DYYYClampAdjacentVerticalPair(CGRectGetMinY(ipView.frame), CGRectGetMaxY(ipView.frame), ipScale, ipOffset,
                                              CGRectGetMinY(descriptionView.frame), CGRectGetMaxY(descriptionView.frame), descScale, descOffset,
                                              minGap);
            }
        } else if (hasNickname && hasIP) {
            if (CGRectGetMinY(nicknameView.frame) <= CGRectGetMinY(ipView.frame)) {
                DYYYClampAdjacentVerticalPair(CGRectGetMinY(nicknameView.frame), CGRectGetMaxY(nicknameView.frame), nickScale, nickOffset,
                                              CGRectGetMinY(ipView.frame), CGRectGetMaxY(ipView.frame), ipScale, ipOffset, minGap);
            } else {
                DYYYClampAdjacentVerticalPair(CGRectGetMinY(ipView.frame), CGRectGetMaxY(ipView.frame), ipScale, ipOffset,
                                              CGRectGetMinY(nicknameView.frame), CGRectGetMaxY(nicknameView.frame), nickScale, nickOffset,
                                              minGap);
            }
        }
    }

    for (NSUInteger i = 0; i < measuredViews.count; i++) {
        DYYYSetViewTransformWithoutAnimation(measuredViews[i], savedTransforms[i].CGAffineTransformValue);
    }
}

// Y 轴偏移会把内容移出祖先视图的可视区域，若祖先开启了 clipsToBounds 就会出现“文案消失/被遮挡”
static void DYYYDisableClippingForElementLayout(UIView *view) {
    Class stackClass = %c(AWEElementStackView);
    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if (ancestor.clipsToBounds) {
            ancestor.clipsToBounds = NO;
        }
        if (stackClass && [ancestor isKindOfClass:stackClass]) {
            break;
        }
    }
}

static NSString *DYYYReportedElementClassName(UIView *view) {
    if (![view respondsToSelector:@selector(elementClassName)]) {
        return nil;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    return [view performSelector:@selector(elementClassName)];
#pragma clang diagnostic pop
}

// 变换目标优先取左侧栏“元素块”：既不会被内部 ScrollView 裁剪，也能整块左对齐
static void DYYYResolveElementLayoutTargets(UIView *view, UIView **outArranged, UIView **outElementBlock) {
    *outArranged = nil;
    *outElementBlock = nil;
    if (!view) {
        return;
    }

    Class stackClass = %c(AWEElementStackView);
    Class baseElementClass = %c(AWEBaseElementView);

    for (UIView *ancestor = view; ancestor; ancestor = ancestor.superview) {
        if (!*outElementBlock && baseElementClass && [ancestor isKindOfClass:baseElementClass]) {
            *outElementBlock = ancestor;
        }
        if (stackClass && [ancestor.superview isKindOfClass:stackClass]) {
            *outArranged = ancestor;
            break;
        }
        if (stackClass && [ancestor isKindOfClass:stackClass]) {
            break;
        }
    }

    if (!*outElementBlock) {
        *outElementBlock = *outArranged ?: view;
    }
}

// 元素类名 -> 对应的缩放键与 Y 轴偏移；由“元素块自身类名”决定，保证三者互不抢同一容器
static BOOL DYYYLayoutSettingsForElementClassName(NSString *elementClassName, NSString **outScaleKey, CGFloat *outVerticalOffset) {
    if (elementClassName.length == 0) {
        return NO;
    }

    if (DYYYIsNicknameElementClassName(elementClassName)) {
        *outScaleKey = @"DYYYNicknameScale";
        *outVerticalOffset = DYYYGetNicknameVerticalOffset();
        return YES;
    }
    // 锚点/弹幕：共用昵称缩放；最终 Y = 昵称 Y + 默认间距按缩放比例补偿
    if (DYYYIsNicknameFollowElementClassName(elementClassName)) {
        *outScaleKey = @"DYYYNicknameScale";
        *outVerticalOffset = 0.0;
        return YES;
    }
    if ([elementClassName isEqualToString:@"AWEPlayInteractionDescriptionElement"]) {
        *outScaleKey = @"DYYYDescriptionScale";
        *outVerticalOffset = DYYYGetDescriptionVerticalOffset();
        return YES;
    }
    if ([elementClassName isEqualToString:@"AWEPlayInteractionTimestampElement"]) {
        *outScaleKey = @"DYYYIPLabelScale";
        *outVerticalOffset = DYYYGetUserVerticalOffsetY(@"DYYYIPLabelVerticalOffset");
        return YES;
    }
    return NO;
}

static UIView *DYYYFindNicknameArrangedViewInStack(UIView *stackView) {
    if (!stackView) {
        return nil;
    }

    Class userNameLabelClass = %c(AWEUserNameLabel);
    for (UIView *sub in [stackView.subviews copy]) {
        NSString *className = DYYYReportedElementClassName(sub);
        if (className.length == 0) {
            className = DYYYLeftStackElementClassNameForSubview(sub);
        }
        if (DYYYIsNicknameElementClassName(className)) {
            return sub;
        }
        if (userNameLabelClass && [DYYYUtils containsSubviewOfClass:userNameLabelClass inContainer:sub]) {
            return sub;
        }
    }
    return nil;
}

// 以昵称左上角为组缩放原点：相对位移 * scale → 间距变为默认间距*scale。
// 宽条（拍同款等）也必须做纵向组缩放；仅横向补偿对小块收紧并加硬帽。
static void DYYYNicknameFollowGroupTransform(UIView *followView, UIView *nicknameView, CGFloat scale, CGFloat nicknameVerticalOffset,
                                             CGFloat *outExtraTx, CGFloat *outVerticalOffset) {
    if (outExtraTx) {
        *outExtraTx = 0.0;
    }
    if (outVerticalOffset) {
        *outVerticalOffset = nicknameVerticalOffset;
    }
    if (!followView || !nicknameView) {
        return;
    }
    if (!(scale > 0.0)) {
        scale = 1.0;
    }

    UIView *followStack = DYYYFindParentElementStackView(followView);
    UIView *nickStack = DYYYFindParentElementStackView(nicknameView);
    if (!followStack || followStack != nickStack || followView.superview != followStack) {
        return;
    }

    CGAffineTransform savedFollow = followView.transform;
    CGAffineTransform savedNickname = nicknameView.transform;
    DYYYSetViewTransformWithoutAnimation(followView, CGAffineTransformIdentity);
    DYYYSetViewTransformWithoutAnimation(nicknameView, CGAffineTransformIdentity);

    CGFloat followMinX = CGRectGetMinX(followView.frame);
    CGFloat followMinY = CGRectGetMinY(followView.frame);
    CGFloat followMaxY = CGRectGetMaxY(followView.frame);
    CGFloat followMidY = CGRectGetMidY(followView.frame);
    CGFloat followHeight = CGRectGetHeight(followView.frame);
    CGFloat followWidth = CGRectGetWidth(followView.frame);
    CGFloat nickMinX = CGRectGetMinX(nicknameView.frame);
    CGFloat nickMinY = CGRectGetMinY(nicknameView.frame);
    CGFloat nickMaxY = CGRectGetMaxY(nicknameView.frame);
    CGFloat nickMidY = CGRectGetMidY(nicknameView.frame);
    CGFloat nickHeight = CGRectGetHeight(nicknameView.frame);

    DYYYSetViewTransformWithoutAnimation(followView, savedFollow);
    DYYYSetViewTransformWithoutAnimation(nicknameView, savedNickname);

    if (followHeight <= 0.5 || nickHeight <= 0.5) {
        return;
    }
    // 明确在昵称下方：只跟昵称 Y（店铺等附属锚点在昵称上方，不走下方逻辑）
    if (followMinY >= nickMaxY - 1.0) {
        return;
    }
    // 高度异常才放弃（宽条如拍同款/店铺必须继续算 Y）
    if (followHeight > 80.0) {
        return;
    }

    CGFloat naturalDx = followMinX - nickMinX;
    CGFloat naturalDy = followMinY - nickMinY;
    if (fabs(naturalDy) > 180.0) {
        return;
    }

    CGFloat ty = nicknameVerticalOffset;
    CGFloat extraTx = 0.0;

    // 昵称正上方：默认间距 * scale
    if (followMaxY <= nickMinY + 1.0) {
        CGFloat naturalGap = nickMinY - followMaxY;
        if (naturalGap < 0.0) {
            naturalGap = 0.0;
        }
        if (naturalGap <= 160.0) {
            CGFloat targetGap = naturalGap * scale;
            ty = (nickMidY - nickHeight * scale / 2.0 + nicknameVerticalOffset) - targetGap - (followMidY + followHeight * scale / 2.0);
        }
    } else {
        // 同排或轻微相交：组缩放左上
        CGFloat visualNickMinY = nickMidY - nickHeight * scale / 2.0 + nicknameVerticalOffset;
        ty = visualNickMinY + naturalDy * scale - (followMidY - followHeight * scale / 2.0);
    }

    if (fabs(ty - nicknameVerticalOffset) > 120.0) {
        ty = nicknameVerticalOffset;
    }

    // 横向：只对昵称左侧的小块（弹幕等）做有限收紧
    if (followWidth <= 72.0 && naturalDx < 0.0 && fabs(naturalDx) <= 100.0) {
        extraTx = (1.0 - scale) * (nickMinX - followMinX);
        if (extraTx < 0.0 || extraTx > 28.0) {
            extraTx = 0.0;
        }
    }

    if (outExtraTx) {
        *outExtraTx = extraTx;
    }
    if (outVerticalOffset) {
        *outVerticalOffset = ty;
    }
}

static void DYYYApplyPlayInteractionElementLayout(UIView *view, NSString *fallbackClassName) {
    if (!view) {
        return;
    }

    UIView *arranged = nil;
    UIView *elementBlock = nil;
    DYYYResolveElementLayoutTargets(view, &arranged, &elementBlock);

    NSString *arrangedClassName = DYYYReportedElementClassName(arranged);

    NSString *arrangedScaleKey = nil;
    CGFloat arrangedOffset = 0.0;
    BOOL arrangedMapped = DYYYLayoutSettingsForElementClassName(arrangedClassName, &arrangedScaleKey, &arrangedOffset);

    // 定位/特效锚点内容块并入昵称组
    if (!arrangedMapped && arranged && DYYYAnchorContentViewsInContainer(arranged).count > 0) {
        arrangedClassName = @"AWEPlayInteractionAnchorElement";
        arrangedMapped = DYYYLayoutSettingsForElementClassName(arrangedClassName, &arrangedScaleKey, &arrangedOffset);
    }

    // 弹幕按钮块兜底识别
    if (!arrangedMapped && arranged) {
        Class danmakuViewClass = %c(AWEPlayDanmakuInputContainView);
        if (danmakuViewClass && ([arranged isKindOfClass:danmakuViewClass] ||
                                 [DYYYUtils containsSubviewOfClass:danmakuViewClass inContainer:arranged])) {
            arrangedClassName = @"AWEPlayInteractionDanmakuElement";
            arrangedMapped = DYYYLayoutSettingsForElementClassName(arrangedClassName, &arrangedScaleKey, &arrangedOffset);
        }
    }

    // 作者店铺（TA的店铺）兜底识别
    if (!arrangedMapped && arranged && DYYYShopContentViewsInContainer(arranged).count > 0) {
        arrangedClassName = @"AWEPlayInteractionECommerceEntryElement";
        arrangedMapped = DYYYLayoutSettingsForElementClassName(arrangedClassName, &arrangedScaleKey, &arrangedOffset);
    }

    NSString *fallbackScaleKey = nil;
    CGFloat fallbackOffset = 0.0;
    BOOL fallbackMapped = DYYYLayoutSettingsForElementClassName(fallbackClassName, &fallbackScaleKey, &fallbackOffset);

    UIView *target = nil;
    NSString *scaleKey = nil;
    NSString *chosenClassName = nil;
    CGFloat verticalOffset = 0.0;

    if (arrangedMapped && (!fallbackMapped || [arrangedScaleKey isEqualToString:fallbackScaleKey])) {
        target = arranged;
        scaleKey = arrangedScaleKey;
        verticalOffset = arrangedOffset;
        chosenClassName = arrangedClassName;
    } else if (fallbackMapped) {
        target = elementBlock;
        scaleKey = fallbackScaleKey;
        verticalOffset = fallbackOffset;
        chosenClassName = fallbackClassName;
    } else {
        return;
    }

    if (!target) {
        return;
    }

    BOOL isNicknameFollow = DYYYIsNicknameFollowElementClassName(chosenClassName) ||
                            [chosenClassName isEqualToString:@"AWEPlayInteractionAnchorElement"];

    if (DYYYIsDanmakuElementClassName(chosenClassName) && DYYYShouldSkipDanmakuFollowLayout(target)) {
        DYYYSetViewTransformWithoutAnimation(target, CGAffineTransformIdentity);
        return;
    }

    // 隐藏作者店铺时不跟随
    if (DYYYIsShopFollowElementClassName(chosenClassName) && DYYYGetBool(@"DYYYHideHisShop")) {
        DYYYSetViewTransformWithoutAnimation(target, CGAffineTransformIdentity);
        return;
    }

    // 仅当确认为视频锚点/POI/贴纸内容且应隐藏时跳过；章节/精选/标签/店铺等不受影响
    if (isNicknameFollow) {
        BOOL isFeedStyleAnchor = DYYYAnchorContentViewsInContainer(target).count > 0 ||
                                 [chosenClassName isEqualToString:@"AWEPlayInteractionAnchorElement"] ||
                                 [chosenClassName containsString:@"POI"] || [chosenClassName containsString:@"Sticker"] ||
                                 ([chosenClassName containsString:@"Anchor"] && ![chosenClassName containsString:@"Chapter"]);
        if (isFeedStyleAnchor && DYYYShouldSkipAnchorFollowLayout(target)) {
            DYYYSetViewTransformWithoutAnimation(target, CGAffineTransformIdentity);
            return;
        }
    }

    // 跟随块必须落在含昵称的左侧 Stack 上，避免误变换其它层级视图
    if (isNicknameFollow) {
        UIView *stackView = DYYYFindParentElementStackView(target);
        UIView *nicknameView = DYYYFindNicknameArrangedViewInStack(stackView);
        if (!stackView || !nicknameView) {
            DYYYSetViewTransformWithoutAnimation(target, CGAffineTransformIdentity);
            return;
        }
        if (target.superview != stackView) {
            UIView *arrangedParent = target;
            while (arrangedParent && arrangedParent.superview != stackView) {
                arrangedParent = arrangedParent.superview;
            }
            if (!arrangedParent || arrangedParent.superview != stackView) {
                DYYYSetViewTransformWithoutAnimation(target, CGAffineTransformIdentity);
                return;
            }
            target = arrangedParent;
        }
    }

    CGFloat scale = DYYYScaleValueForKey(scaleKey);

    CGFloat clampedNick = DYYYGetNicknameVerticalOffset();
    CGFloat clampedDesc = DYYYGetDescriptionVerticalOffset();
    CGFloat clampedIP = DYYYGetUserVerticalOffsetY(@"DYYYIPLabelVerticalOffset");
    DYYYClampLeftTextVerticalOffsets(DYYYFindParentElementStackView(target), &clampedNick, &clampedDesc, &clampedIP);

    CGFloat extraTx = 0.0;
    if (isNicknameFollow) {
        UIView *stackView = DYYYFindParentElementStackView(target);
        UIView *nicknameView = DYYYFindNicknameArrangedViewInStack(stackView);
        DYYYNicknameFollowGroupTransform(target, nicknameView, scale, clampedNick, &extraTx, &verticalOffset);
    } else if ([scaleKey isEqualToString:@"DYYYNicknameScale"]) {
        verticalOffset = clampedNick;
    } else if ([scaleKey isEqualToString:@"DYYYDescriptionScale"]) {
        verticalOffset = clampedDesc;
    } else if ([scaleKey isEqualToString:@"DYYYIPLabelScale"]) {
        verticalOffset = clampedIP;
    }

    if (verticalOffset != 0.0 || fabs(extraTx) > 0.0001 || fabs(scale - 1.0) > 0.0001) {
        DYYYDisableClippingForElementLayout(target);
    }

    DYYYApplyLeftAlignedScaleAndOffsetXY(target, scale, extraTx, verticalOffset);
}

static BOOL DYYYViewIsInsidePlayInteraction(UIView *view) {
    if (!view) {
        return NO;
    }

    Class playClass = %c(AWEPlayInteractionViewController);
    Protocol *playProtocol = NSProtocolFromString(@"AWEPlayInteractionViewControllerProtocol");
    for (UIResponder *responder = view.nextResponder; responder; responder = responder.nextResponder) {
        if (![responder isKindOfClass:[UIViewController class]]) {
            continue;
        }
        if (playClass && [responder isKindOfClass:playClass]) {
            return YES;
        }
        if (playProtocol && [responder conformsToProtocol:playProtocol]) {
            return YES;
        }
    }
    return NO;
}

static void DYYYApplyNicknameLayoutToLabel(UIView *label) {
    if (!label) {
        return;
    }
    if (!DYYYViewIsInsidePlayInteraction(label)) {
        return;
    }
    DYYYApplyPlayInteractionElementLayout(label, @"AWEPlayInteractionAuthorElement");
}

static NSString *DYYYLeftStackElementClassNameForSubview(UIView *sub) {
    NSString *elementClassName = nil;
    if ([sub respondsToSelector:@selector(elementClassName)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        elementClassName = [sub performSelector:@selector(elementClassName)];
#pragma clang diagnostic pop
    }

    if (elementClassName.length > 0) {
        return elementClassName;
    }

    Class userNameLabelClass = %c(AWEUserNameLabel);
    if (userNameLabelClass && [DYYYUtils containsSubviewOfClass:userNameLabelClass inContainer:sub]) {
        return @"AWEPlayInteractionAuthorElement";
    }

    Class danmakuViewClass = %c(AWEPlayDanmakuInputContainView);
    if (danmakuViewClass && ([sub isKindOfClass:danmakuViewClass] || [DYYYUtils containsSubviewOfClass:danmakuViewClass inContainer:sub])) {
        return @"AWEPlayInteractionDanmakuElement";
    }

    if (DYYYShopContentViewsInContainer(sub).count > 0) {
        return @"AWEPlayInteractionECommerceEntryElement";
    }

    if (DYYYAnchorContentViewsInContainer(sub).count > 0) {
        return @"AWEPlayInteractionAnchorElement";
    }
    return nil;
}

// Stack 排版会读取子视图 frame，而 frame 受 transform 影响。布局前必须先恢复 Identity，
// 否则昵称的位移会带动文案/属地，并因反复读取形成上下抖动。
static void DYYYResetPlayInteractionLeftStackElementTransforms(UIView *stackView) {
    if (!stackView) {
        return;
    }

    Class baseElementClass = %c(AWEBaseElementView);
    for (UIView *sub in [stackView.subviews copy]) {
        DYYYSetViewTransformWithoutAnimation(sub, CGAffineTransformIdentity);

        if (!baseElementClass) {
            continue;
        }
        for (UIView *nested in [DYYYUtils findAllSubviewsOfClass:baseElementClass inContainer:sub]) {
            DYYYSetViewTransformWithoutAnimation(nested, CGAffineTransformIdentity);
        }
    }
}

static void DYYYApplyPlayInteractionLeftStackElementTransforms(UIView *stackView) {
    if (!stackView) {
        return;
    }

    stackView.transform = CGAffineTransformIdentity;
    for (UIView *sub in [stackView.subviews copy]) {
        DYYYApplyPlayInteractionElementLayout(sub, DYYYLeftStackElementClassNameForSubview(sub));
    }
}

static BOOL DYYYStackViewContainsScalableLeftElement(UIView *stackView) {
    Class userNameLabelClass = %c(AWEUserNameLabel);
    Class danmakuViewClass = %c(AWEPlayDanmakuInputContainView);
    return DYYYStackViewContainsElementClassName(stackView, @"AWEPlayInteractionAuthorElement") ||
           DYYYStackViewContainsElementClassName(stackView, @"AWEPlayInteractionStandardAuthorElement") ||
           DYYYStackViewContainsElementClassName(stackView, @"AWEPlayInteractionDescriptionElement") ||
           DYYYStackViewContainsElementClassName(stackView, @"AWEPlayInteractionTimestampElement") ||
           DYYYStackViewContainsElementClassName(stackView, @"AWEPlayInteractionDanmakuElement") ||
           DYYYStackViewContainsElementClassName(stackView, @"AWEPlayInteractionECommerceEntryElement") ||
           DYYYAnchorContentViewsInContainer(stackView).count > 0 || DYYYShopContentViewsInContainer(stackView).count > 0 ||
           (danmakuViewClass && [DYYYUtils containsSubviewOfClass:danmakuViewClass inContainer:stackView]) ||
           (userNameLabelClass && [DYYYUtils containsSubviewOfClass:userNameLabelClass inContainer:stackView]);
}

static void DYYYApplyPlayInteractionElementLayoutFromElement(id element, NSString *fallbackClassName) {
    UIView *elementView = DYYYRawElementViewFromElement(element);
    if (!elementView) {
        return;
    }

    DYYYApplyPlayInteractionElementLayout(elementView, fallbackClassName);
}

%hook AWEPlayInteractionTimestampElement

- (id)timestampLabel {
    UILabel *label = %orig;
    BOOL isEnableArea = DYYYGetBool(@"DYYYEnableArea");
    if (!isEnableArea) {
        return label;
    }

    NSString *labelColorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelColor"];
    if (DYYYGetBool(@"DYYYEnableRandomGradient")) {
        labelColorHex = @"random_gradient";
    }

    BOOL boldEnabled = DYYYGetBool(@"DYYYBoldTimestamp");
    if (boldEnabled && label.font) {
        UIFont *boldFont = [UIFont boldSystemFontOfSize:label.font.pointSize];
        label.font = boldFont;
    }

    NSString *cityCode = self.model.cityCode;
    NSString *regionCode = nil;
    if ([self.model respondsToSelector:@selector(region)]) {
        regionCode = [self.model performSelector:@selector(region)];
    }

    if (cityCode && ([cityCode isEqualToString:@"0"] || [cityCode integerValue] == 0)) {
        cityCode = nil;
    }

    static NSCache *locationCache;
    static NSMutableSet *inFlight;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        locationCache = [[NSCache alloc] init];
        locationCache.countLimit = 100;
        inFlight = [[NSMutableSet alloc] init];
    });

    void (^updateLabelWithLocation)(UILabel *, NSString *) = ^(UILabel *lbl, NSString *location) {
        if (location.length == 0) return;

        NSString *currentText = lbl.text ?: @"";
        if ([currentText containsString:location]) return;

        if ([currentText containsString:@"IP属地："]) {
            NSRange range = [currentText rangeOfString:@"IP属地："];
            NSString *baseText = [currentText substringToIndex:range.location];
            lbl.text = [NSString stringWithFormat:@"%@IP属地：%@", baseText, location];
        } else if (currentText.length > 0) {
            lbl.text = [NSString stringWithFormat:@"%@  IP属地：%@", currentText, location];
        }

        [DYYYUtils applyColorSettingsToLabel:lbl colorHexString:labelColorHex];
    };

    if (cityCode.length == 0 && regionCode.length == 0) {
        updateLabelWithLocation(label, @"未知地区");
        DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionTimestampElement");
        return label;
    }

    NSString *cacheKey = cityCode.length > 0 ? cityCode : regionCode;

    NSString *cachedLocation = [locationCache objectForKey:cacheKey];
    if (cachedLocation) {
        updateLabelWithLocation(label, cachedLocation);
        DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionTimestampElement");
        return label;
    }

    __weak __typeof(self) weakSelf = self;
    NSString *displayLocation = nil;

    if (cityCode.length > 0) {
        displayLocation = [CityManager.sharedInstance getCityNameWithCode:cityCode];

        if (!displayLocation) {
            @synchronized(inFlight) {
                if ([inFlight containsObject:cityCode]) {
                    return label;
                }
                [inFlight addObject:cityCode];
            }

            [CityManager fetchLocationWithGeonameId:cityCode completionHandler:^(NSDictionary *locationInfo, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    @synchronized(inFlight) {
                        [inFlight removeObject:cityCode];
                    }

                    NSString *apiLocation = nil;

                    if (!error && locationInfo) {
                        NSString *localName = locationInfo[@"name"];
                        NSString *adminName1 = locationInfo[@"adminName1"];
                        NSString *countryName = locationInfo[@"countryName"];

                        if (![localName isKindOfClass:[NSString class]]) {
                            localName = nil;
                        }
                        if (![adminName1 isKindOfClass:[NSString class]]) {
                            adminName1 = nil;
                        }
                        if (![countryName isKindOfClass:[NSString class]]) {
                            countryName = nil;
                        }

                        if (countryName.length > 0) {
                            if (adminName1.length > 0 && localName.length > 0 && ![countryName isEqualToString:localName]) {
                                if ([adminName1 isEqualToString:localName]) {
                                    apiLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
                                } else {
                                    apiLocation = [NSString stringWithFormat:@"%@ %@ %@", countryName, adminName1, localName];
                                }
                            } else if (localName.length > 0 && ![countryName isEqualToString:localName]) {
                                apiLocation = [NSString stringWithFormat:@"%@ %@", countryName, localName];
                            } else if (adminName1.length > 0 && ![countryName isEqualToString:adminName1]) {
                                apiLocation = [NSString stringWithFormat:@"%@ %@", countryName, adminName1];
                            } else {
                                apiLocation = countryName;
                            }
                        } else if (localName.length > 0) {
                            apiLocation = localName;
                        } else if (adminName1.length > 0) {
                            apiLocation = adminName1;
                        }
                    }

                    if (apiLocation.length > 0) {
                        [locationCache setObject:apiLocation forKey:cacheKey];
                        updateLabelWithLocation(label, apiLocation);
                    } else {
                        if (regionCode.length > 0) {
                            NSString *fallbackCountry = [CityManager.sharedInstance getCountryNameWithCode:regionCode];
                            updateLabelWithLocation(label, fallbackCountry);
                        }
                    }
                    DYYYApplyPlayInteractionElementLayoutFromElement(weakSelf, @"AWEPlayInteractionTimestampElement");
                });
            }];

            return label;
        }
    }

    if (!displayLocation && !cityCode && regionCode.length > 0) {
        displayLocation = [CityManager.sharedInstance getCountryNameWithCode:regionCode];
    }

    if (!displayLocation) {
        displayLocation = @"未知地区";
        updateLabelWithLocation(label, displayLocation);
        DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionTimestampElement");
        return label;
    }

    [locationCache setObject:displayLocation forKey:cacheKey];
    updateLabelWithLocation(label, displayLocation);
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionTimestampElement");
    return label;
}

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionTimestampElement");
}

+ (BOOL)shouldActiveWithData:(id)arg1 context:(id)arg2 {
    return DYYYGetBool(@"DYYYEnableArea");
}

%end

%hook AWEPlayInteractionProgressController

%new
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        return;
    }

    id progressSlider = self.progressSlider;
    if (progressSlider && [progressSlider respondsToSelector:@selector(dyyy_updateScheduleLabelsWithCurrentTime:totalDuration:)]) {
        [progressSlider dyyy_updateScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
    }

    if ([progressSlider isKindOfClass:[UIView class]]) {
        [(UIView *)progressSlider dyyy_updateScheduleLabelsLegacyWithCurrentTime:currentTime totalDuration:totalDuration model:self.model];
    }
}

- (void)updateProgressSliderWithTime:(CGFloat)arg1 totalDuration:(CGFloat)arg2 {
    %orig;
    [self dyyy_syncScheduleLabelsWithCurrentTime:arg1 totalDuration:arg2];
}

%end

%hook AWEDProgressCoreContainer

%new
- (void)dyyy_syncScheduleLabelsWithCurrentTime:(CGFloat)currentTime totalDuration:(CGFloat)totalDuration {
    if (!DYYYGetBool(@"DYYYShowScheduleDisplay")) {
        return;
    }

    id progressSlider = self.progressSlider;
    if (progressSlider && [progressSlider respondsToSelector:@selector(dyyy_updateScheduleLabelsWithCurrentTime:totalDuration:)]) {
        [progressSlider dyyy_updateScheduleLabelsWithCurrentTime:currentTime totalDuration:totalDuration];
    }

    id model = nil;
    if ([self respondsToSelector:@selector(model)]) {
        model = [self valueForKey:@"model"];
    }

    if ([progressSlider isKindOfClass:[UIView class]]) {
        [(UIView *)progressSlider dyyy_updateScheduleLabelsLegacyWithCurrentTime:currentTime totalDuration:totalDuration model:model];
    }
}

- (void)updateProgressSliderWithTime:(CGFloat)arg1 totalDuration:(CGFloat)arg2 {
    %orig;
    [self dyyy_syncScheduleLabelsWithCurrentTime:arg1 totalDuration:arg2];
}

%end

%hook AWEPlayInteractionDescriptionScrollView

- (void)layoutSubviews {
    %orig;
}

%end

// 对新版文案的偏移（33.0以上）
%hook AWEPlayInteractionDescriptionLabel

static char kLongPressGestureKey;
static NSString *const kDYYYLongPressCopyEnabledKey = @"DYYYLongPressCopyTextEnabled";

- (void)didMoveToWindow {
    %orig;

    BOOL longPressCopyEnabled = DYYYGetBool(kDYYYLongPressCopyEnabledKey);

    if (![[NSUserDefaults standardUserDefaults] objectForKey:kDYYYLongPressCopyEnabledKey]) {
        longPressCopyEnabled = NO;
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kDYYYLongPressCopyEnabledKey];
    }

    UIGestureRecognizer *existingGesture = objc_getAssociatedObject(self, &kLongPressGestureKey);
    if (existingGesture && !longPressCopyEnabled) {
        [self removeGestureRecognizer:existingGesture];
        objc_setAssociatedObject(self, &kLongPressGestureKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return;
    }

    if (longPressCopyEnabled && !objc_getAssociatedObject(self, &kLongPressGestureKey)) {
        UILongPressGestureRecognizer *highPriorityLongPress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleHighPriorityLongPress:)];
        highPriorityLongPress.minimumPressDuration = 0.3;

        [self addGestureRecognizer:highPriorityLongPress];

        UIView *currentView = self;
        while (currentView.superview) {
            currentView = currentView.superview;

            for (UIGestureRecognizer *recognizer in currentView.gestureRecognizers) {
                if ([recognizer isKindOfClass:[UILongPressGestureRecognizer class]] || [recognizer isKindOfClass:[UIPinchGestureRecognizer class]]) {
                    [recognizer requireGestureRecognizerToFail:highPriorityLongPress];
                }
            }
        }

        objc_setAssociatedObject(self, &kLongPressGestureKey, highPriorityLongPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer.view isEqual:self] && [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return NO;
    }
    return YES;
}

%new
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    if ([gestureRecognizer.view isEqual:self] && [gestureRecognizer isKindOfClass:[UILongPressGestureRecognizer class]]) {
        return YES;
    }
    return NO;
}

%new
- (void)handleHighPriorityLongPress:(UILongPressGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        NSString *description = self.text;

        if (description.length > 0) {
            [[UIPasteboard generalPasteboard] setString:description];
            [DYYYToast showSuccessToastWithMessage:@"视频文案已复制"];
        }
    }
}

- (void)layoutSubviews {
    %orig;
}

%end

%hook AWEUserNameLabel

- (void)layoutSubviews {
    %orig;
    DYYYApplyNicknameLayoutToLabel(self);
}

%end

%hook AWEPlayInteractionStandardAuthorNamePlugin

- (void)authorElement_didLayout {
    %orig;

    if ([self respondsToSelector:@selector(authorLabel)]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        UIView *authorLabel = [self performSelector:@selector(authorLabel)];
#pragma clang diagnostic pop
        DYYYApplyNicknameLayoutToLabel(authorLabel);
    }
}

%end

%hook AWEPlayInteractionAuthorElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionAuthorElement");
}

%end

%hook AWEPlayInteractionStandardAuthorElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionStandardAuthorElement");
}

%end

%hook AWEPlayInteractionDescriptionElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionDescriptionElement");
}

%end

%hook AWEPlayInteractionDanmakuElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionDanmakuElement");
}

%end

%group DYYYHideFeedAnchorGroup

%hook AWEPlayInteractionAnchorElement

+ (id)activateInfoWithContext:(id)context {
    if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
        DYYYLogFeedAnchorHookOnce(@"Hook 已安装");
        DYYYLogFeedAnchorHookOnce(@"activateInfoWithContext: skipped");
        return nil;
    }
    return %orig;
}

- (void)layoutElementView {
    %orig;
    id elementView = nil;
    if ([self respondsToSelector:@selector(elementView)]) {
        elementView = [self elementView];
    }
    if ([elementView isKindOfClass:[UIView class]]) {
        DYYYSyncHiddenFeedAnchorArrangedView((UIView *)elementView);
    }
    if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
        if ([self respondsToSelector:@selector(setAnchorHidden:)]) {
            [self setAnchorHidden:YES];
        }
        return;
    }
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionAnchorElement");
}

%end

%hook AWEAwemeModel

- (id)anchorInfo {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setAnchorInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)anchorList {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setAnchorList:(id)list {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)anchorNormalInfo {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setAnchorNormalInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)doubleColumnAnchorNormalInfo {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setDoubleColumnAnchorNormalInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)localLifeAnchorInfo {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setLocalLifeAnchorInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)nearbyFeedDualAnchorInfo {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setNearbyFeedDualAnchorInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)minorAnchorInfo {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setMinorAnchorInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)commonAnchor {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		return nil;
	}
	return %orig;
}

- (void)setCommonAnchor:(id)anchor {
	if (DYYYGetBool(@"DYYYHideFeedAnchorContainer")) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

%end

%group DYYYHideFeedAnchorTemplateGroup

%hook AWEFeedTemplateAnchorViewV2

- (void)layoutSubviews {
    %orig;
    DYYYSyncHiddenFeedAnchorArrangedView(self);
}

%end

%end

static void DYYYInitHideFeedAnchorGroupIfNeeded(void) {
    static BOOL coreReady = NO;
    static BOOL templateReady = NO;
    if (!coreReady && objc_getClass("AWEAwemeModel") && objc_getClass("AWEPlayInteractionAnchorElement")) {
        %init(DYYYHideFeedAnchorGroup);
        coreReady = YES;
        NSLog(@"[DYYY][RuntimeHook][FeedAnchor] Hook 已安装");
    }
    if (!templateReady && objc_getClass("AWEFeedTemplateAnchorViewV2")) {
        %init(DYYYHideFeedAnchorTemplateGroup);
        templateReady = YES;
        NSLog(@"[DYYY][RuntimeHook][FeedAnchor] AWEFeedTemplateAnchorViewV2 group installed");
    }
}

static void DYYYStartHideFeedAnchorHookInstaller(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        DYYYInitHideFeedAnchorGroupIfNeeded();
        NSArray<NSNumber *> *delays = @[ @0.2, @0.8, @2.0, @5.0, @10.0 ];
        for (NSNumber *delay in delays) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay.doubleValue * NSEC_PER_SEC)),
                           dispatch_get_main_queue(),
                           ^{
                               DYYYInitHideFeedAnchorGroupIfNeeded();
                           });
        }
    });
}

%hook AWEPlayInteractionChapterElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionChapterElement");
}

%end

%hook AWEPlayInteractionRecommendToFeedCardLabelElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionRecommendToFeedCardLabelElement");
}

%end

%hook AWEPlayInteractionTagsElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionTagsElement");
}

%end

%hook AWEPlayInteractionTagsElementV2

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionTagsElementV2");
}

%end

%hook AWEPlayInteractionMultiQueueLabelElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionMultiQueueLabelElement");
}

%end

%hook AWEPlayInteractionEffectDetailLeftElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionEffectDetailLeftElement");
}

%end

%hook AWEPlayInteractionECommerceEntryElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionECommerceEntryElement");
}

%end

%hook AWEPlayInteractionDarenCardLeftElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionDarenCardLeftElement");
}

%end

%hook AWEPlayInteractionGoodsCardElement

- (void)layoutElementView {
    %orig;
    DYYYApplyPlayInteractionElementLayoutFromElement(self, @"AWEPlayInteractionGoodsCardElement");
}

%end

%hook AWEECommerceEntryView

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideHisShop")) {
        return;
    }
    if (DYYYViewIsInsidePlayInteraction(self)) {
        DYYYApplyPlayInteractionElementLayout(self, @"AWEPlayInteractionECommerceEntryElement");
    }
}

%end

%hook AWEFeedVideoButton

- (void)setImage:(id)arg1 {
    UIImage *imageToApply = arg1;
    NSString *nameString = nil;

    if ([self respondsToSelector:@selector(imageNameString)]) {
        IMP imp = [self methodForSelector:@selector(imageNameString)];
        if (imp) {
            NSString *(*func)(id, SEL) = (NSString * (*)(id, SEL)) imp;
            if (func) {
                nameString = func(self, @selector(imageNameString));
            }
        }
	}

    BOOL isCollectButton = DYYYIsFeedVideoCollectButton(self) || DYYYFeedVideoCollectKeywordMatches(nameString);
    if (isCollectButton && DYYYFeedVideoCollectButtonHideEnabled()) {
        DYYYMarkFeedVideoCollectButtonViewHidden(self);
        %orig(nil);
        return;
    }

    NSString *customFileName = DYYYCustomIconFileNameForButtonName(nameString);
    if (customFileName.length > 0) {
        UIImage *customImage = DYYYLoadCustomImage(customFileName, CGSizeMake(44.0, 44.0));
        if (customImage) {
            imageToApply = customImage;
        }
	}

    %orig(imageToApply);
    if (isCollectButton) {
        DYYYApplyFeedVideoCollectButtonSettingsWithRetry(self);
    }
}

%end

%hook AWENormalModeTabBarGeneralPlusButton
- (void)setImage:(UIImage *)image forState:(UIControlState)state {
    UIImage *imageToApply = image;
    if ([self.accessibilityLabel isEqualToString:@"拍摄"]) {
        UIImage *customImage = DYYYLoadCustomImage(@"tab_plus.png", CGSizeZero);
        if (customImage) {
            imageToApply = customImage;
        }
    }

    %orig(imageToApply, state);
}
%end

// 获取资源的地址
%hook AWEURLModel
%new - (NSURL *)getDYYYSrcURLDownload {
    NSURL *bestURL;
    for (NSString *url in self.originURLList) {
        if ([url containsString:@"video_mp4"] || [url containsString:@".jpeg"] || [url containsString:@".mp3"]) {
            bestURL = [NSURL URLWithString:url];
        }
    }

    if (bestURL == nil) {
        bestURL = [NSURL URLWithString:[self.originURLList firstObject]];
    }

    return bestURL;
}
%end

// 屏蔽版本更新
%group DYYYLoginBypassVersionUpdateManager

%hook AWEVersionUpdateManager

- (void)startVersionUpdateWorkflow:(id)arg1 completion:(id)arg2 {
    if (DYYYShouldBlockVersionUpdateWorkflow()) {
        DYYYLoginBypassInvokeCloseCallback(arg2);
    } else {
        %orig;
    }
}

- (id)workflow {
    return DYYYShouldBlockVersionUpdateWorkflow() ? nil : %orig;
}

- (id)badgeModule {
    return DYYYShouldBlockVersionUpdateWorkflow() ? nil : %orig;
}

%end

%end

// 应用内推送毛玻璃效果
%hook AWEInnerNotificationWindow

- (void)layoutSubviews {
    %orig;
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableNotificationTransparency"]) {
        [self setupBlurEffectForNotificationView];
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window && DYYYGetBool(@"DYYYEnableNotificationTransparency")) {
        [self setupBlurEffectForNotificationView];
    }
}

%new
- (void)setupBlurEffectForNotificationView {
    for (UIView *subview in self.subviews) {
        if ([NSStringFromClass([subview class]) containsString:@"AWEInnerNotificationContainerView"]) {
            [self applyBlurEffectToView:subview];
            break;
        }
    }
}

%new
- (void)applyBlurEffectToView:(UIView *)containerView {
    dispatch_async(dispatch_get_main_queue(), ^{
      if (!containerView) {
          return;
      }

      containerView.backgroundColor = [UIColor clearColor];

      float userRadius = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNotificationCornerRadius"] floatValue];
      if (!userRadius || userRadius < 0 || userRadius > 50) {
          userRadius = 12;
      }

      containerView.layer.cornerRadius = userRadius;
      containerView.layer.masksToBounds = YES;

      for (UIView *subview in containerView.subviews) {
          if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999) {
              [subview removeFromSuperview];
          }
      }

      BOOL isDarkMode = [DYYYUtils isDarkMode];
      UIBlurEffectStyle blurStyle = isDarkMode ? UIBlurEffectStyleDark : UIBlurEffectStyleLight;
      UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:blurStyle];
      UIVisualEffectView *blurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];

      blurView.frame = containerView.bounds;
      blurView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
      blurView.tag = 999;
      blurView.layer.cornerRadius = userRadius;
      blurView.layer.masksToBounds = YES;

      float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
      if (userTransparency <= 0 || userTransparency > 1) {
          userTransparency = 0.5;
      }

      blurView.alpha = userTransparency;

      [containerView insertSubview:blurView atIndex:0];

      [self clearBackgroundRecursivelyInView:containerView];

      [self setLabelsColorWhiteInView:containerView];
    });
}

%new
- (void)setLabelsColorWhiteInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UILabel class]]) {
            UILabel *label = (UILabel *)subview;
            NSString *text = label.text;

            if (![text isEqualToString:@"回复"] && ![text isEqualToString:@"查看"] && ![text isEqualToString:@"续火花"]) {
                label.textColor = [UIColor whiteColor];
            }
        }
        [self setLabelsColorWhiteInView:subview];
    }
}

%new
- (void)clearBackgroundRecursivelyInView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview isKindOfClass:[UIVisualEffectView class]] && subview.tag == 999 && [subview isKindOfClass:[UIButton class]]) {
            continue;
        }
        subview.backgroundColor = [UIColor clearColor];
        [self clearBackgroundRecursivelyInView:subview];
    }
}

%end

// 为 AWEUserActionSheetView 添加毛玻璃效果
%hook AWEUserActionSheetView

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYEnableSheetBlur")) {
        [self applyBlurEffectAndWhiteText];
    }
}

%new
- (void)applyBlurEffectAndWhiteText {
    // 应用毛玻璃效果到容器视图
    if (self.containerView) {
        self.containerView.backgroundColor = [UIColor clearColor];

        // 动态获取用户设置的透明度
        float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSheetBlurTransparent"] floatValue];
        if (userTransparency <= 0 || userTransparency > 1) {
            userTransparency = 0.9; // 默认值0.9
        }

        [DYYYUtils applyBlurEffectToView:self.containerView transparency:userTransparency blurViewTag:9999];
        [DYYYUtils clearBackgroundRecursivelyInView:self.containerView];
        // 调用新的通用方法设置文本颜色，这里没有排除需求，所以传入 nil Block
        [DYYYUtils applyTextColorRecursively:[UIColor whiteColor] inView:self.containerView shouldExcludeViewBlock:nil];
    }
}

%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl32CommentLongPressPanelCopyElement

- (void)elementTapped {
    if (!DYYYGetBool(@"DYYYCommentCopyText")) {
        %orig;
        return;
    }

    AWECommentLongPressPanelContext *commentPageContext = [self commentPageContext];
    AWECommentModel *selectdComment = [commentPageContext selectdComment];
    if (!selectdComment) {
        AWECommentLongPressPanelParam *params = [commentPageContext params];
        selectdComment = [params selectdComment];
    }
    NSString *descText = [selectdComment content];
    if (descText.length == 0) {
        %orig;
        return;
    }

    [[UIPasteboard generalPasteboard] setString:descText];
    [DYYYToast showSuccessToastWithMessage:@"评论已复制"];
}
%end

// 启用自动勾选原图
%hook AWEIMPhotoPickerFunctionModel

- (void)setUseShadowIcon:(BOOL)arg1 {
    BOOL enabled = DYYYGetBool(@"DYYYAutoSelectOriginalPhoto");
    if (enabled) {
        %orig(YES);
    } else {
        %orig(arg1);
    }
}

- (BOOL)isSelected {
    BOOL enabled = DYYYGetBool(@"DYYYAutoSelectOriginalPhoto");
    if (enabled) {
        return YES;
    }
    return %orig;
}

%end

// 屏蔽直播PCDN
%hook HTSLiveStreamPcdnManager

+ (void)start {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (!disablePCDN) {
        %orig;
    } else {
        NSLog(@"[DYYY] HTSLiveStreamPcdnManager start blocked");
    }
}

+ (void)configAndStartLiveIO {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (!disablePCDN) {
        %orig;
    } else {
        NSLog(@"[DYYY] HTSLiveStreamPcdnManager configAndStartLiveIO blocked");
    }
}

%end

// PCDN启动任务hook
%hook IESLiveLaunchTaskPcdn

- (void)excute {
    BOOL disablePCDN = DYYYGetBool(@"DYYYDisableLivePCDN");
    if (disablePCDN) {
        NSLog(@"[DYYY] IESLiveLaunchTaskPcdn excute blocked");
        return;
    }
    %orig;
}

%end

// 投屏忽略 VPN 检测
%hook BDByteCastUtils

+ (BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

%end

%hook BDByteCastNetUtilities

- (BOOL)getVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

%end

%hook BDByteCastMonitorManager

- (BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setNetVPNStatus:(BOOL)netVPNStatus {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(netVPNStatus);
}

%end

%hook BDByteCastEnvInfo

- (BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setIsVPNActive:(BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(isVPNActive);
}

%end

%hook BDByteScreenCastContext

- (BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        return NO;
    }
    return %orig;
}

- (void)setIsVPNActive:(BOOL)isVPNActive {
    if (DYYYGetBool(@"DYYYDisableCastVPNCheck")) {
        %orig(NO);
        return;
    }
    %orig(isVPNActive);
}

%end

// 调整直播默认清晰度功能
static NSArray<NSString *> *dyyy_qualityRank = nil;

%hook HTSLiveStreamQualityFragment

- (void)setupStreamQuality:(id)arg1 {
    %orig;

    NSString *preferredQuality = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLiveQuality"];
    if (!preferredQuality || [preferredQuality isEqualToString:@"自动"]) {
        NSLog(@"[DYYY] Live quality auto - skipping hook");
        return;
    }

    BOOL preferLower = YES;
    NSLog(@"[DYYY] preferredQuality=%@ preferLower=%@", preferredQuality, @(preferLower));

    NSArray *qualities = self.streamQualityArray;
    if (!qualities || qualities.count == 0) {
        qualities = [self getQualities];
    }
    if (!qualities || qualities.count == 0) {
        return;
    }

    if (!dyyy_qualityRank) {
        dyyy_qualityRank = @[ @"蓝光帧彩", @"蓝光", @"超清", @"高清", @"标清" ];
    }
    NSArray *orderedNames = dyyy_qualityRank;

    // Map available names to their indices in the provided order
    NSMutableDictionary<NSString *, NSNumber *> *nameToIndex = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *availableNames = [NSMutableArray array];
    NSMutableArray<NSNumber *> *rankArray = [NSMutableArray array];
    for (NSInteger i = 0; i < qualities.count; i++) {
        id q = qualities[i];
        NSString *name = nil;
        if ([q respondsToSelector:@selector(name)]) {
            name = [q name];
        } else {
            name = [q valueForKey:@"name"];
        }
        if (name) {
            [availableNames addObject:name];
            nameToIndex[name] = @(i);
            NSInteger rank = [orderedNames indexOfObject:name];
            if (rank != NSNotFound) {
                [rankArray addObject:@(rank)];
            }
        }
    }
    NSLog(@"[DYYY] available qualities: %@", availableNames);

    BOOL qualityDesc = YES; // ranks ascending -> high to low
    BOOL qualityAsc = YES;  // ranks descending -> low to high
    for (NSInteger i = 1; i < rankArray.count; i++) {
        NSInteger prev = rankArray[i - 1].integerValue;
        NSInteger curr = rankArray[i].integerValue;
        if (curr < prev) {
            qualityDesc = NO;
        }
        if (curr > prev) {
            qualityAsc = NO;
        }
    }

    NSInteger count = availableNames.count;
    NSInteger (^convertIndex)(NSInteger) = ^NSInteger(NSInteger idx) {
      if (qualityAsc && !qualityDesc) {
          return count - 1 - idx;
      }
      return idx;
    };

    NSArray *searchOrder = orderedNames;

    NSNumber *indexToUse = nameToIndex[preferredQuality];
    if (indexToUse) {
        NSInteger finalIdx = convertIndex(indexToUse.integerValue);
        NSLog(@"[DYYY] exact quality %@ found at index %ld", preferredQuality, (long)finalIdx);
        [self setResolutionWithIndex:finalIdx isManual:YES beginChange:nil completion:nil];
        return;
    }

    NSInteger targetPos = [orderedNames indexOfObject:preferredQuality];
    if (targetPos == NSNotFound) {
        NSLog(@"[DYYY] preferred quality %@ not in list", preferredQuality);
        return;
    }

    NSInteger step = preferLower ? 1 : -1;
    BOOL applied = NO;
    for (NSInteger pos = targetPos + step; pos >= 0 && pos < searchOrder.count; pos += step) {
        NSString *candidate = searchOrder[pos];
        NSNumber *idx = nameToIndex[candidate];
        if (idx) {
            NSInteger finalIdx = convertIndex(idx.integerValue);
            NSLog(@"[DYYY] fallback quality %@ at index %ld", candidate, (long)finalIdx);
            [self setResolutionWithIndex:finalIdx isManual:YES beginChange:nil completion:nil];
            applied = YES;
            break;
        }
    }
    if (!applied) {
        NSLog(@"[DYYY] no suitable fallback quality found");
    }
}

%end

// 强制启用新版抖音长按 UI（现代风）
%hook AWELongPressPanelDataManager
+ (BOOL)enableModernLongPressPanelConfigWithSceneIdentifier:(id)arg1 {
    return DYYYGetBool(@"DYYYEnableModernPanel");
}
%end

%hook AWELongPressPanelABSettings
+ (NSUInteger)modernLongPressPanelStyleMode {
    if (!DYYYGetBool(@"DYYYEnableModernPanel")) {
        return %orig;
    }

    BOOL forceBlur = DYYYGetBool(@"DYYYLongPressPanelBlur");
    BOOL forceDark = DYYYGetBool(@"DYYYLongPressPanelDark");

    if (forceBlur && forceDark) {
        return 1;
    } else if (!forceBlur && !forceDark) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        return isDarkMode ? 1 : 2;
    }
}
%end

%hook AWEModernLongPressPanelUIConfig
+ (NSUInteger)modernLongPressPanelStyleMode {
    if (!DYYYGetBool(@"DYYYEnableModernPanel")) {
        return %orig;
    }

    BOOL forceBlur = DYYYGetBool(@"DYYYLongPressPanelBlur");
    BOOL forceDark = DYYYGetBool(@"DYYYLongPressPanelDark");

    if (forceBlur && forceDark) {
        return 1;
    } else if (!forceBlur && !forceDark) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        return isDarkMode ? 1 : 2;
    }
}
%end

// 禁用个人资料自动进入橱窗
%hook AWEUserTabListModel

- (NSInteger)profileLandingTab {
    if (DYYYGetBool(@"DYYYDefaultEnterWorks")) {
        return 0;
    } else {
        return %orig;
    }
}

%end

%group AutoPlay

%hook AWEAwemeDetailTableViewController

- (BOOL)hasIphoneAutoPlaySwitch {
    return YES;
}

%end

%hook AWEAwemeDetailContainerPlayControlConfig

- (BOOL)enableUserProfilePostAutoPlay {
    return YES;
}

%end

%hook AWEFeedIPhoneAutoPlayManager

- (BOOL)isAutoPlayOpen {
    return YES;
}

%end

%hook AWEFeedModuleService

- (BOOL)getFeedIphoneAutoPlayState {
    return YES;
}
%end

%hook AWEFeedIPhoneAutoPlayManager

- (BOOL)getFeedIphoneAutoPlayState {
    BOOL r = %orig;
    return YES;
}
%end

%end

static char kDYYYLongPressVerticalActiveKey;
static char kDYYYLongPressVerticalInitialYKey;
static char kDYYYLongPressVerticalCurrentSpeedKey;
static __thread BOOL dyyyNativeLockCompletionActive = NO;

static BOOL DYYYLongPressGestureIsEnding(UIGestureRecognizerState state) {
    return state == UIGestureRecognizerStateEnded ||
           state == UIGestureRecognizerStateCancelled ||
           state == UIGestureRecognizerStateFailed;
}

static double DYYYConfiguredLongPressPlaybackSpeed(void) {
    id configuredValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLongPressSpeed"];
    double configuredSpeed = [configuredValue doubleValue];
    return configuredValue && isfinite(configuredSpeed) && configuredSpeed > 0.0
               ? configuredSpeed
               : 0.0;
}

static NSString *DYYYFormattedPlaybackSpeed(double speed) {
    if (fabs(speed - round(speed)) <= 0.0001) {
        return [NSString stringWithFormat:@"%.0f", speed];
    }
    if (fabs(speed * 10.0 - round(speed * 10.0)) <= 0.0001) {
        return [NSString stringWithFormat:@"%.1f", speed];
    }
    return [NSString stringWithFormat:@"%.2f", speed];
}

static NSString *DYYYAdjustedNativeLongPressSpeedHint(NSString *text) {
    if (![text isKindOfClass:[NSString class]] || text.length == 0) {
        return text;
    }

    double targetSpeed = 0.0;
    if ([text containsString:@"锁定"]) {
        targetSpeed = DYYYConfiguredLongPressPlaybackSpeed();
    } else if ([text containsString:@"取消"]) {
        float lockedSpeed = 0.0f;
        targetSpeed = DYYYNativeLockedPlaybackSpeed(&lockedSpeed)
                          ? lockedSpeed
                          : DYYYConfiguredLongPressPlaybackSpeed();
    } else if ([text containsString:@"恢复"]) {
        // 与官方下滑取消一致：恢复目标是默认倍速，而不是快捷倍速按钮的非 1x 会话值。
        targetSpeed = DYYYConfiguredDefaultPlaybackSpeed();
    }
    if (!isfinite(targetSpeed) || targetSpeed <= 0.0) {
        return text;
    }

    NSRange speedUnitRange = [text rangeOfString:@"倍速" options:NSBackwardsSearch];
    if (speedUnitRange.location == NSNotFound) {
        return text;
    }

    NSUInteger numberEnd = speedUnitRange.location;
    while (numberEnd > 0 &&
           [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[text characterAtIndex:numberEnd - 1]]) {
        numberEnd--;
    }

    NSUInteger numberStart = numberEnd;
    while (numberStart > 0) {
        unichar character = [text characterAtIndex:numberStart - 1];
        if ((character >= '0' && character <= '9') || character == '.') {
            numberStart--;
            continue;
        }
        break;
    }
    if (numberStart == numberEnd) {
        return text;
    }

    NSRange numberRange = NSMakeRange(numberStart, numberEnd - numberStart);
    return [text stringByReplacingCharactersInRange:numberRange
                                         withString:DYYYFormattedPlaybackSpeed(targetSpeed)];
}

static void DYYYTriggerNativeLongPressSpeedHaptic(void) {
    Class hapticClass = NSClassFromString(@"AFDHaptic");
    if (!hapticClass || ![hapticClass respondsToSelector:@selector(triggerWithType:)]) {
        return;
    }

    @try {
        [(id)hapticClass triggerWithType:5];
    } @catch (__unused NSException *exception) {
    }
}

static void DYYYBeginLongPressVerticalAdjustment(id owner,
                                                 UILongPressGestureRecognizer *gesture,
                                                 double initialSpeed) {
    if (!owner || !gesture || !isfinite(initialSpeed) || initialSpeed <= 0.0) {
        return;
    }
    CGPoint location = [gesture locationInView:gesture.view];
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalActiveKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalInitialYKey, @(location.y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalCurrentSpeedKey, @(initialSpeed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static BOOL DYYYUpdateLongPressVerticalAdjustment(id owner,
                                                  UILongPressGestureRecognizer *gesture,
                                                  double *updatedSpeed) {
    if (!owner ||
        !gesture ||
        ![objc_getAssociatedObject(owner, &kDYYYLongPressVerticalActiveKey) boolValue]) {
        return NO;
    }

    NSNumber *initialYValue = objc_getAssociatedObject(owner, &kDYYYLongPressVerticalInitialYKey);
    NSNumber *currentSpeedValue = objc_getAssociatedObject(owner, &kDYYYLongPressVerticalCurrentSpeedKey);
    if (!initialYValue || !currentSpeedValue) {
        return NO;
    }

    CGPoint location = [gesture locationInView:gesture.view];
    CGFloat deltaY = location.y - initialYValue.doubleValue;
    static const CGFloat threshold = 30.0;
    NSInteger steps = (NSInteger)floor(fabs(deltaY) / threshold);
    if (steps <= 0) {
        return NO;
    }

    double currentSpeed = currentSpeedValue.doubleValue;
    double direction = deltaY > 0.0 ? 1.0 : -1.0;
    double newSpeed = currentSpeed + direction * 0.25 * steps;
    newSpeed = MAX(0.5, MIN(3.0, newSpeed));
    if (fabs(newSpeed - currentSpeed) <= DBL_EPSILON) {
        objc_setAssociatedObject(owner, &kDYYYLongPressVerticalInitialYKey, @(location.y), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        return NO;
    }

    CGFloat consumedY = initialYValue.doubleValue + direction * threshold * steps;
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalInitialYKey, @(consumedY), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalCurrentSpeedKey, @(newSpeed), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    if (updatedSpeed) {
        *updatedSpeed = newSpeed;
    }
    return YES;
}

static void DYYYEndLongPressVerticalAdjustment(id owner) {
    if (!owner) {
        return;
    }
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalActiveKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalInitialYKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(owner, &kDYYYLongPressVerticalCurrentSpeedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%hook AWEDSpeedBasicConfig

- (double)longPressSpeed {
    double configuredSpeed = DYYYConfiguredLongPressPlaybackSpeed();
    if (configuredSpeed > 0.0) {
        return configuredSpeed;
    }
    return %orig;
}

%end

%hook AFDLongPressFastSpeedHelper

+ (double)longPressFastSpeedValue {
    double configuredSpeed = DYYYConfiguredLongPressPlaybackSpeed();
    if (configuredSpeed > 0.0) {
        return configuredSpeed;
    }
    return %orig;
}

%end

%hook AWEDSpeedLockSpeedContainer

- (BOOL)canShowLockSpeed {
    if (DYYYGetBool(@"DYYYEnableLongPressSpeedGesture")) {
        return NO;
    }
    return %orig;
}

- (void)handleLongPressLockedDoubleSpeedEnded:(CGPoint)point
                                      gesture:(UILongPressGestureRecognizer *)gesture {
    AFDSpeedManager *speedManager = self.speedManager;
    if (speedManager) {
        dyyyActiveNativeSpeedManager = speedManager;
    }

    BOOL previousCompletionState = dyyyNativeLockCompletionActive;
    dyyyNativeLockCompletionActive = YES;
    @try {
        %orig(point, gesture);

        NSString *lockedAwemeID = speedManager.isLockedSpeedAwemeID;
        double synchronizedSpeed = 0.0;
        if (lockedAwemeID.length > 0) {
            // 官方上滑锁定：同步到配置的长按倍速。
            synchronizedSpeed = DYYYConfiguredLongPressPlaybackSpeed();
        } else {
            // 官方下滑松手取消：必须真正回到默认倍速。
            // 若此时仍把快捷倍速非 1x 当作“解锁后的正常倍速”，取消会被立刻写回，表现为无法解除。
            if (isFloatSpeedButtonEnabled) {
                setCurrentSpeedIndex(0);
                updateSpeedButtonUI();
            }
            synchronizedSpeed = DYYYConfiguredDefaultPlaybackSpeed();
        }
        if (isfinite(synchronizedSpeed) && synchronizedSpeed > 0.0) {
            if ([speedManager respondsToSelector:@selector(setCurrentSpeed:)]) {
                [speedManager setCurrentSpeed:synchronizedSpeed];
            }
            if (lockedAwemeID.length == 0) {
                DYYYApplyPlaybackSpeedThroughInteractionController(dyyyActivePlaybackInteractionController,
                                                                   synchronizedSpeed);
            }
        }
    } @finally {
        dyyyNativeLockCompletionActive = previousCompletionState;
    }
}

%end

%hook AWEDSpeedPortraitContainer

- (double)longPressSpeedValue {
    double configuredSpeed = DYYYConfiguredLongPressPlaybackSpeed();
    if (configuredSpeed > 0.0) {
        return configuredSpeed;
    }
    return %orig;
}

- (void)showToastWithText:(NSString *)text {
    if ([text isKindOfClass:NSString.class] &&
        [text containsString:@"已取消"] &&
        [text containsString:@"倍速播放"]) {
        text = DYYYAdjustedNativeLongPressSpeedHint(text);
    }
    %orig(text);
}

%end

%hook AWEDSpeedCoreContainer

- (void)changeSpeed:(double)speed {
    if (self.speedManager) {
        dyyyActiveNativeSpeedManager = self.speedManager;
    }

    if (dyyyNativeLockCompletionActive) {
        if (fabs(speed - 2.0) <= DBL_EPSILON) {
            double configuredSpeed = DYYYConfiguredLongPressPlaybackSpeed();
            if (configuredSpeed > 0.0) {
                speed = configuredSpeed;
            }
        } else if (fabs(speed - 1.0) <= DBL_EPSILON) {
            // 官方取消路径传入 1.0 时，只能回到默认倍速，不能回写快捷倍速按钮的非 1x 值。
            speed = DYYYConfiguredDefaultPlaybackSpeed();
        }
    }

    %orig(speed);
}

- (void)handleFastSpeed:(UILongPressGestureRecognizer *)gesture {
    if (self.speedManager) {
        dyyyActiveNativeSpeedManager = self.speedManager;
    }

    id playerProvider = self.playerProvider;
    if (DYYYIsVerifiedNativeDPlayerSpeedController(playerProvider)) {
        dyyyActiveDPlayerSpeedController = (AWEDPlayerSpeedController *)playerProvider;
    }

    UIGestureRecognizerState state = gesture.state;
    BOOL verticalAdjustmentEnabled = DYYYGetBool(@"DYYYEnableLongPressSpeedGesture");
    if (verticalAdjustmentEnabled && state == UIGestureRecognizerStateBegan) {
        DYYYBeginLongPressVerticalAdjustment(self, gesture, [self longPressFastSpeedValue]);
    }

    %orig(gesture);

    if ((state == UIGestureRecognizerStateBegan || state == UIGestureRecognizerStateChanged) &&
        self.isInLongPressFastSpeed &&
        DYYYIsVerifiedNativeDPlayerSpeedController(playerProvider)) {
        dyyyLongPressDPlayerSpeedController = (AWEDPlayerSpeedController *)playerProvider;
    }

    if (verticalAdjustmentEnabled &&
        state == UIGestureRecognizerStateBegan &&
        !self.isInLongPressFastSpeed) {
        DYYYEndLongPressVerticalAdjustment(self);
        return;
    }

    if (verticalAdjustmentEnabled &&
        state == UIGestureRecognizerStateChanged &&
        self.isInLongPressFastSpeed) {
        double updatedSpeed = 0.0;
        if (DYYYUpdateLongPressVerticalAdjustment(self, gesture, &updatedSpeed)) {
            [self changeSpeed:updatedSpeed];
            AWEDSpeedPortraitContainer *portraitContainer = self.portraitContainer;
            BOOL nativeViewWillTriggerHaptic = NO;
            if ([portraitContainer respondsToSelector:@selector(updateFastSpeedView:)]) {
                @try {
                    AFDFastSpeedView *speedView = portraitContainer.longPressFastSpeedView;
                    nativeViewWillTriggerHaptic = speedView && !speedView.superview;
                    [portraitContainer updateFastSpeedView:updatedSpeed];
                } @catch (__unused NSException *exception) {
                }
            }
            if (!nativeViewWillTriggerHaptic) {
                DYYYTriggerNativeLongPressSpeedHaptic();
            }
        }
    }

    if (DYYYLongPressGestureIsEnding(state)) {
        DYYYEndLongPressVerticalAdjustment(self);
        if (dyyyLongPressDPlayerSpeedController == playerProvider) {
            dyyyLongPressDPlayerSpeedController = nil;
        }
    }
}

%end

%hook AWEDPlayerSpeedController

- (void)viewDidLoad {
    %orig;
    dyyyActiveDPlayerSpeedController = self;
    DYYYApplyNormalPlaybackSpeedToNativeDPlayer(self);
}

- (void)setData:(id)data {
    %orig(data);
    dyyyActiveDPlayerSpeedController = self;
    DYYYApplyNormalPlaybackSpeedToNativeDPlayer(self);
}

- (void)viewWillAppear {
    %orig;
    dyyyActiveDPlayerSpeedController = self;
    DYYYApplyNormalPlaybackSpeedToNativeDPlayer(self);
}

- (void)onPlayerPlay:(id)player ifPlay:(BOOL)isPlaying {
    %orig(player, isPlaying);
    if (isPlaying) {
        dyyyActiveDPlayerSpeedController = self;
        DYYYApplyNormalPlaybackSpeedToNativeDPlayer(self);
    }
}

%end

%hook AWEPlayInteractionSpeedController

- (CGFloat)longPressFastSpeedValue {
    double configuredSpeed = DYYYConfiguredLongPressPlaybackSpeed();
    if (configuredSpeed > 0.0) {
        return (CGFloat)configuredSpeed;
    }
    return %orig;
}

- (void)showToastWithText:(NSString *)text {
    if ([text isKindOfClass:NSString.class] &&
        [text containsString:@"已取消"] &&
        [text containsString:@"倍速播放"]) {
        text = DYYYAdjustedNativeLongPressSpeedHint(text);
    }
    %orig(text);
}

- (void)handleLongPressFastSpeed:(UILongPressGestureRecognizer *)gesture {
    UIGestureRecognizerState state = gesture.state;
    BOOL verticalAdjustmentEnabled = DYYYGetBool(@"DYYYEnableLongPressSpeedGesture");
    if (verticalAdjustmentEnabled && state == UIGestureRecognizerStateBegan) {
        DYYYBeginLongPressVerticalAdjustment(self, gesture, [self longPressFastSpeedValue]);
    }

    %orig(gesture);

    if (verticalAdjustmentEnabled && state == UIGestureRecognizerStateChanged) {
        double updatedSpeed = 0.0;
        if (DYYYUpdateLongPressVerticalAdjustment(self, gesture, &updatedSpeed)) {
            [self changeSpeed:updatedSpeed];
        }
    }

    if (DYYYLongPressGestureIsEnding(state)) {
        DYYYEndLongPressVerticalAdjustment(self);
    }
}

%end

// 强制启用保存他人头像
%hook AFDProfileAvatarFunctionManager
- (BOOL)shouldShowSaveAvatarItem {
    BOOL shouldEnable = DYYYGetBool(@"DYYYEnableSaveAvatar");
    if (shouldEnable) {
        return YES;
    }
    return %orig;
}
%end

static char kDYYYAvatarPreviewSaveLongPressKey;

static id DYYYAvatarPreviewObjectForSelector(id object, NSString *selectorName) {
    if (!object || selectorName.length == 0) {
        return nil;
    }

    SEL selector = NSSelectorFromString(selectorName);
    if (![object respondsToSelector:selector]) {
        return nil;
    }

    return ((id (*)(id, SEL))objc_msgSend)(object, selector);
}

static NSURL *DYYYAvatarPreviewURLFromString(NSString *urlString) {
    if (![urlString isKindOfClass:NSString.class] || urlString.length == 0) {
        return nil;
    }

    NSString *normalizedURLString = urlString;
    if ([normalizedURLString hasPrefix:@"//"]) {
        normalizedURLString = [@"https:" stringByAppendingString:normalizedURLString];
    }

    NSURL *url = [NSURL URLWithString:normalizedURLString];
    if (!url.scheme || !url.host) {
        return nil;
    }

    return url;
}

static NSURL *DYYYAvatarPreviewURLFromURLList(NSArray *urlList) {
    if (![urlList isKindOfClass:NSArray.class] || urlList.count == 0) {
        return nil;
    }

    for (id urlValue in urlList) {
        if ([urlValue isKindOfClass:NSURL.class]) {
            return urlValue;
        }
        NSURL *url = DYYYAvatarPreviewURLFromString(urlValue);
        if (url) {
            return url;
        }
    }

    return nil;
}

static NSURL *DYYYAvatarPreviewURLFromObject(id object) {
    if (!object) {
        return nil;
    }

    if ([object isKindOfClass:NSURL.class]) {
        return object;
    }

    if ([object isKindOfClass:NSString.class]) {
        return DYYYAvatarPreviewURLFromString(object);
    }

    if ([object isKindOfClass:NSArray.class]) {
        return DYYYAvatarPreviewURLFromURLList(object);
    }

    NSURL *originURL = DYYYAvatarPreviewURLFromURLList(DYYYAvatarPreviewObjectForSelector(object, @"originURLList"));
    if (originURL) {
        return originURL;
    }

    NSURL *urlListURL = DYYYAvatarPreviewURLFromURLList(DYYYAvatarPreviewObjectForSelector(object, @"URLList"));
    if (urlListURL) {
        return urlListURL;
    }

    id dyyyDownloadURL = DYYYAvatarPreviewObjectForSelector(object, @"getDYYYSrcURLDownload");
    if ([dyyyDownloadURL isKindOfClass:NSURL.class]) {
        return dyyyDownloadURL;
    }

    return nil;
}

static NSURL *DYYYAvatarPreviewSourceURLForController(id controller) {
    NSArray<NSString *> *controllerURLSelectors = @[
        @"avatarImageURL",
        @"avatarImagePlaceholderURL",
    ];

    for (NSString *selectorName in controllerURLSelectors) {
        NSURL *url = DYYYAvatarPreviewURLFromObject(DYYYAvatarPreviewObjectForSelector(controller, selectorName));
        if (url) {
            return url;
        }
    }

    id user = DYYYAvatarPreviewObjectForSelector(controller, @"user");
    NSArray<NSString *> *userAvatarSelectors = @[
        @"avatarLarger",
        @"avatar300X300",
        @"avatar300x300",
        @"avatar168X168",
        @"avatar168x168",
        @"avatarMedium",
        @"avatarThumb",
    ];

    for (NSString *selectorName in userAvatarSelectors) {
        NSURL *url = DYYYAvatarPreviewURLFromObject(DYYYAvatarPreviewObjectForSelector(user, selectorName));
        if (url) {
            return url;
        }
    }

    return nil;
}

static BOOL DYYYInvokeAvatarPreviewNativeSave(id controller) {
    id functionManager = DYYYAvatarPreviewObjectForSelector(controller, @"functionManager");
    if (!functionManager || ![functionManager respondsToSelector:@selector(didClickedSaveAvatar)]) {
        return NO;
    }

    ((void (*)(id, SEL))objc_msgSend)(functionManager, @selector(didClickedSaveAvatar));
    return YES;
}

static void DYYYAttachAvatarPreviewSaveLongPressToView(id controller, UIView *targetView) {
    if (!controller || !targetView || objc_getAssociatedObject(targetView, &kDYYYAvatarPreviewSaveLongPressKey)) {
        return;
    }

    targetView.userInteractionEnabled = YES;
    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc] initWithTarget:controller action:@selector(dyyy_handleAvatarPreviewSaveLongPress:)];
    longPress.minimumPressDuration = 0.5;
    longPress.cancelsTouchesInView = NO;
    [targetView addGestureRecognizer:longPress];
    objc_setAssociatedObject(targetView, &kDYYYAvatarPreviewSaveLongPressKey, longPress, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    objc_setAssociatedObject(longPress, &kDYYYAvatarPreviewSaveLongPressKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void DYYYAttachAvatarPreviewSaveLongPress(id controller) {
    if (!controller || !DYYYGetBool(@"DYYYEnableSaveAvatar")) {
        return;
    }

    id gestureView = DYYYAvatarPreviewObjectForSelector(controller, @"avatarGestureView");
    if ([gestureView isKindOfClass:UIView.class]) {
        DYYYAttachAvatarPreviewSaveLongPressToView(controller, gestureView);
    }

    id imageView = DYYYAvatarPreviewObjectForSelector(controller, @"avatarImageView");
    if ([imageView isKindOfClass:UIView.class]) {
        DYYYAttachAvatarPreviewSaveLongPressToView(controller, imageView);
    }

    id rootView = DYYYAvatarPreviewObjectForSelector(controller, @"view");
    if ([rootView isKindOfClass:UIView.class]) {
        DYYYAttachAvatarPreviewSaveLongPressToView(controller, rootView);
    }
}

%hook AWEProfileAvatarViewController
- (void)viewDidLoad {
    %orig;
    DYYYAttachAvatarPreviewSaveLongPress(self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig(animated);
    DYYYAttachAvatarPreviewSaveLongPress(self);
}

- (void)p_setupViews {
    %orig;
    DYYYAttachAvatarPreviewSaveLongPress(self);
}

%new
- (void)dyyy_saveAvatarPreviewFromDouyinSource {
    NSURL *avatarURL = DYYYAvatarPreviewSourceURLForController(self);
    if (avatarURL) {
        [DYYYManager downloadMedia:avatarURL
                         mediaType:MediaTypeImage
                             audio:nil
                        completion:^(BOOL success) {
                          if (!success) {
                              [DYYYUtils showToast:@"头像下载失败"];
                          }
                        }];
        return;
    }

    if (DYYYInvokeAvatarPreviewNativeSave(self)) {
        [DYYYUtils showToast:@"正在保存头像..."];
        return;
    }

    [DYYYUtils showToast:@"无法获取头像原始链接"];
}

%new
- (void)dyyy_handleAvatarPreviewSaveLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan || !DYYYGetBool(@"DYYYEnableSaveAvatar")) {
        return;
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert addAction:[UIAlertAction actionWithTitle:@"保存头像"
                                              style:UIAlertActionStyleDefault
                                            handler:^(__unused UIAlertAction *action) {
                                              ((void (*)(id, SEL))objc_msgSend)(self, @selector(dyyy_saveAvatarPreviewFromDouyinSource));
                                            }]];
    [alert addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];

    UIView *sourceView = gesture.view;
    if (!sourceView) {
        id rootView = DYYYAvatarPreviewObjectForSelector(self, @"view");
        if ([rootView isKindOfClass:UIView.class]) {
            sourceView = rootView;
        }
    }
    if (alert.popoverPresentationController && sourceView) {
        alert.popoverPresentationController.sourceView = sourceView;
        CGPoint location = [gesture locationInView:sourceView];
        alert.popoverPresentationController.sourceRect = CGRectMake(location.x, location.y, 1.0, 1.0);
    }

    UIViewController *presentingController = (UIViewController *)self;
    while (presentingController.presentedViewController) {
        presentingController = presentingController.presentedViewController;
    }
    [presentingController presentViewController:alert animated:YES completion:nil];
}
%end

%hook AWECommentMediaDownloadConfigLivePhoto

BOOL commentLivePhotoNotWaterMark = DYYYGetBool(@"DYYYCommentLivePhotoNotWaterMark");

- (BOOL)needClientWaterMark {
    return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (BOOL)needClientEndWaterMark {
    return commentLivePhotoNotWaterMark ? 0 : %orig;
}

- (id)watermarkConfig {
    return commentLivePhotoNotWaterMark ? nil : %orig;
}

%end

%hook AWECommentImageModel
- (id)downloadUrl {
    if (DYYYGetBool(@"DYYYCommentNotWaterMark")) {
        return self.originUrl;
    }
    return %orig;
}
%end

%group EnableStickerSaveMenu
static __weak YYAnimatedImageView *targetStickerView = nil;

%hook _TtCV28AWECommentPanelListSwiftImpl6NEWAPI27CommentCellStickerComponent

- (void)handleLongPressWithGes:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        if ([gesture.view isKindOfClass:%c(YYAnimatedImageView)]) {
            targetStickerView = (YYAnimatedImageView *)gesture.view;
            NSLog(@"DYYY 长按表情：%@", targetStickerView);
        } else {
            targetStickerView = nil;
        }
    }

    %orig;
}

%end

%hook _TtC33AWECommentLongPressPanelSwiftImpl37CommentLongPressPanelSaveImageElement

- (BOOL)elementShouldShow {
    BOOL shouldShow = %orig;
    if (!DYYYGetBool(@"DYYYForceDownloadEmotion") && !DYYYGetBool(@"DYYYForceDownloadCommentAudio")) {
        return shouldShow;
    }
    AWECommentLongPressPanelContext *context = [self commentPageContext];
    AWECommentModel *selected = [context selectdComment] ?: [[context params] selectdComment];
    AWEIMStickerModel *sticker = [selected sticker];
    if (sticker && DYYYGetBool(@"DYYYForceDownloadEmotion")) {
        return NO;
    }
    AWECommentAudioModel *audio = [selected audioModel];
    if (audio && audio.content) {
        return YES;
    }
    return shouldShow;
}

- (void)elementTapped {
    AWECommentLongPressPanelContext *context = [self commentPageContext];
    AWECommentLongPressPanelParam *params = [context params];
    AWECommentModel *comment = [context selectdComment] ?: [params selectdComment];

    // 判断保存类型(表情包/音频/图片)
    AWEIMStickerModel *sticker = [comment sticker];

    AWECommentAudioModel *audio = [comment audioModel];
    BOOL hasAudio = (audio && audio.content);

    NSArray *imageList = nil;
    if ([comment respondsToSelector:@selector(imageList)]) {
        imageList = [comment imageList];
    }
    BOOL hasImages = (imageList && imageList.count > 0);

    // 整条评论菜单不提供表情保存；表情仅通过直接长按保存
    if (sticker && DYYYGetBool(@"DYYYForceDownloadEmotion")) {
        return;
    }

    // 音频保存逻辑
    if (hasAudio && DYYYGetBool(@"DYYYForceDownloadCommentAudio")) {
        NSString *audioContent = audio.content;

        NSString *userName = @"未知用户";
        if (comment.author && [comment.author respondsToSelector:@selector(nickname)]) {
            NSString *nickname = [comment.author performSelector:@selector(nickname)];
            if (nickname && nickname.length > 0) {
                userName = nickname;
            }
        }

        [DYYYManager downloadAndShareCommentAudio:audioContent
                                         userName:userName
                                       createTime:comment.createTime];
        return;
    }

    // 图片保存逻辑
    if (hasImages && DYYYGetBool(@"DYYYForceDownloadCommentImage")) {
        // 检查 is_pic_inflow 判断是保存全部还是单张
        // is_pic_inflow = 1: 点开具体图片后长按 -> 只保存当前图片
        // is_pic_inflow = 0: 直接在评论区长按 -> 保存全部图片
        NSDictionary *extraParams = [params extraParams];
        BOOL isPicInflow = NO;
        if (extraParams && [extraParams isKindOfClass:[NSDictionary class]]) {
            id isPicInflowValue = extraParams[@"is_pic_inflow"];
            if (isPicInflowValue) {
                isPicInflow = [isPicInflowValue integerValue] == 1;
            }
        }

        NSInteger currentIndex = -1; // -1 表示保存全部

        if (isPicInflow) {
            // 使用 DYYYUtils 封装的方法查找目标控制器
            UIViewController *topVC = [DYYYUtils topView];

            // 获取 Ivar 定义的类和目标控制器类
            Class ivarClass = NSClassFromString(@"AWECommentMediaFeedSwfitImpl.CommentMediaFeedCellViewController");
            Class targetClass = NSClassFromString(@"AWECommentMediaFeedSwfitImpl.CommentMediaFeedCommonImageCellViewController");

            if (ivarClass && targetClass && topVC) {
                Ivar multiIndexIvar = class_getInstanceVariable(ivarClass, "currentIndexInMultiImageList");
                if (multiIndexIvar) {
                    UIViewController *cellVC = [DYYYUtils findViewControllerOfClass:targetClass inViewController:topVC];
                    if (cellVC) {
                        ptrdiff_t offset = ivar_getOffset(multiIndexIvar);
                        NSInteger *ptr = (NSInteger *)((char *)(__bridge void *)cellVC + offset);
                        currentIndex = *ptr;
                    }
                }
            }
        }

        NSString *hint = (currentIndex >= 0) ? @"正在保存当前图片..." :
            [NSString stringWithFormat:@"正在保存 %lu 张图片...", (unsigned long)imageList.count];
        [DYYYUtils showToast:hint];

        [DYYYManager saveCommentImages:imageList
                            currentIndex:currentIndex
                            completion:^(NSInteger successCount, NSInteger livePhotoCount, NSInteger failedCount) {
            NSMutableString *message = [NSMutableString stringWithFormat:@"成功保存 %ld 张", (long)successCount];
            if (livePhotoCount > 0) {
                [message appendFormat:@"\n(含 %ld 张实况照片)", (long)livePhotoCount];
            }
            if (failedCount > 0) {
                [message appendFormat:@"\n失败 %ld 张", (long)failedCount];
            }
            [DYYYUtils showToast:message];
        }];
        return;
    }

    // 默认行为
    %orig;
}

%end

%hook UIMenu

+ (instancetype)menuWithTitle:(NSString *)title image:(UIImage *)image identifier:(UIMenuIdentifier)identifier options:(UIMenuOptions)options children:(NSArray<UIMenuElement *> *)children {
    BOOL hasAddStickerOption = NO;
    BOOL hasSaveLocalOption = NO;

    for (UIMenuElement *element in children) {
        NSString *elementTitle = nil;

        if ([element isKindOfClass:%c(UIAction)]) {
            elementTitle = [(UIAction *)element title];
        } else if ([element isKindOfClass:%c(UICommand)]) {
            elementTitle = [(UICommand *)element title];
        }

        if ([elementTitle isEqualToString:@"添加到表情"]) {
            hasAddStickerOption = YES;
        } else if ([elementTitle isEqualToString:@"保存到相册"]) {
            hasSaveLocalOption = YES;
        }
    }

    if (hasAddStickerOption && !hasSaveLocalOption) {
        NSMutableArray *newChildren = [children mutableCopy];

        UIAction *saveAction = [%c(UIAction) actionWithTitle:@"保存到相册"
                                                                 image:nil
                                                            identifier:nil
                                                               handler:^(__kindof UIAction *_Nonnull action) {
                                                                 // 使用全局变量 targetStickerView 保存当前长按的表情
                                                                 if (targetStickerView) {
                                                                     [DYYYManager saveAnimatedSticker:targetStickerView];
                                                                 } else {
                                                                     [DYYYUtils showToast:@"无法获取表情视图"];
                                                                 }
                                                               }];

        [newChildren addObject:saveAction];
        return %orig(title, image, identifier, options, newChildren);
    }

    return %orig;
}

%end
%end

%hook AWEIMEmoticonPreviewV2

// 添加保存按钮
- (void)layoutSubviews {
    %orig;
    static char kHasSaveButtonKey;
    BOOL DYYYForceDownloadPreviewEmotion = DYYYGetBool(@"DYYYForceDownloadPreviewEmotion");
    if (DYYYForceDownloadPreviewEmotion) {
        if (!objc_getAssociatedObject(self, &kHasSaveButtonKey)) {
            UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeSystem];
            UIImage *downloadIcon = [UIImage systemImageNamed:@"arrow.down.circle"];
            [saveButton setImage:downloadIcon forState:UIControlStateNormal];
            [saveButton setTintColor:[UIColor whiteColor]];
            saveButton.backgroundColor = [UIColor colorWithRed:0.0 green:0.5 blue:0.9 alpha:0.5];

            saveButton.layer.shadowColor = [UIColor blackColor].CGColor;
            saveButton.layer.shadowOffset = CGSizeMake(0, 2);
            saveButton.layer.shadowOpacity = 0.3;
            saveButton.layer.shadowRadius = 3;

            saveButton.translatesAutoresizingMaskIntoConstraints = NO;
            [self addSubview:saveButton];
            CGFloat buttonSize = 24.0;
            saveButton.layer.cornerRadius = buttonSize / 2;

            [NSLayoutConstraint activateConstraints:@[
                [saveButton.bottomAnchor constraintEqualToAnchor:self.bottomAnchor constant:-15], [saveButton.rightAnchor constraintEqualToAnchor:self.rightAnchor constant:-10],
                [saveButton.widthAnchor constraintEqualToConstant:buttonSize], [saveButton.heightAnchor constraintEqualToConstant:buttonSize]
            ]];

            saveButton.userInteractionEnabled = YES;
            [saveButton addTarget:self action:@selector(dyyy_saveButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
            objc_setAssociatedObject(self, &kHasSaveButtonKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

%new
- (void)dyyy_saveButtonTapped:(UIButton *)sender {
    // 获取表情包URL
    AWEIMEmoticonModel *emoticonModel = self.model;
    if (!emoticonModel) {
        [DYYYUtils showToast:@"无法获取表情包信息"];
        return;
    }

    NSString *urlString = nil;
    MediaType mediaType = MediaTypeImage;

    // 尝试动态URL
    if ([emoticonModel valueForKey:@"animate_url"]) {
        urlString = [emoticonModel valueForKey:@"animate_url"];
    }
    // 如果没有动态URL，则使用静态URL
    else if ([emoticonModel valueForKey:@"static_url"]) {
        urlString = [emoticonModel valueForKey:@"static_url"];
    }
    // 使用animateURLModel获取URL
    else if ([emoticonModel valueForKey:@"animateURLModel"]) {
        AWEURLModel *urlModel = [emoticonModel valueForKey:@"animateURLModel"];
        if (urlModel.originURLList.count > 0) {
            urlString = urlModel.originURLList[0];
        }
    }

    if (!urlString) {
        [DYYYUtils showToast:@"无法获取表情包链接"];
        return;
    }

    NSURL *url = [NSURL URLWithString:urlString];
    [DYYYManager downloadMedia:url
                     mediaType:MediaTypeHeic
                         audio:nil
                    completion:^(BOOL success){
                    }];
}

%end

static NSString *DYYYIMMessageStringValue(id object, NSString *selectorName) {
    if (!object || selectorName.length == 0) {
        return nil;
    }
    SEL selector = NSSelectorFromString(selectorName);
    if (!selector || ![object respondsToSelector:selector]) {
        return nil;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    id value = [object performSelector:selector];
#pragma clang diagnostic pop
    if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
        return value;
    }
    return nil;
}

static NSURL *DYYYIMEmotionDownloadURLFromMessage(AWEIMGiphyMessage *giphyMessage) {
    if (!giphyMessage) {
        return nil;
    }
    NSString *urlString = nil;
    if (giphyMessage.giphyURL.originURLList.count > 0) {
        urlString = giphyMessage.giphyURL.originURLList.firstObject;
    }
    if (urlString.length == 0) {
        NSString *animateURL = DYYYIMMessageStringValue(giphyMessage, @"animateURL");
        if (animateURL.length > 0) {
            urlString = animateURL;
        }
    }
    if (urlString.length == 0) {
        NSString *displayIconURL = DYYYIMMessageStringValue(giphyMessage, @"displayIconURL");
        if (displayIconURL.length > 0) {
            urlString = displayIconURL;
        }
    }
    if (urlString.length == 0) {
        return nil;
    }
    return [NSURL URLWithString:urlString];
}

static AWEIMCustomMenuModel *DYYYIMCreateDownloadMenuItem(AWEIMReusableCommonCell *cell, AWEIMCustomMenuComponent *menuComponent) {
    if (!cell) {
        return nil;
    }
    __weak AWEIMReusableCommonCell *weakCell = cell;
    __weak AWEIMCustomMenuComponent *weakMenuComponent = menuComponent;
    AWEIMCustomMenuModel *menuItem = [%c(AWEIMCustomMenuModel) new];
    menuItem.title = @"保存表情";
    menuItem.imageName = @"im_emoticon_interactive_tab_new";
    menuItem.trackerName = @"保存表情";
    menuItem.willPerformMenuActionSelectorBlock = ^(AWEIMCustomMenuModel *actionItem, NSUInteger actionIndex, BOOL *actionState) {
      (void)actionItem;
      (void)actionIndex;
      (void)actionState;
      AWEIMReusableCommonCell *strongCell = weakCell;
      AWEIMCustomMenuComponent *strongMenuComponent = weakMenuComponent;
      if ([strongMenuComponent respondsToSelector:@selector(msg_dismissMenu)]) {
          [strongMenuComponent msg_dismissMenu];
      }
      if (!strongCell) {
          [DYYYUtils showToast:@"无法获取表情包信息"];
          return;
      }
      AWEIMMessageComponentContext *context = (AWEIMMessageComponentContext *)strongCell.currentContext;
      if (!context || ![context.message isKindOfClass:%c(AWEIMGiphyMessage)]) {
          [DYYYUtils showToast:@"无法获取表情包信息"];
          return;
      }
      NSURL *downloadURL = DYYYIMEmotionDownloadURLFromMessage((AWEIMGiphyMessage *)context.message);
      if (!downloadURL) {
          [DYYYUtils showToast:@"无法获取表情包链接"];
          return;
      }
      [DYYYManager downloadMedia:downloadURL
                       mediaType:MediaTypeHeic
                           audio:nil
                      completion:^(BOOL success){
                      }];
    };
    return menuItem;
}

static NSArray *DYYYIMMenuItemsByAddingDownloadAction(NSArray *menuItems, id cell, AWEIMCustomMenuComponent *menuComponent) {
    if (!DYYYGetBool(@"DYYYForceDownloadIMEmotion")) {
        return menuItems;
    }
    if (!menuItems || !cell) {
        return menuItems;
    }
    AWEIMReusableCommonCell *commonCell = [cell isKindOfClass:%c(AWEIMReusableCommonCell)] ? (AWEIMReusableCommonCell *)cell : nil;
    if (!commonCell) {
        return menuItems;
    }
    AWEIMMessageComponentContext *context = (AWEIMMessageComponentContext *)commonCell.currentContext;
    if (!context || ![context.message isKindOfClass:%c(AWEIMGiphyMessage)]) {
        return menuItems;
    }
    for (AWEIMCustomMenuModel *item in menuItems) {
        if ([item isKindOfClass:%c(AWEIMCustomMenuModel)] && [item.title isEqualToString:@"保存表情"]) {
            return menuItems;
        }
    }
    NSMutableArray *newMenuItems = [menuItems mutableCopy];
    AWEIMCustomMenuModel *downloadItem = DYYYIMCreateDownloadMenuItem(commonCell, menuComponent);
    if (downloadItem) {
        [newMenuItems addObject:downloadItem];
    }
    return newMenuItems ?: menuItems;
}

%group DYYYIMMenuLegacyGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame tapLocationInScreen:(CGPoint)tapLocation menuItemList:(NSArray *)menuItems moreEmoticon:(BOOL)moreEmoticon onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMMenuItemsByAddingDownloadAction(menuItems, cell, self);
    %orig(bubbleFrame, tapLocation, updatedMenuItems, moreEmoticon, cell, extra);
}
%end
%end

%group DYYYIMMenuTapLocationGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame tapLocationInScreen:(CGPoint)tapLocation menuItemList:(NSArray *)menuItems menuPanelOptions:(unsigned long long)menuPanelOptions moreEmoticon:(BOOL)moreEmoticon onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMMenuItemsByAddingDownloadAction(menuItems, cell, self);
    %orig(bubbleFrame, tapLocation, updatedMenuItems, menuPanelOptions, moreEmoticon, cell, extra);
}
%end
%end

%group DYYYIMMenuHighLowGroup
%hook AWEIMCustomMenuComponent
- (void)msg_showMenuForBubbleFrameInScreen:(CGRect)bubbleFrame highLocationInScreen:(CGPoint)highLocation lowLocationInScreen:(CGPoint)lowLocation tryHighLocationFirst:(BOOL)tryHighLocationFirst menuItemList:(NSArray *)menuItems menuPanelOptions:(unsigned long long)menuPanelOptions onCell:(id)cell extra:(id)extra {
    NSArray *updatedMenuItems = DYYYIMMenuItemsByAddingDownloadAction(menuItems, cell, self);
    %orig(bubbleFrame, highLocation, lowLocation, tryHighLocationFirst, updatedMenuItems, menuPanelOptions, cell, extra);
}
%end
%end

%hook AWEFeedTabJumpGuideView

- (void)layoutSubviews {
    %orig;
    [self removeFromSuperview];
}

%end

%hook AWEFeedLiveMarkView
- (void)setHidden:(BOOL)hidden {
    if (DYYYGetBool(@"DYYYHideAvatarLive") || DYYYGetBool(@"DYYYHideAvatarButton")) {
        hidden = YES;
    }

    %orig(hidden);
}
%end

static id DYYYAvatarObjectForSelector(id object, SEL selector) {
    if (!object || !selector || ![object respondsToSelector:selector]) {
        return nil;
    }
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    @try {
        return [object performSelector:selector];
    } @catch (__unused NSException *exception) {
        return nil;
    }
#pragma clang diagnostic pop
}

static UIView *DYYYAvatarViewForSelector(id object, SEL selector) {
    id value = DYYYAvatarObjectForSelector(object, selector);
    return [value isKindOfClass:[UIView class]] ? value : nil;
}

static char kDYYYAvatarFollowApplyingKey;
static char kDYYYAvatarFollowDeferredApplyKey;
static char kDYYYAvatarFollowScopeViewKey;
static char kDYYYAvatarActionHiddenViewKey;
static char kDYYYAvatarActionRemovedViewKey;
static char kDYYYAvatarActionChromeViewKey;
static char kDYYYAvatarActionHiddenLayerKey;
static char kDYYYAvatarActionChromeLayerKey;
static char kDYYYAvatarSurroundingHiddenViewKey;

static BOOL DYYYAvatarFollowOptionsEnabled(void) {
    return DYYYGetBoolCached(@"DYYYHideLOTAnimationView") || DYYYGetBoolCached(@"DYYYHideFollowPromptView");
}

// 与收藏按钮同理：开关关闭时不再进入 runtime 关联对象表查询。
static BOOL DYYYShouldForceHideAvatarActionLayer(CALayer *layer) {
    return layer && DYYYAvatarFollowOptionsEnabled() && objc_getAssociatedObject(layer, &kDYYYAvatarActionHiddenLayerKey);
}

static BOOL DYYYShouldClearAvatarActionLayer(CALayer *layer) {
    if (!layer || !DYYYAvatarFollowOptionsEnabled()) {
        return NO;
    }
    return objc_getAssociatedObject(layer, &kDYYYAvatarActionChromeLayerKey) != nil ||
           objc_getAssociatedObject(layer, &kDYYYAvatarActionHiddenLayerKey) != nil;
}

static void DYYYMarkAvatarActionLayerHidden(CALayer *layer) {
    if (!layer) {
        return;
    }

    objc_setAssociatedObject(layer, &kDYYYAvatarActionHiddenLayerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    layer.hidden = YES;
    for (CALayer *sublayer in [layer.sublayers copy]) {
        DYYYMarkAvatarActionLayerHidden(sublayer);
    }
}

static void DYYYMarkAvatarActionLayerChrome(CALayer *layer) {
    if (!layer) {
        return;
    }

    objc_setAssociatedObject(layer, &kDYYYAvatarActionChromeLayerKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    layer.contents = nil;
    layer.opaque = NO;
    layer.backgroundColor = UIColor.clearColor.CGColor;
    layer.borderWidth = 0.0;
    layer.borderColor = UIColor.clearColor.CGColor;
    layer.shadowOpacity = 0.0;
    layer.shadowColor = UIColor.clearColor.CGColor;
    if ([layer isKindOfClass:[CAShapeLayer class]]) {
        CAShapeLayer *shapeLayer = (CAShapeLayer *)layer;
        shapeLayer.fillColor = UIColor.clearColor.CGColor;
        shapeLayer.strokeColor = UIColor.clearColor.CGColor;
    }

    for (CALayer *sublayer in [layer.sublayers copy]) {
        DYYYMarkAvatarActionLayerHidden(sublayer);
    }
}

static void DYYYPrepareAvatarActionSublayer(CALayer *parentLayer, CALayer *sublayer) {
    if (!parentLayer || !sublayer) {
        return;
    }

    BOOL isSuppressedTree = objc_getAssociatedObject(parentLayer, &kDYYYAvatarActionChromeLayerKey) ||
                            objc_getAssociatedObject(parentLayer, &kDYYYAvatarActionHiddenLayerKey);
    if (isSuppressedTree && DYYYAvatarFollowOptionsEnabled()) {
        DYYYMarkAvatarActionLayerHidden(sublayer);
    }
}

static void DYYYMarkAvatarActionViewHidden(UIView *view) {
    if (!view) {
        return;
    }

    objc_setAssociatedObject(view, &kDYYYAvatarActionHiddenViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    view.hidden = YES;
}

static BOOL DYYYShouldForceAvatarActionViewHidden(UIView *view) {
    // 两个开关全关时结果必然为 NO，提前返回可省掉后面的关联对象查询。
    if (!view || !DYYYAvatarFollowOptionsEnabled()) {
        return NO;
    }

    BOOL hideVisual = objc_getAssociatedObject(view, &kDYYYAvatarActionHiddenViewKey) != nil;
    if (hideVisual) {
        return YES;
    }

    BOOL removeView = objc_getAssociatedObject(view, &kDYYYAvatarActionRemovedViewKey) != nil;
    return removeView && DYYYGetBoolCached(@"DYYYHideFollowPromptView");
}

static BOOL DYYYShouldClearAvatarActionViewChrome(UIView *view) {
    return view && DYYYGetBoolCached(@"DYYYHideLOTAnimationView") && objc_getAssociatedObject(view, &kDYYYAvatarActionChromeViewKey);
}

static void DYYYHideAvatarVisualForSelector(id object, SEL selector) {
    UIView *view = DYYYAvatarViewForSelector(object, selector);
    if (view) {
        view.hidden = YES;
    }
}

static void DYYYMarkAvatarSurroundingViewHidden(UIView *view) {
    if (!view) {
        return;
    }

    objc_setAssociatedObject(view, &kDYYYAvatarSurroundingHiddenViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    view.hidden = YES;
    view.userInteractionEnabled = NO;
}

static BOOL DYYYShouldForceAvatarSurroundingViewHidden(UIView *view) {
    return view && DYYYGetBoolCached(@"DYYYHideAvatarButton") && objc_getAssociatedObject(view, &kDYYYAvatarSurroundingHiddenViewKey);
}

static void DYYYHideAvatarSurroundingVisualForSelector(id object, SEL selector) {
    UIView *view = DYYYAvatarViewForSelector(object, selector);
    DYYYMarkAvatarSurroundingViewHidden(view);
}

static void DYYYApplyAvatarSurroundingSettingsForOwner(id owner) {
    if (!owner || !DYYYGetBool(@"DYYYHideAvatarButton")) {
        return;
    }

    for (NSString *selectorName in @[
             @"colorRingView",
             @"storyRingView",
             @"story25RingView",
             @"decorationView",
             @"avatarDecorationView",
             @"avatarPendantView",
             @"avatarLiveMarkView",
             @"liveMarkView",
             @"avatarLiveTagView",
             @"liveTagView",
         ]) {
        DYYYHideAvatarSurroundingVisualForSelector(owner, NSSelectorFromString(selectorName));
    }
}

static void DYYYRemoveAvatarView(UIView *view) {
    if (!view) {
        return;
    }
    objc_setAssociatedObject(view, &kDYYYAvatarActionRemovedViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    view.hidden = YES;
    view.userInteractionEnabled = NO;
}

static void DYYYRemoveAvatarViewForSelector(id object, SEL selector) {
    UIView *view = DYYYAvatarViewForSelector(object, selector);
    DYYYRemoveAvatarView(view);
}

static void DYYYHideAvatarFollowLayerContents(UIView *view) {
    if (!view) {
        return;
    }
    objc_setAssociatedObject(view, &kDYYYAvatarActionChromeViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    view.backgroundColor = UIColor.clearColor;
    view.opaque = NO;
    DYYYMarkAvatarActionLayerChrome(view.layer);
}

static void DYYYClearAvatarActionLayerChrome(CALayer *layer) {
    DYYYMarkAvatarActionLayerChrome(layer);
}

static void DYYYClearAvatarActionSubviewChrome(UIView *view) {
    if (!view) {
        return;
    }

    objc_setAssociatedObject(view, &kDYYYAvatarActionChromeViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    view.backgroundColor = UIColor.clearColor;
    view.opaque = NO;
    DYYYClearAvatarActionLayerChrome(view.layer);

    for (UIView *subview in [view.subviews copy]) {
        DYYYClearAvatarActionSubviewChrome(subview);
    }
}

static void DYYYClearAvatarActionViewChrome(UIView *view) {
    if (!view) {
        return;
    }

    objc_setAssociatedObject(view, &kDYYYAvatarActionChromeViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    view.backgroundColor = UIColor.clearColor;
    view.opaque = NO;
    DYYYClearAvatarActionLayerChrome(view.layer);

    for (UIView *subview in [view.subviews copy]) {
        DYYYClearAvatarActionSubviewChrome(subview);
    }
}

static BOOL DYYYIsLegacyAvatarFollowAnimationView(UIView *view) {
    Class promptClass = NSClassFromString(@"AWEPlayInteractionFollowPromptView");
    UIView *ancestor = view.superview;
    for (NSInteger depth = 0; ancestor && depth < 6; depth++, ancestor = ancestor.superview) {
        if (promptClass && [ancestor isKindOfClass:promptClass]) {
            return YES;
        }
    }
    return NO;
}

static BOOL DYYYHideAvatarFollowIconInView(UIView *view) {
    if (!view) {
        return NO;
    }

    NSString *className = NSStringFromClass(view.class);
    if ([className isEqualToString:@"LOTAnimationView"]) {
        DYYYHideAvatarFollowLayerContents(view);
        return YES;
    }

    if ([className isEqualToString:@"AWEPlayInteractionStaticFollowAnimationView"]) {
        BOOL foundIcon = NO;
        for (NSString *selectorName in @[ @"plusImageView", @"tickImageView" ]) {
            UIView *iconView = DYYYAvatarViewForSelector(view, NSSelectorFromString(selectorName));
            if (iconView) {
                DYYYMarkAvatarActionViewHidden(iconView);
                foundIcon = YES;
            }
        }
        if (!foundIcon) {
            DYYYHideAvatarFollowLayerContents(view);
        }
        return YES;
    }

    BOOL foundIcon = NO;
    for (UIView *subview in view.subviews) {
        foundIcon = DYYYHideAvatarFollowIconInView(subview) || foundIcon;
    }
    return foundIcon;
}

static BOOL DYYYIsAvatarFollowContainerView(UIView *view) {
    NSString *className = NSStringFromClass(view.class);
    return [className containsString:@"Follow"] || [className containsString:@"follow"] ||
           [className containsString:@"Prompt"] || [className containsString:@"Add"] ||
           [className containsString:@"SendMessage"] || [className containsString:@"sendMessage"] ||
           [className containsString:@"SendMsg"] || [className containsString:@"sendMsg"] ||
           [className containsString:@"EnterStore"] || [className containsString:@"enterStore"] ||
           [className containsString:@"LinkIcon"] || [className containsString:@"linkIcon"];
}

static BOOL DYYYIsSmallAvatarFollowBadgeView(UIView *view) {
    CGFloat width = CGRectGetWidth(view.bounds);
    CGFloat height = CGRectGetHeight(view.bounds);
    return width > 0.0 && height > 0.0 && width <= 52.0 && height <= 52.0;
}

static UIView *DYYYAvatarFollowRemovalTargetForView(UIView *view, UIView *rootView) {
    UIView *target = view;
    UIView *ancestor = view.superview;
    while (ancestor && ancestor != rootView) {
        if (DYYYIsAvatarFollowContainerView(ancestor) || DYYYIsSmallAvatarFollowBadgeView(ancestor)) {
            target = ancestor;
            ancestor = ancestor.superview;
            continue;
        }
        break;
    }
    return target;
}

static BOOL DYYYHideAvatarAuxiliaryActionVisualsInView(UIView *view) {
    if (!view) {
        return NO;
    }

    NSString *className = NSStringFromClass(view.class);
    BOOL isActionVisual = [view isKindOfClass:[UIImageView class]] ||
                          [className containsString:@"GuideAnimation"] ||
                          [className containsString:@"SendMessageImage"] ||
                          [className containsString:@"SendMsgImage"] ||
                          [className containsString:@"EnterStoreImage"] ||
                          [className containsString:@"LinkIcon"];
    if (isActionVisual) {
        DYYYMarkAvatarActionViewHidden(view);
        return YES;
    }

    BOOL foundVisual = NO;
    for (UIView *subview in [view.subviews copy]) {
        foundVisual = DYYYHideAvatarAuxiliaryActionVisualsInView(subview) || foundVisual;
    }
    return foundVisual;
}

static NSArray<NSArray<NSString *> *> *DYYYAvatarAuxiliaryActionSelectorGroups(void) {
    return @[
        @[ @"sendMessageView", @"avatarSendMessageImageView", @"sendMessageGuideView" ],
        @[ @"enterStoreView", @"avatarEnterStoreImageView", @"enterStoreGuideView" ],
        @[ @"linkIconContainerView", @"userAvatarLinkIcon" ],
    ];
}

static BOOL DYYYApplyAvatarAuxiliaryActionSettingsForOwner(id owner) {
    BOOL hidePlus = DYYYGetBool(@"DYYYHideLOTAnimationView");
    BOOL removePlus = DYYYGetBool(@"DYYYHideFollowPromptView");
    if (!hidePlus && !removePlus) {
        return NO;
    }

    BOOL handled = NO;
    for (NSArray<NSString *> *selectorGroup in DYYYAvatarAuxiliaryActionSelectorGroups()) {
        UIView *containerView = DYYYAvatarViewForSelector(owner, NSSelectorFromString(selectorGroup.firstObject));
        NSMutableArray<UIView *> *visualViews = [NSMutableArray array];
        for (NSUInteger index = 1; index < selectorGroup.count; index++) {
            UIView *visualView = DYYYAvatarViewForSelector(owner, NSSelectorFromString(selectorGroup[index]));
            if (visualView) {
                [visualViews addObject:visualView];
            }
        }

        if (removePlus) {
            UIView *fallbackVisual = visualViews.firstObject;
            UIView *removalTarget = containerView ?: DYYYAvatarFollowRemovalTargetForView(fallbackVisual, nil);
            DYYYRemoveAvatarView(removalTarget);
            for (UIView *visualView in visualViews) {
                DYYYRemoveAvatarView(visualView);
            }
            handled = (removalTarget || visualViews.count > 0) || handled;
            continue;
        }

        for (UIView *visualView in visualViews) {
            visualView.hidden = YES;
            handled = YES;
        }
        if (containerView) {
            DYYYClearAvatarActionViewChrome(containerView);
            BOOL foundVisual = DYYYHideAvatarAuxiliaryActionVisualsInView(containerView);
            if (!foundVisual && visualViews.count == 0) {
                DYYYHideAvatarFollowLayerContents(containerView);
            }
            handled = YES;
        }
    }
    return handled;
}

static BOOL DYYYApplyAvatarFollowSettingsInView(UIView *view, UIView *rootView) {
    if (!view) {
        return NO;
    }

    BOOL hidePlus = DYYYGetBool(@"DYYYHideLOTAnimationView");
    BOOL removePlus = DYYYGetBool(@"DYYYHideFollowPromptView");
    if (!hidePlus && !removePlus) {
        return NO;
    }

    // 记录已识别的头像操作树，便于异步追加子视图时立即再识别。
    objc_setAssociatedObject(view, &kDYYYAvatarFollowScopeViewKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    NSString *className = NSStringFromClass(view.class);
    BOOL isAvatarView = [className isEqualToString:@"AWEPlayInteractionUserAvatarView"];
    BOOL isStaticFollowView = [className isEqualToString:@"AWEPlayInteractionStaticFollowAnimationView"];
    BOOL isLegacyFollowAnimation = [className isEqualToString:@"LOTAnimationView"] && DYYYIsLegacyAvatarFollowAnimationView(view);
    BOOL isLegacyPromptContainer = [className isEqualToString:@"AWEPlayInteractionFollowPromptView"];
    BOOL handled = NO;

    if (isAvatarView) {
        handled = DYYYApplyAvatarAuxiliaryActionSettingsForOwner(view) || handled;
    }

    if (isStaticFollowView || isLegacyFollowAnimation) {
        if (removePlus) {
            DYYYRemoveAvatarView(DYYYAvatarFollowRemovalTargetForView(view, rootView));
        } else {
            DYYYHideAvatarFollowIconInView(view);
        }
        handled = YES;
    } else if (removePlus && isLegacyPromptContainer) {
        view.hidden = YES;
        view.userInteractionEnabled = NO;
        handled = YES;
    }

    for (UIView *subview in [view.subviews copy]) {
        handled = DYYYApplyAvatarFollowSettingsInView(subview, rootView) || handled;
    }
    return handled;
}

static void DYYYApplyAvatarFollowSettingsForContext(id context) {
    UIView *elementView = DYYYAvatarViewForSelector(context, NSSelectorFromString(@"elementView"));
    if (elementView) {
        DYYYApplyAvatarFollowSettingsInView(elementView, elementView);
    }
}

static void DYYYApplyAvatarFollowPromptSettings(id owner) {
    BOOL hidePlus = DYYYGetBool(@"DYYYHideLOTAnimationView");
    BOOL removePlus = DYYYGetBool(@"DYYYHideFollowPromptView");
    if (!hidePlus && !removePlus) {
        return;
    }

    for (NSString *selectorName in @[ @"followAnimationView", @"unfollowAnimationView", @"staticFollowAnimationView" ]) {
        UIView *animationView = DYYYAvatarViewForSelector(owner, NSSelectorFromString(selectorName));
        if (!animationView) {
            continue;
        }
        if (removePlus) {
            DYYYRemoveAvatarView(DYYYAvatarFollowRemovalTargetForView(animationView, nil));
        } else {
            DYYYHideAvatarFollowIconInView(animationView);
        }
    }

    UIView *followAddView = DYYYAvatarViewForSelector(owner, NSSelectorFromString(@"followAddView"));
    if (removePlus) {
        DYYYRemoveAvatarView(followAddView);
    } else {
        BOOL foundIcon = DYYYHideAvatarFollowIconInView(followAddView);
        if (hidePlus && followAddView) {
            DYYYClearAvatarActionViewChrome(followAddView);
            if (!foundIcon) {
                DYYYHideAvatarFollowLayerContents(followAddView);
            }
        }
    }

    UIView *followPromptView = DYYYAvatarViewForSelector(owner, NSSelectorFromString(@"followPromptView"));
    if (removePlus) {
        DYYYRemoveAvatarView(followPromptView);
    } else {
        DYYYApplyAvatarFollowSettingsInView(followPromptView, followPromptView);
    }

    DYYYApplyAvatarAuxiliaryActionSettingsForOwner(owner);

    if ([owner isKindOfClass:[UIView class]]) {
        DYYYApplyAvatarFollowSettingsInView((UIView *)owner, (UIView *)owner);
    } else if ([owner isKindOfClass:[UIViewController class]]) {
        DYYYApplyAvatarFollowSettingsInView(((UIViewController *)owner).view, ((UIViewController *)owner).view);
    }
    UIView *userAvatarView = DYYYAvatarViewForSelector(owner, NSSelectorFromString(@"userAvatarView"));
    if (userAvatarView) {
        DYYYApplyAvatarFollowSettingsInView(userAvatarView, userAvatarView);
    }
    DYYYApplyAvatarFollowSettingsForContext(DYYYAvatarObjectForSelector(owner, NSSelectorFromString(@"userAvatarContext")));
}

static void DYYYApplyAvatarFollowPromptSettingsSafely(id owner) {
    if (!owner || !DYYYAvatarFollowOptionsEnabled() ||
        objc_getAssociatedObject(owner, &kDYYYAvatarFollowApplyingKey)) {
        return;
    }

    // 必须在任何动态 getter 探测前建立屏障。部分版本的 userAvatarView getter
    // 会同步回调 controllerStartConfigAvatarView:，若稍后再标记会形成无限递归。
    objc_setAssociatedObject(owner, &kDYYYAvatarFollowApplyingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    @try {
        DYYYApplyAvatarFollowPromptSettings(owner);
    } @catch (__unused NSException *exception) {
        // 宿主私有 getter 在版本变化时可能抛出异常；头像附加功能失败不应终止主进程。
    } @finally {
        objc_setAssociatedObject(owner, &kDYYYAvatarFollowApplyingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
}

static void DYYYApplyAvatarFollowPromptSettingsWithRetry(id owner) {
    if (!owner || !DYYYAvatarFollowOptionsEnabled() ||
        objc_getAssociatedObject(owner, &kDYYYAvatarFollowApplyingKey)) {
        return;
    }

    DYYYApplyAvatarFollowPromptSettingsSafely(owner);
    if (objc_getAssociatedObject(owner, &kDYYYAvatarFollowDeferredApplyKey)) {
        return;
    }

    objc_setAssociatedObject(owner, &kDYYYAvatarFollowDeferredApplyKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    id target = owner;
    dispatch_async(dispatch_get_main_queue(), ^{
        DYYYApplyAvatarFollowPromptSettingsSafely(target);
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            DYYYApplyAvatarFollowPromptSettingsSafely(target);
            objc_setAssociatedObject(target, &kDYYYAvatarFollowDeferredApplyKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        });
    });
}

// 隐藏头像加号和透明
%hook LOTAnimationView
- (void)layoutSubviews {
    %orig;
    // 旧版加号动画可能被额外容器包裹，沿父视图向上识别关注提示视图。
    if (DYYYIsLegacyAvatarFollowAnimationView(self)) {
        // 检查是否需要隐藏加号
        if (DYYYAvatarFollowOptionsEnabled()) {
            if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
                DYYYRemoveAvatarView(DYYYAvatarFollowRemovalTargetForView(self, nil));
            } else {
                DYYYHideAvatarFollowLayerContents(self);
            }
            DYYYApplyAvatarFollowPromptSettingsWithRetry(self.superview ?: self);
            return;
        }
        // 应用透明度设置
        NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
        if (transparencyValue && transparencyValue.length > 0) {
            CGFloat alphaValue = [transparencyValue floatValue];
            self.alpha = alphaValue;
        }
    }
}
%end

%hook AWEPlayInteractionStaticFollowAnimationView
- (void)layoutSubviews {
    %orig;
    if (DYYYAvatarFollowOptionsEnabled()) {
        DYYYApplyAvatarFollowSettingsInView((UIView *)self, nil);
        DYYYApplyAvatarFollowPromptSettingsWithRetry(self.superview ?: self);
    }
}
%end

// 首页头像隐藏和透明
%hook AWEAdAvatarView
- (void)layoutSubviews {
    %orig;

    // 检查是否需要隐藏头像
    if (DYYYGetBool(@"DYYYHideAvatarButton")) {
        self.hidden = YES;
        return;
    }

    // 应用透明度设置
    NSString *transparencyValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYAvatarViewTransparency"];
    if (transparencyValue && transparencyValue.length > 0) {
        CGFloat alphaValue = [transparencyValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            self.alpha = alphaValue;
        }
    }
}
%end

// 移除同城吃喝玩乐提示框
%hook AWENearbySkyLightCapsuleView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideNearbyCapsuleView")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏弹幕按钮
%hook AWEPlayDanmakuInputContainView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideDanmuButton")) {
        self.hidden = YES;
        return;
    }

    if (DYYYViewIsInsidePlayInteraction(self)) {
        DYYYApplyPlayInteractionElementLayout(self, @"AWEPlayInteractionDanmakuElement");
    }
}

%end

static char kDYYYCommentSearchAnchorManagedHiddenKey;
static char kDYYYCommentSearchAnchorPreviousHiddenKey;

static void DYYYApplyCommentSearchAnchorVisibility(UIView *view) {
    if (!view) {
        return;
    }

    @try {
        BOOL shouldHide = DYYYGetBool(@"DYYYHideCommentViews");
        NSNumber *managedHidden = objc_getAssociatedObject(view, &kDYYYCommentSearchAnchorManagedHiddenKey);

        if (shouldHide) {
            if (![managedHidden boolValue]) {
                objc_setAssociatedObject(view,
                                         &kDYYYCommentSearchAnchorPreviousHiddenKey,
                                         @(view.hidden),
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                objc_setAssociatedObject(view,
                                         &kDYYYCommentSearchAnchorManagedHiddenKey,
                                         @YES,
                                         OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            view.hidden = YES;
            return;
        }

        if ([managedHidden boolValue]) {
            NSNumber *previousHidden = objc_getAssociatedObject(view, &kDYYYCommentSearchAnchorPreviousHiddenKey);
            view.hidden = previousHidden ? previousHidden.boolValue : NO;
            objc_setAssociatedObject(view, &kDYYYCommentSearchAnchorManagedHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(view, &kDYYYCommentSearchAnchorPreviousHiddenKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    } @catch (NSException *exception) {
        NSLog(@"[DYYY][CommentSearchAnchor] visibility update failed on %@: %@",
              NSStringFromClass([view class]),
              exception.reason);
    }
}

static char kDYYYCommentHeaderVerifiedCollapseModelKey;

static BOOL DYYYIsCommentHeaderLeafViewHiddenBySetting(UIView *view) {
    if (!view || !DYYYGetBool(@"DYYYHideCommentViews")) {
        return NO;
    }

    NSString *className = NSStringFromClass([view class]);
    static NSArray<NSString *> *commentViewsHiddenSuffixes = nil;
    static dispatch_once_t commentViewsOnceToken;
    dispatch_once(&commentViewsOnceToken, ^{
      commentViewsHiddenSuffixes = @[
          @"AWECommentSearchAnchorView",
          @"AWEPOIEntryAnchorView",
          @"AWECommentGuideLunaAnchorView",
          @"CommentHeaderGeneralView",
          @"CommentHeaderGoodsView",
          @"CommentHeaderTemplateAnchorView"
      ];
    });

    for (NSString *suffix in commentViewsHiddenSuffixes) {
        if ([className hasSuffix:suffix]) {
            return YES;
        }
    }
    return NO;
}

static BOOL DYYYCommentHeaderViewTreeContainsHiddenLeaf(UIView *view, NSUInteger depth) {
    if (!view || depth > 6) {
        return NO;
    }
    if (DYYYIsCommentHeaderLeafViewHiddenBySetting(view)) {
        return YES;
    }
    for (UIView *subview in view.subviews) {
        if (DYYYCommentHeaderViewTreeContainsHiddenLeaf(subview, depth + 1)) {
            return YES;
        }
    }
    return NO;
}

static BOOL DYYYCommentHeaderCellContainsOnlyHiddenLeaf(UIView *cell) {
    if (!cell) {
        return NO;
    }

    UIView *contentContainer = cell;
    if ([cell isKindOfClass:[UICollectionViewCell class]]) {
        contentContainer = ((UICollectionViewCell *)cell).contentView;
    }

    // 39.7.0 的实机日志显示：产生空行的 Header Cell 只有一个业务叶子分支。
    // 若 Cell 同时承载其他分支（例如页签），保持宿主原高度，避免再次误伤。
    if (contentContainer.subviews.count != 1) {
        return NO;
    }
    return DYYYCommentHeaderViewTreeContainsHiddenLeaf(contentContainer.subviews.firstObject, 0);
}

static BOOL DYYYCommentHeaderCellShouldCollapseForHide(UIView *cell, id model) {
    if (!DYYYGetBool(@"DYYYHideCommentViews") || !cell) {
        return NO;
    }

    if (DYYYCommentHeaderCellContainsOnlyHiddenLeaf(cell)) {
        return YES;
    }

    UIView *contentContainer = cell;
    if ([cell isKindOfClass:[UICollectionViewCell class]]) {
        contentContainer = ((UICollectionViewCell *)cell).contentView;
    }
    if (contentContainer.subviews.count == 1) {
        UIView *only = contentContainer.subviews.firstObject;
        if (only.hidden || only.alpha < 0.01 || CGRectGetHeight(only.bounds) < 0.5) {
            return YES;
        }
    }
    return NO;
}

static void DYYYSetCommentHeaderModelVerifiedCollapse(id model, BOOL shouldCollapse) {
    if (!model) {
        return;
    }
    objc_setAssociatedObject(model,
                             &kDYYYCommentHeaderVerifiedCollapseModelKey,
                             @(shouldCollapse),
                             OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static BOOL DYYYShouldVerifiedCollapseCommentHeaderModel(id model) {
    return DYYYGetBool(@"DYYYHideCommentViews") &&
           [objc_getAssociatedObject(model, &kDYYYCommentHeaderVerifiedCollapseModelKey) boolValue];
}

%group CommentSearchAnchorGroup

%hook AWECommentSearchAnchorView

- (void)updateWithModel:(id)model {
    %orig(model);
    DYYYApplyCommentSearchAnchorVisibility(self);
}

- (void)layoutSubviews {
    %orig;
    DYYYApplyCommentSearchAnchorVisibility(self);
}

- (void)didMoveToWindow {
    %orig;
    DYYYApplyCommentSearchAnchorVisibility(self);
}

%end

%end

%group CommentPanelHeaderVerifiedCollapseGroup

%hook AWECommentPanelHeaderSwiftImpl_CommentPanelHeaderSectionController

- (CGSize)sizeForItemAtIndex:(NSInteger)index model:(id)model collectionViewSize:(CGSize)collectionViewSize {
    CGSize originalSize = %orig(index, model, collectionViewSize);
    if (DYYYShouldVerifiedCollapseCommentHeaderModel(model)) {
        originalSize.height = 0.0;
    }
    return originalSize;
}

- (double)currentHeight {
    double originalHeight = %orig;

    id models = DYYYKVCValueIfPossible(self, @"modelsArray");
    if (![models isKindOfClass:[NSArray class]] || [(NSArray *)models count] == 0) {
        return originalHeight;
    }

    BOOL shouldRecalculate = NO;
    for (id model in (NSArray *)models) {
        if (DYYYShouldVerifiedCollapseCommentHeaderModel(model)) {
            shouldRecalculate = YES;
            break;
        }
    }
    if (!shouldRecalculate) {
        return originalHeight;
    }

    double totalHeight = 0.0;
    CGSize collectionViewSize = CGSizeMake([UIScreen mainScreen].bounds.size.width, 0.0);
    NSInteger index = 0;
    SEL sizeSelector = @selector(sizeForItemAtIndex:model:collectionViewSize:);
    for (id model in (NSArray *)models) {
        CGSize itemSize = ((CGSize (*)(id, SEL, NSInteger, id, CGSize))objc_msgSend)(self,
                                                                                       sizeSelector,
                                                                                       index,
                                                                                       model,
                                                                                       collectionViewSize);
        totalHeight += itemSize.height;
        index++;
    }
    return totalHeight;
}

- (void)configCell:(id)cell index:(NSInteger)index model:(id)model {
    %orig(cell, index, model);
    BOOL shouldCollapse = [cell isKindOfClass:[UIView class]] &&
                          DYYYCommentHeaderCellShouldCollapseForHide((UIView *)cell, model);
    BOOL wasCollapsed = DYYYShouldVerifiedCollapseCommentHeaderModel(model);
    DYYYSetCommentHeaderModelVerifiedCollapse(model, shouldCollapse);
    if (shouldCollapse && !wasCollapsed) {
        id didUpdateHeight = DYYYKVCValueIfPossible(self, @"didUpdateHeight");
        if (didUpdateHeight) {
            ((void (^)(void))didUpdateHeight)();
        }
    }
}

%end

%end

// 隐藏评论区定位
%hook AWEPOIEntryAnchorView

- (void)p_addViews {
    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        return;
    }
    %orig;
}

%end

// 隐藏评论音乐
%hook AWECommentGuideLunaAnchorView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }

    if (DYYYGetBool(@"DYYYMusicCopyText")) {
        UILabel *label = nil;
        if ([self respondsToSelector:@selector(preTitleLabel)]) {
            label = [self valueForKey:@"preTitleLabel"];
        }
        if (label && [label isKindOfClass:[UILabel class]]) {
            label.text = @"";
        }
    }
}

- (void)p_didClickSong {
    if (DYYYGetBool(@"DYYYMusicCopyText")) {
        // 通过 KVC 拿到内部的 songButton
        UIButton *btn = nil;
        if ([self respondsToSelector:@selector(songButton)]) {
            btn = (UIButton *)[self valueForKey:@"songButton"];
        }

        // 获取歌曲名并复制到剪贴板
        if (btn && [btn isKindOfClass:[UIButton class]]) {
            NSString *song = btn.currentTitle;
            if (song.length) {
                [UIPasteboard generalPasteboard].string = song;
                [DYYYToast showSuccessToastWithMessage:@"歌曲名已复制"];
            }
        }
    } else {
        %orig;
    }
}

%end

// Swift 类组
%group CommentHeaderGeneralGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}
%end
%end
%group CommentHeaderGoodsGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}
%end
%end
%group CommentHeaderTemplateGroup
%hook AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        [self setHidden:YES];
    }
}
%end
%end
%group CommentBottomTipsVCGroup
%hook AWECommentPanelListSwiftImpl_CommentBottomTipsContainerViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    if (DYYYGetBool(@"DYYYHideCommentTips")) {
        ((UIViewController *)self).view.hidden = YES;
    }
}
%end
%end

// 去除隐藏大家都在搜后的留白
%hook AWESearchAnchorListModel

- (BOOL)hideWords {
    if (DYYYGetBool(@"DYYYHideCommentViews")) {
        return YES;
    }
    return %orig;
}

%end

// 隐藏观看历史搜索
%hook AWEDiscoverFeedEntranceView
- (id)init {
    if (DYYYGetBool(@"DYYYHideInteractionSearch")) {
        return nil;
    }
    return %orig;
}
%end

// 隐藏校园提示
%hook AWETemplateTagsCommonView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideTemplateTags")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
        } else {
            self.hidden = YES;
        }
    }
}

%end

// 隐藏消息页顶栏头像气泡
%hook AFDSkylightCellBubble
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideAvatarBubble")) {
        [self removeFromSuperview];
    }
    %orig;
}
%end

// 隐藏消息页开启通知提示
%hook AWEIMMessageTabOptPushBannerView

- (instancetype)initWithFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYHidePushBanner")) {
        return %orig(CGRectMake(frame.origin.x, frame.origin.y, 0, 0));
    }
    return %orig;
}

%end

// 隐藏消息页顶栏红包
%hook AWEIMMessageTabSideBarView
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHideMessageTabRedPacket")) {
        return;
    }

    UIView *parentView = self.superview;
    if (!parentView) {
        return;
    }

    NSArray<UIView *> *siblings = [parentView.subviews copy];
    if (siblings.count <= 1) {
        return;
    }

    for (UIView *subview in siblings) {
        if (subview != self) {
            [subview removeFromSuperview];
        }
    }
}
%end

// 隐藏我的添加朋友
%hook AWEProfileNavigationButton
- (void)setupUI {
    if (DYYYGetBool(@"DYYYHideButton")) {
        return;
    }
    %orig;
}
%end

// 隐藏朋友"关注/不关注"按钮
%hook AWEFeedUnfollowFamiliarFollowAndDislikeView
- (void)showUnfollowFamiliarView {
    if (DYYYGetBool(@"DYYYHideFamiliar")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏朋友日常按钮
%hook AWEFamiliarNavView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideFamiliar")) {
        self.hidden = YES;
    }
    %orig;
}
%end


%hook AWELeftSideBarEntranceView

- (void)setRedDot:(id)redDot {
    %orig(nil);
}

- (void)setNumericalRedDot:(id)numericalRedDot {
    %orig(nil);
}

- (void)layoutSubviews {
    %orig;

    // 隐藏左侧边栏的 badge
    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:%c(DUXBadge)]) {
            subview.hidden = YES;
            break;
        }
    }

    UIResponder *responder = self;
    UIViewController *parentVC = nil;
    while ((responder = [responder nextResponder])) {
        if ([responder isKindOfClass:%c(AWEFeedContainerViewController)]) {
            parentVC = (UIViewController *)responder;
            break;
        }
    }

    if (!(parentVC && [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLeftSideBar"])) {
        return;
    }

    static char kDYLeftSideViewCacheKey;
    NSArray *cachedViews = objc_getAssociatedObject(self, &kDYLeftSideViewCacheKey);
    if (!cachedViews) {
        NSMutableArray *views = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:%c(DUXBaseImageView)]) {
                [views addObject:subview];
            }
        }
        cachedViews = [views copy];
        objc_setAssociatedObject(self, &kDYLeftSideViewCacheKey, cachedViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *v in cachedViews) {
        v.hidden = YES;
    }
}

%end

%hook AWEFeedVideoButton

- (void)layoutSubviews {
    %orig;

    NSString *accessibilityLabel = self.accessibilityLabel;
    BOOL isCollectButton = DYYYIsFeedVideoCollectButton(self);

    BOOL hideBtn = NO;
    BOOL hideLabel = NO;

    if ([accessibilityLabel isEqualToString:@"点赞"]) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLikeLabel"];
    } else if ([accessibilityLabel isEqualToString:@"评论"]) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCommentLabel"];
    } else if ([accessibilityLabel isEqualToString:@"分享"]) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideShareLabel"];
    } else if (isCollectButton) {
        hideBtn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectButton"];
        hideLabel = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideCollectLabel"];
    }

    if (!hideBtn && !hideLabel) {
        return; // 设置未启用，无需额外处理
    }

    if (hideBtn) {
        if (isCollectButton) {
            DYYYApplyFeedVideoCollectButtonSettingsWithRetry(self);
            return;
        }
        [self removeFromSuperview];
        return;
    }

    if (isCollectButton && hideLabel) {
        DYYYSetFeedVideoButtonLabelsHidden(self, YES);
        return;
    }

    static char kDYLabelCacheKey;
    NSArray *cachedLabels = objc_getAssociatedObject(self, &kDYLabelCacheKey);
    if (!cachedLabels) {
        NSMutableArray *labels = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UILabel class]]) {
                [labels addObject:subview];
            }
        }
        cachedLabels = [labels copy];
        objc_setAssociatedObject(self, &kDYLabelCacheKey, cachedLabels, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UILabel *label in cachedLabels) {
        label.hidden = hideLabel;
    }
}

%end

%hook UIButton

- (void)layoutSubviews {
    %orig;

    NSString *accessibilityLabel = self.accessibilityLabel;

    if ([accessibilityLabel isEqualToString:@"拍照搜同款"] || [accessibilityLabel isEqualToString:@"扫一扫"]) {
        if (DYYYGetBool(@"DYYYHideScancode")) {
            [self removeFromSuperview];
        }
    }

    if ([accessibilityLabel isEqualToString:@"返回"]) {
        if (DYYYGetBool(@"DYYYHideBack")) {
            UIView *parent = self.superview;
            // 父视图是AWEBaseElementView(排除用户主页返回按钮) 按钮类不是AWENoxusHighlightButton(排除横屏返回按钮)
            if ([parent isKindOfClass:%c(AWEBaseElementView)] && ![self isKindOfClass:%c(AWENoxusHighlightButton)]) {
                [self removeFromSuperview];
            }
            return;
        }
    }
}

%end

%hook AWEIMFeedVideoQuickReplayInputViewController

- (void)viewDidLayoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideReply")) {
        [self.view removeFromSuperview];
        return;
    }
}

%end

%hook AWEHPSearchBubbleEntranceView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideSearchBubble")) {
        [self removeFromSuperview];
        return;
    }
}

%end

static BOOL DYYYLiveDiscoveryHideEnabled(void) {
    return DYYYGetBool(@"DYYYHideLiveDiscovery");
}

static void DYYYApplyLiveDiscoveryChromeHidden(UIView *view) {
    if (![view isKindOfClass:[UIView class]]) {
        return;
    }
    view.hidden = YES;
    view.alpha = 0;
}

static BOOL DYYYLiveDiscoveryClosingRevisit = NO;

static void DYYYCloseLiveDiscoveryRevisitIfNeeded(id controller) {
    if (!DYYYLiveDiscoveryHideEnabled() || DYYYLiveDiscoveryClosingRevisit) {
        return;
    }
    if (![controller respondsToSelector:@selector(p_closeRevisitViewImmediately)]) {
        return;
    }
    DYYYLiveDiscoveryClosingRevisit = YES;
    [controller p_closeRevisitViewImmediately];
    DYYYLiveDiscoveryClosingRevisit = NO;
}

%hook AWEFeedLiveTabTopSelectionView
- (void)setHideTimer:(id)timer {
    if (DYYYGetBool(@"DYYYDisableAutoHideLive")) {
        timer = nil;
    }
    %orig(timer);
}

// 隐藏直播发现：展开态顶部标签栏（精选/关注/…/发现更多）
// 宿主入口为 -showTabTopSelectionView:（v20@0:8B16）；隐藏优先于 DYYYDisableAutoHideLive
- (void)showTabTopSelectionView:(BOOL)show {
    if (DYYYLiveDiscoveryHideEnabled()) {
        %orig(NO);
        DYYYApplyLiveDiscoveryChromeHidden(self);
        return;
    }
    %orig(show);
}

- (void)setHidden:(BOOL)hidden {
    if (DYYYLiveDiscoveryHideEnabled()) {
        %orig(YES);
        return;
    }
    %orig(hidden);
}

- (void)setAlpha:(CGFloat)alpha {
    if (DYYYLiveDiscoveryHideEnabled()) {
        %orig(0);
        return;
    }
    %orig(alpha);
}

- (void)layoutSubviews {
    %orig;
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYApplyLiveDiscoveryChromeHidden(self);
    }
}
%end

// 隐藏文案下推荐应用下载横幅
static void DYYYRemoveRecommendAppDownloadView(id viewObject) {
    if (![viewObject isKindOfClass:[UIView class]]) {
        return;
    }
    UIView *view = (UIView *)viewObject;
    view.hidden = YES;
    [view removeFromSuperview];
}

static void DYYYHideRecommendAppDownloadViewForOwner(id owner) {
    id addFeedMusicView = DYYYKVCValueIfPossible(owner, @"addFeedMusicView");
    DYYYRemoveRecommendAppDownloadView(addFeedMusicView);
    DYYYSetKVCValueIfPossible(owner, @"addFeedMusicView", nil);
}

%hook AWEPlayInteractionMusicAiRefactorListenFeedController

- (BOOL)shouldShowAddFeedMusicView {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        return NO;
    }
    return %orig;
}

- (void)showFeedMusicViewIfNeeded {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYHideRecommendAppDownloadViewForOwner(self);
        return;
    }
    %orig;
}

- (void)setAddFeedMusicView:(UIView *)view {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        if ([view isKindOfClass:[UIView class]]) {
            view.hidden = YES;
            [view removeFromSuperview];
        }
        %orig(nil);
        return;
    }
    %orig;
}

- (void)updateAddFeedMusicViewLayoutWithShowSpeedControl:(BOOL)showSpeedControl {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYHideRecommendAppDownloadViewForOwner(self);
        return;
    }
    %orig;
}

%end

// 39.3.0 的应用推荐已改走通用 Diversion Bar。该视图只承载
// pkgInfo/appMarket/downloadIntermediatePage 类应用引流，隐藏它不会删除作品文案或普通音乐信息。
%hook AWEPlayInteractionDiversionBar

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYRemoveRecommendAppDownloadView(self);
        return;
    }
    %orig;
}

- (void)didMoveToWindow {
    %orig;
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYRemoveRecommendAppDownloadView(self);
    }
}

%end

%hook AWEPlayInteractionNewDiversionBarBottomElement

- (void)setDiversionBarView:(AWEPlayInteractionDiversionBar *)view {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYRemoveRecommendAppDownloadView(view);
        %orig(nil);
        return;
    }
    %orig;
}

- (void)layoutElementView {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYRemoveRecommendAppDownloadView(DYYYIvarValueIfPossible(self, "_diversionBarView"));
        return;
    }
    %orig;
}

%end

// 抖音精选的应用推荐使用独立 Lynx 底栏。只在其自身的
// canShow/update/add 入口阻断，不移除 feed 容器。
static void DYYYHideDouYinSelectAppGuideViews(id owner) {
    DYYYRemoveRecommendAppDownloadView(DYYYIvarValueIfPossible(owner, "_appGuideView"));
    DYYYRemoveRecommendAppDownloadView(DYYYIvarValueIfPossible(owner, "_appGuideContainer"));
}

%hook AWEDouYinSelectUGBottomBarController

- (BOOL)canShowBottomBarForAweme:(id)aweme {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        return NO;
    }
    return %orig;
}

- (void)updateBottomBarWithAweme:(id)aweme updateTiming:(BOOL)updateTiming {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYHideDouYinSelectAppGuideViews(self);
        return;
    }
    %orig;
}

- (void)bottomBarAddedToContainer:(id)container {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYHideDouYinSelectAppGuideViews(self);
        return;
    }
    %orig;
}

- (void)setAppGuideView:(UIView *)view {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYRemoveRecommendAppDownloadView(view);
        %orig(nil);
        return;
    }
    %orig;
}

- (void)setAppGuideContainer:(UIView *)view {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        DYYYRemoveRecommendAppDownloadView(view);
        %orig(nil);
        return;
    }
    %orig;
}

%end

%hook AWEFeedMeetMusicView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        UIView *view = (UIView *)self;
        view.hidden = YES;
        [view removeFromSuperview];
        return;
    }
    %orig;
}

- (void)didMoveToWindow {
    %orig;
    if (DYYYGetBool(@"DYYYHideRecommendAppDownload")) {
        UIView *view = (UIView *)self;
        view.hidden = YES;
        [view removeFromSuperview];
    }
}

%end

%hook AWEPlayInteractionFollowPromptView

- (void)layoutSubviews {
    %orig;

    if (DYYYAvatarFollowOptionsEnabled()) {
        DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
        if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
            return;
        }
    }
}

- (void)didMoveToWindow {
    %orig;

    if (DYYYAvatarFollowOptionsEnabled()) {
        DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
    }
}

- (void)didMoveToSuperview {
    %orig;

    if (DYYYAvatarFollowOptionsEnabled()) {
        DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
        return;
    }
}

%end

%hook AWEPlayInteractionElementMaskView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGradient")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook AWEGradientView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGradient")) {
        UIView *parent = self.superview;
        if ([parent.accessibilityLabel isEqualToString:@"暂停，按钮"] || [parent.accessibilityLabel isEqualToString:@"播放，按钮"] || [parent.accessibilityLabel isEqualToString:@"“切换视角，按钮"] ||
            [parent isKindOfClass:%c(AWEStoryProgressContainerView)]) {
            self.hidden = YES;
        }
        return;
    }
    %orig;
}
%end

%hook AWEHotSpotBlurView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGradient")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook AWEHotSearchInnerBottomView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideHotSearch")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏双指缩放虾线
%hook AWELoadingAndVolumeView

- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
    return;
}

%end

// 隐藏状态栏
%hook AWEFeedRootViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    }
    if (DYYYGetBool(@"DYYYHideStatusBarOnClear") && hideButton && hideButton.isElementsHidden) {
        return YES;
    }
    if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) != class_getInstanceMethod([%c(AWEFeedRootViewController) class], @selector(prefersStatusBarHidden))) {
        return %orig;
    }
    return NO;
}
%end

static const void *kDYYYLiveDurationViewKey = &kDYYYLiveDurationViewKey;
static const void *kDYYYLiveDurationTimerKey = &kDYYYLiveDurationTimerKey;
static const void *kDYYYLiveDurationRoomKey = &kDYYYLiveDurationRoomKey;
static NSString *const kDYYYLiveDurationCenterXPercentKey = @"DYYYLiveDurationCenterXPercent";
static NSString *const kDYYYLiveDurationCenterYPercentKey = @"DYYYLiveDurationCenterYPercent";
static NSString *const kDYYYLiveDurationPositionLockedKey = @"DYYYLiveDurationPositionLocked";
static BOOL dyyyLiveDurationOfficialClearScreenActive = NO;

static void DYYYLiveDurationUpdateView(UIView *root);
static void DYYYLiveDurationSetOfficialClearScreenActive(BOOL active);

static NSHashTable<UIView *> *DYYYLiveDurationTrackedRoots(void) {
    static NSHashTable<UIView *> *trackedRoots = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      trackedRoots = [NSHashTable weakObjectsHashTable];
    });
    return trackedRoots;
}

static void DYYYLiveDurationTrackRoot(UIView *root) {
    if (!root) {
        return;
    }
    [DYYYLiveDurationTrackedRoots() addObject:root];
}

static void DYYYLiveDurationUntrackRoot(UIView *root) {
    if (!root) {
        return;
    }

    NSHashTable<UIView *> *trackedRoots = DYYYLiveDurationTrackedRoots();
    [trackedRoots removeObject:root];
    if (trackedRoots.count == 0) {
        dyyyLiveDurationOfficialClearScreenActive = NO;
    }
}

static BOOL DYYYLiveDurationOfficialClearScreenActive(void) {
    return dyyyLiveDurationOfficialClearScreenActive;
}

static UIEdgeInsets DYYYLiveDurationSafeInsets(UIView *root) {
    return [root respondsToSelector:@selector(safeAreaInsets)] ? root.safeAreaInsets : UIEdgeInsetsZero;
}

static CGPoint DYYYLiveDurationClampedCenter(CGPoint center, CGSize viewSize, UIView *root) {
    if (!root) {
        return center;
    }

    UIEdgeInsets safeInsets = DYYYLiveDurationSafeInsets(root);
    CGFloat halfWidth = viewSize.width / 2.0;
    CGFloat halfHeight = viewSize.height / 2.0;
    CGFloat minX = safeInsets.left + halfWidth + 4.0;
    CGFloat maxX = fmax(minX, CGRectGetWidth(root.bounds) - safeInsets.right - halfWidth - 4.0);
    CGFloat minY = safeInsets.top + halfHeight + 4.0;
    CGFloat maxY = fmax(minY, CGRectGetHeight(root.bounds) - safeInsets.bottom - halfHeight - 4.0);
    return CGPointMake(fmin(fmax(center.x, minX), maxX), fmin(fmax(center.y, minY), maxY));
}

@interface DYYYLiveDurationWeakViewBox : NSObject
@property(nonatomic, weak) UIView *view;
@end

@implementation DYYYLiveDurationWeakViewBox
@end

@interface DYYYLiveDurationView : UIView
@property(nonatomic, strong) UILabel *durationLabel;
@property(nonatomic, assign, getter=isDragging) BOOL dragging;
@property(nonatomic, assign, getter=isMovementLocked) BOOL movementLocked;
- (CGRect)frameByApplyingSavedPositionToFrame:(CGRect)frame inRoot:(UIView *)root;
@end

@implementation DYYYLiveDurationView

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.42];
        self.layer.cornerRadius = 7.0;
        self.layer.masksToBounds = YES;
        self.layer.borderColor = [[UIColor whiteColor] colorWithAlphaComponent:0.12].CGColor;
        self.layer.borderWidth = 0.5;
        self.accessibilityIdentifier = @"dyyy_live_duration_view";

        _durationLabel = [[UILabel alloc] initWithFrame:CGRectZero];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
        _durationLabel.adjustsFontSizeToFitWidth = YES;
        _durationLabel.minimumScaleFactor = 0.75;
        _durationLabel.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.75];
        _durationLabel.shadowOffset = CGSizeMake(0.0, 1.0);
        [self addSubview:_durationLabel];

        _movementLocked = [[NSUserDefaults standardUserDefaults] boolForKey:kDYYYLiveDurationPositionLockedKey];

        UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        longPressGesture.minimumPressDuration = 0.5;
        [self addGestureRecognizer:longPressGesture];

        UIPanGestureRecognizer *panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
        [panGesture requireGestureRecognizerToFail:longPressGesture];
        [self addGestureRecognizer:panGesture];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.durationLabel.frame = CGRectInset(self.bounds, 7.0, 2.0);
}

- (void)handlePan:(UIPanGestureRecognizer *)gesture {
    UIView *root = self.superview;
    if (self.isMovementLocked || !root) {
        return;
    }

    if (gesture.state == UIGestureRecognizerStateBegan) {
        self.dragging = YES;
        self.alpha = 0.8;
    }

    if (gesture.state == UIGestureRecognizerStateBegan || gesture.state == UIGestureRecognizerStateChanged) {
        CGPoint translation = [gesture translationInView:root];
        CGPoint newCenter = CGPointMake(self.center.x + translation.x, self.center.y + translation.y);
        self.center = DYYYLiveDurationClampedCenter(newCenter, self.bounds.size, root);
        [gesture setTranslation:CGPointZero inView:root];
    }

    if (gesture.state == UIGestureRecognizerStateEnded || gesture.state == UIGestureRecognizerStateCancelled || gesture.state == UIGestureRecognizerStateFailed) {
        self.dragging = NO;
        self.alpha = 1.0;
        [self savePosition];
    }
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) {
        return;
    }

    self.movementLocked = !self.isMovementLocked;
    [[NSUserDefaults standardUserDefaults] setBool:self.isMovementLocked forKey:kDYYYLiveDurationPositionLockedKey];
    if (self.isMovementLocked) {
        [self savePosition];
    }

    [DYYYUtils showToast:self.isMovementLocked ? @"开播时长位置已锁定" : @"开播时长位置已解锁"];
    if (@available(iOS 10.0, *)) {
        UIImpactFeedbackGenerator *generator = [[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleLight];
        [generator prepare];
        [generator impactOccurred];
    }
}

- (void)savePosition {
    UIView *root = self.superview;
    if (!root) {
        return;
    }

    CGFloat rootWidth = CGRectGetWidth(root.bounds);
    CGFloat rootHeight = CGRectGetHeight(root.bounds);
    if (rootWidth <= 0.0 || rootHeight <= 0.0) {
        return;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setDouble:self.center.x / rootWidth forKey:kDYYYLiveDurationCenterXPercentKey];
    [defaults setDouble:self.center.y / rootHeight forKey:kDYYYLiveDurationCenterYPercentKey];
}

- (CGRect)frameByApplyingSavedPositionToFrame:(CGRect)frame inRoot:(UIView *)root {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (![defaults objectForKey:kDYYYLiveDurationCenterXPercentKey] || ![defaults objectForKey:kDYYYLiveDurationCenterYPercentKey]) {
        return frame;
    }

    CGFloat rootWidth = CGRectGetWidth(root.bounds);
    CGFloat rootHeight = CGRectGetHeight(root.bounds);
    if (rootWidth <= 0.0 || rootHeight <= 0.0) {
        return frame;
    }

    CGFloat centerXPercent = fmin(fmax([defaults doubleForKey:kDYYYLiveDurationCenterXPercentKey], 0.0), 1.0);
    CGFloat centerYPercent = fmin(fmax([defaults doubleForKey:kDYYYLiveDurationCenterYPercentKey], 0.0), 1.0);
    CGPoint center = CGPointMake(centerXPercent * rootWidth, centerYPercent * rootHeight);
    center = DYYYLiveDurationClampedCenter(center, frame.size, root);
    return CGRectIntegral(CGRectMake(center.x - frame.size.width / 2.0, center.y - frame.size.height / 2.0, frame.size.width, frame.size.height));
}

@end

static void DYYYLiveDurationSetOfficialClearScreenActive(BOOL active) {
    void (^applyBlock)(void) = ^{
      dyyyLiveDurationOfficialClearScreenActive = active;
      NSArray<UIView *> *roots = [[DYYYLiveDurationTrackedRoots() allObjects] copy];
      for (UIView *root in roots) {
          if (!root.window) {
              DYYYLiveDurationUntrackRoot(root);
              continue;
          }

          DYYYLiveDurationView *durationView = objc_getAssociatedObject(root, kDYYYLiveDurationViewKey);
          if (active) {
              durationView.dragging = NO;
              durationView.hidden = YES;
          } else {
              DYYYLiveDurationUpdateView(root);
          }
      }
    };

    if ([NSThread isMainThread]) {
        applyBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), applyBlock);
    }
}

static id DYYYLiveDurationSafeValue(id obj, NSString *key) {
    if (!obj || key.length == 0) {
        return nil;
    }

    @try {
        return [obj valueForKey:key];
    } @catch (__unused NSException *exception) {
        return nil;
    }
}

static long long DYYYLiveDurationLongValue(id obj, NSString *key) {
    id value = DYYYLiveDurationSafeValue(obj, key);
    return [value respondsToSelector:@selector(longLongValue)] ? [value longLongValue] : 0;
}

static BOOL DYYYLiveDurationBoolValue(id obj, NSString *key) {
    id value = DYYYLiveDurationSafeValue(obj, key);
    return [value respondsToSelector:@selector(boolValue)] ? [value boolValue] : NO;
}

static NSTimeInterval DYYYLiveDurationNowSeconds(void) {
    return [[NSDate date] timeIntervalSince1970];
}

static NSTimeInterval DYYYLiveDurationNormalizeTimestamp(long long timestamp) {
    if (timestamp <= 0) {
        return 0.0;
    }
    return timestamp > 20000000000LL ? ((NSTimeInterval)timestamp / 1000.0) : (NSTimeInterval)timestamp;
}

static long long DYYYLiveDurationFirstPositiveValue(id obj, NSArray<NSString *> *keys) {
    for (NSString *key in keys) {
        long long value = DYYYLiveDurationLongValue(obj, key);
        if (value > 0) {
            return value;
        }
    }
    return 0;
}

static BOOL DYYYLiveDurationLooksLikeRoomObject(id obj) {
    if (!obj) {
        return NO;
    }

    NSString *className = NSStringFromClass([obj class]);
    NSArray<NSString *> *excludedParts = @[ @"Cell", @"Item", @"Aisle", @"Context", @"Config", @"Controller", @"View", @"Factory" ];
    for (NSString *part in excludedParts) {
        if ([className rangeOfString:part options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return NO;
        }
    }

    if ([className rangeOfString:@"LiveRoom" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [className rangeOfString:@"RoomModel" options:NSCaseInsensitiveSearch].location != NSNotFound ||
        [className rangeOfString:@"WebcastRoom" options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return YES;
    }

    return DYYYLiveDurationSafeValue(obj, @"roomID") || DYYYLiveDurationSafeValue(obj, @"idStr");
}

static NSTimeInterval DYYYLiveDurationElapsedSeconds(id roomModel) {
    if (!DYYYLiveDurationLooksLikeRoomObject(roomModel)) {
        return -1.0;
    }

    id rawRoom = DYYYLiveDurationSafeValue(roomModel, @"rawRoom") ?: roomModel;
    NSArray<NSString *> *startKeys = @[ @"startTime", @"createTime", @"liveStartTime", @"start_time", @"create_time" ];
    long long startTime = DYYYLiveDurationFirstPositiveValue(rawRoom, startKeys);
    if (startTime <= 0) {
        startTime = DYYYLiveDurationFirstPositiveValue(roomModel, startKeys);
    }

    NSTimeInterval timestamp = DYYYLiveDurationNormalizeTimestamp(startTime);
    NSTimeInterval now = DYYYLiveDurationNowSeconds();
    if (timestamp > 1000000000.0 && timestamp <= now + 3600.0) {
        return fmax(0.0, now - timestamp);
    }

    NSArray<NSString *> *durationKeys = @[ @"liveDuration", @"liveTime", @"duration", @"totalDuration" ];
    long long duration = DYYYLiveDurationFirstPositiveValue(rawRoom, durationKeys);
    if (duration <= 0) {
        duration = DYYYLiveDurationFirstPositiveValue(roomModel, durationKeys);
    }
    if (duration > 0 && duration < 365LL * 24LL * 3600LL) {
        return (NSTimeInterval)duration;
    }

    return -1.0;
}

static BOOL DYYYLiveDurationHasValidLiveTime(id obj) {
    return DYYYLiveDurationElapsedSeconds(obj) >= 0.0;
}

static id DYYYLiveDurationRoomFromCarrierDepth(id obj, NSUInteger depth);

static id DYYYLiveDurationRoomFromKnownKeys(id obj, NSUInteger depth) {
    if (!obj || depth > 3) {
        return nil;
    }

    NSArray<NSString *> *keys = @[
        @"rawHTSLiveRoomModel", @"rawDataRoomModel", @"roomModel", @"rawRoom", @"liveRoom", @"room", @"currentRoom",
        @"containerContext", @"roomDI", @"roomConfig", @"roomAisle"
    ];
    for (NSString *key in keys) {
        id value = DYYYLiveDurationSafeValue(obj, key);
        if (DYYYLiveDurationHasValidLiveTime(value)) {
            return value;
        }

        id nestedRawRoom = DYYYLiveDurationSafeValue(value, @"rawRoom");
        if (DYYYLiveDurationHasValidLiveTime(nestedRawRoom)) {
            return value;
        }

        id nestedRoom = DYYYLiveDurationRoomFromCarrierDepth(value, depth + 1);
        if (nestedRoom) {
            return nestedRoom;
        }
    }
    return nil;
}

static id DYYYLiveDurationRoomFromCarrierDepth(id obj, NSUInteger depth) {
    if (!obj || depth > 3) {
        return nil;
    }

    if (DYYYLiveDurationHasValidLiveTime(obj)) {
        return obj;
    }

    id room = DYYYLiveDurationRoomFromKnownKeys(obj, depth + 1);
    if (room) {
        return room;
    }

    if ([obj respondsToSelector:@selector(liveRoomModel)]) {
        @try {
            id value = ((id (*)(id, SEL))objc_msgSend)(obj, @selector(liveRoomModel));
            if (DYYYLiveDurationHasValidLiveTime(value)) {
                return value;
            }
        } @catch (__unused NSException *exception) {
        }
    }

    NSArray<NSString *> *carrierKeys = @[ @"itemModel", @"awemeModel", @"aweme", @"model", @"item" ];
    for (NSString *key in carrierKeys) {
        id carrier = DYYYLiveDurationSafeValue(obj, key);
        room = DYYYLiveDurationRoomFromCarrierDepth(carrier, depth + 1);
        if (room) {
            return room;
        }
    }

    return nil;
}

static id DYYYLiveDurationRoomFromCarrier(id obj) {
    return DYYYLiveDurationRoomFromCarrierDepth(obj, 0);
}

static NSString *DYYYLiveDurationFormatElapsed(NSTimeInterval seconds) {
    long long totalSeconds = (long long)fmax(0.0, floor(seconds));
    long long days = totalSeconds / 86400;
    long long hours = (totalSeconds % 86400) / 3600;
    long long minutes = (totalSeconds % 3600) / 60;
    long long secs = totalSeconds % 60;

    if (days > 0) {
        return [NSString stringWithFormat:@"已开播 %lld天%02lld:%02lld:%02lld", days, hours, minutes, secs];
    }
    return [NSString stringWithFormat:@"已开播 %02lld:%02lld:%02lld", hours, minutes, secs];
}

static DYYYLiveDurationView *DYYYLiveDurationEnsureView(UIView *root) {
    DYYYLiveDurationView *durationView = objc_getAssociatedObject(root, kDYYYLiveDurationViewKey);
    if (durationView && durationView.superview == root) {
        return durationView;
    }

    durationView = [[DYYYLiveDurationView alloc] initWithFrame:CGRectZero];
    objc_setAssociatedObject(root, kDYYYLiveDurationViewKey, durationView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    [root addSubview:durationView];
    return durationView;
}

static CGRect DYYYLiveDurationFrameForRoot(UIView *root, id roomModel, NSString *text) {
    UIEdgeInsets safeInsets = DYYYLiveDurationSafeInsets(root);

    CGFloat rootWidth = CGRectGetWidth(root.bounds);
    CGFloat rootHeight = CGRectGetHeight(root.bounds);
    BOOL isLandscape = rootWidth > rootHeight || DYYYLiveDurationBoolValue(roomModel, @"isLandscape");
    if (!isLandscape) {
        long long orientation = DYYYLiveDurationLongValue(roomModel, @"orientation");
        isLandscape = orientation == 2 || orientation == 90 || orientation == 270;
    }

    UIFont *font = [UIFont systemFontOfSize:12.0 weight:UIFontWeightSemibold];
    CGSize textSize = [text ?: @"已开播 00:00:00" sizeWithAttributes:@{NSFontAttributeName : font}];
    CGFloat width = fmin(ceil(fmax(textSize.width + 18.0, 118.0)), isLandscape ? 190.0 : 170.0);
    CGFloat height = 26.0;

    CGFloat minX = safeInsets.left + 4.0;
    CGFloat maxX = fmax(minX, rootWidth - safeInsets.right - width - 4.0);
    CGFloat minY = safeInsets.top + 4.0;
    CGFloat maxY = fmax(minY, rootHeight - safeInsets.bottom - height - 4.0);

    CGFloat x = fmin(fmax(safeInsets.left + 12.0, minX), maxX);
    CGFloat y = fmin(fmax(safeInsets.top + (isLandscape ? 12.0 : 86.0), minY), maxY);
    return CGRectIntegral(CGRectMake(x, y, width, height));
}

static void DYYYLiveDurationRemoveFromView(UIView *root) {
    if (!root) {
        return;
    }

    NSTimer *timer = objc_getAssociatedObject(root, kDYYYLiveDurationTimerKey);
    [timer invalidate];
    objc_setAssociatedObject(root, kDYYYLiveDurationTimerKey, nil, OBJC_ASSOCIATION_ASSIGN);

    UIView *durationView = objc_getAssociatedObject(root, kDYYYLiveDurationViewKey);
    [durationView removeFromSuperview];
    objc_setAssociatedObject(root, kDYYYLiveDurationViewKey, nil, OBJC_ASSOCIATION_ASSIGN);
    objc_setAssociatedObject(root, kDYYYLiveDurationRoomKey, nil, OBJC_ASSOCIATION_ASSIGN);
    DYYYLiveDurationUntrackRoot(root);
}

static void DYYYLiveDurationUpdateView(UIView *root) {
    if (!root) {
        return;
    }

    if (!DYYYGetBool(@"DYYYShowLiveDuration")) {
        DYYYLiveDurationRemoveFromView(root);
        return;
    }

    id roomModel = objc_getAssociatedObject(root, kDYYYLiveDurationRoomKey);
    NSTimeInterval elapsed = DYYYLiveDurationElapsedSeconds(roomModel);
    DYYYLiveDurationView *durationView = objc_getAssociatedObject(root, kDYYYLiveDurationViewKey);
    if (DYYYLiveDurationOfficialClearScreenActive()) {
        durationView.dragging = NO;
        durationView.hidden = YES;
        return;
    }

    if (elapsed < 0.0) {
        durationView.hidden = YES;
        return;
    }

    NSString *text = DYYYLiveDurationFormatElapsed(elapsed);
    durationView = DYYYLiveDurationEnsureView(root);
    durationView.durationLabel.text = text;
    if (!durationView.isDragging) {
        CGRect defaultFrame = DYYYLiveDurationFrameForRoot(root, roomModel, text);
        durationView.frame = [durationView frameByApplyingSavedPositionToFrame:defaultFrame inRoot:root];
        durationView.alpha = 1.0;
    }
    durationView.hidden = NO;
    [root bringSubviewToFront:durationView];
}

@interface DYYYLiveDurationTicker : NSObject
+ (instancetype)sharedTicker;
- (void)tick:(NSTimer *)timer;
@end

@implementation DYYYLiveDurationTicker

+ (instancetype)sharedTicker {
    static DYYYLiveDurationTicker *ticker = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      ticker = [DYYYLiveDurationTicker new];
    });
    return ticker;
}

- (void)tick:(NSTimer *)timer {
    DYYYLiveDurationWeakViewBox *box = (DYYYLiveDurationWeakViewBox *)timer.userInfo;
    UIView *root = box.view;
    if (![root isKindOfClass:[UIView class]]) {
        [timer invalidate];
        return;
    }
    if (!root.window) {
        DYYYLiveDurationRemoveFromView(root);
        return;
    }
    DYYYLiveDurationUpdateView(root);
}

@end

static void DYYYLiveDurationEnsureTimer(UIView *root) {
    NSTimer *timer = objc_getAssociatedObject(root, kDYYYLiveDurationTimerKey);
    if (timer && timer.isValid) {
        return;
    }

    DYYYLiveDurationWeakViewBox *box = [DYYYLiveDurationWeakViewBox new];
    box.view = root;
    timer = [NSTimer timerWithTimeInterval:1.0 target:[DYYYLiveDurationTicker sharedTicker] selector:@selector(tick:) userInfo:box repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    objc_setAssociatedObject(root, kDYYYLiveDurationTimerKey, timer, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

static void DYYYLiveDurationInstallOnView(UIView *root, id carrier) {
    if (!root) {
        return;
    }

    void (^installBlock)(void) = ^{
      if (!DYYYGetBool(@"DYYYShowLiveDuration")) {
          DYYYLiveDurationRemoveFromView(root);
          return;
      }

      DYYYLiveDurationTrackRoot(root);

      id room = DYYYLiveDurationRoomFromCarrier(carrier);
      if (!DYYYLiveDurationHasValidLiveTime(room)) {
          UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:root];
          room = DYYYLiveDurationRoomFromCarrier(viewController);
      }

      if (DYYYLiveDurationHasValidLiveTime(room)) {
          objc_setAssociatedObject(root, kDYYYLiveDurationRoomKey, room, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      }

      DYYYLiveDurationUpdateView(root);
      if (DYYYLiveDurationHasValidLiveTime(objc_getAssociatedObject(root, kDYYYLiveDurationRoomKey))) {
          DYYYLiveDurationEnsureTimer(root);
      }
    };

    if ([NSThread isMainThread]) {
        installBlock();
    } else {
        dispatch_async(dispatch_get_main_queue(), installBlock);
    }
}

static UIViewController *DYYYLiveDurationContainerAudienceVC(id container) {
    UIViewController *viewController = DYYYLiveDurationSafeValue(container, @"audienceVC");
    if (![viewController isKindOfClass:[UIViewController class]] && [container respondsToSelector:@selector(audienceViewController)]) {
        @try {
            viewController = ((id (*)(id, SEL))objc_msgSend)(container, @selector(audienceViewController));
        } @catch (__unused NSException *exception) {
            viewController = nil;
        }
    }
    return [viewController isKindOfClass:[UIViewController class]] ? viewController : nil;
}

static void DYYYLiveDurationInstallFromContainer(id container) {
    UIViewController *viewController = DYYYLiveDurationContainerAudienceVC(container);
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationInstallOnView(viewController.view, DYYYLiveDurationSafeValue(container, @"roomModel") ?: container);
    }
}

static void DYYYLiveDurationInstallFromAudienceWrapper(id wrapper) {
    UIViewController *viewController = DYYYLiveDurationSafeValue(wrapper, @"audienceViewController");
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationInstallOnView(viewController.view, DYYYLiveDurationSafeValue(wrapper, @"roomModel") ?: wrapper);
    }
}

static void DYYYLiveDurationInstallFromInnerFeedCell(id cell) {
    UIViewController *viewController = DYYYLiveDurationSafeValue(cell, @"audienceVC");
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationInstallOnView(viewController.view, cell);
    }
}

%hook AWELiveAudienceContainerController

- (id)initWithRoomModel:(id)roomModel {
    id result = %orig;
    __weak id weakResult = result;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      DYYYLiveDurationInstallFromContainer(weakResult);
    });
    return result;
}

- (id)initWithRoomModel:(id)roomModel config:(id)config {
    id result = %orig;
    __weak id weakResult = result;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      DYYYLiveDurationInstallFromContainer(weakResult);
    });
    return result;
}

- (id)initWithRoomModel:(id)roomModel context:(id)context {
    id result = %orig;
    __weak id weakResult = result;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      DYYYLiveDurationInstallFromContainer(weakResult);
    });
    return result;
}

- (id)initWithRoomModel:(id)roomModel context:(id)context player:(id)player {
    id result = %orig;
    __weak id weakResult = result;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      DYYYLiveDurationInstallFromContainer(weakResult);
    });
    return result;
}

- (void)setAudienceVC:(UIViewController *)audienceVC {
    %orig;
    DYYYLiveDurationInstallFromContainer(self);
}

- (void)setRoomModel:(id)roomModel {
    %orig;
    DYYYLiveDurationInstallFromContainer(self);
}

- (void)createAudienceViewController:(id)arg beginTime:(double)beginTime {
    %orig;
    __weak id weakSelf = self;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      DYYYLiveDurationInstallFromContainer(weakSelf);
    });
}

- (id)audienceControllerWithRoom:(id)room beginTime:(double)beginTime {
    id result = %orig;
    __weak id weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
      DYYYLiveDurationInstallFromContainer(weakSelf);
    });
    return result;
}

- (void)updateWithRoomModel:(id)roomModel config:(id)config {
    %orig;
    DYYYLiveDurationInstallFromContainer(self);
}

- (void)updateWithRoomModel:(id)roomModel context:(id)context {
    %orig;
    DYYYLiveDurationInstallFromContainer(self);
}

- (void)updateWithRoomModel:(id)roomModel context:(id)context player:(id)player {
    %orig;
    DYYYLiveDurationInstallFromContainer(self);
}

- (void)clearAudience {
    UIViewController *viewController = DYYYLiveDurationContainerAudienceVC(self);
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationRemoveFromView(viewController.view);
    }
    %orig;
}

- (void)prepareForReuse {
    UIViewController *viewController = DYYYLiveDurationContainerAudienceVC(self);
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationRemoveFromView(viewController.view);
    }
    %orig;
}

- (void)dealloc {
    UIViewController *viewController = DYYYLiveDurationContainerAudienceVC(self);
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationRemoveFromView(viewController.view);
    }
    %orig;
}

%end

%hook AWELiveAudienceViewController

- (id)initWithRoomModel:(id)roomModel {
    id result = %orig;
    __weak id weakResult = result;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.35 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      DYYYLiveDurationInstallFromAudienceWrapper(weakResult);
    });
    return result;
}

- (void)setRoomModel:(id)roomModel {
    %orig;
    DYYYLiveDurationInstallFromAudienceWrapper(self);
}

- (void)setAudienceViewController:(UIViewController *)audienceViewController {
    %orig;
    DYYYLiveDurationInstallFromAudienceWrapper(self);
}

- (void)attachAudienceViewControllerDelegate:(id)delegate {
    %orig;
    DYYYLiveDurationInstallFromAudienceWrapper(self);
}

- (void)exitLiveRoomWithType:(unsigned long long)type {
    UIViewController *viewController = DYYYLiveDurationSafeValue(self, @"audienceViewController");
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationRemoveFromView(viewController.view);
    }
    %orig;
}

- (void)dealloc {
    UIViewController *viewController = DYYYLiveDurationSafeValue(self, @"audienceViewController");
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationRemoveFromView(viewController.view);
    }
    %orig;
}

%end

%hook IESLiveInnerFeedLiveRoomCell

- (void)setItemModel:(id)itemModel {
    %orig;
    DYYYLiveDurationInstallFromInnerFeedCell(self);
}

- (void)setRoomAisle:(id)roomAisle {
    %orig;
    DYYYLiveDurationInstallFromInnerFeedCell(self);
}

- (void)setAudienceVC:(UIViewController *)audienceVC {
    %orig;
    DYYYLiveDurationInstallFromInnerFeedCell(self);
}

- (void)updateWithItemModel:(id)itemModel {
    %orig;
    DYYYLiveDurationInstallFromInnerFeedCell(self);
}

- (void)prepareForReuse {
    UIViewController *viewController = DYYYLiveDurationSafeValue(self, @"audienceVC");
    if ([viewController isKindOfClass:[UIViewController class]]) {
        DYYYLiveDurationRemoveFromView(viewController.view);
    }
    %orig;
}

%end

%hook IESLiveCleanScreenNormalAbility

- (void)switchToCleanScreenModeWithOffset:(double)offset duration:(double)duration completion:(id)completion {
    DYYYLiveDurationSetOfficialClearScreenActive(YES);
    %orig;
}

- (void)p_switchToCleanScreenModeWithOffset:(double)offset duration:(double)duration completion:(id)completion {
    DYYYLiveDurationSetOfficialClearScreenActive(YES);
    %orig;
}

- (void)p_prepareCleanScreenWithMode:(long long)mode type:(long long)type {
    DYYYLiveDurationSetOfficialClearScreenActive(YES);
    %orig;
}

- (void)exitCleanScreenIfNeed {
    %orig;
    DYYYLiveDurationSetOfficialClearScreenActive(NO);
}

- (void)p_exitCleanScreenWithType:(long long)type duration:(double)duration {
    %orig;
    DYYYLiveDurationSetOfficialClearScreenActive(NO);
}

- (void)p_exitCleanScreenWithType:(long long)type {
    %orig;
    DYYYLiveDurationSetOfficialClearScreenActive(NO);
}

%end

%hook IESLiveClearScreenServiceImpl

- (void)switchToCleanScreenModeWithOffset:(double)offset duration:(double)duration completion:(id)completion {
    DYYYLiveDurationSetOfficialClearScreenActive(YES);
    %orig;
}

- (void)exitCleanScreenIfNeed {
    %orig;
    DYYYLiveDurationSetOfficialClearScreenActive(NO);
}

%end

// 直播状态栏
%hook IESLiveAudienceViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    }
    if (DYYYGetBool(@"DYYYHideStatusBarOnClear") && hideButton && hideButton.isElementsHidden) {
        return YES;
    }
    if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
        class_getInstanceMethod([%c(IESLiveAudienceViewController) class], @selector(prefersStatusBarHidden))) {
        return %orig;
    }
    return NO;
}

- (void)viewDidLoad {
    %orig;
    DYYYLiveDurationInstallOnView(self.view, self);
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    DYYYLiveDurationInstallOnView(self.view, self);
}

- (void)viewDidLayoutSubviews {
    %orig;
    DYYYLiveDurationInstallOnView(self.view, self);
    DYYYLiveDurationUpdateView(self.view);
}

- (void)didEnterRoom:(id)room {
    %orig;
    DYYYLiveDurationInstallOnView(self.view, room ?: self);
}

- (void)didPreloadRoom:(id)room {
    %orig;
    DYYYLiveDurationInstallOnView(self.view, room ?: self);
}

- (void)didCloseRoom:(id)room closeType:(unsigned long long)type {
    DYYYLiveDurationRemoveFromView(self.view);
    %orig;
}

- (void)dealloc {
    if (self.isViewLoaded) {
        DYYYLiveDurationRemoveFromView(self.view);
    }
    %orig;
}
%end

// 主页状态栏
%hook AWEAwemeDetailTableViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    }
    if (DYYYGetBool(@"DYYYHideStatusBarOnClear") && hideButton && hideButton.isElementsHidden) {
        return YES;
    }
    if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
        class_getInstanceMethod([%c(AWEAwemeDetailTableViewController) class], @selector(prefersStatusBarHidden))) {
        return %orig;
    }
    return NO;
}
%end

// 热点状态栏
%hook AWEAwemeHotSpotTableViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    }
    if (DYYYGetBool(@"DYYYHideStatusBarOnClear") && hideButton && hideButton.isElementsHidden) {
        return YES;
    }
    if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
        class_getInstanceMethod([%c(AWEAwemeHotSpotTableViewController) class], @selector(prefersStatusBarHidden))) {
        return %orig;
    }
    return NO;
}
%end

// 图文状态栏
%hook AWEFullPageFeedNewContainerViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    }
    if (DYYYGetBool(@"DYYYHideStatusBarOnClear") && hideButton && hideButton.isElementsHidden) {
        return YES;
    }
    if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
        class_getInstanceMethod([%c(AWEFullPageFeedNewContainerViewController) class], @selector(prefersStatusBarHidden))) {
        return %orig;
    }
    return NO;
}
%end

// 纯净模式状态栏
%hook AFDPureModePageContainerViewController
- (BOOL)prefersStatusBarHidden {
    if (DYYYGetBool(@"DYYYHideStatusbar")) {
        return YES;
    }
    if (DYYYGetBool(@"DYYYHideStatusBarOnClear") && hideButton && hideButton.isElementsHidden) {
        return YES;
    }
    if (class_getInstanceMethod([self class], @selector(prefersStatusBarHidden)) !=
        class_getInstanceMethod([%c(AFDPureModePageContainerViewController) class], @selector(prefersStatusBarHidden))) {
        return %orig;
    }
    return NO;
}
%end

%hook AWEPlayInteractionSearchAnchorView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideInteractionSearch")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}

%end

// 隐藏暂停关键词
%hook AWEFeedPauseRelatedWordComponent

- (id)updateViewWithModel:(id)arg0 {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return nil;
    }
    return %orig;
}

- (id)pauseContentWithModel:(id)arg0 {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return nil;
    }
    return %orig;
}

- (id)recommendsWords {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return nil;
    }
    return %orig;
}

- (void)showRelatedRecommendPanelControllerWithSelectedText:(id)arg0 {
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        return;
    }
    %orig;
}

- (void)setupUI {
    %orig;
    if (DYYYGetBool(@"DYYYHidePauseVideoRelatedWord")) {
        if (self.relatedView) {
            self.relatedView.hidden = YES;
        }
    }
}

%end

// 隐藏视频顶部搜索框、隐藏搜索框背景、应用全局透明
%hook AWESearchEntranceView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideSearchEntrance")) {
        self.hidden = YES;
        return;
    }
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSearchEntranceIndicator"]) {
        static char kDYSearchIndicatorKey;
        NSArray *indicatorViews = objc_getAssociatedObject(self, &kDYSearchIndicatorKey);
        if (!indicatorViews) {
            NSMutableArray *tmp = [NSMutableArray array];
            for (UIView *subviews in self.subviews) {
                if ([subviews isKindOfClass:%c(UIImageView)] && [NSStringFromClass([((UIImageView *)subviews).image class]) isEqualToString:@"_UIResizableImage"]) {
                    [tmp addObject:subviews];
                }
            }
            indicatorViews = [tmp copy];
            objc_setAssociatedObject(self, &kDYSearchIndicatorKey, indicatorViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        for (UIImageView *imgView in indicatorViews) {
            imgView.hidden = YES;
        }
    }

    %orig;
}

%end

// 隐藏视频滑条
%hook AWEStoryProgressSlideView

- (void)layoutSubviews {
    %orig;

    BOOL shouldHide = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideStoryProgressSlide"];
    if (!shouldHide)
        return;

    static char kDYStoryProgressCacheKey;
    UIView *targetView = objc_getAssociatedObject(self, &kDYStoryProgressCacheKey);
    if (!targetView) {
        for (UIView *obj in self.subviews) {
            if ([obj isKindOfClass:NSClassFromString(@"UISlider")] || obj.frame.size.height < 5) {
                targetView = obj.superview;
                break;
            }
        }
        if (targetView) {
            objc_setAssociatedObject(self, &kDYStoryProgressCacheKey, targetView, OBJC_ASSOCIATION_ASSIGN);
        }
    }

    if (targetView) {
        targetView.hidden = YES;
    }
}

%end

// 隐藏好友分享私信
%hook AFDNewFastReplyView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHidePrivateMessages")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
        } else {
            self.hidden = YES;
        }
    }
}

%end

// 隐藏直播发现：上滑收起后的「直播发现」胶囊
// 宿主入口为 -showControlView:animation:（v24@0:8B16B20）；layoutSubviews 仅作显隐回写
%hook AWEFeedLiveTabRevisitControlView

- (void)showControlView:(BOOL)show animation:(BOOL)animation {
    if (DYYYLiveDiscoveryHideEnabled()) {
        %orig(NO, NO);
        DYYYApplyLiveDiscoveryChromeHidden(self);
        return;
    }
    %orig(show, animation);
}

- (void)autoOpenRevisitSection {
    if (DYYYLiveDiscoveryHideEnabled()) {
        return;
    }
    %orig;
}

- (void)setHidden:(BOOL)hidden {
    if (DYYYLiveDiscoveryHideEnabled()) {
        %orig(YES);
        return;
    }
    %orig(hidden);
}

- (void)layoutSubviews {
    %orig;
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYApplyLiveDiscoveryChromeHidden(self);
    }
}
%end

%hook AWEFeedLiveTabSelectionComponent
- (void)showTopTabView:(BOOL)show {
    if (DYYYLiveDiscoveryHideEnabled()) {
        %orig(NO);
        return;
    }
    %orig(show);
}
%end

// 进直播 Tab 自动下拉的是 VC 打开 revisit 面板（约 252pt 不透明空容器 + IESLiveImageView），
// 不是 EventView 本身。关闭走宿主 -p_closeRevisitViewImmediately。
%hook AWEFeedLiveTabViewController
- (void)p_openRevisitView {
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
        return;
    }
    %orig;
}

- (void)p_openRevisitViewAnimation {
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
        return;
    }
    %orig;
}

- (void)p_showRevisitViewWithAnimation {
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
        return;
    }
    %orig;
}

- (void)openAndRefreshRevisit {
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
        return;
    }
    %orig;
}

- (void)p_showTopSelectionView:(BOOL)show {
    if (DYYYLiveDiscoveryHideEnabled()) {
        %orig(NO);
        return;
    }
    %orig(show);
}

- (CGFloat)portalViewHeight {
    if (DYYYLiveDiscoveryHideEnabled()) {
        return 0;
    }
    return %orig;
}

- (void)clickOpenRevisitEvent:(BOOL)open visitType:(int)visitType {
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
        return;
    }
    %orig;
}

- (void)handleOpenAndRefreshRevisitNotification:(id)notification {
    if (DYYYLiveDiscoveryHideEnabled()) {
        DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
        return;
    }
    %orig;
}

- (void)feedLiveTabDidEnter:(id)context {
    %orig;
    DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    DYYYCloseLiveDiscoveryRevisitIfNeeded(self);
}
%end

%hook IESLiveDynamicRankListEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveDetail")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook _TtC18IESLiveRevenueImpl34IESLiveDynamicRankListEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveDetail")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveMatrixEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveDetail")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveShortTouchActionView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveLotteryAnimationViewNew
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveConfigurableShortTouchEntranceView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook IESLiveRedEnvelopeAniLynxView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTouchView")) {
        self.hidden = YES;
        return;
    }
}
%end

// 隐藏直播点歌
%hook IESLiveKTVSongIndicatorView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideKTVSongIndicator")) {
        self.hidden = YES;
        return;
    }
}
%end

// 隐藏昵称右侧
%hook UILabel

static NSHashTable *processedParentViews = nil;

+ (void)load {
    %orig;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      processedParentViews = [NSHashTable weakObjectsHashTable];
    });
}

- (void)layoutSubviews {
    %orig;

    BOOL hideRightLabel = DYYYGetBoolCached(@"DYYYHideRightLabel");
    BOOL hideChapterPoints = DYYYGetBoolCached(@"DYYYHideChapterPoints");
    if (!hideRightLabel && !hideChapterPoints)
        return;

    NSString *accessibilityLabel = self.accessibilityLabel;
    if (!accessibilityLabel || accessibilityLabel.length == 0)
        return;

    // 避免重复处理同一个父视图
    UIView *parentView = self.superview;
    if (!parentView)
        return;

    @synchronized(processedParentViews) {
        if ([processedParentViews containsObject:parentView]) {
            return;
        }
    }

    NSString *trimmedLabel = [accessibilityLabel stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    BOOL shouldRemove = NO;

    // 独立开关：只隐藏昵称旁边的章节要点
    if (hideChapterPoints && [trimmedLabel isEqualToString:@"章节要点"]) {
        shouldRemove = YES;
    }

    if (!shouldRemove && hideRightLabel) {
        if ([trimmedLabel hasSuffix:@"人共创"] && trimmedLabel.length > 3) {
            NSString *prefix = [trimmedLabel substringToIndex:trimmedLabel.length - 3];
            NSCharacterSet *nonDigits = [[NSCharacterSet decimalDigitCharacterSet] invertedSet];
            shouldRemove = ([prefix rangeOfCharacterFromSet:nonDigits].location == NSNotFound);
        }

        if (!shouldRemove) {
            shouldRemove = [trimmedLabel isEqualToString:@"章节要点"] || [trimmedLabel isEqualToString:@"图集"] || [trimmedLabel isEqualToString:@"下一章"];
        }
    }

    if (shouldRemove) {
        @synchronized(processedParentViews) {
            [processedParentViews addObject:parentView];
        }

        UIView *grandparentView = parentView.superview; // 爷爷视图

        if (grandparentView) {
            dispatch_async(dispatch_get_main_queue(), ^{
              if ([grandparentView isKindOfClass:[UIStackView class]]) {
                  UIStackView *stackView = (UIStackView *)grandparentView;
                  [stackView removeArrangedSubview:parentView];
              }

              [parentView removeFromSuperview];

              // 强制刷新爷爷视图布局
              [grandparentView setNeedsLayout];
              [grandparentView layoutIfNeeded];
            });
        }
    }
}

%end

// 隐藏顶栏关注下的提示线
%hook AWEFeedMultiTabSelectedContainerView

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideTopBarLine")) {
        self.hidden = YES;
    }
}

%end

%hook AFDRecommendToFriendEntranceLabel
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideRecommendTips")) {
        if (self.accessibilityLabel) {
            [self removeFromSuperview];
        }
    }
}

%end

// 隐藏自己无公开作品的视图
static void DYYYHideProfilePostGuideView(UIView *view) {
    if (!view) {
        return;
    }

    view.hidden = YES;
    view.alpha = 0.0;
    view.userInteractionEnabled = NO;
    view.accessibilityElementsHidden = YES;

    if ([view isKindOfClass:[UICollectionViewCell class]]) {
        UIView *contentView = ((UICollectionViewCell *)view).contentView;
        contentView.hidden = YES;
        contentView.alpha = 0.0;
        contentView.userInteractionEnabled = NO;
        contentView.accessibilityElementsHidden = YES;
    }
}

%hook AWEProfileMixItemCollectionViewCell
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        if ([self.accessibilityLabel isEqualToString:@"私密作品"]) {
            self.hidden = YES;
            return;
        }
    }
}
%end

%hook AWEProfilePostEmptyPublishGuideCollectionViewCell

- (void)didMoveToSuperview {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        if ([(UIView *)self superview]) {
            [(UIView *)self setHidden:YES];
        }
    }
}

%end

%hook AWEProfilePublishGuideCollectionViewCell

- (void)didMoveToWindow {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

%end

%hook AWEProfileTaskCardStyleListCollectionViewCell
- (BOOL)shouldShowPublishGuide {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        return NO;
    }
    return %orig;
}
%end

%hook AWEUserProfileUGCHeaderContributionGuideBannerSectionViewModel

- (CGSize)sectionSize {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        return CGSizeZero;
    }
    return %orig;
}

%end

%hook AWEUserProfileUGCHeaderContributionGuideBannerSectionController

- (void)configCell:(UICollectionViewCell *)cell index:(NSInteger)index model:(id)model {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView(cell);
        return;
    }
    %orig(cell, index, model);
}

%end

%hook AWEUserProfileUGCContributionGuideCollectionViewCell

- (void)didMoveToWindow {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

%end

%hook AWEUserProfileUGCContributionGuideEmptyCollectionViewCell

- (void)didMoveToWindow {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

%end

%hook AWEUserProfileUGCHeaderContributionGuideBannerSectionCell

- (void)didMoveToWindow {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

%end

%hook AWEUserProfileUGCTaskCardStyleListCollectionViewCell

- (void)didMoveToWindow {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePostView")) {
        DYYYHideProfilePostGuideView((UIView *)self);
    }
}

%end

%hook AWEProfileRichEmptyView

- (void)setTitle:(id)title {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        return;
    }
    %orig(title);
}

- (void)setDetail:(id)detail {
    if (DYYYGetBool(@"DYYYHidePostView")) {
        return;
    }
    %orig(detail);
}
%end

// 隐藏关注直播顶端的直播视图
%hook AWENewLiveSkylightViewController

- (void)showSkylight:(BOOL)arg0 animated:(BOOL)arg1 actionMethod:(unsigned long long)arg2 {
    if (DYYYGetBool(@"DYYYHideLiveView")) {
        return;
    }
    %orig(arg0, arg1, arg2);
}

- (void)updateIsSkylightShowing:(BOOL)arg0 {
    if (DYYYGetBool(@"DYYYHideLiveView")) {
        %orig(NO);
    } else {
        %orig(arg0);
    }
}

%end

// 隐藏关注直播
%hook AWELiveSkylightViewModel

- (id)dataSource {
	BOOL DYYYHideConcernCapsuleView = DYYYGetBool(@"DYYYHideConcernCapsuleView");
	if (DYYYHideConcernCapsuleView) {
		return nil;
	}
	return %orig;
}

- (void)setDataSource:(id)dataSource {
	BOOL DYYYHideConcernCapsuleView = DYYYGetBool(@"DYYYHideConcernCapsuleView");
	if (DYYYHideConcernCapsuleView) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

%hook AWELiveAutoEnterStyleAView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideLiveView")) {
        self.hidden = YES;
        return;
    }
}

%end

// 隐藏同城顶端
%hook AWENearbyFullScreenViewModel

- (void)setShowSkyLight:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideMenuView")) {
        arg1 = nil;
    }
    %orig(arg1);
}

- (void)setHaveSkyLight:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideMenuView")) {
        arg1 = nil;
    }
    %orig(arg1);
}

%end

// 屏蔽模板按钮组件（底部互动）- hook button 方法返回 nil
%hook AWEPlayInteractionTemplateButton
- (id)button {
	BOOL DYYYHideBottomInteraction = DYYYGetBool(@"DYYYHideBottomInteraction");
	if (DYYYHideBottomInteraction) {
		return nil;
	}
	return %orig;
}

- (void)setButton:(id)button {
	BOOL DYYYHideBottomInteraction = DYYYGetBool(@"DYYYHideBottomInteraction");
	if (DYYYHideBottomInteraction) {
		return;  // 不设置按钮
	}
	%orig;
}
%end

// 隐藏右上搜索，但可点击
%hook AWEHPDiscoverFeedEntranceView

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideDiscover")) {
        UIView *firstSubview = self.subviews.firstObject;
        if ([firstSubview isKindOfClass:[UIImageView class]]) {
            ((UIImageView *)firstSubview).image = nil;
        }
    }
}

%end

// 隐藏点击进入直播间
%hook AWELiveFeedStatusLabel
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideEnterLive")) {
        UIView *parentView = self.superview;
        UIView *grandparentView = parentView.superview;

        if (grandparentView) {
            grandparentView.hidden = YES;
            return;
        } else if (parentView) {
            parentView.hidden = YES;
            return;
        } else {
            self.hidden = YES;
            return;
        }
    }
    %orig;
}
%end

// 去除消息群直播提示
%hook AWEIMCellLiveStatusContainerView

- (void)p_initUI {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideGroupLiveIndicator"])
        %orig;
}
%end

%hook AWELiveStatusIndicatorView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGroupLiveIndicator")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook AWELiveFeedLabelTagView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveCapsuleView")) {
        UIView *parentView = self.superview;
        if (parentView) {
            parentView.hidden = YES;
            return;
        } else {
            self.hidden = YES;
            return;
        }
    }
    %orig;
}

%end

%hook AWEPlayInteractionLiveExtendGuideView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveCapsuleView")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏首页直播胶囊
%hook AWEHPTopTabItemBadgeContentView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideConcernCapsuleView")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏群商店
%hook AWEIMFansGroupTopDynamicDomainTemplateView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGroupShop")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 去除群聊天输入框上方快捷方式
%hook AWEIMInputActionBarInteractor

- (void)p_setupUI {
    if (DYYYGetBool(@"DYYYHideGroupInputActionBar")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏相机定位
%hook AWETemplateCommonView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideCameraLocation")) {
        [self removeFromSuperview];
    }
}
%end

// 隐藏侧栏红点
%hook AWEHPTopBarCTAItemView

- (void)showRedDot {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideSidebarDot"])
        %orig;
}

- (void)hideCountRedDot {
    if (![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHideSidebarDot"])
        %orig;
}

- (void)layoutSubviews {
    %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideSidebarDot"]) {
        return;
    }

    static char kDYSidebarBadgeCacheKey;
    NSArray *cachedBadges = objc_getAssociatedObject(self, &kDYSidebarBadgeCacheKey);
    if (!cachedBadges) {
        NSMutableArray *badges = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:%c(DUXBadge)]) {
                [badges addObject:subview];
            }
        }
        cachedBadges = [badges copy];
        objc_setAssociatedObject(self, &kDYSidebarBadgeCacheKey, cachedBadges, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *badge in cachedBadges) {
        badge.hidden = YES;
    }
}
%end

// 隐藏搜同款
%hook ACCStickerContainerView
- (void)layoutSubviews {
    %orig;
    if (!DYYYGetBool(@"DYYYHideSearchSame")) {
        return;
    }

    // 该容器同时承载暂停态的单击复播手势，不能整体移出视图层级。
    // 只隐藏并禁用标签内容，保留容器自身的手势识别能力。
    self.backgroundColor = UIColor.clearColor;
    for (UIView *contentView in self.subviews) {
        contentView.hidden = YES;
        contentView.userInteractionEnabled = NO;
    }
}
%end

// 隐藏礼物展馆
%hook BDXWebView
- (void)layoutSubviews {
    %orig;

    BOOL enabled = DYYYGetBool(@"DYYYHideGiftPavilion");
    if (!enabled)
        return;

    NSString *title = [self valueForKey:@"title"];

    if ([title containsString:@"任务Banner"] || [title containsString:@"活动Banner"]) {
        self.hidden = YES;
    }
}
%end

// 隐藏直播广场
%hook IESLiveFeedDrawerEntranceView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideLivePlayground")) {
        self.hidden = YES;
    }
}

%end

// 隐藏直播间分享面板直播伴侣提示
%hook IESLiveFlowGuidanceFragment

+ (BOOL)componentShouldActive:(id)attacher {
    if (DYYYGetBool(@"DYYYHideLiveRoomShareCompanion")) {
        return NO;
    }
    return %orig;
}

%end

%hook IESLiveFlowGuidanceAdView

- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveRoomShareCompanion")) {
        self.hidden = YES;
        [self removeFromSuperview];
        return;
    }
    %orig;
}

- (void)didMoveToSuperview {
    if (DYYYGetBool(@"DYYYHideLiveRoomShareCompanion")) {
        if (self.superview) {
            self.hidden = YES;
            [self removeFromSuperview];
        }
        return;
    }
    %orig;
}

%end

// 隐藏直播退出清屏、投屏按钮
%hook IESLiveButton

- (void)layoutSubviews {
    %orig;
    BOOL hideClear = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClear"];
    BOOL hideMirror = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomMirroring"];
    BOOL hideFull = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomFullscreen"];
    BOOL hideClose = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideLiveRoomClose"];

    if (!(hideClear || hideMirror || hideFull)) {
        return;
    }

    NSString *label = self.accessibilityLabel;
    if (hideClear && [label isEqualToString:@"退出清屏"] && self.superview) {
        [self.superview removeFromSuperview];
        return;
    } else if (hideMirror && [label isEqualToString:@"投屏"] && self.superview) {
        self.superview.hidden = YES;
        return;
    } else if (hideFull && [label isEqualToString:@"横屏"] && self.superview) {
        static char kDYLiveButtonCacheKey;
        NSArray *cached = objc_getAssociatedObject(self, &kDYLiveButtonCacheKey);
        if (!cached) {
            cached = [self.subviews copy];
            objc_setAssociatedObject(self, &kDYLiveButtonCacheKey, cached, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        for (UIView *subview in cached) {
            subview.hidden = YES;
        }
        return;
    } else if (hideClose && [self.superview isKindOfClass:%c(HTSLive4LayerContainerView)]) {
        self.hidden = YES;
        return;
    }
}

%end

// 隐藏直播间右上方关闭直播按钮
%hook IESLiveLayoutPlaceholderView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveRoomClose")) {
        [self removeFromSuperview];
        return;
    }
}
%end

// 隐藏直播间流量弹窗
%hook AWELiveFlowAlertView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideCellularAlert")) {
        self.hidden = YES;
        return;
    }
}
%end

// 隐藏直播间商品和推广
%hook IESECLivePluginLayoutView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESECLiveCardSizeComponent
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESECLiveGoodsCardView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveBottomRightCardView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveGameCPExplainCardContainerImpl
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        self.hidden = YES;
        return;
    }
}
%end

%hook AWEPOILivePurchaseAtmosphereView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg") && self.superview) {
        self.superview.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveActivityBannnerView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveGoodsMsg")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏直播间点赞动画
%hook HTSLiveDiggView
- (void)setIconImageView:(UIImageView *)arg1 {
    if (DYYYGetBool(@"DYYYHideLiveLikeAnimation")) {
        %orig(nil);
    } else {
        %orig(arg1);
    }
}
%end

// 隐藏直播间文字贴纸
%hook IESLiveStickerView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideStickerView")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 隐藏直播间礼物挑战
%hook IESLiveGroupLiveComponentView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideGroupComponent")) {
        [self removeFromSuperview];
        return;
    }
    %orig;
}
%end

// 预约直播
%hook IESLivePreAnnouncementPanelViewNew
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideStickerView")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏会员进场特效
%hook IESLiveDynamicUserEnterView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 会员进场特效: 高版本启用swift类名
%hook _TtC18IESLiveRevenueImpl32IESLiveSwiftDynamicUserEnterView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 隐藏特殊进场特效
%hook PlatformCanvasView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        UIView *pview = self.superview;
        UIView *gpview = pview.superview;
        // 基于accessibilitylabel的判断
        BOOL isLynxView = [pview isKindOfClass:%c(UILynxView)] && [gpview isKindOfClass:%c(LynxView)] && [gpview.accessibilityLabel isEqualToString:@"lynxview"];
        // 基于最近的视图控制器IESLiveAudienceViewController的判断
        UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
        BOOL isLiveAudienceVC = [vc isKindOfClass:%c(IESLiveAudienceViewController)];
        if (isLynxView && isLiveAudienceVC) {
            self.hidden = YES;
        }
    }
    return;
}
%end

// 特殊视频进场特效:高版本启用swift类名
%hook _TtC18IESLiveRevenueImpl35IESLiveSwiftVideoLayerUserEnterView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLivePopup")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveDanmakuVariousView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveDanmaku")) {
        self.hidden = YES;
        return;
    }
    %orig;
}

%end

%hook IESLiveDanmakuSupremeView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveDanmaku")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

%hook IESLiveHotMessageView
- (void)layoutSubviews {
    if (DYYYGetBool(@"DYYYHideLiveHotMessage")) {
        self.hidden = YES;
        return;
    }
    %orig;
}
%end

// 数据源 getter 会在详情/合集滚动枚举期间被频繁读取；过滤只能发生在写入边界，
// 不能在 getter 内原地修改宿主持有的 NSMutableArray，否则会触发快速枚举突变异常。
%hook AWEListDataController

- (void)setDataSource:(NSMutableArray *)dataSource {
    Class userPostsClass = objc_getClass("AWEUserPostsDataManager");
    if (userPostsClass && [self isKindOfClass:userPostsClass]) {
        %orig(dataSource);
        return;
    }
    NSArray *filtered = [DYYYUtils arrayByRemovingAdvertisements:dataSource];
    %orig(filtered);
}

- (void)setFilteredDataSource:(NSMutableArray *)filteredDataSource {
    Class userPostsClass = objc_getClass("AWEUserPostsDataManager");
    if (userPostsClass && [self isKindOfClass:userPostsClass]) {
        %orig(filteredDataSource);
        return;
    }
    NSArray *filtered = [DYYYUtils arrayByRemovingAdvertisements:filteredDataSource];
    %orig(filtered);
}

%end

%hook AWEMixVideoListDataController

- (void)setDataSource:(id)dataSource {
    NSArray *filtered = [DYYYUtils arrayByRemovingAdvertisements:dataSource];
    %orig(filtered);
}

%end

%hook AWEMixVideoDetailPlayListDataController

- (void)setDataSource:(id)dataSource {
    NSArray *filtered = [DYYYUtils arrayByRemovingAdvertisements:dataSource];
    %orig(filtered);
}

%end

%hook AWEMixVideoRelatedListDataController

- (void)setDataSource:(id)dataSource {
    NSArray *filtered = [DYYYUtils arrayByRemovingAdvertisements:dataSource];
    %orig(filtered);
}

%end

static BOOL DYYYAwemeModelIsRecommendFeed(AWEAwemeModel *aweme) {
    if (![aweme respondsToSelector:@selector(referString)]) {
        return NO;
    }

    return [aweme.referString isEqualToString:@"homepage_hot"];
}

static BOOL DYYYAwemeModelHasLiveSignal(AWEAwemeModel *aweme) {
    if ([aweme respondsToSelector:@selector(isLive)] && aweme.isLive) {
        return YES;
    }

    if ([aweme respondsToSelector:@selector(cellRoom)] && aweme.cellRoom != nil) {
        return YES;
    }

    return [aweme respondsToSelector:@selector(videoFeedTag)] && [aweme.videoFeedTag isEqualToString:@"直播中"];
}

static BOOL DYYYAwemeModelIsFamiliarItem(AWEAwemeModel *aweme) {
    return [aweme respondsToSelector:@selector(isFamiliarItem)] && aweme.isFamiliarItem;
}

static BOOL DYYYAwemeModelIsAIInteraction(AWEAwemeModel *aweme) {
    return [aweme respondsToSelector:@selector(awemeType)] && aweme.awemeType == 162;
}

@interface DYYYRecommendationFilterConfig : NSObject
@property(nonatomic) NSUInteger generation;
@property(nonatomic) BOOL noAds;
@property(nonatomic) BOOL skipLive;
@property(nonatomic) BOOL skipAllLive;
@property(nonatomic) BOOL skipHotSpot;
@property(nonatomic) BOOL skipPhoto;
@property(nonatomic) BOOL skipPhotoText;
@property(nonatomic) BOOL skipFriendsVideo;
@property(nonatomic) BOOL skipMusic;
@property(nonatomic) BOOL skipAIInteraction;
@property(nonatomic) BOOL shouldDisableHDR;
@property(nonatomic) BOOL filterHDR;
@property(nonatomic) NSInteger minLikesThreshold;
@property(nonatomic) NSInteger daysThreshold;
@property(nonatomic, copy) NSArray<NSString *> *keywords;
@property(nonatomic, copy) NSArray<NSString *> *propKeywords;
@property(nonatomic, copy) NSSet<NSString *> *userIDs;
@property(nonatomic) BOOL hasBatchWork;
@property(nonatomic) BOOL hasModelFilterWork;
@end

@implementation DYYYRecommendationFilterConfig
@end

static os_unfair_lock gDYYYRecommendationFilterConfigLock = OS_UNFAIR_LOCK_INIT;
static DYYYRecommendationFilterConfig *gDYYYRecommendationFilterConfig = nil;
static BOOL gDYYYRecommendationFilterConfigDirty = YES;
static NSUInteger gDYYYRecommendationFilterConfigGeneration = 1;
static id gDYYYRecommendationFilterDefaultsObserver = nil;

static NSArray<NSString *> *DYYYNormalizedFilterTokens(id rawValue) {
    if (![rawValue isKindOfClass:[NSString class]] || [(NSString *)rawValue length] == 0) {
        return @[];
    }

    NSMutableArray<NSString *> *tokens = [NSMutableArray array];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSString *rawToken in [(NSString *)rawValue componentsSeparatedByString:@","]) {
        NSString *token = [rawToken stringByTrimmingCharactersInSet:whitespace];
        if (token.length > 0) {
            [tokens addObject:token];
        }
    }
    return [tokens copy];
}

static NSSet<NSString *> *DYYYNormalizedFilterUserIDs(id rawValue) {
    NSMutableSet<NSString *> *userIDs = [NSMutableSet set];
    NSCharacterSet *whitespace = [NSCharacterSet whitespaceAndNewlineCharacterSet];
    for (NSString *userInfo in DYYYNormalizedFilterTokens(rawValue)) {
        NSString *userID = [userInfo stringByTrimmingCharactersInSet:whitespace];
        NSRange canonicalSeparatorRange = [userID rangeOfString:@"|" options:NSBackwardsSearch];
        if (canonicalSeparatorRange.location != NSNotFound) {
            userID = NSMaxRange(canonicalSeparatorRange) < userID.length
                         ? [[userID substringFromIndex:NSMaxRange(canonicalSeparatorRange)] stringByTrimmingCharactersInSet:whitespace]
                         : @"";
        } else {
            NSRange legacySeparatorRange = [userID rangeOfString:@"-" options:NSBackwardsSearch];
            if (legacySeparatorRange.location != NSNotFound) {
                userID = NSMaxRange(legacySeparatorRange) < userID.length
                             ? [[userID substringFromIndex:NSMaxRange(legacySeparatorRange)] stringByTrimmingCharactersInSet:whitespace]
                             : @"";
            }
        }

        if (userID.length > 0) {
            [userIDs addObject:userID];
        }
    }
    return [userIDs copy];
}

static BOOL DYYYRecommendationFilterMatchesAuthor(DYYYRecommendationFilterConfig *config, AWEUserModel *author) {
    if (config.userIDs.count == 0 || !author) {
        return NO;
    }

    NSString *userID = [author.userID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (userID.length > 0 &&
        ([config.userIDs containsObject:userID] ||
         [config.userIDs containsObject:[@"uid:" stringByAppendingString:userID]])) {
        return YES;
    }

    NSString *shortID = [author.shortID stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    return shortID.length > 0 &&
           ([config.userIDs containsObject:shortID] ||
            [config.userIDs containsObject:[@"short:" stringByAppendingString:shortID]]);
}

static DYYYRecommendationFilterConfig *DYYYBuildRecommendationFilterConfig(NSUInteger generation) {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    DYYYRecommendationFilterConfig *config = [DYYYRecommendationFilterConfig new];
    config.generation = generation;
    config.noAds = [defaults boolForKey:@"DYYYNoAds"];
    config.skipLive = [defaults boolForKey:@"DYYYSkipLive"];
    config.skipAllLive = [defaults boolForKey:@"DYYYSkipAllLive"];
    config.skipHotSpot = [defaults boolForKey:@"DYYYSkipHotSpot"];
    config.skipPhoto = [defaults boolForKey:@"DYYYSkipPhoto"];
    config.skipPhotoText = [defaults boolForKey:@"DYYYSkipPhotoText"];
    config.skipFriendsVideo = [defaults boolForKey:@"DYYYSkipFriendsVideo"];
    config.skipMusic = [defaults boolForKey:@"DYYYSkipMusic"];
    config.skipAIInteraction = [defaults boolForKey:@"DYYYSkipAIInteraction"];
    config.shouldDisableHDR = DYYYShouldDisableAllHDR();
    config.filterHDR = DYYYShouldFilterGlobalHDR();
    config.minLikesThreshold = MAX([defaults integerForKey:@"DYYYFilterLowLikes"], 0);
    config.daysThreshold = MAX([defaults integerForKey:@"DYYYFilterTimeLimit"], 0);
    config.keywords = DYYYNormalizedFilterTokens([defaults objectForKey:@"DYYYFilterKeywords"]);
    config.propKeywords = DYYYNormalizedFilterTokens([defaults objectForKey:@"DYYYFilterProp"]);
    config.userIDs = DYYYNormalizedFilterUserIDs([defaults objectForKey:@"DYYYFilterUsers"]);

    config.hasBatchWork = config.noAds ||
                          config.skipLive ||
                          config.skipAllLive ||
                          config.skipPhoto ||
                          config.skipPhotoText ||
                          config.skipFriendsVideo ||
                          config.skipMusic ||
                          config.skipAIInteraction ||
                          config.shouldDisableHDR ||
                          config.minLikesThreshold > 0 ||
                          config.daysThreshold > 0 ||
                          config.userIDs.count > 0;
    config.hasModelFilterWork = config.noAds ||
                                config.skipAllLive ||
                                config.skipHotSpot ||
                                config.skipFriendsVideo ||
                                config.skipMusic ||
                                config.skipAIInteraction ||
                                config.shouldDisableHDR ||
                                config.filterHDR ||
                                config.keywords.count > 0 ||
                                config.propKeywords.count > 0 ||
                                config.userIDs.count > 0;
    return config;
}

static DYYYRecommendationFilterConfig *DYYYCurrentRecommendationFilterConfig(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        gDYYYRecommendationFilterDefaultsObserver =
            [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                              object:nil
                                                               queue:nil
                                                          usingBlock:^(__unused NSNotification *notification) {
            os_unfair_lock_lock(&gDYYYRecommendationFilterConfigLock);
            gDYYYRecommendationFilterConfigDirty = YES;
            gDYYYRecommendationFilterConfigGeneration += 1;
            os_unfair_lock_unlock(&gDYYYRecommendationFilterConfigLock);
        }];
    });

    os_unfair_lock_lock(&gDYYYRecommendationFilterConfigLock);
    if (gDYYYRecommendationFilterConfigDirty || !gDYYYRecommendationFilterConfig) {
        gDYYYRecommendationFilterConfig =
            DYYYBuildRecommendationFilterConfig(gDYYYRecommendationFilterConfigGeneration);
        gDYYYRecommendationFilterConfigDirty = NO;
    }
    DYYYRecommendationFilterConfig *config = gDYYYRecommendationFilterConfig;
    os_unfair_lock_unlock(&gDYYYRecommendationFilterConfigLock);
    return config;
}

static BOOL DYYYStringContainsAnyFilterToken(NSString *value, NSArray<NSString *> *tokens) {
    if (value.length == 0 || tokens.count == 0) {
        return NO;
    }

    for (NSString *token in tokens) {
        if ([value containsString:token]) {
            return YES;
        }
    }
    return NO;
}

%hook AWEHotListDataController

%new
- (NSNumber *)dyyy_numberValueForLowLikesFilter:(id)rawValue {
    if (!rawValue || rawValue == [NSNull null]) {
        return nil;
    }

    if ([rawValue isKindOfClass:[NSNumber class]]) {
        return (NSNumber *)rawValue;
    }

    if ([rawValue isKindOfClass:[NSString class]]) {
        NSString *trimmed = [(NSString *)rawValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (trimmed.length == 0) {
            return nil;
        }

        NSString *normalized = [[trimmed componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] componentsJoinedByString:@""];
        normalized = [normalized stringByReplacingOccurrencesOfString:@"," withString:@""];
        normalized = [normalized stringByReplacingOccurrencesOfString:@"+" withString:@""];
        if ([normalized hasSuffix:@"赞"]) {
            normalized = [normalized substringToIndex:normalized.length - 1];
        }

        double multiplier = 1.0;
        NSString *lowercaseValue = [normalized lowercaseString];
        if ([normalized hasSuffix:@"亿"]) {
            multiplier = 100000000.0;
            normalized = [normalized substringToIndex:normalized.length - 1];
        } else if ([normalized hasSuffix:@"万"] || [lowercaseValue hasSuffix:@"w"]) {
            multiplier = 10000.0;
            normalized = [normalized substringToIndex:normalized.length - 1];
        } else if ([normalized hasSuffix:@"千"] || [lowercaseValue hasSuffix:@"k"]) {
            multiplier = 1000.0;
            normalized = [normalized substringToIndex:normalized.length - 1];
        }

        NSScanner *doubleScanner = [NSScanner scannerWithString:normalized];
        double doubleValue = 0.0;
        if ([doubleScanner scanDouble:&doubleValue] && doubleScanner.isAtEnd) {
            return @((long long)llround(doubleValue * multiplier));
        }
    }

    return nil;
}

%new
- (NSNumber *)dyyy_resolvedDiggCountForAweme:(AWEAwemeModel *)aweme {
    if (!aweme) {
        return nil;
    }

    // 39.7.0 的稳定原生路径，绝大多数推荐模型可在这里直接命中，避免进入 KVC 兼容探测。
    NSNumber *directDiggCount = [self dyyy_numberValueForLowLikesFilter:aweme.statistics.diggCount];
    if (directDiggCount) {
        return directDiggCount;
    }

    static NSArray<NSString *> *diggKeyPaths = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        diggKeyPaths = @[
            @"statistics.digg_count",
            @"diggCount",
            @"digg_count",
            @"feedSequenceExtendFeature.digg_count",
            @"feedSequenceExtendFeature.diggCount",
            @"recommendFeedExtendFeature.digg_count",
            @"recommendFeedExtendFeature.diggCount"
        ];
    });

    for (NSString *keyPath in diggKeyPaths) {
        id rawValue = nil;
        @try {
            rawValue = [aweme valueForKeyPath:keyPath];
        } @catch (__unused NSException *exception) {
            rawValue = nil;
        }

        NSNumber *resolved = [self dyyy_numberValueForLowLikesFilter:rawValue];
        if (resolved) {
            return resolved;
        }
    }

    return nil;
}

- (id)transferAwemeListIfNeededWithArray:(id)arg1 isInitFetch:(BOOL)arg2 {
    NSArray *orig = %orig;
    if (![orig isKindOfClass:[NSArray class]] || orig.count == 0) {
        return orig;
    }

    DYYYRecommendationFilterConfig *config = DYYYCurrentRecommendationFilterConfig();
    if (!config.hasBatchWork) {
        return orig;
    }

    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSTimeInterval thresholdInSeconds = config.daysThreshold * 86400.0;
    NSMutableArray *filtered = [NSMutableArray arrayWithCapacity:orig.count];

    for (id obj in orig) {
        if (![obj isKindOfClass:%c(AWEAwemeModel)]) {
            [filtered addObject:obj];
            continue;
        }

        AWEAwemeModel *m = (AWEAwemeModel *)obj;
        BOOL isRecommendFeed = DYYYAwemeModelIsRecommendFeed(m);
        BOOL isLiveAweme = DYYYAwemeModelHasLiveSignal(m);

        // 1. 广告过滤：合集、搜索内流、分页追加等旁路也会进入此共享转换。
        if (config.noAds && [DYYYUtils isAdvertisementAwemeModel:m]) {
            continue;
        }

        // 2. 直播过滤：当前路径是推荐流转换，全部过滤同样覆盖这里。
        if ((config.skipAllLive || config.skipLive) && isLiveAweme) {
            continue;
        }

        if (isLiveAweme) {
            [filtered addObject:obj];
            continue;
        }

        // 2.1 图文模式过滤逻辑（推荐页）
        if (config.skipPhotoText &&
            [m respondsToSelector:@selector(isNewTextMode)] &&
            m.isNewTextMode &&
            isRecommendFeed) {
            continue;
        }

        // 2.2 图集过滤逻辑（推荐页）
        if (config.skipPhoto &&
            [m respondsToSelector:@selector(awemeType)] &&
            m.awemeType == 68 &&
            isRecommendFeed) {
            continue;
        }

        // 2.3 朋友作品过滤逻辑（推荐页）：仅使用宿主原生 isFamiliarItem 标记。
        if (config.skipFriendsVideo &&
            isRecommendFeed &&
            DYYYAwemeModelIsFamiliarItem(m)) {
            continue;
        }

        // 2.4 音乐过滤逻辑（推荐页）
        if (config.skipMusic &&
            isRecommendFeed &&
            [m respondsToSelector:@selector(musicCard)] &&
            m.musicCard) {
            continue;
        }

        // 2.5 AI 互动过滤逻辑（推荐页）：仅接受宿主 awemeType == 162 的明确类型。
        if (config.skipAIInteraction &&
            isRecommendFeed &&
            DYYYAwemeModelIsAIInteraction(m)) {
            continue;
        }

        // 2.6 用户过滤：当前控制器只处理推荐流，模型字段也已在数组转换阶段完整初始化。
        // 优先匹配稳定 userID，并保留旧版 shortID 配置兼容。
        if (DYYYRecommendationFilterMatchesAuthor(config, m.author)) {
            continue;
        }

        // 3. 时间限制过滤
        if (config.daysThreshold > 0 && [m respondsToSelector:@selector(createTime)]) {
            NSTimeInterval vTs = [m.createTime doubleValue];
            if (vTs > 1e12) {
                vTs /= 1000.0;
            }

            if (vTs > 0 && (now - vTs) > thresholdInSeconds) {
                continue;
            }
        }

        // 4. 全局屏蔽 HDR 时，若作品没有 SDR 码率档，直接过滤，避免强播纯 HDR 源导致黑屏或 HDR 漏出。
        if (config.shouldDisableHDR &&
            ![m dyyy_shouldExcludeFromGlobalHDRFilter] &&
            DYYYAwemeModelHasOnlyHDRBitrateModels(m)) {
            continue;
        }

        if (config.shouldDisableHDR) {
            DYYYStripHDRHintsFromAwemeModel(m);
        }

        // 5. 低赞过滤：字段缺失时放行；可解析到数值时严格按阈值过滤。
        if (config.minLikesThreshold > 0) {
            NSNumber *diggCountValue = [self dyyy_resolvedDiggCountForAweme:m];
            if (diggCountValue && diggCountValue.integerValue < config.minLikesThreshold) {
                continue;
            }
        }

        [filtered addObject:obj];
    }

    return [filtered copy];
}

%end

static BOOL DYYYShouldHideTemplateVideoForAweme(AWEAwemeModel *aweme) {
    if (!DYYYGetBool(@"DYYYHideTemplateVideo")) {
        return NO;
    }

    if (![aweme respondsToSelector:@selector(referString)]) {
        return YES;
    }

    NSString *referString = aweme.referString;
    return referString.length == 0 || [referString isEqualToString:@"homepage_hot"];
}

static BOOL DYYYAwemeModelMatchesConfiguredContentFilters(AWEAwemeModel *aweme,
                                                           DYYYRecommendationFilterConfig *config) {
    if (!aweme || !config.hasModelFilterWork) {
        return NO;
    }

    BOOL shouldFilterAds = config.noAds && [DYYYUtils isAdvertisementAwemeModel:aweme];
    BOOL shouldFilterHotSpot = config.skipHotSpot && aweme.hotSpotLynxCardModel;
    BOOL isRecommendFeed = DYYYAwemeModelIsRecommendFeed(aweme);
    BOOL shouldFilterAllLive = config.skipAllLive && DYYYAwemeModelHasLiveSignal(aweme);
    BOOL shouldFilterFriendsVideo = config.skipFriendsVideo && isRecommendFeed && DYYYAwemeModelIsFamiliarItem(aweme);
    BOOL shouldFilterMusic = config.skipMusic && isRecommendFeed && aweme.musicCard;
    BOOL shouldFilterAIInteraction = config.skipAIInteraction && isRecommendFeed && DYYYAwemeModelIsAIInteraction(aweme);
    BOOL shouldFilterKeywords = NO;
    BOOL shouldFilterProp = NO;
    BOOL shouldFilterUser = NO;
    BOOL shouldFilterHDR = NO;

    if (isRecommendFeed) {
        shouldFilterUser = DYYYRecommendationFilterMatchesAuthor(config, aweme.author);
    }

    if (isRecommendFeed && config.keywords.count > 0) {
        shouldFilterKeywords = DYYYStringContainsAnyFilterToken(aweme.descriptionString, config.keywords);
    }

    if (isRecommendFeed && config.propKeywords.count > 0) {
        shouldFilterProp = DYYYStringContainsAnyFilterToken(aweme.propGuideV2.propName, config.propKeywords);
    }

    if (config.shouldDisableHDR &&
        ![aweme dyyy_shouldExcludeFromGlobalHDRFilter] &&
        DYYYAwemeModelHasOnlyHDRBitrateModels(aweme)) {
        shouldFilterHDR = YES;
    }

    if (config.filterHDR && ![aweme dyyy_shouldExcludeFromGlobalHDRFilter] && aweme.video) {
        AWEVideoModel *video = aweme.video;
        if ([video respondsToSelector:@selector(isSourceHDR)] && video.isSourceHDR > 0) {
            shouldFilterHDR = YES;
        } else if ([video respondsToSelector:@selector(hasFilterHDR)] && video.hasFilterHDR) {
            shouldFilterHDR = YES;
        }

        if (!shouldFilterHDR) {
            for (id bitrateModel in video.bitrateModels) {
                @try {
                    NSNumber *hdrType = [bitrateModel valueForKey:@"hdrType"];
                    NSNumber *hdrBit = [bitrateModel valueForKey:@"hdrBit"];
                    if ((hdrType && [hdrType integerValue] > 0) ||
                        (!hdrType && hdrBit && [hdrBit integerValue] >= 10)) {
                        shouldFilterHDR = YES;
                        break;
                    }
                } @catch (__unused NSException *exception) {
                }
            }
        }
    }

    return shouldFilterAds ||
           shouldFilterAllLive ||
           shouldFilterHotSpot ||
           shouldFilterFriendsVideo ||
           shouldFilterMusic ||
           shouldFilterAIInteraction ||
           shouldFilterHDR ||
           shouldFilterKeywords ||
           shouldFilterProp ||
           shouldFilterUser;
}

%hook AWEAwemeModel

- (id)initWithDictionary:(id)arg1 error:(id *)arg2 {
    id orig = %orig;
    if (orig) {
        DYYYRecommendationFilterConfig *filterConfig = DYYYCurrentRecommendationFilterConfig();
        BOOL shouldDisableHDR = filterConfig.shouldDisableHDR;
        BOOL shouldFilterOnlyHDRSource = NO;
        if (shouldDisableHDR && ![self dyyy_shouldExcludeFromGlobalHDRFilter]) {
            shouldFilterOnlyHDRSource = DYYYAwemeModelHasOnlyHDRBitrateModels(self);
            if (!shouldFilterOnlyHDRSource) {
                shouldFilterOnlyHDRSource = DYYYRawObjectHasOnlyHDRBitrateModels(arg1);
                if (shouldFilterOnlyHDRSource) {
                    objc_setAssociatedObject(self, &kDYYYHDROnlyAwemeModelKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                }
            }
        }
        BOOL shouldFilter = filterConfig.noAds && [DYYYUtils isAdvertisementRawData:arg1];
        if (!shouldFilter) {
            shouldFilter = DYYYAwemeModelMatchesConfiguredContentFilters(self, filterConfig);
        }
        if (!shouldFilter && shouldFilterOnlyHDRSource) {
            shouldFilter = YES;
        }
        if (!shouldFilter && filterConfig.filterHDR &&
            ![self dyyy_shouldExcludeFromGlobalHDRFilter] &&
            [self dyyy_containsHDRMetadataInObject:arg1 depth:0]) {
            shouldFilter = YES;
        }
        if (shouldFilter) {
            return nil;
        }
        if (shouldDisableHDR) {
            DYYYStripHDRHintsFromAwemeModel(self);
        }
    }
    return orig;
}

- (void)setVideo:(AWEVideoModel *)video {
    DYYYStripHDRHintsFromVideoModel(video);
    %orig;
}

- (AWEVideoModel *)video {
    return %orig;
}

- (void)setAlbumImages:(NSArray<AWEImageAlbumImageModel *> *)albumImages {
    if (DYYYShouldDisableAllHDR()) {
        for (AWEImageAlbumImageModel *imageModel in albumImages) {
            DYYYStripHDRHintsFromVideoModel(DYYYValuePreferringIvar(imageModel, "_clipVideo", @"clipVideo"));
        }
    }
    %orig;
}

- (NSArray<AWEImageAlbumImageModel *> *)albumImages {
    return %orig;
}

- (BOOL)awe_enableHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (id)awe_HDRValueFor:(long long)value enableHDR:(BOOL)enableHDR {
    return %orig(value, DYYYShouldDisableAllHDR() ? NO : enableHDR);
}

%new
- (BOOL)dyyy_shouldExcludeFromGlobalHDRFilter {
    NSString *referString = [self.referString lowercaseString];
    if (referString.length == 0) {
        return NO;
    }

    return [referString isEqualToString:@"chat"] ||
           [referString containsString:@"chat_room"] ||
           [referString containsString:@"message"] ||
           [referString containsString:@"forward"] ||
           [referString containsString:@"private"] ||
           [referString containsString:@"share"] ||
           [referString hasPrefix:@"im_"] ||
           [referString containsString:@"_im_"];
}

%new
- (BOOL)dyyy_containsHDRMetadataInObject:(id)object depth:(NSUInteger)depth {
    if (!object || depth > 8) {
        return NO;
    }

    if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dictionary = (NSDictionary *)object;
        for (id rawKey in dictionary) {
            id value = dictionary[rawKey];
            NSString *key = [[rawKey description] lowercaseString];
            NSInteger numericValue = [value respondsToSelector:@selector(integerValue)] ? [value integerValue] : 0;

            if (([key isEqualToString:@"is_source_hdr"] || [key isEqualToString:@"has_filter_hdr"]) && numericValue > 0) {
                return YES;
            }
            if ([key isEqualToString:@"hdr_type"] && numericValue > 0) {
                return YES;
            }
            if ([key isEqualToString:@"hdr_bit"] && numericValue >= 10) {
                return YES;
            }
            if (([value isKindOfClass:[NSDictionary class]] || [value isKindOfClass:[NSArray class]]) &&
                [self dyyy_containsHDRMetadataInObject:value depth:depth + 1]) {
                return YES;
            }
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        for (id value in (NSArray *)object) {
            if ([self dyyy_containsHDRMetadataInObject:value depth:depth + 1]) {
                return YES;
            }
        }
    }

    return NO;
}

%new
- (BOOL)contentFilter {
    return DYYYAwemeModelMatchesConfiguredContentFilters(self, DYYYCurrentRecommendationFilterConfig());
}

- (AWEECommerceLabel *)ecommerceBelowLabel {
    if (DYYYGetBool(@"DYYYHideHisShop")) {
        return nil;
    }
    return %orig;
}

- (void)setEcommerceBelowLabel:(id)label {
	if (DYYYGetBool(@"DYYYHideHisShop")) {
		%orig(nil);
		return;
	}
	%orig;
}

- (void)setDescriptionString:(NSString *)desc {
    NSString *labelStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelStyle"];
    BOOL hideLabel = [labelStyle isEqualToString:@"文案标签隐藏"];
    if (hideLabel) {
        // 过滤掉所有以 # 开头的标签
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"#\\S+" options:0 error:nil];
        NSString *filtered = [regex stringByReplacingMatchesInString:desc options:0 range:NSMakeRange(0, desc.length) withTemplate:@""];
        // 去除首尾空白字符
        filtered = [filtered stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        // 为空则赋nil，避免显示空行
        desc = filtered.length > 0 ? filtered : nil;
    }
    %orig(desc);
}

- (void)setTextExtras:(NSArray *)extras {
    NSString *labelStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelStyle"];
    BOOL disableLabelSearch = [labelStyle isEqualToString:@"文案标签禁止跳转搜索"] || [labelStyle isEqualToString:@"文案标签隐藏"];
    if (disableLabelSearch && [extras isKindOfClass:[NSArray class]]) {
        NSMutableArray *filtered = [NSMutableArray array];
        for (AWEAwemeTextExtraModel *model in extras) {
            if (model.userID.length > 0) {
                [filtered addObject:model];
            }
        }
        extras = [filtered copy];
    }
    %orig(extras);
}

// 固定设置为 1，启用自定义背景色
- (NSUInteger)awe_playerBackgroundViewShowType {
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYVideoBGColor"]) {
        return 1;
    }
    return %orig;
}

- (UIColor *)awe_smartBackgroundColor {
    NSString *colorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYVideoBGColor"];
    if (colorHex && colorHex.length > 0) {
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        UIColor *customColor = [DYYYUtils colorFromSchemeHexString:colorHex targetWidth:screenWidth];
        if (customColor)
            return customColor;
    }
    return %orig;
}

//屏蔽章节要点数据
- (NSArray *)chapterList {
	BOOL hideChapterList = DYYYGetBool(@"DYYYHideChapterProgress");
	if (hideChapterList) {
		return @[]; // 返回空数组
	}
	return %orig;
}

// 屏蔽共创数据
- (id)acceptedCoCreators {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return @[]; // 永远为空
	}
	return %orig;
}

- (id)unAcceptedCoCreators {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return @[];
	}
	return %orig;
}

- (NSInteger)acceptedCoCreatorsNums {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return 0;
	}
	return %orig;
}

- (id)awe_coCreatorPoster {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return nil;
	}
	return %orig;
}

- (id)awe_coCreatorFromAuthor {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return nil;
	}
	return %orig;
}

- (id)awe_userModelWithCoCreator:(id)creator {
	BOOL DYYYHideGongChuang = DYYYGetBool(@"DYYYHideGongChuang");
	if (DYYYHideGongChuang) {
		return nil;
	}
	return %orig;
}

// 屏蔽相关视频推荐
- (id)relatedVideoExtra {
	BOOL DYYYHideBottomRelated = DYYYGetBool(@"DYYYHideBottomRelated");
	if (DYYYHideBottomRelated) {
		return nil;
	}
	return %orig;
}

- (id)relatedVideo {
	BOOL DYYYHideBottomRelated = DYYYGetBool(@"DYYYHideBottomRelated");
	if (DYYYHideBottomRelated) {
		return nil;
	}
	return %orig;
}

- (id)playletRelatedVideoInfoModel {
	BOOL DYYYHideBottomRelated = DYYYGetBool(@"DYYYHideBottomRelated");
	if (DYYYHideBottomRelated) {
		return nil;
	}
	return %orig;
}

// 屏蔽评论搜索锚点
- (id)commonSearchAnchor {
	BOOL DYYYHideCommentLongPressSearch = DYYYGetBool(@"DYYYHideCommentLongPressSearch");
	if (DYYYHideCommentLongPressSearch) {
		return nil;
	}
	return %orig;
}

- (void)setCommonSearchAnchor:(id)arg {
	BOOL DYYYHideCommentLongPressSearch = DYYYGetBool(@"DYYYHideCommentLongPressSearch");
	if (DYYYHideCommentLongPressSearch) {
		%orig(nil);
		return;
	}
	%orig;
}

// 屏蔽汽水音乐锚点
- (id)relatedMusicAnchor {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

- (void)setRelatedMusicAnchor:(id)anchor {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		%orig(nil);
		return;
	}
	%orig;
}

// 屏蔽底栏热点
- (id)hotSpotRawData {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return nil;
	}
	return %orig;
}

- (void)setHotSpotRawData:(id)data {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)hotSpotListModel {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return nil;
	}
	return %orig;
}

- (void)setHotSpotListModel:(id)model {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		%orig(nil);
		return;
	}
	%orig;
}

- (NSString *)templateBarsString {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (void)setTemplateBarsString:(NSString *)string {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		%orig(@"");
		return;
	}
	%orig;
}

// 屏蔽底部合集
- (id)mixInfo {
	if (DYYYShouldHideTemplateVideoForAweme(self)) {
		return nil;
	}
	return %orig;
}

- (void)setMixInfo:(id)info {
	if (DYYYShouldHideTemplateVideoForAweme(self)) {
		%orig(nil);
		return;
	}
	%orig;
}

// 屏蔽短剧信息（只对推荐页生效）
- (id)playletInfoModel {
	BOOL DYYYHideTemplatePlaylet = DYYYGetBool(@"DYYYHideTemplatePlaylet");
	if (DYYYHideTemplatePlaylet && [self.referString isEqualToString:@"homepage_hot"]) {
		return nil;
	}
	return %orig;
}

// 屏蔽作者声明及风险提示
- (id)riskInfoModel {
	BOOL DYYYHideAntiAddictedNotice = DYYYGetBool(@"DYYYHideAntiAddictedNotice");
	if (DYYYHideAntiAddictedNotice) {
		return nil;
	}
	return %orig;
}

- (void)setRiskInfoModel:(id)model {
	BOOL DYYYHideAntiAddictedNotice = DYYYGetBool(@"DYYYHideAntiAddictedNotice");
	if (DYYYHideAntiAddictedNotice) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

//以下部分为新增
// 屏蔽头像直播
%hook AWEUserModel

- (NSNumber *)roomID {
	BOOL DYYYHideAvatarLive = DYYYGetBool(@"DYYYHideAvatarLive") || DYYYGetBool(@"DYYYHideAvatarButton");
	if (DYYYHideAvatarLive) {
		return @(0);
	}
	return %orig;
}

%end

// 屏蔽头像光圈
%hook AWEUserModel

- (id)storyRing {
	BOOL DYYYHideAvatarButton = DYYYGetBool(@"DYYYHideAvatarButton");
	if (DYYYHideAvatarButton) {
		return nil;
	}
	return %orig;
}

- (void)setStoryRing:(id)ring {
	BOOL DYYYHideAvatarButton = DYYYGetBool(@"DYYYHideAvatarButton");
	if (DYYYHideAvatarButton) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

%hook AWECodeGenStoryRingInfoModel

- (NSArray *)storyRingsModelArray {
	BOOL DYYYHideAvatarButton = DYYYGetBool(@"DYYYHideAvatarButton");
	if (DYYYHideAvatarButton) {
		return @[];
	}
	return %orig;
}

- (void)setStoryRingsModelArray:(NSArray *)array {
	BOOL DYYYHideAvatarButton = DYYYGetBool(@"DYYYHideAvatarButton");
	if (DYYYHideAvatarButton) {
		%orig(@[]);
		return;
	}
	%orig;
}

%end

// 屏蔽挑战贴纸
%hook AWEInteractionHashtagStickerModel

- (id)hashtagInfo {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		return nil;
	}
	return %orig;
}

- (void)setHashtagInfo:(id)info {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		%orig(nil);
		return;
	}
	%orig;
}

- (id)hashtagId {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		return nil;
	}
	return %orig;
}

- (id)hashtagName {
	BOOL DYYYHideChallengeStickers = DYYYGetBool(@"DYYYHideChallengeStickers");
	if (DYYYHideChallengeStickers) {
		return nil;
	}
	return %orig;
}

%end

// 屏蔽互动贴纸
%hook AWEInteractionEditTagStickerModel

- (id)editTagInfo {
	if (DYYYGetBool(@"DYYYHideEditTag")) {
		return nil;
	}
	return %orig;
}

- (void)setEditTagInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideEditTag")) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

// 隐藏下面底部热点框
%hook AWEHotSpotListModel

- (BOOL)disableDisplay {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return YES;
	}
	return %orig;
}

- (BOOL)disableDisplayInner {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return YES;
	}
	return %orig;
}

- (NSString *)hotSpotTipTitleHeader {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)hotSpotTipTitle {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)hotSpotTipTitleFooter {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)hotInfoWord {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)i18NTipTitle {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @"";
	}
	return %orig;
}

- (NSString *)tipSchema {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return nil;
	}
	return %orig;
}

- (NSDictionary *)extraDictionary {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @{};
	}
	return %orig;
}

- (NSDictionary *)relativityExtra {
	BOOL DYYYHideHotspot = DYYYGetBool(@"DYYYHideHotspot");
	if (DYYYHideHotspot) {
		return @{};
	}
	return %orig;
}

%end

%hook AWESearchMixVideoModel

- (id)mixInfo {
	if (DYYYGetBool(@"DYYYHideTemplateVideo")) {
		return nil;
	}
	return %orig;
}

- (void)setMixInfo:(id)info {
	if (DYYYGetBool(@"DYYYHideTemplateVideo")) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

// 屏蔽精选标签
%hook AWETemplateStaticLabelInfoModel

- (NSArray *)containers {
	if (DYYYGetBool(@"DYYYHideTemplateLabel")) {
		return @[];
	}
	return %orig;
}

- (void)setContainers:(NSArray *)containers {
	if (DYYYGetBool(@"DYYYHideTemplateLabel")) {
		%orig(@[]);
		return;
	}
	%orig;
}

%end

// 隐藏好友推荐
%hook AFDFriendRecommendTagView

- (void)layoutSubviews {
	if (DYYYGetBool(@"DYYYHideFriendRecommend")) {
		self.hidden = YES;
		return;
	}
	%orig;
}

%end

// 屏蔽汽水音乐锚点 - hook AWERelatedMusicAnchorModel
%hook AWERelatedMusicAnchorModel

- (instancetype)init {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

- (instancetype)initWithDictionary:(id)dict error:(NSError **)error {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

%end

// 屏蔽汽水音乐 - 清空 commentTopBarInfo
%hook AWEMusicExtraModel

- (id)commentTopBarInfo {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		return nil;
	}
	return %orig;
}

- (void)setCommentTopBarInfo:(id)info {
	BOOL DYYYHideQuqishuiting = DYYYGetBool(@"DYYYHideQuqishuiting");
	if (DYYYHideQuqishuiting) {
		%orig(nil);
		return;
	}
	%orig;
}

%end

// 拦截开屏广告 - hook TTAdSplashModel，直接返回 nil
%hook TTAdSplashModel

+ (id)alloc {
	if (DYYYGetBool(@"DYYYNoAds")) {
		return nil;  // 直接返回 nil，阻止对象创建
	}
	return %orig;
}

%end

%hook AWEOriginalAdModel
- (instancetype)init {
	BOOL noAds = DYYYGetBool(@"DYYYNoAds");
	if (noAds) {
		return nil;  // 阻止创建，直接返回 nil
	}
	return %orig;
}

- (instancetype)initWithDictionary:(id)dict error:(NSError **)error {
	BOOL noAds = DYYYGetBool(@"DYYYNoAds");
	if (noAds) {
		return nil;  // 阻止创建，直接返回 nil
	}
	return %orig;
}
%end

// 屏蔽 AWEGeneralSearchModel 中的广告卡（搜索卡片、动态卡及其作品模型统一判定）
%hook AWEGeneralSearchModel
- (instancetype)initWithDictionary:(id)dict error:(NSError **)error {
	id orig = %orig;

	BOOL noAds = DYYYGetBool(@"DYYYNoAds");
	if (!noAds || !orig) {
		return orig;
	}

	if ([DYYYUtils isAdvertisementContainerModel:orig] || [DYYYUtils isAdvertisementRawData:dict]) {
		return nil;
	}

	return orig;
}
%end

// 去除启动视频广告
%hook AWEAwesomeSplashFeedCellOldAccessoryView

// 在方法入口处添加控制逻辑
- (id)ddExtraView {
	if (DYYYGetBool(@"DYYYNoAds")) {
		return NULL; // 返回空视图
	}

	// 正常模式调用原始方法
	return %orig;
}

%end

// 屏蔽青少年模式弹窗
%hook AWETeenModeAlertView
- (BOOL)show {
	if (DYYYGetBool(@"DYYYHideTeenMode")) {
		return NO;
	}
	return %orig;
}
%end

// 屏蔽青少年模式弹窗
%hook AWETeenModeSimpleAlertView
- (BOOL)show {
	if (DYYYGetBool(@"DYYYHideTeenMode")) {
		return NO;
	}
	return %orig;
}
%end

%hook AWEFeedCommentConfigModel
- (void)setCommentInputConfigText:(NSString *)text {
    NSString *customText = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentContent"];
    if (customText && customText.length > 0) {
        text = customText;
    }
    %orig(text);
}
%end

%hook AWEAwemeStatusModel
- (void)setListenVideoStatus:(NSInteger)status {
    if (status == 1 && DYYYGetBool(@"DYYYEnableBackgroundListen")) {
        status = 2;
    }
    %orig(status);
}
%end

%hook MTKView

- (void)layoutSubviews {
    %orig;
    DYYYDisableExtendedRangeForLayer(self.layer);
    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
    Class playVCClass = NSClassFromString(@"AWEPlayVideoViewController");
    if (vc && playVCClass && [vc isKindOfClass:playVCClass]) {
        NSString *colorHex = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYVideoBGColor"];
        if (colorHex && colorHex.length > 0) {
            CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
            UIColor *customColor = [DYYYUtils colorFromSchemeHexString:colorHex targetWidth:screenWidth];
            if (customColor)
                self.backgroundColor = customColor;
        }
    }
}

%end

%hook AWEPlayInteractionUserAvatarView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideAvatarButton")) {
        DYYYHideAvatarVisualForSelector(self, NSSelectorFromString(@"userAvatarView"));
        DYYYApplyAvatarSurroundingSettingsForOwner(self);
    }

    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)didMoveToWindow {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)didMoveToSuperview {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)updateRightContainerElement {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)p_resetFollowAnimation {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)playFollowAnimation:(id)completion {
    %orig(completion);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)playUnFollowAnimation {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)changeSendMessageViewWithFlag:(BOOL)flag {
    %orig(flag);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}
%end

%hook AWEPlayInteractionUserAvatarFollowPromptController
- (void)onFollowViewClicked:(UITapGestureRecognizer *)gesture {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return;
    }

    if (DYYYGetBool(@"DYYYFollowTips")) {
        AWEPlayInteractionUserAvatarContext *context = nil;
        if ([self respondsToSelector:@selector(userAvatarContext)]) {
            context = [self valueForKey:@"userAvatarContext"];
        }

        AWEUserModel *author = context.model.author;
        NSString *nickname = @"";
        NSString *signature = @"";
        NSString *avatarURL = @"";

        if (author) {
            if ([author respondsToSelector:@selector(nickname)]) {
                nickname = [author valueForKey:@"nickname"] ?: @"";
            }

            if ([author respondsToSelector:@selector(signature)]) {
                signature = [author valueForKey:@"signature"] ?: @"";
            }

            if ([author respondsToSelector:@selector(avatarThumb)]) {
                AWEURLModel *avatarThumb = [author valueForKey:@"avatarThumb"];
                if (avatarThumb && avatarThumb.originURLList.count > 0) {
                    avatarURL = avatarThumb.originURLList.firstObject;
                }
            }
        }

        NSMutableString *messageContent = [NSMutableString string];
        if (signature.length > 0) {
            [messageContent appendFormat:@"%@", signature];
        }

        NSString *title = nickname.length > 0 ? nickname : @"关注确认";

        [DYYYBottomAlertView showAlertWithTitle:title
                                        message:messageContent
                                      avatarURL:avatarURL
                               cancelButtonText:@"取消"
                              confirmButtonText:@"关注"
                                   cancelAction:nil
                                    closeAction:nil
                                  confirmAction:^{
                                    DYYYRunDeferredFollowConfirm(^{
                                        %orig(nil);
                                    });
                                  }];
    } else {
        %orig;
    }
}

- (void)onUnFollowViewClicked:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return;
    }
    %orig(arg1);
}

- (void)followPromptViewClicked:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return;
    }
    %orig(arg1);
}

- (void)layoutElementView {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (BOOL)shouldShowFollowAddWithModel:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return NO;
    }
    return %orig(arg1);
}

- (BOOL)shouldShowSpecialFollowWithModel:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return NO;
    }
    return %orig(arg1);
}

- (void)showFollowAddView:(BOOL)show {
    %orig(show);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_willDisplay {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_viewDidAppear {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)updateFollowStatus {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)followStatusChanged:(id)arg1 {
    %orig(arg1);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)playFollowAnimation {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)playFollowAnimation:(id)completion {
    %orig(completion);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)playUnFollowAnimation {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)_ensureStaticFollowAnimationView {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}
%end

%hook AWEPlayInteractionUserAvatarMainBusinessController
- (void)layoutElementView {
    %orig;
    if (DYYYGetBool(@"DYYYHideAvatarButton")) {
        DYYYHideAvatarVisualForSelector(self, NSSelectorFromString(@"avatarPicView"));
        id context = DYYYAvatarObjectForSelector(self, NSSelectorFromString(@"userAvatarContext"));
        DYYYHideAvatarVisualForSelector(context, NSSelectorFromString(@"avatarPicView"));
        DYYYApplyAvatarSurroundingSettingsForOwner(self);
    }
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}
%end

%hook AWEPlayInteractionUserAvatarOptElementElement
- (void)layoutElementView {
    %orig;
    if (DYYYGetBool(@"DYYYHideAvatarButton")) {
        id context = DYYYAvatarObjectForSelector(self, NSSelectorFromString(@"userAvatarContext"));
        DYYYHideAvatarVisualForSelector(context, NSSelectorFromString(@"avatarPicView"));
        DYYYApplyAvatarSurroundingSettingsForOwner(self);
    }
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_willDisplay {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_viewDidAppear {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)setAppear:(BOOL)appear {
    %orig(appear);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}
%end

%hook AWEPlayInteractionUserAvatarStoryController
- (void)layoutElementView {
    %orig;
    DYYYApplyAvatarSurroundingSettingsForOwner(self);
}

- (void)showStory25RingView {
    %orig;
    DYYYApplyAvatarSurroundingSettingsForOwner(self);
}
%end

%hook AWEPlayInteractionUserAvatarDecorationController
- (void)layoutElementView {
    %orig;
    DYYYApplyAvatarSurroundingSettingsForOwner(self);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_willDisplay {
    %orig;
    DYYYApplyAvatarSurroundingSettingsForOwner(self);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)setDecorationStyle:(long long)style {
    %orig(style);
    DYYYApplyAvatarSurroundingSettingsForOwner(self);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}
%end

%hook AWEPlayInteractionUserAvatarSendMessageController
- (void)controllerViewDidLayout {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)controllerStartConfigAvatarView:(id)view {
    %orig(view);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(view);
}

- (void)controllerWillDisplay {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)controllerPlay {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)controllerReset {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)updateSendMessageView:(BOOL)show {
    %orig(show);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)p_updateSendMessageView:(BOOL)show {
    %orig(show);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)p_showSendMessageView:(id)view shouldShowSendMessageView:(BOOL)show animated:(BOOL)animated completion:(id)completion {
    %orig(view, show, animated, completion);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(view);
}

- (BOOL)shouldShowSendMessageView {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return NO;
    }
    return %orig;
}

- (BOOL)shouldShowSendMessageGuideAnimation {
    if (DYYYAvatarFollowOptionsEnabled()) {
        return NO;
    }
    return %orig;
}

- (void)playSendMessageGuideAnimationIfNeeded {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)onSendMessageViewClicked:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return;
    }
    %orig(arg1);
}
%end

%hook AWEPlayInteractionUserAvatarSendMsgController
- (void)layoutElementView {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_willDisplay {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_viewDidDisappear {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)play {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)reset {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)changeSendMessageViewWithFlag:(BOOL)flag {
    %orig(flag);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)showSendMessageView:(id)view show:(BOOL)show animated:(BOOL)animated completion:(id)completion {
    %orig(view, show, animated, completion);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(view);
}

- (void)showSendMessageViewWithAnimation:(BOOL)animated {
    %orig(animated);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (BOOL)shouldShowSendMessageView:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return NO;
    }
    return %orig(arg1);
}

- (BOOL)shouldShowSendMessageGuideAnimation {
    if (DYYYAvatarFollowOptionsEnabled()) {
        return NO;
    }
    return %orig;
}

- (void)updateSendMsgWithFollowShow:(BOOL)show animation:(BOOL)animated {
    %orig(show, animated);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)handleAvatarFollowStatusChange:(id)arg1 {
    %orig(arg1);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)playSendMessageGuideAnimationIfNeeded {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)onSendMessageViewClicked:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return;
    }
    %orig(arg1);
}
%end

%hook AWEPlayInteractionUserAvatarEnterStoreController
- (void)layoutElementView {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_willDisplay {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)viewController_viewDidAppear {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)play {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)reset {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)showEnterStore {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)hideEnterStore {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (BOOL)shouldShowEnterStoreView {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return NO;
    }
    return %orig;
}

- (BOOL)shouldShowEnterStoreGuideAnimation {
    if (DYYYAvatarFollowOptionsEnabled()) {
        return NO;
    }
    return %orig;
}

- (void)playEnterStoreGuideAnimationIfNeeded {
    if (DYYYAvatarFollowOptionsEnabled()) {
        DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
        return;
    }
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)handleAvatarFollowStatusChange:(id)arg1 {
    %orig(arg1);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)onEnterStoreViewClicked:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return;
    }
    %orig(arg1);
}
%end

%hook AWEPlayInteractionUserAvatarAdLinkController
- (void)layoutElementView {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)reset {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)updateCommerceHotSplashLinkIconImageIfNeeded:(id)arg1 {
    %orig(arg1);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)onLinkIconContainerViewClicked:(id)arg1 {
    if (DYYYGetBool(@"DYYYHideFollowPromptView")) {
        return;
    }
    %orig(arg1);
}
%end

%hook AWEPlayInteractionViewController

- (void)performCommentAction {
    %orig;
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)setIsCommentVCShowing:(BOOL)showing {
    %orig(showing);
    DYYYApplyAvatarFollowPromptSettingsWithRetry(self);
}

- (void)onPlayer:(id)arg0 didDoubleClick:(id)arg1 {
    BOOL isPopupEnabled = DYYYGetBool(@"DYYYEnableDoubleTapMenu");
    BOOL isDirectCommentEnabled = DYYYGetBool(@"DYYYEnableDoubleOpenComment");

    // 直接打开评论区的情况
    if (isDirectCommentEnabled) {
        [self performCommentAction];
        return;
    }

    if (isPopupEnabled) {
        AWEAwemeModel *awemeModel = nil;

        awemeModel = [self performSelector:@selector(awemeModel)];
        [DYYYManager setAlbumDescriptionContextWithAwemeModel:awemeModel];

        AWEVideoModel *videoModel = awemeModel.video;
        AWEMusicModel *musicModel = awemeModel.music;
        NSURL *audioURL = nil;
        if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
            audioURL = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
        }

        // 确定内容类型（视频或图片）
        BOOL isImageContent = (awemeModel.awemeType == 68);
        // 判断是否为新版实况照片
        BOOL isNewLivePhoto = (awemeModel.video && awemeModel.animatedImageVideoInfo != nil);
        NSString *downloadTitle;

        if (isImageContent) {
            AWEImageAlbumImageModel *currentImageModel = nil;
            if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
            } else {
                currentImageModel = awemeModel.albumImages.firstObject;
            }

            if (awemeModel.albumImages.count > 1) {
                downloadTitle = (currentImageModel.clipVideo != nil || awemeModel.isLivePhoto) ? @"保存当前实况" : @"保存当前图片";
            } else {
                downloadTitle = (currentImageModel.clipVideo != nil || awemeModel.isLivePhoto) ? @"保存实况" : @"保存图片";
            }
        } else if (isNewLivePhoto) {
            downloadTitle = @"保存实况";
        } else {
            downloadTitle = @"保存视频";
        }

        AWEUserActionSheetView *actionSheet = [[NSClassFromString(@"AWEUserActionSheetView") alloc] init];
        NSMutableArray *actions = [NSMutableArray array];

        // 添加下载选项
        if (DYYYGetBool(@"DYYYDoubleTapDownload") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapDownload"]) {
            AWEUserSheetAction *downloadAction = [NSClassFromString(@"AWEUserSheetAction")
                actionWithTitle:downloadTitle
                        imgName:nil
                        handler:^{
                          if (isImageContent) {
                              // 图片内容
                              AWEImageAlbumImageModel *currentImageModel = nil;
                              if (awemeModel.currentImageIndex > 0 && awemeModel.currentImageIndex <= awemeModel.albumImages.count) {
                                  currentImageModel = awemeModel.albumImages[awemeModel.currentImageIndex - 1];
                              } else {
                                  currentImageModel = awemeModel.albumImages.firstObject;
                              }

                              // 查找非.image后缀的URL
                              NSURL *downloadURL = nil;
                              for (NSString *urlString in currentImageModel.urlList) {
                                  NSURL *url = [NSURL URLWithString:urlString];
                                  NSString *pathExtension = [url.path.lowercaseString pathExtension];
                                  if (![pathExtension isEqualToString:@"image"]) {
                                      downloadURL = url;
                                      break;
                                  }
                              }

                              if (currentImageModel.clipVideo != nil) {
                                  NSURL *videoURL = [currentImageModel.clipVideo.playURL getDYYYSrcURLDownload];
                                  [DYYYManager downloadLivePhoto:downloadURL
                                                        videoURL:videoURL
                                                      completion:^{
                                                      }];
                              } else if (currentImageModel && currentImageModel.urlList.count > 0) {
                                  if (downloadURL) {
                                      [DYYYManager downloadMedia:downloadURL
                                                       mediaType:MediaTypeImage
                                                           audio:nil
                                                      completion:^(BOOL success) {
                                                        if (success) {
                                                        } else {
                                                            [DYYYUtils showToast:@"图片保存已取消"];
                                                        }
                                                      }];
                                  } else {
                                      [DYYYUtils showToast:@"没有找到合适格式的图片"];
                                  }
                              }
                          } else if (isNewLivePhoto) {
                              // 新版实况照片
                              // 使用封面URL作为图片URL
                              NSURL *imageURL = nil;
                              if (videoModel.coverURL && videoModel.coverURL.originURLList.count > 0) {
                                  imageURL = [NSURL URLWithString:videoModel.coverURL.originURLList.firstObject];
                              }

                              // 视频URL从视频模型获取
                              NSURL *videoURL = nil;
                              if (videoModel && videoModel.playURL && videoModel.playURL.originURLList.count > 0) {
                                  videoURL = [NSURL URLWithString:videoModel.playURL.originURLList.firstObject];
                              } else if (videoModel && videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
                                  videoURL = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
                              }

                              // 下载实况照片
                              if (imageURL && videoURL) {
                                  [DYYYManager downloadLivePhoto:imageURL
                                                        videoURL:videoURL
                                                      completion:^{
                                                      }];
                              }
                          } else {
                              if (videoModel.h264URL && videoModel.h264URL.originURLList.count > 0) {
                                  NSURL *url = [NSURL URLWithString:videoModel.h264URL.originURLList.firstObject];
                                  [DYYYManager downloadMedia:url
                                                   mediaType:MediaTypeVideo
                                                       audio:audioURL
                                                  completion:^(BOOL success){
                                                  }];
                              }
                          }
                        }];
            [actions addObject:downloadAction];

            // 如果是图集，添加下载所有图片选项
            if (isImageContent && awemeModel.albumImages.count > 1) {
                // 检查是否有实况照片
                BOOL hasLivePhoto = NO;
                for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                    if (imageModel.clipVideo != nil) {
                        hasLivePhoto = YES;
                        break;
                    }
                }

                NSString *actionTitle = hasLivePhoto ? @"保存所有实况" : @"保存所有图片";

                AWEUserSheetAction *downloadAllAction = [NSClassFromString(@"AWEUserSheetAction")
                    actionWithTitle:actionTitle
                            imgName:nil
                            handler:^{
                              NSMutableArray *imageURLs = [NSMutableArray array];
                              NSMutableArray *livePhotos = [NSMutableArray array];

                              for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                                  if (imageModel.urlList.count > 0) {
                                      // 查找非.image后缀的URL
                                      NSURL *downloadURL = nil;
                                      for (NSString *urlString in imageModel.urlList) {
                                          NSURL *url = [NSURL URLWithString:urlString];
                                          NSString *pathExtension = [url.path.lowercaseString pathExtension];
                                          if (![pathExtension isEqualToString:@"image"]) {
                                              downloadURL = url;
                                              break;
                                          }
                                      }

                                      if (!downloadURL && imageModel.urlList.count > 0) {
                                          downloadURL = [NSURL URLWithString:imageModel.urlList.firstObject];
                                      }

                                      // 检查是否是实况照片
                                      if (imageModel.clipVideo != nil) {
                                          NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                                          [livePhotos addObject:@{@"imageURL" : downloadURL.absoluteString, @"videoURL" : videoURL.absoluteString}];
                                      } else {
                                          [imageURLs addObject:downloadURL.absoluteString];
                                      }
                                  }
                              }

                              // 分别处理普通图片和实况照片
                              if (livePhotos.count > 0) {
                                  [DYYYManager downloadAllLivePhotos:livePhotos];
                              }

                              if (imageURLs.count > 0) {
                                  [DYYYManager downloadAllImages:imageURLs];
                              }

                              if (livePhotos.count == 0 && imageURLs.count == 0) {
                                  [DYYYUtils showToast:@"没有找到合适格式的图片"];
                              }
                            }];
                [actions addObject:downloadAllAction];
            }
        }

        // 添加下载音频选项
        if (DYYYGetBool(@"DYYYDoubleTapDownloadAudio") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapDownloadAudio"]) {
            AWEUserSheetAction *downloadAudioAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"保存音频"
                                                                                                        imgName:nil
                                                                                                        handler:^{
                                                                                                          if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
                                                                                                              NSURL *url = [NSURL URLWithString:musicModel.playURL.originURLList.firstObject];
                                                                                                              [DYYYManager downloadMedia:url mediaType:MediaTypeAudio audio:nil completion:nil];
                                                                                                          }
                                                                                                        }];
            [actions addObject:downloadAudioAction];
        }

        // 添加接口保存选项
        if (DYYYGetBool(@"DYYYDoubleInterfaceDownload")) {
            NSString *apiKey = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
            if (apiKey.length > 0) {
                AWEUserSheetAction *apiDownloadAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"接口保存"
                                                                                                          imgName:nil
                                                                                                          handler:^{
                                                                                                            NSString *shareLink = [awemeModel valueForKey:@"shareURL"];
                                                                                                            if (shareLink.length == 0) {
                                                                                                                [DYYYUtils showToast:@"无法获取分享链接"];
                                                                                                                return;
                                                                                                            }

                                                                                                            // 使用封装的方法进行解析下载
                                                                                                            [DYYYManager parseAndDownloadVideoWithShareLink:shareLink apiKey:apiKey];
                                                                                                          }];
                [actions addObject:apiDownloadAction];
            }
        }

        // 添加制作视频功能
        if (DYYYGetBool(@"DYYYDoubleCreateVideo") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleCreateVideo"]) {
            if (isImageContent) {
                AWEUserSheetAction *createVideoAction = [NSClassFromString(@"AWEUserSheetAction")
                    actionWithTitle:@"制作视频"
                            imgName:nil
                            handler:^{
                              // 收集普通图片URL
                              NSMutableArray *imageURLs = [NSMutableArray array];
                              // 收集实况照片信息（图片URL+视频URL）
                              NSMutableArray *livePhotos = [NSMutableArray array];

                              // 获取背景音乐URL
                              NSString *bgmURL = nil;
                              if (musicModel && musicModel.playURL && musicModel.playURL.originURLList.count > 0) {
                                  bgmURL = musicModel.playURL.originURLList.firstObject;
                              }

                              // 处理所有图片和实况
                              for (AWEImageAlbumImageModel *imageModel in awemeModel.albumImages) {
                                  if (imageModel.urlList.count > 0) {
                                      // 查找非.image后缀的URL
                                      NSString *bestURL = nil;
                                      for (NSString *urlString in imageModel.urlList) {
                                          NSURL *url = [NSURL URLWithString:urlString];
                                          NSString *pathExtension = [url.path.lowercaseString pathExtension];
                                          if (![pathExtension isEqualToString:@"image"]) {
                                              bestURL = urlString;
                                              break;
                                          }
                                      }

                                      if (!bestURL && imageModel.urlList.count > 0) {
                                          bestURL = imageModel.urlList.firstObject;
                                      }

                                      // 如果是实况照片，需要收集图片和视频URL
                                      if (imageModel.clipVideo != nil) {
                                          NSURL *videoURL = [imageModel.clipVideo.playURL getDYYYSrcURLDownload];
                                          if (videoURL) {
                                              [livePhotos addObject:@{@"imageURL" : bestURL, @"videoURL" : videoURL.absoluteString}];
                                          }
                                      } else {
                                          // 普通图片
                                          [imageURLs addObject:bestURL];
                                      }
                                  }
                              }

                              // 调用视频创建API
                              [DYYYManager createVideoFromMedia:imageURLs
                                  livePhotos:livePhotos
                                  bgmURL:bgmURL
                                  progress:^(NSInteger current, NSInteger total, NSString *status) {
                                  }
                                  completion:^(BOOL success, NSString *message) {
                                    if (success) {
                                    } else {
                                        [DYYYUtils showToast:[NSString stringWithFormat:@"视频制作失败: %@", message]];
                                    }
                                  }];
                            }];
                [actions addObject:createVideoAction];
            }
        }

        // 添加复制文案选项
        if (DYYYGetBool(@"DYYYDoubleTapCopyDesc") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapCopyDesc"]) {
            AWEUserSheetAction *copyTextAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"复制文案"
                                                                                                   imgName:nil
                                                                                                   handler:^{
                                                                                                     NSString *descText = [awemeModel valueForKey:@"descriptionString"];
                                                                                                     [[UIPasteboard generalPasteboard] setString:descText];
                                                                                                     [DYYYToast showSuccessToastWithMessage:@"文案已复制"];
                                                                                                   }];
            [actions addObject:copyTextAction];
        }

        // 添加打开评论区选项
        if (DYYYGetBool(@"DYYYDoubleTapComment") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapComment"]) {
            AWEUserSheetAction *openCommentAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"打开评论"
                                                                                                      imgName:nil
                                                                                                      handler:^{
                                                                                                        [self performCommentAction];
                                                                                                      }];
            [actions addObject:openCommentAction];
        }

        // 添加分享选项
        if (DYYYGetBool(@"DYYYDoubleTapshowSharePanel") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapshowSharePanel"]) {
            AWEUserSheetAction *showSharePanel = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"分享视频"
                                                                                                   imgName:nil
                                                                                                   handler:^{
                                                                                                     [self showSharePanel];
                                                                                                   }];
            [actions addObject:showSharePanel];
        }

        // 添加点赞视频选项
        if (DYYYGetBool(@"DYYYDoubleTapLike") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapLike"]) {
            AWEUserSheetAction *likeAction = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"点赞视频"
                                                                                               imgName:nil
                                                                                               handler:^{
                                                                                                 [self performLikeAction];
                                                                                               }];
            [actions addObject:likeAction];
        }

        // 添加长按面板
        if (DYYYGetBool(@"DYYYDoubleTapshowDislikeOnVideo") || ![[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDoubleTapshowDislikeOnVideo"]) {
            AWEUserSheetAction *showDislikeOnVideo = [NSClassFromString(@"AWEUserSheetAction") actionWithTitle:@"长按面板"
                                                                                                       imgName:nil
                                                                                                       handler:^{
                                                                                                         [self showDislikeOnVideo];
                                                                                                       }];
            [actions addObject:showDislikeOnVideo];
        }

        // 显示操作表
        [actionSheet setActions:actions];
        [actionSheet show];

        return;
    }

    // 默认行为
    %orig;
}

%end

static void DYYYUpdateManagedPrivacyHalfScreenAppearance(AFDPrivacyHalfScreenViewController *viewController) {
    BOOL isDarkMode = [DYYYUtils isDarkMode];

    UIView *contentView = viewController.view.subviews.count > 1 ? viewController.view.subviews[1] : nil;
    if (contentView) {
        if (isDarkMode) {
            contentView.backgroundColor = [UIColor colorWithRed:0.13 green:0.13 blue:0.13 alpha:1.0];
        } else {
            contentView.backgroundColor = [UIColor whiteColor];
        }
    }

    // 修改标题文本颜色
    if (viewController.titleLabel) {
        if (isDarkMode) {
            viewController.titleLabel.textColor = [UIColor whiteColor];
        } else {
            viewController.titleLabel.textColor = [UIColor blackColor];
        }
    }

    // 修改内容文本颜色
    if (viewController.contentLabel) {
        if (isDarkMode) {
            viewController.contentLabel.textColor = [UIColor lightGrayColor];
        } else {
            viewController.contentLabel.textColor = [UIColor darkGrayColor];
        }
    }

    // 修改左侧按钮颜色和文字颜色
    if (viewController.leftCancelButton) {
        if (isDarkMode) {
            [viewController.leftCancelButton setBackgroundColor:[UIColor colorWithRed:0.25 green:0.25 blue:0.25 alpha:1.0]];
            [viewController.leftCancelButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        } else {
            [viewController.leftCancelButton setBackgroundColor:[UIColor colorWithRed:0.9 green:0.9 blue:0.9 alpha:1.0]];
            [viewController.leftCancelButton setTitleColor:[UIColor darkTextColor] forState:UIControlStateNormal];
        }
    }
}

%hook AFDPrivacyHalfScreenViewController

- (void)viewDidLoad {
    %orig;
    if ([DYYYBottomAlertView isManagedHalfScreenViewController:self]) {
        DYYYUpdateManagedPrivacyHalfScreenAppearance(self);
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    if ([DYYYBottomAlertView isManagedHalfScreenViewController:self]) {
        DYYYUpdateManagedPrivacyHalfScreenAppearance(self);
    }
}

- (void)configWithImageView:(UIImageView *)imageView
                  lockImage:(UIImage *)lockImage
           defaultLockState:(BOOL)defaultLockState
             titleLabelText:(NSString *)titleText
           contentLabelText:(NSString *)contentText
       leftCancelButtonText:(NSString *)leftButtonText
     rightConfirmButtonText:(NSString *)rightButtonText
       rightBtnClickedBlock:(void (^)(void))rightBtnBlock
     leftButtonClickedBlock:(void (^)(void))leftBtnBlock {
    %orig;
    if ([DYYYBottomAlertView isManagedHalfScreenViewController:self]) {
        DYYYUpdateManagedPrivacyHalfScreenAppearance(self);
    }
}

%end

%hook UITextField

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;

    if (newWindow) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    }
}

- (BOOL)becomeFirstResponder {
    BOOL isDarkMode = [DYYYUtils isDarkMode];
    self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    return %orig;
}

%end

%hook UITextView

- (void)willMoveToWindow:(UIWindow *)newWindow {
    %orig;

    if (newWindow) {
        BOOL isDarkMode = [DYYYUtils isDarkMode];
        self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    }
}

- (BOOL)becomeFirstResponder {
    BOOL isDarkMode = [DYYYUtils isDarkMode];
    self.keyboardAppearance = isDarkMode ? UIKeyboardAppearanceDark : UIKeyboardAppearanceLight;
    return %orig;
}

%end

static void DYYYHidePlusButtonOverlayView(id overlay) {
    if (![overlay isKindOfClass:[UIView class]]) {
        return;
    }
    UIView *overlayView = (UIView *)overlay;
    overlayView.userInteractionEnabled = NO;
    overlayView.hidden = YES;
    overlayView.alpha = 0;
}

static void DYYYHidePlusButtonOverlays(UIView *plusButton) {
    if (![plusButton isKindOfClass:[UIView class]]) {
        return;
    }
    plusButton.userInteractionEnabled = NO;
    plusButton.hidden = YES;

    static const SEL overlaySelectors[] = {
        @selector(animationImageView),
        @selector(specialContentAnimationView),
        @selector(plusBubble),
        @selector(studioBubble),
    };
    for (size_t index = 0; index < sizeof(overlaySelectors) / sizeof(overlaySelectors[0]); index++) {
        SEL selector = overlaySelectors[index];
        if (![plusButton respondsToSelector:selector]) {
            continue;
        }
        DYYYHidePlusButtonOverlayView(((id (*)(id, SEL))objc_msgSend)(plusButton, selector));
    }
}

static void DYYYLogHidePlusOverlayOnce(NSString *target) {
    static NSMutableSet<NSString *> *logged = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      logged = [NSMutableSet set];
    });
    if (target.length == 0) {
        return;
    }
    @synchronized(logged) {
        if ([logged containsObject:target]) {
            return;
        }
        [logged addObject:target];
    }
    NSLog(@"[DYYY][HidePlusButton] overlay-skip %@", target);
}

// 底栏高度
%hook AWENormalModeTabBarPlusButton

- (void)setHidden:(BOOL)hidden {
    BOOL hidePlus = DYYYGetBool(@"DYYYHidePlusButton");
    %orig(hidePlus ? YES : hidden);

    if (hidePlus) {
        DYYYHidePlusButtonOverlays(self);
    }
}

- (void)didMoveToWindow {
    %orig;

    if (self.window && DYYYGetBool(@"DYYYHidePlusButton")) {
        DYYYHidePlusButtonOverlays(self);
    }
}

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBoolCached(@"DYYYHidePlusButton")) {
        DYYYHidePlusButtonOverlays(self);
    }
}

%end

%group DYYYHidePlusButtonStickerOverlay

%hook AWENormalModeTabBarPlusButton

- (void)addStickerImageViewAnimationView {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        DYYYLogHidePlusOverlayOnce(@"addStickerImageViewAnimationView");
        return;
    }
    %orig;
}

- (BOOL)canShowSpecialPlusBigAnimation {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        return NO;
    }
    return %orig;
}

- (BOOL)couldShowPlusBubble {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        return NO;
    }
    return %orig;
}

- (void)begainShowPlusAddImage {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        DYYYLogHidePlusOverlayOnce(@"begainShowPlusAddImage");
        return;
    }
    %orig;
}

- (void)__showBubbleWithCustomView:(id)view duration:(NSTimeInterval)duration completion:(id)completion {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        DYYYLogHidePlusOverlayOnce(@"__showBubbleWithCustomView");
        return;
    }
    %orig;
}

%end

%end

%group DYYYHidePlusButtonSpecialPlusManager

%hook AWEStudioSpecialPlusManager

+ (BOOL)shouldShowStudioSpecialPlusIconWithAwemeModel:(id)model {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        return NO;
    }
    return %orig;
}

+ (BOOL)shouldContinueCheckShowSpecialPlusButton {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        return NO;
    }
    return %orig;
}

%end

%end

%group DYYYHidePlusButtonBigAnimation

%hook AWEStudioSpecialPlusBigAnimationManager

- (BOOL)enableShowSpecialPlusBigAnimation {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        return NO;
    }
    return %orig;
}

%end

%end

%group DYYYHidePlusButtonInnerBubble

%hook AWENormalModeTabBarGeneralPlusInnerButton

- (void)showBubbleWithText:(id)text {
    if (DYYYGetBool(@"DYYYHidePlusButton")) {
        DYYYLogHidePlusOverlayOnce(@"showBubbleWithText:");
        return;
    }
    %orig;
}

%end

%end

%hook AWENormalModeTabBar

static Class barBackgroundClass = nil;
static Class generalButtonClass = nil;
static Class plusContainerButtonClass = nil;
static Class plusButtonClass = nil;
static Class plusInnerButtonClass = nil;
static Class tabBarButtonClass = nil;
+ (void)initialize {
    if (self == [%c(AWENormalModeTabBar) class]) {
        barBackgroundClass = NSClassFromString(@"_UIBarBackground");
        generalButtonClass = %c(AWENormalModeTabBarGeneralButton);
        plusContainerButtonClass = %c(AWENormalModeTabBarPlusButton);
        plusButtonClass = %c(AWENormalModeTabBarGeneralPlusButton);
        plusInnerButtonClass = %c(AWENormalModeTabBarGeneralPlusInnerButton);
        tabBarButtonClass = %c(UITabBarButton);
    }
}

%new
- (void)initializeOriginalTabBarHeight {
    if (originalTabBarHeight != kInvalidHeight) {
        if (gCurrentTabBarHeight == kInvalidHeight) {
            gCurrentTabBarHeight = originalTabBarHeight;
        }
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Skipped! originalTabBarHeight already initialized as %.1f.", originalTabBarHeight);
        return;
    }

    UIWindow *targetWindow = self.window ?: [DYYYUtils getActiveWindow];
    if (self.frame.size.height >= 30) {
        originalTabBarHeight = self.frame.size.height;
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Success! originalTabBarHeight set to %.1f (from self.frame.size.height)", originalTabBarHeight);
    } else if (targetWindow) {
        CGFloat bottomInset = targetWindow.safeAreaInsets.bottom;
        originalTabBarHeight = 49 + bottomInset;
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Success! originalTabBarHeight set to %.1f (fallback calculation: 49.0 + %.1f)", originalTabBarHeight, bottomInset);
    } else {
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: Failed! No window available.");
    }
    if (originalTabBarHeight != kInvalidHeight) {
        gCurrentTabBarHeight = originalTabBarHeight;
        NSLog(@"[DYYY] initializeOriginalTabBarHeight: gCurrentTabBarHeight synced to %.1f.", gCurrentTabBarHeight);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self initializeOriginalTabBarHeight];
    }
}

- (void)layoutSubviews {
    %orig;

    if (originalTabBarHeight == kInvalidHeight) {
        NSLog(@"[DYYY] layoutSubviews: Fallback! originalTabBarHeight initialization triggered.");
        [self initializeOriginalTabBarHeight];
    }

    if (gCurrentTabBarHeight == kInvalidHeight) {
        gCurrentTabBarHeight = originalTabBarHeight;
        NSLog(@"[DYYY] layoutSubviews: gCurrentTabBarHeight fallback synced to %.1f.", gCurrentTabBarHeight);
    }

    BOOL hideShop = DYYYGetBool(@"DYYYHideShopButton");
    BOOL hideMsg = DYYYGetBool(@"DYYYHideMessageButton");
    BOOL hideFri = DYYYGetBool(@"DYYYHideFriendsButton");
    BOOL hideMe = DYYYGetBool(@"DYYYHideMyButton");
    BOOL hidePlus = DYYYGetBool(@"DYYYHidePlusButton");
    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);

    NSMutableArray *visibleButtons = [NSMutableArray array];
    UIView *ipadContainerView = nil;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:generalButtonClass] || [subview isKindOfClass:plusContainerButtonClass] || [subview isKindOfClass:plusButtonClass] ||
            [subview isKindOfClass:plusInnerButtonClass]) {
            NSString *label = subview.accessibilityLabel;
            BOOL isPlusButton = [subview isKindOfClass:plusContainerButtonClass] || [subview isKindOfClass:plusButtonClass] || [subview isKindOfClass:plusInnerButtonClass] ||
                                [label isEqualToString:@"拍摄"];
            BOOL shouldHide = (isPlusButton && hidePlus) || ([label containsString:@"商城"] && hideShop) || ([label containsString:@"消息"] && hideMsg) || ([label containsString:@"朋友"] && hideFri) ||
                              ([label isEqualToString:@"我"] && hideMe);

            subview.userInteractionEnabled = !shouldHide;
            subview.hidden = shouldHide;

            if (!shouldHide) {
                [visibleButtons addObject:subview];
            }
        } else if ([subview isKindOfClass:tabBarButtonClass]) {
            subview.userInteractionEnabled = NO;
            subview.hidden = YES;
        } else if (isPad && !ipadContainerView && [subview isMemberOfClass:UIView.class] && fabs(subview.frame.size.width - self.bounds.size.width) > 0.1) {
            ipadContainerView = subview;
        }
    }

    [visibleButtons sortUsingComparator:^NSComparisonResult(UIView *a, UIView *b) {
      return [@(a.frame.origin.x) compare:@(b.frame.origin.x)];
    }];

    CGFloat offsetX, totalWidth;
    if (ipadContainerView) {
        offsetX = ipadContainerView.frame.origin.x;
        totalWidth = ipadContainerView.bounds.size.width;
    } else {
        offsetX = 0;
        totalWidth = self.bounds.size.width;
    }
    CGFloat buttonWidth = (visibleButtons.count > 0) ? (totalWidth / visibleButtons.count) : 0;

    // 均匀布局按钮
    for (NSInteger i = 0; i < visibleButtons.count; i++) {
        UIView *button = visibleButtons[i];
        button.frame = CGRectMake(offsetX + i * buttonWidth, button.frame.origin.y, buttonWidth, button.frame.size.height);
    }

    // 禁用首页刷新功能
    if (DYYYGetBool(@"DYYYDisableHomeRefresh")) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:generalButtonClass]) {
                AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;
                if ([button.accessibilityLabel isEqualToString:@"首页"]) {
                    // status == 2 表示选中状态
                    button.userInteractionEnabled = (button.status != 2);
                }
            }
        }
    }

    // 背景和分隔线处理
    BOOL hideBottomBg = DYYYGetBool(@"DYYYHideBottomBg");
    BOOL enableFullScreen = DYYYGetBool(@"DYYYEnableFullScreen");

    if (hideBottomBg || enableFullScreen) {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = YES;
        }

        BOOL isHomeSelected = NO;
        BOOL isFriendsSelected = NO;

        if (enableFullScreen && !hideBottomBg) {
            for (UIView *subview in self.subviews) {
                if ([subview isKindOfClass:generalButtonClass]) {
                    AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;
                    if (button.status == 2) {
                        if ([button.accessibilityLabel isEqualToString:@"首页"])
                            isHomeSelected = YES;
                        else if ([button.accessibilityLabel containsString:@"朋友"])
                            isFriendsSelected = YES;
                    }
                }
            }
        }

        BOOL hideFriendsButton = DYYYGetBool(@"DYYYHideFriendsButton");
        BOOL shouldHideBackgrounds = hideBottomBg || (enableFullScreen && (isHomeSelected || (isFriendsSelected && !hideFriendsButton)));

        // 单次遍历处理所有背景和分割线
        for (UIView *subview in self.subviews) {
            // 跳过底栏按钮
            if ([subview isKindOfClass:generalButtonClass] || [subview isKindOfClass:plusContainerButtonClass] || [subview isKindOfClass:plusButtonClass] ||
                [subview isKindOfClass:plusInnerButtonClass]) {
                continue;
            }
            // 隐藏底栏背景
            if ([subview isKindOfClass:barBackgroundClass] || ([subview isMemberOfClass:[UIView class]] && originalTabBarHeight > 0 && fabs(subview.frame.size.height - gCurrentTabBarHeight) < 0.1)) {
                subview.hidden = shouldHideBackgrounds;
            }
            // 隐藏细分割线
            if (subview.frame.size.height > 0 && subview.frame.size.height < 1 && subview.frame.size.width > 300) {
                subview.hidden = enableFullScreen;
            }
        }
    } else {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = NO;
        }

        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:barBackgroundClass] || [subview isMemberOfClass:[UIView class]]) {
                subview.hidden = NO;
            }
        }
    }
}

- (void)setHidden:(BOOL)hidden {
    %orig(hidden);

    BOOL disableHomeRefresh = DYYYGetBool(@"DYYYDisableHomeRefresh");
    BOOL enableFullScreen = DYYYGetBool(@"DYYYEnableFullScreen");
    BOOL hideBottomBg = DYYYGetBool(@"DYYYHideBottomBg");
    BOOL hideFriendsButton = DYYYGetBool(@"DYYYHideFriendsButton");

    BOOL isHomeSelected = NO;
    BOOL isFriendsSelected = NO;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:generalButtonClass]) {
            AWENormalModeTabBarGeneralButton *button = (AWENormalModeTabBarGeneralButton *)subview;

            // 禁用首页刷新功能
            if (disableHomeRefresh && [button.accessibilityLabel isEqualToString:@"首页"]) {
                button.userInteractionEnabled = (button.status != 2);
            }

            // 检查当前选中的页
            if (enableFullScreen && button.status == 2) {
                if ([button.accessibilityLabel isEqualToString:@"首页"]) {
                    isHomeSelected = YES;
                } else if ([button.accessibilityLabel containsString:@"朋友"]) {
                    isFriendsSelected = YES;
                }
            }
        }
    }

    if (hideBottomBg || enableFullScreen) {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = YES;
        }

        BOOL shouldHideBackgrounds = NO;
        if (hideBottomBg) {
            shouldHideBackgrounds = YES;
        } else if (enableFullScreen) {
            shouldHideBackgrounds = isHomeSelected || (isFriendsSelected && !hideFriendsButton);
        }

        // 处理所有背景和分割线
        for (UIView *subview in self.subviews) {
            CGFloat subviewHeight = subview.frame.size.height;
            // 跳过底栏按钮
            if ([subview isKindOfClass:generalButtonClass] || [subview isKindOfClass:plusContainerButtonClass] || [subview isKindOfClass:plusButtonClass] ||
                [subview isKindOfClass:plusInnerButtonClass]) {
                continue;
            }
            // 隐藏底栏背景
            if ([subview isKindOfClass:barBackgroundClass] || ([subview isMemberOfClass:[UIView class]] && originalTabBarHeight > 0 && fabs(subviewHeight - gCurrentTabBarHeight) < 0.1)) {
                subview.hidden = shouldHideBackgrounds;
            }
            // 隐藏细分割线
            if (subviewHeight > 0 && subviewHeight < 1 && subview.frame.size.width > 300) {
                subview.hidden = enableFullScreen;
            }
        }
    } else {
        if (self.skinContainerView) {
            self.skinContainerView.hidden = NO;
        }
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:barBackgroundClass] || [subview isMemberOfClass:[UIView class]]) {
                subview.hidden = NO;
            }
        }
    }
}

%end

// 精简平板底栏
%hook AWETabBarElementContainerView

- (void)setHidden:(BOOL)hidden {
    if (DYYYGetBool(@"DYYYHidePadTabBarElements")) {
        %orig(YES);
        return;
    }

    %orig(hidden);
}

%end

%hook AWENormalModeTabBarBadgeContainerView

- (void)layoutSubviews {
    %orig;
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideBottomDot"]) {
        return;
    }

    static char kDYBadgeCacheKey;
    NSArray *badges = objc_getAssociatedObject(self, &kDYBadgeCacheKey);
    if (!badges) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIView *subview in [self subviews]) {
            if ([subview isKindOfClass:NSClassFromString(@"DUXBadge")]) {
                [tmp addObject:subview];
            }
        }
        badges = [tmp copy];
        objc_setAssociatedObject(self, &kDYBadgeCacheKey, badges, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *badge in badges) {
        badge.hidden = YES;
    }
}

%end

// 禁用点击首页刷新
%hook AWENormalModeTabBarGeneralButton

- (BOOL)enableRefresh {
    if ([self.accessibilityLabel isEqualToString:@"首页"]) {
        if (DYYYGetBool(@"DYYYDisableHomeRefresh")) {
            return NO;
        }
    }
    return %orig;
}

%end

%hook AWENormalModeTabBarTextView

- (void)layoutSubviews {
    @try {
        %orig;

        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self layoutSubviews];
            });
            return;
        }

        if (!self || !self.superview) {
            return;
        }

        NSString *indexTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYIndexTitle"];
        NSString *friendsTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFriendsTitle"];
        NSString *msgTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYMsgTitle"];
        NSString *selfTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSelfTitle"];

        if (!(indexTitle.length || friendsTitle.length || msgTitle.length || selfTitle.length)) {
            return;
        }

        static char kDYTabTextLabelCacheKey;
        NSArray *labelCache = objc_getAssociatedObject(self, &kDYTabTextLabelCacheKey);
        if (!labelCache) {
            NSMutableArray *tmp = [NSMutableArray array];
            if (!tmp) {
                return;
            }

            NSArray *subviews = [self subviews];
            if (!subviews) {
                return;
            }

            for (UIView *subview in subviews) {
                if (subview && [subview isKindOfClass:[UILabel class]]) {
                    [tmp addObject:subview];
                }
            }

            labelCache = [tmp copy];
            if (labelCache) {
                objc_setAssociatedObject(self, &kDYTabTextLabelCacheKey, labelCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }

        if (!labelCache) {
            return;
        }

        for (UILabel *label in labelCache) {
            if (!label || ![label isKindOfClass:[UILabel class]]) {
                continue;
            }

            NSString *labelText = label.text;
            if (!labelText) {
                continue;
            }

            if ([labelText isEqualToString:@"首页"] && indexTitle.length > 0) {
                label.text = indexTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            } else if ([labelText isEqualToString:@"朋友"] && friendsTitle.length > 0) {
                label.text = friendsTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            } else if ([labelText isEqualToString:@"消息"] && msgTitle.length > 0) {
                label.text = msgTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            } else if ([labelText isEqualToString:@"我"] && selfTitle.length > 0) {
                label.text = selfTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            }
        }
    } @catch (NSException *exception) {
        return;
    }
}
%end

%hook AWENormalModeTabBarFeedView

- (void)layoutSubviews {
    @try {
        %orig;
        if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYHideDoubleColumnEntry"]) {
            return;
        }

        static char kDYDoubleColumnCacheKey;
        static char kDYDoubleColumnCountKey;
        NSArray *cachedViews = objc_getAssociatedObject(self, &kDYDoubleColumnCacheKey);
        NSNumber *cachedCount = objc_getAssociatedObject(self, &kDYDoubleColumnCountKey);
        if (!cachedViews || cachedCount.unsignedIntegerValue != self.subviews.count) {
            NSMutableArray *views = [NSMutableArray array];
            for (UIView *subview in self.subviews) {
                if (![subview isKindOfClass:[UILabel class]]) {
                    [views addObject:subview];
                }
            }
            cachedViews = [views copy];
            objc_setAssociatedObject(self, &kDYDoubleColumnCacheKey, cachedViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &kDYDoubleColumnCountKey, @(self.subviews.count), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }

        for (UIView *v in cachedViews) {
            v.hidden = YES;
        }

        if (![NSThread isMainThread]) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [self layoutSubviews];
            });
            return;
        }

        if (!self || !self.superview) {
            return;
        }

        NSString *indexTitle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYIndexTitle"];

        if (!(indexTitle.length)) {
            return;
        }

        static char kDYTabFeedLabelCacheKey;
        NSArray *labelCache = objc_getAssociatedObject(self, &kDYTabFeedLabelCacheKey);
        if (!labelCache) {
            NSMutableArray *tmp = [NSMutableArray array];
            if (!tmp) {
                return;
            }

            NSArray *subviews = [self subviews];
            if (!subviews) {
                return;
            }

            for (UIView *subview in subviews) {
                if (subview && [subview isKindOfClass:[UILabel class]]) {
                    [tmp addObject:subview];
                }
            }

            labelCache = [tmp copy];
            if (labelCache) {
                objc_setAssociatedObject(self, &kDYTabFeedLabelCacheKey, labelCache, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
        }

        if (!labelCache) {
            return;
        }

        for (UILabel *label in labelCache) {
            if (!label || ![label isKindOfClass:[UILabel class]]) {
                continue;
            }

            NSString *labelText = label.text;
            if (!labelText) {
                continue;
            }

            if ([labelText isEqualToString:@"首页"] && indexTitle.length > 0) {
                label.text = indexTitle;
                dispatch_async(dispatch_get_main_queue(), ^{
                  [self setNeedsLayout];
                });
            }
        }
    } @catch (NSException *exception) {
        return;
    }
}
%end

%hook AWEConcernCellLastView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen") && gCurrentTabBarHeight > 0) {
        for (UIView *subview in self.subviews) {
            CGRect frame = subview.frame;
            frame.origin.y -= gCurrentTabBarHeight;
            subview.frame = frame;
        }
    }
}
%end

%hook AWECommentInputBackgroundView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideComment")) {
        [self removeFromSuperview];
        return;
    }

    CGAffineTransform newTransform = CGAffineTransformMakeTranslation(0, originalTabBarHeight - gCurrentTabBarHeight);

    if (!CGAffineTransformEqualToTransform(self.transform, newTransform)) {
        self.transform = newTransform;
    }
}
%end

%hook AWECommentMediaFeedParams

- (BOOL (^)(void))panelVideoHasPausedByComment {
    BOOL (^originalBlock)(void) = %orig;
    if (!DYYYCommentPauseOwnsPlayback()) {
        return originalBlock;
    }

    return ^BOOL {
      if (DYYYCommentPauseOwnsPlayback()) {
          return YES;
      }
      return originalBlock ? originalBlock() : NO;
    };
}

- (BOOL (^)(void))fullPanelShouldPreventPlay {
    BOOL (^originalBlock)(void) = %orig;
    if (!DYYYCommentPauseOwnsPlayback()) {
        return originalBlock;
    }

    return ^BOOL {
      if (DYYYCommentPauseOwnsPlayback()) {
          return YES;
      }
      return originalBlock ? originalBlock() : NO;
    };
}

%end

%hook _TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel

- (instancetype)init {
    id viewModel = %orig;
    DYYYRegisterCommentPauseViewModel(viewModel);
    return viewModel;
}

- (void)setTabManager:(id)tabManager {
    %orig(tabManager);
    DYYYRegisterCommentPauseViewModel(self);
    if (dyyyCommentViewVisible && DYYYGetBool(@"DYYYCommentPausePlayback")) {
        dispatch_async(dispatch_get_main_queue(), ^{
          DYYYCommentPausePlaybackIfNeeded();
        });
    }
}

%end

%hook AWECommentContainerViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig(animated);
    dyyyCommentViewVisible = YES;
    updateSpeedButtonVisibility();
    DYYYCommentPausePlaybackIfNeeded();
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    dyyyCommentViewVisible = YES;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
    DYYYCommentPausePlaybackIfNeeded();
    NSString *transparentValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYTopBarTransparent"];
    if (transparentValue && transparentValue.length > 0) {
        CGFloat alphaValue = [transparentValue floatValue];
        if (alphaValue >= 0.0 && alphaValue <= 1.0) {
            UIView *parentView = self.view.superview;
            if (parentView) {
                for (UIView *subview in parentView.subviews) {
                    if ([subview.accessibilityLabel isEqualToString:@"搜索"]) {
                        CGFloat finalAlpha = (alphaValue < 0.011) ? 0.011 : alphaValue;
                        subview.alpha = finalAlpha;
                    }
                }
            }
        }
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    BOOL skipsPanelLifecycle = DYYYCommentContainerSkipsPanelLifecycle(self);
    _TtC33AWECommentPanelContainerSwiftImpl30CommentContainerInnerViewModel *pausedViewModel = dyyyLastCommentPauseViewModel;
    %orig;

    // Comment media preview temporarily drives this lifecycle callback while
    // the comment panel is still active. Mirror the host's lifecycle gate so
    // opening an image cannot release the comment-owned playback pause.
    if (skipsPanelLifecycle) {
        dyyyCommentViewVisible = YES;
        updateSpeedButtonVisibility();
        updateClearButtonVisibility();
        return;
    }

    dyyyCommentViewVisible = NO;
    updateSpeedButtonVisibility();
    updateClearButtonVisibility();
    DYYYCommentRecoverPlaybackIfNeeded(pausedViewModel);
}

- (void)viewDidLayoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYEnableCommentBlur"))
        return;

    Class containerViewClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputContainerView");
    NSArray<UIView *> *containerViews = [DYYYUtils findAllSubviewsOfClass:containerViewClass inContainer:self.view];
    for (UIView *containerView in containerViews) {
        for (UIView *subview in containerView.subviews) {
            if (subview.hidden == NO && subview.backgroundColor && CGColorGetAlpha(subview.backgroundColor.CGColor) == 1) {
                float userTransparency = [[[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYCommentBlurTransparent"] floatValue];
                if (userTransparency <= 0 || userTransparency > 1) {
                    userTransparency = 0.8;
                }
                [DYYYUtils applyBlurEffectToView:subview transparency:userTransparency blurViewTag:999];
            }
        }
    }

    Class middleContainerClass = NSClassFromString(@"AWECommentInputViewSwiftImpl.CommentInputViewMiddleContainer");
    NSArray<UIView *> *middleContainers = [DYYYUtils findAllSubviewsOfClass:middleContainerClass inContainer:self.view];
    for (UIView *middleContainer in middleContainers) {
        BOOL containsDanmu = NO;
        for (UIView *innerSubviewCheck in middleContainer.subviews) {
            if ([innerSubviewCheck isKindOfClass:[UILabel class]] && [((UILabel *)innerSubviewCheck).text containsString:@"弹幕"]) {
                containsDanmu = YES;
                break;
            }
        }

        if (containsDanmu) {
            UIView *parentView = middleContainer.superview;
            for (UIView *innerSubview in parentView.subviews) {
                if ([innerSubview isKindOfClass:[UIView class]]) {
                    if (innerSubview.subviews.count > 0) {
                        innerSubview.subviews[0].hidden = YES;
                    }

                    UIView *whiteBackgroundView = [[UIView alloc] initWithFrame:innerSubview.bounds];
                    whiteBackgroundView.backgroundColor = [UIColor whiteColor];
                    whiteBackgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
                    [innerSubview addSubview:whiteBackgroundView];
                    break;
                }
            }
        } else {
            for (UIView *subview in middleContainer.subviews) {
                if (subview.hidden == NO && subview.backgroundColor && CGColorGetAlpha(subview.backgroundColor.CGColor) == 1) {
                    [DYYYUtils applyBlurEffectToView:subview transparency:0.2f blurViewTag:999];
                }
            }
        }
    }
}

%end

// 开启评论区毛玻璃后滚动区域填满底部
%hook AWEListKitMagicCollectionView

- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYEnableCommentBlur")) {
        return;
    }

    UICollectionView *collectionView = (UICollectionView *)self;

    UIView *superview = collectionView.superview;
    CGRect targetFrame = superview.bounds;
    if (superview == nil || CGSizeEqualToSize(targetFrame.size, CGSizeZero) || CGRectEqualToRect(collectionView.frame, targetFrame)) {
        return;
    }

    collectionView.frame = targetFrame;

    CGFloat commentOffset = 166.0;

    UIEdgeInsets inset = collectionView.contentInset;
    inset.bottom = commentOffset;
    collectionView.contentInset = inset;
    collectionView.scrollIndicatorInsets = inset;
}

%end

%hook UIView

- (void)setHidden:(BOOL)hidden {
    BOOL shouldForceHidden = DYYYShouldForceAvatarActionViewHidden(self) ||
                             DYYYShouldForceAvatarSurroundingViewHidden(self) ||
                             DYYYShouldForceHideFeedVideoCollectButtonView(self);
    %orig(shouldForceHidden ? YES : hidden);
}

- (void)didAddSubview:(UIView *)subview {
    %orig(subview);

    if (!subview) {
        return;
    }

    if (DYYYShouldForceHideFeedVideoCollectButtonView(self)) {
        DYYYMarkFeedVideoCollectButtonViewHidden(subview);
    }

    BOOL hasSuppressedChrome = objc_getAssociatedObject(self, &kDYYYAvatarActionChromeViewKey) != nil;
    BOOL isAvatarFollowScope = objc_getAssociatedObject(self, &kDYYYAvatarFollowScopeViewKey) != nil;
    if ((!hasSuppressedChrome && !isAvatarFollowScope) || !DYYYAvatarFollowOptionsEnabled()) {
        return;
    }

    if (hasSuppressedChrome) {
        DYYYClearAvatarActionSubviewChrome(subview);
        DYYYHideAvatarAuxiliaryActionVisualsInView(subview);
    }

    if (isAvatarFollowScope) {
        DYYYApplyAvatarFollowSettingsInView(subview, self);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (!hideButton || !hideButton.isElementsHidden || DYYYShouldExemptClearTargetView(self)) {
        DYYYRestoreClearTargetViewStateIfNeeded(self);
    }
}

- (id)initWithFrame:(CGRect)frame {
    UIView *view = %orig;
    if (hideButton && hideButton.isElementsHidden) {
        for (NSString *className in targetClassNames) {
            if ([view isKindOfClass:NSClassFromString(className)]) {
                if ([view isKindOfClass:NSClassFromString(@"AWELeftSideBarEntranceView")]) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                      UIViewController *controller = [hideButton findViewController:view];
                      if ([controller isKindOfClass:NSClassFromString(@"AWEFeedContainerViewController")]) {
                          DYYYApplyClearTargetViewHiddenState(view);
                      }
                    });
                    break;
                }
                DYYYApplyClearTargetViewHiddenState(view);
                break;
            }
        }
    }
    return view;
}

- (void)setBackgroundColor:(UIColor *)backgroundColor {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setBackgroundColor:backgroundColor];
        });
        return;
    }

    if (DYYYShouldForceHideFeedVideoCollectButtonView(self)) {
        %orig([UIColor clearColor]);
        return;
    }

    if (DYYYShouldClearAvatarActionViewChrome(self)) {
        %orig([UIColor clearColor]);
        return;
    }

    if (DYYYGetBoolCached(@"DYYYEnableFullScreen")) {
        UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
        if ([vc isKindOfClass:%c(AWEAwemeDetailTableViewController)] ||
            [vc isKindOfClass:%c(AWEAwemeDetailCellViewController)]) {
            %orig([UIColor clearColor]);
            return;
        }
    }

    %orig(backgroundColor);
}

- (void)layoutSubviews {
    %orig;

    BOOL enableFS = DYYYGetBoolCached(@"DYYYEnableFullScreen");
    BOOL enableBlur = DYYYGetBoolCached(@"DYYYEnableCommentBlur");

    // 全局 -layoutSubviews 会覆盖到界面上的每一个视图，两项开关都关闭时不必回溯响应链。
    if (!enableFS && !enableBlur) {
        return;
    }

    // 同一次布局里最多只回溯一次响应链，下面两段判定共用结果。
    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];

    if (enableFS) {
        if (self.frame.size.height == originalTabBarHeight && originalTabBarHeight > 0) {
            if ([vc isKindOfClass:%c(AWEMixVideoPanelDetailTableViewController)] || [vc isKindOfClass:%c(AWECommentInputViewController)] ||
                [vc isKindOfClass:%c(AWEAwemeDetailTableViewController)]) {
                self.backgroundColor = [UIColor clearColor];
            }
        }
    }

    if ([vc isKindOfClass:%c(AWEPlayInteractionViewController)]) {
        for (UIView *subview in self.subviews) {
            if ([subview isKindOfClass:[UIView class]] && subview.backgroundColor && CGColorEqualToColor(subview.backgroundColor.CGColor, [UIColor blackColor].CGColor)) {
                subview.hidden = YES;
            }
        }
    }
}

- (void)setFrame:(CGRect)frame {
    if (![NSThread isMainThread]) {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self setFrame:frame];
        });
        return;
    }

    BOOL enableBlur = DYYYGetBoolCached(@"DYYYEnableCommentBlur");
    BOOL enableFS = DYYYGetBoolCached(@"DYYYEnableFullScreen");

    // -setFrame: 在滚动时每帧会被调用上千次，而下面的响应链回溯与类查找只有
    // 毛玻璃或全屏开启时才会用到。两者都关闭时直接放行，行为与未 Hook 时一致。
    if (!enableBlur && !enableFS) {
        %orig(frame);
        return;
    }

    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
    Class PlayVCClass1 = %c(AWEAwemePlayVideoViewController);
    Class PlayVCClass2 = %c(AWEDPlayerFeedPlayerViewController);
    Class PlayVCClass3 = %c(AWEDPlayerViewController_Merge);

    BOOL isPlayVC = ((PlayVCClass1 && [vc isKindOfClass:PlayVCClass1]) ||
                     (PlayVCClass2 && [vc isKindOfClass:PlayVCClass2]) ||
                     (PlayVCClass3 && [vc isKindOfClass:PlayVCClass3]));

    if (isPlayVC && enableBlur) {
        if (frame.origin.x != 0) {
            return;
        }
    }

    if (isPlayVC && enableFS) {
        if (frame.origin.x != 0 && frame.origin.y != 0) {
            %orig(frame);
            return;
        }
        CGRect superF = self.superview.frame;
        if (CGRectGetHeight(superF) > 0 && CGRectGetHeight(frame) > 0 && CGRectGetHeight(frame) < CGRectGetHeight(superF)) {
            CGFloat diff = CGRectGetHeight(superF) - CGRectGetHeight(frame);
            if (fabs(diff - gCurrentTabBarHeight) < 1.0) {
                frame.size.height = CGRectGetHeight(superF);
            }
        }

        %orig(frame);
        return;
    }
    %orig(frame);
}

%new
- (void)dyyy_applyGlobalTransparency {
    if ([NSThread isMainThread]) {
        if (self.window && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG) {
            NSNumber *stored = objc_getAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey);
            CGFloat baseAlpha = stored ? stored.floatValue : self.alpha;
            if (!stored) {
                objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(baseAlpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            }
            CGFloat finalAlpha = baseAlpha;
            if (gGlobalTransparency != kInvalidAlpha) {
                CGFloat clampedAlpha = MIN(MAX(baseAlpha, 0.0), 1.0);
                finalAlpha = clampedAlpha * gGlobalTransparency;
            }
            if (fabs(self.alpha - finalAlpha) >= 0.01) {
                [UIView animateWithDuration:0.2
                                 animations:^{
                                   dyyyGlobalTransparencyMutationDepth++;
                                   self.alpha = finalAlpha;
                                   if (dyyyGlobalTransparencyMutationDepth > 0) {
                                       dyyyGlobalTransparencyMutationDepth--;
                                   }
                                 }];
            }
        }
    } else {
        dispatch_async(dispatch_get_main_queue(), ^{
          [self dyyy_applyGlobalTransparency];
        });
    }
}

%end

%hook AWEIMSkylightListView
- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYHideAvatarList")) {
        CGFloat scale = [UIScreen mainScreen].scale ?: 2.0;
        CGFloat minH = MAX(1.0 / scale, 0.5);
        frame.size.height = minH;
    }
    %orig(frame);
}
%end

%hook AFDPureModePageTapController

- (void)onVideoPlayerViewDoubleClicked:(id)arg1 {
    BOOL isSwitchOn = DYYYGetBool(@"DYYYDisableDoubleTapLike");
    if (!isSwitchOn) {
        %orig;
    }
}

%end

static void DYYYHideVideoAIParseBar(UIView *view);

%hook AWEPlayInteractionViewController

- (void)onVideoPlayerViewDoubleClicked:(id)arg1 {
    BOOL isSwitchOn = DYYYGetBool(@"DYYYDisableDoubleTapLike");
    if (!isSwitchOn) {
        %orig;
    }
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    dyyyInteractionViewVisible = YES;
    dyyyActivePlaybackInteractionController = self;
    DYYYScheduleCurrentAwemeTracking(self, self.model);
    DYYYEnsureFloatSpeedButton(self);
    reloadClearButtonConfiguration();
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    // AI 解析隐藏：布局完全稳定后执行，避免在 layout 过程中改视图导致上移
    if (DYYYGetBool(@"DYYYHideVideoAIParse")) {
        dispatch_async(dispatch_get_main_queue(), ^{
            DYYYHideVideoAIParseBar(self.view);
        });
    }
}

- (void)setModel:(AWEAwemeModel *)model {
    %orig(model);
    if (self.view.window && !self.view.hidden) {
        DYYYScheduleCurrentAwemeTracking(self, model);
    }
}

static void DYYYHideVideoAIParseBar(UIView *view) {
    if (!view) {
        return;
    }
    if ([view isKindOfClass:[UILabel class]]) {
        UILabel *label = (UILabel *)view;
        NSString *text = label.text;
        if (text.length > 0 && ([text hasPrefix:@"AI 解析"] || [text hasPrefix:@"AI解析"] || [text containsString:@"AI 解析"])) {
            UIView *container = label.superview;
            UIView *superview = container.superview;
            // 防止重复处理：检查是否已经是占位视图
            if (container && superview && ![container.accessibilityIdentifier isEqualToString:@"DYYYAIParsePlaceholder"]) {
                CGRect frame = container.frame;
                NSInteger index = [superview.subviews indexOfObject:container];
                // 创建同尺寸透明占位
                UIView *placeholder = [[UIView alloc] initWithFrame:frame];
                placeholder.accessibilityIdentifier = @"DYYYAIParsePlaceholder";
                placeholder.backgroundColor = [UIColor clearColor];
                placeholder.userInteractionEnabled = NO;
                placeholder.autoresizingMask = container.autoresizingMask;
                placeholder.clipsToBounds = YES;
                // 先加占位，再移除原容器，保证同一 runloop 内无缝替换
                if (index != NSNotFound) {
                    [superview insertSubview:placeholder atIndex:index];
                } else {
                    [superview addSubview:placeholder];
                }
                [container removeFromSuperview];
            }
            return;
        }
    }
    for (UIView *subview in [view.subviews copy]) {
        DYYYHideVideoAIParseBar(subview);
    }
}

- (void)viewDidLayoutSubviews {
    %orig;

    if (self.view.window && !self.view.hidden) {
        dyyyInteractionViewVisible = YES;
        dyyyActivePlaybackInteractionController = self;
        DYYYEnsureFloatSpeedButton(self);
        reloadClearButtonConfiguration();
    } else {
        updateSpeedButtonVisibility();
        updateClearButtonVisibility();
    }

    UIWindow *keyWindow = [DYYYUtils getActiveWindow];
    if (keyWindow && keyWindow.safeAreaInsets.bottom == 0) {
        return;
    }

    if (!DYYYGetBool(@"DYYYEnableFullScreen")) {
        return;
    }

    UIViewController *directParentVC = self.parentViewController;
    UIViewController *parentVC = directParentVC;
    int maxIterations = 3;
    int count = 0;

    while (parentVC && count < maxIterations) {
        if ([parentVC isKindOfClass:%c(AFDPlayRemoteFeedTableViewController)]) {
            return;
        }
        parentVC = parentVC.parentViewController;
        count++;
    }

    BOOL isShowingRelatedMixViewController = NO;
    UIViewController *sceneParentVC = directParentVC;
    int sceneDepth = 0;
    while (sceneParentVC && sceneDepth < 8) {
        if ([sceneParentVC isKindOfClass:%c(AWEMixVideoPanelDetailTableViewController)]) {
            AWEMixVideoPanelDetailTableViewController *mixDetailVC = (AWEMixVideoPanelDetailTableViewController *)sceneParentVC;
            isShowingRelatedMixViewController = mixDetailVC.isShowingRelatedMixViewController;
            break;
        }
        sceneParentVC = sceneParentVC.parentViewController;
        sceneDepth++;
    }

    if (!self.view.superview) {
        return;
    }

    CGRect frame = self.view.frame;
    CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
    CGFloat superviewHeight = self.view.superview.frame.size.height;

    if (frame.size.width != screenWidth && frame.size.height < superviewHeight) {
        return;
    }

    NSString *currentReferString = self.referString;

    BOOL useFullHeight = [currentReferString isEqualToString:@"general_search"] || [currentReferString isEqualToString:@"search_result"] || [currentReferString isEqualToString:@"search_ecommerce"] ||
                         [currentReferString isEqualToString:@"close_friends_moment"] || [currentReferString isEqualToString:@"offline_mode"] || [currentReferString isEqualToString:@"challenge"] ||
                         [currentReferString isEqualToString:@"general_search_scan"] || currentReferString == nil || isShowingRelatedMixViewController;

    if (!useFullHeight && [currentReferString isEqualToString:@"co_play_watch"]) {
        Class richContentVCClass = NSClassFromString(@"AWEFriendsImpl.RichContentNewListViewController");
        if (richContentVCClass && [directParentVC isKindOfClass:richContentVCClass]) {
            useFullHeight = YES;
        }
    }

    if (!useFullHeight && [currentReferString isEqualToString:@"chat"]) {
        AWEAwemeModel *currentModel = self.model;
        BOOL isLiveModel = currentModel && (([currentModel respondsToSelector:@selector(isLive)] && currentModel.isLive) ||
                                            ([currentModel respondsToSelector:@selector(cellRoom)] && currentModel.cellRoom != nil) ||
                                            ([currentModel respondsToSelector:@selector(videoFeedTag)] && [currentModel.videoFeedTag isEqualToString:@"直播中"]));

        // 私信视频的信息区依赖完整高度；直播内容保持原布局，避免影响直播文案位置。
        if (!isLiveModel) {
            useFullHeight = YES;
        }
    }

    if (useFullHeight) {
        frame.size.height = superviewHeight;
    } else {
        frame.size.height = superviewHeight - gCurrentTabBarHeight;
    }

    if (fabs(frame.size.height - self.view.frame.size.height) > 0.5) {
        self.view.frame = frame;
    }
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    if (dyyyActivePlaybackInteractionController == self) {
        __weak AWEPlayInteractionViewController *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
          AWEPlayInteractionViewController *strongSelf = weakSelf;
          AWEPlayInteractionViewController *replacementController =
              DYYYResolvePlaybackInteractionController(nil, dyyyCurrentSpeedAweme, YES);
          if (replacementController == strongSelf) {
              replacementController = nil;
          }
          dyyyActivePlaybackInteractionController = replacementController;
          BOOL hasVisibleInteractionController = replacementController != nil;
          dyyyInteractionViewVisible = hasVisibleInteractionController;
          dyyyCommentViewVisible = strongSelf.isCommentVCShowing;
          updateSpeedButtonVisibility();
          updateClearButtonVisibility();
        });
    }
}

%new
- (void)speedButtonTapped:(UIButton *)sender {
    [(FloatingSpeedButton *)sender resetFadeTimer];
    NSArray *speeds = getSpeedOptions();
    if (speeds.count == 0) {
        return;
    }

    NSInteger newIndex = (getCurrentSpeedIndex() + 1) % speeds.count;
    setCurrentSpeedIndex(newIndex);
    float newSpeed = [speeds[(NSUInteger)newIndex] floatValue];
    if (!isfinite(newSpeed) || newSpeed <= 0.0f) {
        newSpeed = 1.0f;
    }
    updateSpeedButtonUI();

    if (!DYYYApplyPlaybackSpeedThroughInteractionController(self, newSpeed)) {
        [DYYYUtils showToast:@"无法找到视频控制器"];
    }
}

%new
- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                     animations:^{
                       sender.alpha = 0.7;
                       sender.transform = CGAffineTransformMakeScale(0.95, 0.95);
                     }];
}

%new
- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.1
                     animations:^{
                       sender.alpha = 1.0;
                       sender.transform = CGAffineTransformIdentity;
                     }];
}

%end

%hook AWEAwemePlayVideoViewController

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    DYYYApplyNormalPlaybackSpeedToPlayerFallback(self);
}

- (void)prepareForDisplay {
    %orig;
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }

    BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
    if (isFloatSpeedButtonEnabled && autoRestoreSpeed) {
        setCurrentSpeedIndex(0);
    }
    DYYYApplyNormalPlaybackSpeedToPlayerFallback(self);
    updateSpeedButtonUI();
}

%end

%hook AWEDPlayerFeedPlayerViewController

- (BOOL)enableHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIView *contentView = self.contentView;
        if (contentView && contentView.superview) {
            CGRect frame = contentView.frame;
            CGFloat parentHeight = contentView.superview.frame.size.height;

            if (frame.size.height == parentHeight - gCurrentTabBarHeight) {
                frame.size.height = parentHeight;
                contentView.frame = frame;
            } else if (frame.size.height == parentHeight - (gCurrentTabBarHeight * 2)) {
                frame.size.height = parentHeight - gCurrentTabBarHeight;
                contentView.frame = frame;
            }
        }
    }
}

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    DYYYApplyNormalPlaybackSpeedToPlayerFallback(self);
}

- (void)prepareForDisplay {
    %orig;
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }
    BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
    if (isFloatSpeedButtonEnabled && autoRestoreSpeed) {
        setCurrentSpeedIndex(0);
    }
    DYYYApplyNormalPlaybackSpeedToPlayerFallback(self);
    updateSpeedButtonUI();
}

%end

%hook AWEDPlayerViewController_Merge

- (BOOL)enableHDR {
    if (DYYYShouldDisableAllHDR()) {
        return NO;
    }
    return %orig;
}

- (void)viewDidLayoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIView *contentView = self.contentView;
        if (contentView && contentView.superview) {
            CGRect frame = contentView.frame;
            CGFloat parentHeight = contentView.superview.frame.size.height;

            if (frame.size.height == parentHeight - gCurrentTabBarHeight) {
                frame.size.height = parentHeight;
                contentView.frame = frame;
            } else if (frame.size.height == parentHeight - (gCurrentTabBarHeight * 2)) {
                frame.size.height = parentHeight - gCurrentTabBarHeight;
                contentView.frame = frame;
            }
        }
    }
}

- (void)setIsAutoPlay:(BOOL)arg0 {
    %orig(arg0);
    DYYYApplyNormalPlaybackSpeedToPlayerFallback(self);
}

- (void)prepareForDisplay {
    %orig;
    if (!DYYYShouldHandleSpeedFeatures()) {
        return;
    }
    BOOL autoRestoreSpeed = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
    if (isFloatSpeedButtonEnabled && autoRestoreSpeed) {
        setCurrentSpeedIndex(0);
    }
    DYYYApplyNormalPlaybackSpeedToPlayerFallback(self);
    updateSpeedButtonUI();
}

%end

static char kDYYYFeedTableOriginalHeightGapKey;
static char kDYYYFeedTableFullScreenAppliedKey;

%hook AWEFeedTableView
- (void)layoutSubviews {
    %orig;

    UIView *superview = self.superview;
    if (!superview) {
        return;
    }

    BOOL enableFullScreen = DYYYGetBool(@"DYYYEnableFullScreen");
    BOOL fullScreenApplied = [objc_getAssociatedObject(self, &kDYYYFeedTableFullScreenAppliedKey) boolValue];
    CGFloat superviewHeight = CGRectGetHeight(superview.bounds);

    if (!enableFullScreen) {
        if (fullScreenApplied) {
            NSNumber *storedGap = objc_getAssociatedObject(self, &kDYYYFeedTableOriginalHeightGapKey);
            CGFloat originalHeightGap = storedGap ? MAX(storedGap.doubleValue, 0.0) : 0.0;
            CGFloat restoredHeight = MAX(superviewHeight - originalHeightGap, 0.0);
            CGRect frame = self.frame;
            if (fabs(CGRectGetHeight(frame) - restoredHeight) > 0.5) {
                frame.size.height = restoredHeight;
                self.frame = frame;
            }
            objc_setAssociatedObject(self, &kDYYYFeedTableOriginalHeightGapKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(self, &kDYYYFeedTableFullScreenAppliedKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
        return;
    }

    if (!fullScreenApplied) {
        CGFloat originalHeightGap = MAX(superviewHeight - CGRectGetHeight(self.frame), 0.0);
        objc_setAssociatedObject(self, &kDYYYFeedTableOriginalHeightGapKey, @(originalHeightGap), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(self, &kDYYYFeedTableFullScreenAppliedKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (fabs(CGRectGetHeight(self.frame) - superviewHeight) > 0.5) {
        CGRect frame = self.frame;
        frame.size.height = superviewHeight;
        self.frame = frame;
    }
}
%end

%hook AWEFeedTableViewCell
- (void)prepareForReuse {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)layoutSubviews {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
}
%end

%hook AWEFeedViewCell
- (void)layoutSubviews {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)setModel:(id)model {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}
%end

%hook UIViewController
- (void)viewWillAppear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      isAppInTransition = NO;
    });
}

- (void)viewWillDisappear:(BOOL)animated {
    %orig;
    isAppInTransition = YES;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      isAppInTransition = NO;
    });
}
%end

%hook AFDPureModePageContainerViewController
- (void)viewDidAppear:(BOOL)animated {
    %orig;
    isPureViewVisible = YES;
    updateClearButtonVisibility();
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    isPureViewVisible = NO;
    updateClearButtonVisibility();
}
%end

%hook AWEFeedContainerViewController
- (void)aweme:(id)arg1 currentIndexWillChange:(NSInteger)arg2 {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
}

- (void)aweme:(id)arg1 currentIndexDidChange:(NSInteger)arg2 {
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
    %orig;
    // This callback is the feed's committed index transition. Do not validate it
    // against the controller hierarchy: old/new controllers can overlap briefly
    // after a real switch, causing the old controller to win the visibility score.
    DYYYHandleCurrentAwemeChanged(arg1);
}

- (void)viewWillLayoutSubviews {
    %orig;
    if (hideButton && hideButton.isElementsHidden) {
        [hideButton hideUIElements];
    }
}
%end

%hook AWEFeedTableViewController

- (void)setCurrentPlayIndex:(NSInteger)index {
    %orig(index);
    DYYYHandleCommittedSpeedAwemeChanged([self currentAweme]);
}

- (void)playVideo:(id)video {
    %orig(video);
    DYYYHandleCommittedSpeedAwemeChanged([self currentAweme] ?: video);
}

- (void)playVideoOnScrollDidEnd {
    %orig;
    DYYYHandleCommittedSpeedAwemeChanged([self currentAweme]);
}

%end

static id dyyyWindowKeyObserverToken = nil;
static id dyyyDidBecomeActiveToken = nil;
static id dyyyWillResignActiveToken = nil;
static void *DYYYGlobalTransparencyContext = &DYYYGlobalTransparencyContext;

static void DYYYRemoveAppLifecycleObservers(void) {
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    if (dyyyWindowKeyObserverToken) {
        [center removeObserver:dyyyWindowKeyObserverToken];
        dyyyWindowKeyObserverToken = nil;
    }
    if (dyyyDidBecomeActiveToken) {
        [center removeObserver:dyyyDidBecomeActiveToken];
        dyyyDidBecomeActiveToken = nil;
    }
    if (dyyyWillResignActiveToken) {
        [center removeObserver:dyyyWillResignActiveToken];
        dyyyWillResignActiveToken = nil;
    }
}

%hook AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    BOOL result = %orig;
    initTargetClassNames();

    updateGlobalTransparencyCache();

    [[NSUserDefaults standardUserDefaults] addObserver:(NSObject *)self forKeyPath:kDYYYGlobalTransparencyKey options:NSKeyValueObservingOptionNew context:DYYYGlobalTransparencyContext];

    reloadClearButtonConfiguration();
    DYYYRemoveAppLifecycleObservers();

    dyyyWindowKeyObserverToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIWindowDidBecomeKeyNotification
                                                                                   object:nil
                                                                                    queue:[NSOperationQueue mainQueue]
                                                                               usingBlock:^(NSNotification *_Nonnull notification) {
                                                                                 reloadClearButtonConfiguration();
                                                                               }];

    dyyyDidBecomeActiveToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                                                 object:nil
                                                                                  queue:[NSOperationQueue mainQueue]
                                                                             usingBlock:^(NSNotification *_Nonnull notification) {
                                                                               isAppActive = YES;
                                                                               reloadClearButtonConfiguration();
                                                                             }];

    dyyyWillResignActiveToken = [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                                                  object:nil
                                                                                   queue:[NSOperationQueue mainQueue]
                                                                              usingBlock:^(NSNotification *_Nonnull notification) {
                                                                                isAppActive = NO;
                                                                                updateClearButtonVisibility();
                                                                              }];

    return result;
}

- (void)applicationWillTerminate:(UIApplication *)application {
    DYYYRemoveAppLifecycleObservers();
    %orig;
}

- (void)dealloc {
    DYYYRemoveAppLifecycleObservers();
    @try {
        [[NSUserDefaults standardUserDefaults] removeObserver:(NSObject *)self forKeyPath:kDYYYGlobalTransparencyKey context:DYYYGlobalTransparencyContext];
    } @catch (NSException *exception) {
        NSLog(@"[DYYY] KVO removeObserver failed: %@", exception);
    }
    %orig;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey, id> *)change context:(void *)context {
    if (context == DYYYGlobalTransparencyContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
          updateGlobalTransparencyCache();
          [[NSNotificationCenter defaultCenter] postNotificationName:kDYYYGlobalTransparencyDidChangeNotification object:nil];
        });
    } else {
        %orig(keyPath, object, change, context);
    }
}

%end

%hook AWELiveNewPreStreamViewController

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    [DYYYLivePreStreamLayoutCoordinator activateLayoutForController:self];
}

- (void)viewDidAppear:(BOOL)animated {
    %orig;
    [DYYYLivePreStreamLayoutCoordinator activateLayoutForController:self];
}

- (void)viewDidLayoutSubviews {
    %orig;
    [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForController:self];
}

- (void)viewDidDisappear:(BOOL)animated {
    %orig;
    [DYYYLivePreStreamLayoutCoordinator restoreLayoutForController:self];
}

%end

%hook AWEElementStackView

- (void)setAlpha:(CGFloat)alpha {
    BOOL isApplyingGlobal = (dyyyGlobalTransparencyMutationDepth > 0);
    if (!isApplyingGlobal) {
        objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    // 纯净模式功能
    static AWMSafeDispatchTimer *pureModeTimer = nil;
    static int attempts = 0;
    static BOOL pureModeSet = NO;
    static BOOL pureModeTimerStarted = NO;
    static NSUInteger pureModeGeneration = 0;
    if (DYYYGetBool(@"DYYYEnablePure")) {
        %orig(0.0);
        if (pureModeSet) {
            return;
        }
        if (!pureModeTimer) {
            pureModeTimer = [[AWMSafeDispatchTimer alloc] init];
        }
        // Guard before isRunning: startWithInterval schedules asynchronously, so
        // repeated setAlpha (fullscreen/status-bar layout churn) can otherwise
        // enqueue many overlapping starts while running is still NO.
        if (!pureModeTimerStarted) {
            pureModeTimerStarted = YES;
            attempts = 0;
            NSUInteger generation = ++pureModeGeneration;
            __weak AWMSafeDispatchTimer *weakTimer = pureModeTimer;
            [pureModeTimer startWithInterval:0.5
                                      leeway:0.1
                                       queue:dispatch_get_main_queue()
                                     repeats:YES
                                     handler:^{
                                       if (generation != pureModeGeneration) {
                                           return;
                                       }
                                       AWMSafeDispatchTimer *strongTimer = weakTimer;
                                       if (!strongTimer) {
                                           return;
                                       }
                                       UIWindow *keyWindow = [DYYYUtils getActiveWindow];
                                       if (keyWindow && keyWindow.rootViewController) {
                                           UIViewController *feedVC = [DYYYUtils findViewControllerOfClass:NSClassFromString(@"AWEFeedTableViewController")
                                                                                          inViewController:keyWindow.rootViewController];
                                           if (feedVC) {
                                               [feedVC setValue:@YES forKey:@"pureMode"];
                                               pureModeSet = YES;
                                               attempts = 0;
                                               pureModeGeneration++;
                                               pureModeTimerStarted = NO;
                                               if (pureModeTimer == strongTimer) {
                                                   pureModeTimer = nil;
                                               }
                                               [strongTimer cancel];
                                               return;
                                           }
                                       }
                                       attempts++;
                                       if (attempts >= 10) {
                                           attempts = 0;
                                           pureModeGeneration++;
                                           pureModeTimerStarted = NO;
                                           if (pureModeTimer == strongTimer) {
                                               pureModeTimer = nil;
                                           }
                                           [strongTimer cancel];
                                       }
                                     }];
        }
        return;
    }

    // 清理纯净模式的残留状态
    if (pureModeTimer) {
        AWMSafeDispatchTimer *timer = pureModeTimer;
        pureModeTimer = nil;
        pureModeTimerStarted = NO;
        pureModeGeneration++;
        [timer cancel];
    }
    attempts = 0;
    pureModeSet = NO;

    // 值守全局透明度
    CGFloat finalAlpha = alpha;
    if (!isApplyingGlobal && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG && gGlobalTransparency != kInvalidAlpha) {
        CGFloat clampedAlpha = MIN(MAX(alpha, 0.0), 1.0);
        finalAlpha = clampedAlpha * gGlobalTransparency;
    }

    // 统一应用透明度
    if (fabs(self.alpha - finalAlpha) >= 0.01) {
        %orig(finalAlpha);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self dyyy_applyGlobalTransparency];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dyyy_applyGlobalTransparency) name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    }
    [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForView:self];
}

- (void)didAddSubview:(UIView *)subview {
    %orig(subview);
    [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForView:self];
}

- (void)willRemoveSubview:(UIView *)subview {
    %orig(subview);
    [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForView:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (void)layoutSubviews {
    BOOL insidePlayInteraction = DYYYViewIsInsidePlayInteraction(self);
    // 只清理播放交互层左侧栏。全局 reset 会把作品详情等页面里 element hook 已写好的缩放清掉。
    if (insidePlayInteraction) {
        DYYYResetPlayInteractionLeftStackElementTransforms(self);
    }

    %orig;

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];

    if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
        [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForController:viewController];
    }

    if (insidePlayInteraction) {
        NSString *label = self.accessibilityLabel ?: @"";
        BOOL hasAnchor = [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEFeedAnchorContainerView") inContainer:self];
        BOOL hasAvatar = [DYYYUtils containsSubviewOfClass:NSClassFromString(@"AWEPlayInteractionUserAvatarView") inContainer:self];

        BOOL isRightStack = ([label isEqualToString:@"right"] || hasAvatar);
        if (!isRightStack) {
            NSArray *subviews = [self.subviews copy];
            for (NSInteger i = (NSInteger)subviews.count - 1; i >= 0; i--) {
                UIView *sub = subviews[i];
                if ([sub respondsToSelector:@selector(elementClassName)]) {
                    NSString *elementClassName = [sub performSelector:@selector(elementClassName)];
                    if ([elementClassName isEqualToString:@"AWEPlayInteractionUserAvatarOptElementElement"]) {
                        isRightStack = YES;
                        break;
                    }
                }
            }
        }

        BOOL hasScalableLeftElement = DYYYStackViewContainsScalableLeftElement(self);

        // 右侧元素的处理逻辑
        if (isRightStack) {
            NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYElementScale"];
            self.transform = CGAffineTransformIdentity;
            if (scaleValue.length > 0) {
                CGFloat scale = [scaleValue floatValue];
                if (scale > 0 && scale != 1.0) {
                    NSArray *subviews = [self.subviews copy];
                    CGFloat ty = 0;
                    for (UIView *view in subviews) {
                        CGFloat viewHeight = view.frame.size.height;
                        ty += (viewHeight - viewHeight * scale) / 2;
                    }
                    CGFloat frameWidth = self.frame.size.width;
                    CGFloat right_tx = (frameWidth - frameWidth * scale) / 2;
                    self.transform = CGAffineTransformMake(scale, 0, 0, scale, right_tx, ty);
                } else {
                    self.transform = CGAffineTransformIdentity;
                }
            }
        }
        // 左侧昵称/文案元素按子元素分别缩放
        else if (hasScalableLeftElement) {
            DYYYApplyPlayInteractionLeftStackElementTransforms(self);
        }
    }
}

- (NSArray<__kindof UIView *> *)arrangedSubviews {
    NSArray *originalSubviews = %orig;
    return originalSubviews;
}

%end

%hook IESLiveStackView

- (void)setAlpha:(CGFloat)alpha {
    BOOL isApplyingGlobal = (dyyyGlobalTransparencyMutationDepth > 0);
    if (!isApplyingGlobal) {
        objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat finalAlpha = alpha;
    if (!isApplyingGlobal && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG && gGlobalTransparency != kInvalidAlpha) {
        CGFloat clampedAlpha = MIN(MAX(alpha, 0.0), 1.0);
        finalAlpha = clampedAlpha * gGlobalTransparency;
    }

    if (fabs(self.alpha - finalAlpha) >= 0.01) {
        %orig(finalAlpha);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self dyyy_applyGlobalTransparency];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dyyy_applyGlobalTransparency) name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    }
    [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForView:self];
}

- (void)didAddSubview:(UIView *)subview {
    %orig(subview);
    [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForView:self];
}

- (void)willRemoveSubview:(UIView *)subview {
    %orig(subview);
    [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForView:self];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (void)layoutSubviews {
    %orig;

    UIViewController *viewController = [DYYYUtils firstAvailableViewControllerFromView:self];

    if ([viewController isKindOfClass:%c(AWELiveNewPreStreamViewController)]) {
        [DYYYLivePreStreamLayoutCoordinator scheduleUpdateForController:viewController];
    }
}

%end

%hook AWEStoryContainerCollectionView
- (void)layoutSubviews {
    %orig;
    if ([self.subviews count] == 2)
        return;

    // 获取 enableEnterProfile 属性来判断是否是主页
    id enableEnterProfile = [self valueForKey:@"enableEnterProfile"];
    BOOL isHome = (enableEnterProfile != nil && [enableEnterProfile boolValue]);

    // 检查是否在作者主页
    BOOL isAuthorProfile = NO;
    UIResponder *responder = self;
    while ((responder = [responder nextResponder])) {
        if ([NSStringFromClass([responder class]) containsString:@"UserHomeViewController"] || [NSStringFromClass([responder class]) containsString:@"ProfileViewController"]) {
            isAuthorProfile = YES;
            break;
        }
    }

    // 如果不是主页也不是作者主页，直接返回
    if (!isHome && !isAuthorProfile)
        return;

    for (UIView *subview in self.subviews) {
        if ([subview isKindOfClass:[UIView class]]) {
            UIView *nextResponder = (UIView *)subview.nextResponder;

            // 处理主页的情况
            if (isHome && [nextResponder isKindOfClass:%c(AWEPlayInteractionViewController)]) {
                UIViewController *awemeBaseViewController = [nextResponder valueForKey:@"awemeBaseViewController"];
                if (![awemeBaseViewController isKindOfClass:%c(AWEFeedCellViewController)]) {
                    continue;
                }

                CGRect frame = subview.frame;
                if (DYYYGetBool(@"DYYYEnableFullScreen")) {
                    frame.size.height = subview.superview.frame.size.height - gCurrentTabBarHeight;
                    subview.frame = frame;
                }
            }
            // 处理作者主页的情况
            else if (isAuthorProfile) {
                // 检查是否是作品图片
                BOOL isWorkImage = NO;

                // 可以通过检查子视图、标签或其他特性来确定是否是作品图片
                for (UIView *childView in subview.subviews) {
                    if ([NSStringFromClass([childView class]) containsString:@"ImageView"] || [NSStringFromClass([childView class]) containsString:@"ThumbnailView"]) {
                        isWorkImage = YES;
                        break;
                    }
                }

                if (isWorkImage) {
                    // 修复作者主页作品图片上移问题
                    CGRect frame = subview.frame;
                    frame.origin.y += gCurrentTabBarHeight;
                    subview.frame = frame;
                }
            }
        }
    }
}
%end

%hook AFDFastSpeedView

- (void)updateSpeedLockBottomWithText:(NSString *)text Type:(NSInteger)type {
    %orig(DYYYAdjustedNativeLongPressSpeedHint(text), type);
}

- (void)layoutSubviews {
    %orig;

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFullScreen"]) {
        return;
    }

    static char kDYFastSpeedBgKey;
    NSArray *bgViews = objc_getAssociatedObject(self, &kDYFastSpeedBgKey);
    if (!bgViews) {
        NSMutableArray *tmp = [NSMutableArray array];
        for (UIView *subview in self.subviews) {
            if ([subview class] == [UIView class]) {
                [tmp addObject:subview];
            }
        }
        bgViews = [tmp copy];
        objc_setAssociatedObject(self, &kDYFastSpeedBgKey, bgViews, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    for (UIView *view in bgViews) {
        view.backgroundColor = [UIColor clearColor];
    }
}
%end

%hook TTPlayerView

- (void)layoutSubviews {
    %orig;
    UIView *parent = self.superview;
    if (parent) {
        parent.backgroundColor = self.backgroundColor;
    }
}

%end

%hook TTMetalView
- (void)setCenter:(CGPoint)center {
    BOOL shouldAdjust = NO;
    UIView *view = (UIView *)self;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if (viewWidth + 0.5f >= screenWidth) {
            UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:view];
            Class playClass = %c(AWEPlayVideoViewController);
            if (playClass && [vc isKindOfClass:playClass]) {
                AWEPlayVideoViewController *playVC = (AWEPlayVideoViewController *)vc;
                AWEAwemeModel *model = playVC.model;
                if ([model respondsToSelector:@selector(isShowLandscapeEntryView)] && model.isShowLandscapeEntryView) {
                    shouldAdjust = YES;
                }
            }
        }
    }

    if (shouldAdjust) {
        CGFloat offset = gCurrentTabBarHeight > 0 ? gCurrentTabBarHeight : originalTabBarHeight;
        if (offset > 0) {
            center.y -= offset * 0.5;
        }
    }

    %orig(center);
}
%end

%hook TTMetalViewNew
- (void)setCenter:(CGPoint)center {
    BOOL shouldAdjust = NO;
    UIView *view = (UIView *)self;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if (viewWidth + 0.5f >= screenWidth) {
            UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:view];
            Class playClass = %c(AWEPlayVideoViewController);
            if (playClass && [vc isKindOfClass:playClass]) {
                AWEPlayVideoViewController *playVC = (AWEPlayVideoViewController *)vc;
                AWEAwemeModel *model = playVC.model;
                if ([model respondsToSelector:@selector(isShowLandscapeEntryView)] && model.isShowLandscapeEntryView) {
                    shouldAdjust = YES;
                }
            }
        }
    }

    if (shouldAdjust) {
        CGFloat offset = gCurrentTabBarHeight > 0 ? gCurrentTabBarHeight : originalTabBarHeight;
        if (offset > 0) {
            center.y -= offset * 0.5;
        }
    }

    %orig(center);
}
%end

%hook TTMetalViewVP
- (void)setCenter:(CGPoint)center {
    BOOL shouldAdjust = NO;
    UIView *view = (UIView *)self;
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat viewWidth = CGRectGetWidth(view.bounds);
        CGFloat screenWidth = [UIScreen mainScreen].bounds.size.width;
        if (viewWidth + 0.5f >= screenWidth) {
            UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:view];
            Class playClass = %c(AWEPlayVideoViewController);
            if (playClass && [vc isKindOfClass:playClass]) {
                AWEPlayVideoViewController *playVC = (AWEPlayVideoViewController *)vc;
                AWEAwemeModel *model = playVC.model;
                if ([model respondsToSelector:@selector(isShowLandscapeEntryView)] && model.isShowLandscapeEntryView) {
                    shouldAdjust = YES;
                }
            }
        }
    }

    if (shouldAdjust) {
        CGFloat offset = gCurrentTabBarHeight > 0 ? gCurrentTabBarHeight : originalTabBarHeight;
        if (offset > 0) {
            center.y -= offset * 0.5;
        }
    }

    %orig(center);
}
%end

// 隐藏图片滑条
%hook AWEStoryProgressContainerView
- (void)setCenter:(CGPoint)center {
    UIViewController *vc = [DYYYUtils firstAvailableViewControllerFromView:self];
    BOOL isPureModeImageBrowser = [vc isKindOfClass:NSClassFromString(@"AWEFeedPlayControlImpl.PureModePageCellViewController")];
    if (isPureModeImageBrowser && DYYYGetBool(@"DYYYEnableFullScreen")) {
        NSString *appVersion = [NSBundle mainBundle].infoDictionary[@"CFBundleShortVersionString"];
        BOOL needsLegacyOffset = appVersion.length == 0 || [DYYYUtils compareVersion:appVersion toVersion:@"37.2.0"] == NSOrderedAscending;
        if (needsLegacyOffset && gCurrentTabBarHeight > 0) {
            center.y -= gCurrentTabBarHeight;
        }
    }
    %orig(center);
}

- (BOOL)isHidden {
    BOOL originalValue = %orig;
    BOOL customHide = DYYYGetBool(@"DYYYHideDotsIndicator");
    return originalValue || customHide;
}

- (void)setHidden:(BOOL)hidden {
    BOOL forceHide = DYYYGetBool(@"DYYYHideDotsIndicator");
    %orig(forceHide ? YES : hidden);
}
%end

%hook AWELandscapeFeedEntryView

- (void)setAlpha:(CGFloat)alpha {
    BOOL isApplyingGlobal = (dyyyGlobalTransparencyMutationDepth > 0);
    if (!isApplyingGlobal) {
        objc_setAssociatedObject(self, &kDYYYGlobalTransparencyBaseAlphaKey, @(alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    CGFloat finalAlpha = alpha;
    if (!isApplyingGlobal && self.tag != DYYY_IGNORE_GLOBAL_ALPHA_TAG && gGlobalTransparency != kInvalidAlpha) {
        CGFloat clampedAlpha = MIN(MAX(alpha, 0.0), 1.0);
        finalAlpha = clampedAlpha * gGlobalTransparency;
    }

    if (fabs(self.alpha - finalAlpha) >= 0.01) {
        %orig(finalAlpha);
    }
}

- (void)didMoveToWindow {
    %orig;
    if (self.window) {
        [self dyyy_applyGlobalTransparency];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dyyy_applyGlobalTransparency) name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    } else {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kDYYYGlobalTransparencyDidChangeNotification object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    %orig;
}

- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYRemoveEntry")) {
        [self removeFromSuperview];
        return;
    }
    if (DYYYGetBool(@"DYYYHideEntry")) {
        for (UIView *subview in self.subviews) {
            subview.hidden = YES;
        }
        return;
    }

    if (self.superview) {
        [self.superview bringSubviewToFront:self];
    }

    NSString *scaleValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYNicknameScale"];
    CGFloat scale = scaleValue.length > 0 ? [scaleValue floatValue] : 1.0;
    if (scale > 0 && scale != 1.0) {
        self.transform = CGAffineTransformMakeScale(scale, scale);
    } else {
        self.transform = CGAffineTransformIdentity;
    }
}

%end

%hook AWEAwemeDetailTableView

- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat screenHeight = [UIScreen mainScreen].bounds.size.height;

        CGFloat remainder = fmod(frame.size.height, screenHeight);
        if (remainder != 0) {
            frame.size.height += (screenHeight - remainder);
        }
    }
    %orig(frame);
}

%end

%hook AWEMixVideoPanelMoreView

- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYHideTemplateVideo")) {
        self.hidden = YES;
        %orig(frame);
        return;
    }

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        CGFloat targetY = frame.origin.y - gCurrentTabBarHeight;
        CGFloat screenHeightMinusGDiff = [UIScreen mainScreen].bounds.size.height - gCurrentTabBarHeight;

        CGFloat tolerance = 10.0;

        if (fabs(targetY - screenHeightMinusGDiff) <= tolerance) {
            frame.origin.y = targetY;
        }
    }
    %orig(frame);
}

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYHideTemplateVideo")) {
        self.hidden = YES;
        return;
    }

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        self.backgroundColor = [UIColor clearColor];
    }
}

%end

%group DYYYCommentInputContainerGroup

%hook CommentInputContainerView

- (void)layoutSubviews {
    %orig;
    UIViewController *parentVC = nil;
    if ([self respondsToSelector:@selector(viewController)]) {
        id viewController = [self performSelector:@selector(viewController)];
        if ([viewController respondsToSelector:@selector(parentViewController)]) {
            parentVC = [viewController parentViewController];
        }
    }

    if (parentVC && ([parentVC isKindOfClass:%c(AWEAwemeDetailTableViewController)] || [parentVC isKindOfClass:%c(AWEAwemeDetailCellViewController)])) {
        static char kDYCommentHideCacheKey;
        UIView *target = objc_getAssociatedObject(self, &kDYCommentHideCacheKey);
        if (!target) {
            for (UIView *subview in [self subviews]) {
                if ([subview class] == [UIView class]) {
                    target = subview;
                    objc_setAssociatedObject(self, &kDYCommentHideCacheKey, target, OBJC_ASSOCIATION_ASSIGN);
                    break;
                }
            }
        }
        if (target) {
            target.hidden = ([(UIView *)self frame].size.height == gCurrentTabBarHeight);
        }
    }
}

%end

%end

// 聊天视频底部评论框背景透明
%hook AWEIMFeedBottomQuickEmojiInputBar

- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        UIView *parentView = self.superview;
        while (parentView) {
            if ([NSStringFromClass([parentView class]) isEqualToString:@"UIView"]) {
                dispatch_async(dispatch_get_main_queue(), ^{
                  parentView.backgroundColor = [UIColor clearColor];
                  parentView.layer.backgroundColor = [UIColor clearColor].CGColor;
                  parentView.opaque = NO;
                });
                break;
            }
            parentView = parentView.superview;
        }
    }
}

%end

// 隐藏上次看到
%hook DUXPopover
- (void)layoutSubviews {
    %orig;

    if (!DYYYGetBool(@"DYYYHidePopover")) {
        return;
    }

    id rawContent = nil;
    @try {
        rawContent = [self valueForKey:@"content"];
    } @catch (__unused NSException *e) {
        return;
    }

    NSString *text = [rawContent isKindOfClass:NSString.class] ? (NSString *)rawContent : [rawContent description];

    if ([text containsString:@"上次看到"]) {
        self.hidden = YES;
        return;
    }
}
%end

%hook _TtC21AWEIncentiveSwiftImpl29IncentivePendantContainerView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePendantGroup")) {
        [self removeFromSuperview];
    }
}
%end

%hook UIImageView
- (void)setImage:(UIImage *)image {
    if (DYYYShouldForceHideFeedVideoCollectButtonView(self)) {
        %orig(nil);
        return;
    }

    DYYYApplySDRDynamicRangeToImageView(self);
    %orig;
    DYYYApplySDRDynamicRangeToImageView(self);
}

- (void)setHighlightedImage:(UIImage *)highlightedImage {
    if (DYYYShouldForceHideFeedVideoCollectButtonView(self)) {
        %orig(nil);
        return;
    }

    DYYYApplySDRDynamicRangeToImageView(self);
    %orig;
    DYYYApplySDRDynamicRangeToImageView(self);
}

- (void)setAnimationImages:(NSArray<UIImage *> *)animationImages {
    if (DYYYShouldForceHideFeedVideoCollectButtonView(self)) {
        %orig(nil);
        return;
    }

    DYYYApplySDRDynamicRangeToImageView(self);
    %orig;
    DYYYApplySDRDynamicRangeToImageView(self);
}

- (void)setHighlightedAnimationImages:(NSArray<UIImage *> *)highlightedAnimationImages {
    if (DYYYShouldForceHideFeedVideoCollectButtonView(self)) {
        %orig(nil);
        return;
    }

    DYYYApplySDRDynamicRangeToImageView(self);
    %orig;
    DYYYApplySDRDynamicRangeToImageView(self);
}

- (void)layoutSubviews {
    %orig;
    if (DYYYShouldForceHideFeedVideoCollectButtonView(self)) {
        DYYYClearFeedVideoCollectImageView(self);
        self.hidden = YES;
        return;
    }

    DYYYApplySDRDynamicRangeToImageView(self);
    if (DYYYGetBoolCached(@"DYYYHideCommentDiscover")) {
        if (!self.accessibilityLabel) {
            UIView *parentView = self.superview;

            if (parentView && [parentView class] == [UIView class] && [parentView.accessibilityLabel isEqualToString:@"搜索"]) {
                self.hidden = YES;
            }

            else if (parentView && [NSStringFromClass([parentView class]) isEqualToString:@"AWESearchEntryHalfScreenElement"] && [parentView.accessibilityLabel isEqualToString:@"搜索"]) {
                self.hidden = YES;
            }
        }
    }
    return;
}
%end

// 移除极速版我的片面红包横幅
%hook AWELuckyCatBannerView
- (id)initWithFrame:(CGRect)frame {
    return nil;
}

- (id)init {
    return nil;
}
%end

static NSString *const kHideRecentAppsKey = @"DYYYHideSidebarRecentApps";
static NSString *const kHideRecentUsersKey = @"DYYYHideSidebarRecentUsers";

%hook AWELeftSideBarModel

- (NSArray *)moduleModels {
    NSArray *originalModels = %orig;

    BOOL shouldHideRecentApps = DYYYGetBool(kHideRecentAppsKey);
    BOOL shouldHideRecentUsers = DYYYGetBool(kHideRecentUsersKey);

    if (!shouldHideRecentApps && !shouldHideRecentUsers) {
        return originalModels;
    }

    NSMutableArray *filteredModels = [NSMutableArray arrayWithCapacity:originalModels.count];

    for (id moduleModel in originalModels) {
        if ([moduleModel respondsToSelector:@selector(moduleID)]) {
            NSString *moduleID = [moduleModel moduleID];

            if (shouldHideRecentApps && [moduleID isEqualToString:@"recently_apps_module"]) {
                continue;
            }

            if (shouldHideRecentUsers && [moduleID isEqualToString:@"recently_users_module"]) {
                continue;
            }
        }

        id filteredModule = [self filterModuleItems:moduleModel];
        if (filteredModule) {
            [filteredModels addObject:filteredModule];
        }
    }

    return [filteredModels copy];
}

%new
- (id)filterModuleItems:(id)moduleModel {
    if (![moduleModel respondsToSelector:@selector(items)] || ![moduleModel respondsToSelector:@selector(moduleID)]) {
        return moduleModel;
    }

    NSString *moduleID = [moduleModel moduleID];
    NSArray *originalItems = [moduleModel items];

    if ([moduleID isEqualToString:@"top_area"]) {
        // 只保留天气、设置、扫一扫
        NSMutableArray *filteredItems = [NSMutableArray array];

        for (id item in originalItems) {
            if ([item respondsToSelector:@selector(businessType)]) {
                NSString *businessType = [item businessType];

                // 保留需要的组件
                if ([businessType isEqualToString:@"weather_time_tip_component"] || [businessType isEqualToString:@"setting_page_component"] ||
                    [businessType isEqualToString:@"top_area_vertical_cell"]) {
                    [filteredItems addObject:item];
                }
            }
        }

        // 创建新的模块对象，保持原有属性但更新items
        if ([moduleModel respondsToSelector:@selector(copy)]) {
            id newModule = [moduleModel copy];
            if ([newModule respondsToSelector:@selector(setItems:)]) {
                [newModule setItems:[filteredItems copy]];
            }
            return newModule;
        }
    }

    return moduleModel;
}

%end

%hook AFDViewedBottomView
- (void)layoutSubviews {
    %orig;

    if (DYYYGetBool(@"DYYYEnableFullScreen")) {
        self.backgroundColor = [UIColor clearColor];

        self.effectView.hidden = YES;
    }
}
%end

// 极速版红包激励挂件容器视图类组（移除逻辑）
%group IncentivePendantGroup
%hook AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView
- (void)layoutSubviews {
    %orig;
    if (DYYYGetBool(@"DYYYHidePendantGroup")) {
        [self removeFromSuperview];
    }
}
%end
%end

// View scaling fix when comment blur is enabled
%group BDMultiContentImageViewGroup
%hook BDMultiContentContainer_ImageContentView

- (void)setTransform:(CGAffineTransform)transform {
    if (DYYYGetBool(@"DYYYEnableCommentBlur")) {
        return;
    }
    %orig(transform);
}

%end
%end

%hook AWEStoryContainerCollectionView

- (void)setFrame:(CGRect)frame {
    if (DYYYGetBool(@"DYYYEnableCommentBlur")) {
        if (frame.origin.y != 0) {
            return;
        }
    }
    %orig(frame);
}

%end

%hook AWEDPlayerProgressContainerView

- (void)layoutSubviews {
    %orig;
    DYYYApplyFloatClearProgressStateToView(self);

    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEnableFullScreen"]) {
        return;
    }

    for (UIView *subview in self.subviews) {
        if ([subview isMemberOfClass:[UIView class]]) {
            UIColor *bgColor = subview.backgroundColor;
            if (bgColor) {
                CGFloat h, s, v, a;
                if ([bgColor getHue:&h saturation:&s brightness:&v alpha:&a]) {
                    if (v < 0.2) {
                        subview.backgroundColor = [UIColor clearColor];
                    }
                }
            }
        }
    }
}

%end

%ctor {
    [DYYYLoginBypassManager configureInitialStateIfNeeded];

    [[NSUserDefaults standardUserDefaults] registerDefaults:@{
        DYYY_DISABLE_FEED_NOW_PLAYING_INFO_KEY : @NO,
        @"DYYYSpeedSettings" : @"1.0,1.25,1.5,2.0",
        @"DYYYSpeedButtonSize" : @35.0,
        @"DYYYAutoHideSpeedButtonTime" : @30.0,
        kDYYYEnableLoginBypassKey : @YES
    }];

    DYYYMigrateCombinedHDRModeIfNeeded();
    DYYYMigrateScaleAndSizeSettingsIfNeeded();
    DYYYMigrateScaleAndSizeSettingsV2IfNeeded();

    // 仅在构造阶段准备 C Hook；UIKit 与宿主帧率对象延后至 App 激活后访问。
    DYYYHookManagerStartLoaderSafePhase();
    DYYYStartHideFeedAnchorHookInstaller();

    Class plusButtonOverlayClass = objc_getClass("AWENormalModeTabBarPlusButton");
    if (plusButtonOverlayClass && class_getInstanceMethod(plusButtonOverlayClass, @selector(addStickerImageViewAnimationView))) {
        %init(DYYYHidePlusButtonStickerOverlay);
    }
    Class specialPlusManagerClass = objc_getClass("AWEStudioSpecialPlusManager");
    if (specialPlusManagerClass &&
        class_getClassMethod(specialPlusManagerClass, @selector(shouldShowStudioSpecialPlusIconWithAwemeModel:))) {
        %init(DYYYHidePlusButtonSpecialPlusManager);
    }
    Class plusBigAnimationClass = objc_getClass("AWEStudioSpecialPlusBigAnimationManager");
    if (plusBigAnimationClass && class_getInstanceMethod(plusBigAnimationClass, @selector(enableShowSpecialPlusBigAnimation))) {
        %init(DYYYHidePlusButtonBigAnimation);
    }
    Class plusInnerButtonClass = objc_getClass("AWENormalModeTabBarGeneralPlusInnerButton");
    if (plusInnerButtonClass && class_getInstanceMethod(plusInnerButtonClass, @selector(showBubbleWithText:))) {
        %init(DYYYHidePlusButtonInnerBubble);
    }

    %init(DYYYLoginBypassCore);
    DYYYHookManagerStartAfterLoginCorePhase();

    Class loginListenerClass = objc_getClass("AWEUserServiceListener");
    if (loginListenerClass && class_getInstanceMethod(loginListenerClass, @selector(didFinishLoginWithUid:))) {
        %init(DYYYLoginBypassAccountLifecycle);
    }
    if (loginListenerClass && class_getInstanceMethod(loginListenerClass, @selector(didFinishLogoutWithUid:))) {
        %init(DYYYLoginBypassAccountLogout);
    }
    if (loginListenerClass && class_getInstanceMethod(loginListenerClass, @selector(didFinishLogin:))) {
        %init(DYYYLoginBypassAccountLifecycleDidFinishLogin);
    }
    Class accountMulticastClass = objc_getClass("TTAccountMulticast");
    if (accountMulticastClass &&
        class_getInstanceMethod(accountMulticastClass, @selector(broadcastLoginSuccess:platform:reason:))) {
        %init(DYYYLoginBypassAccountMulticast);
    }
    if (objc_getClass("AWEVersionUpdateManager")) {
        %init(DYYYLoginBypassVersionUpdateManager);
    }
    if (objc_getClass("AWEVersionUpdateAlert")) {
        %init(DYYYLoginBypassVersionUpdateAlert);
    }
    if (objc_getClass("AWEVersionUpdatePopup")) {
        %init(DYYYLoginBypassVersionUpdatePopup);
    }
    if (objc_getClass("AWEVersionUpdateWorkflow")) {
        %init(DYYYLoginBypassVersionUpdateWorkflow);
    }
    if (objc_getClass("AWETeenVersionUpdateManager")) {
        %init(DYYYLoginBypassTeenVersionUpdateManager);
    }
    Class preLoginAlertClass = objc_getClass("AWEPreLoginAlertManager");
    if (preLoginAlertClass && class_getInstanceMethod(preLoginAlertClass, @selector(canShow)) &&
        class_getInstanceMethod(preLoginAlertClass, @selector(canShowNow))) {
        %init(DYYYLoginBypassPreLoginAlert);
    }
    if (preLoginAlertClass && class_getInstanceMethod(preLoginAlertClass, @selector(isShowFrequencySatisfied)) &&
        class_getInstanceMethod(preLoginAlertClass, @selector(isShowFrequencySatisfiedByLoginStrategy))) {
        %init(DYYYLoginBypassPreLoginFrequency);
    }
    Class newVersionAlertClass = objc_getClass("AWENewVersionAlertManager");
    if (newVersionAlertClass && class_getInstanceMethod(newVersionAlertClass, @selector(canShow))) {
        %init(DYYYLoginBypassNewVersionAlert);
    }

    Class interactionBaseLabelClass = objc_getClass("AWECommentSwiftBizUI.CommentInteractionBaseLabel");
    if (interactionBaseLabelClass) {
        %init(DYYYCommentExactTimeGroup, AWECommentSwiftBizUI_CommentInteractionBaseLabel = interactionBaseLabelClass);
    }

    Class imMenuComponentClass = objc_getClass("AWEIMCustomMenuComponent");
    if (imMenuComponentClass) {
        SEL legacySelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:tapLocationInScreen:menuItemList:moreEmoticon:onCell:extra:");
        SEL tapLocationSelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:tapLocationInScreen:menuItemList:menuPanelOptions:moreEmoticon:onCell:extra:");
        SEL highLowSelector = NSSelectorFromString(@"msg_showMenuForBubbleFrameInScreen:highLocationInScreen:lowLocationInScreen:tryHighLocationFirst:menuItemList:menuPanelOptions:onCell:extra:");
        if (legacySelector && class_getInstanceMethod(imMenuComponentClass, legacySelector)) {
            %init(DYYYIMMenuLegacyGroup);
        }
        if (tapLocationSelector && class_getInstanceMethod(imMenuComponentClass, tapLocationSelector)) {
            %init(DYYYIMMenuTapLocationGroup);
        }
        if (highLowSelector && class_getInstanceMethod(imMenuComponentClass, highLowSelector)) {
            %init(DYYYIMMenuHighLowGroup);
        }
    }

    if (!DYYYGetBool(@"DYYYDisableSettingsGesture")) {
        %init(DYYYSettingsGesture);
    }
    if (DYYYGetBool(@"DYYYUserAgreementAccepted")) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        isFloatSpeedButtonEnabled = [defaults boolForKey:@"DYYYEnableFloatSpeedButton"];
        showSpeedX = [defaults boolForKey:@"DYYYSpeedButtonShowX"];
        CGFloat configuredSpeedButtonSize = [defaults floatForKey:@"DYYYSpeedButtonSize"];
        speedButtonSize = configuredSpeedButtonSize > 0.0 ? configuredSpeedButtonSize : 35.0;

        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
          %init;
          Class wSwiftImpl = objc_getClass("AWECommentInputViewSwiftImpl.CommentInputContainerView");
          if (wSwiftImpl) {
              %init(DYYYCommentInputContainerGroup, CommentInputContainerView = wSwiftImpl);
          }
        });
        BOOL isAutoPlayEnabled = DYYYGetBool(@"DYYYEnableAutoPlay");
        if (isAutoPlayEnabled) {
            %init(AutoPlay);
        }
        if (DYYYGetBool(@"DYYYForceDownloadEmotion") ||
            DYYYGetBool(@"DYYYForceDownloadCommentAudio") ||
            DYYYGetBool(@"DYYYForceDownloadCommentImage")) {
            %init(EnableStickerSaveMenu);
        }
        DYYYHookManagerStartAfterAgreementPhase();

        // 初始化红包激励挂件容器视图类组
        Class incentivePendantClass = objc_getClass("AWEIncentiveSwiftImplDOUYINLite.IncentivePendantContainerView");
        if (incentivePendantClass) {
            %init(IncentivePendantGroup, AWEIncentiveSwiftImplDOUYINLite_IncentivePendantContainerView = incentivePendantClass);
        }
        Class imageContentClass = objc_getClass("BDMultiContentContainer.ImageContentView");
        if (imageContentClass) {
            %init(BDMultiContentImageViewGroup, BDMultiContentContainer_ImageContentView = imageContentClass);
        }

        // 动态获取 Swift 类并初始化对应的组
        Class commentSearchAnchorViewClass = objc_getClass("AWECommentSearchAnchorView");
        if (commentSearchAnchorViewClass) {
            %init(CommentSearchAnchorGroup, AWECommentSearchAnchorView = commentSearchAnchorViewClass);
        }

        Class commentHeaderSectionControllerClass =
            NSClassFromString(@"AWECommentPanelHeaderSwiftImpl.CommentPanelHeaderSectionController");
        if (!commentHeaderSectionControllerClass) {
            commentHeaderSectionControllerClass =
                objc_getClass("_TtC30AWECommentPanelHeaderSwiftImpl40CommentPanelHeaderSectionController");
        }
        if (!commentHeaderSectionControllerClass) {
            commentHeaderSectionControllerClass =
                objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentPanelHeaderSectionController");
        }
        if (commentHeaderSectionControllerClass) {
            %init(CommentPanelHeaderVerifiedCollapseGroup,
                  AWECommentPanelHeaderSwiftImpl_CommentPanelHeaderSectionController = commentHeaderSectionControllerClass);
        }

        Class commentHeaderGeneralClass = objc_getClass("AWECommentCommerceSwiftImpl.CommentHeaderGeneralView");
        if (!commentHeaderGeneralClass) {
            commentHeaderGeneralClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGeneralView");
        }
        if (commentHeaderGeneralClass) {
            %init(CommentHeaderGeneralGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGeneralView = commentHeaderGeneralClass);
        }

        Class commentHeaderGoodsClass = objc_getClass("AWECommentCommerceSwiftImpl.CommentHeaderGoodsView");
        if (!commentHeaderGoodsClass) {
            commentHeaderGoodsClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderGoodsView");
        }
        if (commentHeaderGoodsClass) {
            %init(CommentHeaderGoodsGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderGoodsView = commentHeaderGoodsClass);
        }
        Class commentHeaderTemplateClass = objc_getClass("AWECommentPanelHeaderSwiftImpl.CommentHeaderTemplateAnchorView");
        if (commentHeaderTemplateClass) {
            %init(CommentHeaderTemplateGroup, AWECommentPanelHeaderSwiftImpl_CommentHeaderTemplateAnchorView = commentHeaderTemplateClass);
        }

        Class tipsVCClass = objc_getClass("AWECommentPanelListSwiftImpl.CommentBottomTipsContainerViewController");
        if (tipsVCClass) {
            %init(CommentBottomTipsVCGroup, AWECommentPanelListSwiftImpl_CommentBottomTipsContainerViewController = tipsVCClass);
        }

    }
}
