#import "AwemeHeaders.h"
#import "DYYYManager.h"
#import <fcntl.h>
#import <math.h>
#import <spawn.h>
#import <stdlib.h>
#import <UIKit/UIKit.h>
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>
#import <unistd.h>
#import <objc/message.h>
#import <objc/runtime.h>

#import "DYYYABTestHook.h"

#import "DYYYAboutDialogView.h"
#import "DYYYBottomAlertView.h"
#import "DYYYCustomInputView.h"
#import "DYYYIconOptionsDialogView.h"
#import "DYYYKeyboardAvoidanceCoordinator.h"
#import "DYYYKeywordListView.h"
#import "DYYYOptionsSelectionView.h"

#import "DYYYConstants.h"
#import "DYYYFloatClearButton.h"
#import "DYYYFloatSpeedButton.h"
#import "DYYYFPSOverlay.h"
#import "DYYYHighFPSHooks.h"
#import "DYYYSettingsHelper.h"
#import "DYYYUtils.h"

@class DYYYIconOptionsDialogView;
static void showIconOptionsDialog(NSString *title, UIImage *previewImage, NSString *saveFilename, void (^onClear)(void), void (^onSelect)(void));

#import "DYYYPickerDelegates.h"

#ifdef __cplusplus
extern "C" {
#endif
void *kViewModelKey = &kViewModelKey;
#ifdef __cplusplus
}
#endif

static id dyyyRemoteConfigChangedToken = nil;
static char kDYYYWeatherViewGestureInstalledKey;
static char kDYYYWeatherSubviewGestureInstalledKey;

static char kDYYYSettingsSearchCoordinatorKey;
static BOOL DYYYBuildingSettingsSearchIndex = NO;
static BOOL DYYYSettingsSearchIndexBuilt = NO;
static NSString *const kDYYYFeedNowPlayingSettingTitle = @"屏蔽灵动岛抖音播放信息";
static NSString *const kDYYYFeedNowPlayingSettingIdentifier = @"DYYYDisableFeedNowPlayingInfo";
static NSString *const kDYYYFeedNowPlayingSVGIconName = @"ic_liveactivityplayslash_dyyy_outlined_20";
static NSString *const kDYYYExactInteractionCountsSettingIdentifier = DYYY_SHOW_EXACT_INTERACTION_COUNTS_KEY;
static NSString *const kDYYYExactInteractionCountsSVGIconName = @"ic_numberformat_dyyy_outlined_20";
static NSString *const kDYYYEnableHighFPSSettingTitle = @"开启最高可用帧率";
static NSString *const kDYYYEnableHighFPSSettingIdentifier = @"DYYYEnableHighFPS";
static NSString *const kDYYYEnableHighFPSSVGIconName = @"ic_highfps_dyyy_outlined_20";
static NSString *const kDYYYShowFPSOverlaySettingTitle = @"实时帧率显示";
static NSString *const kDYYYShowFPSOverlaySettingIdentifier = @"DYYYShowFPSOverlay";
static NSString *const kDYYYShowFPSOverlaySVGIconName = @"ic_fpsoverlay_dyyy_outlined_20";
static NSString *const kDYYYCommentPausePlaybackSettingIdentifier = @"DYYYCommentPausePlayback";
static NSString *const kDYYYCommentPausePlaybackSVGIconName = @"ic_commentpause_dyyy_outlined_20";
static NSString *const kDYYYAlbumMediaDescriptionSettingIdentifier = DYYY_ALBUM_MEDIA_DESCRIPTION_KEY;
static NSString *const kDYYYLoginBypassSVGIconName = @"ic_unlocknew_outlined_20";
static NSString *const kDYYYHideRecommendAppDownloadSettingIdentifier = @"DYYYHideRecommendAppDownload";
static NSString *const kDYYYMiniProgramJumpingAdsSettingIdentifier = @"DYYYEnableMiniProgramJumpingAds";
static NSString *const kDYYYSpeedButtonStickToEdgeSettingIdentifier = DYYY_SPEED_BUTTON_STICK_TO_EDGE_KEY;
static NSString *const kDYYYClearButtonStickToEdgeSettingIdentifier = DYYY_CLEAR_BUTTON_STICK_TO_EDGE_KEY;
static NSString *const kDYYYStickToEdgeSettingTitle = @"固定按钮贴边";
static NSString *const kDYYYStickToEdgeSVGIconName = @"ic_sticktoedge_dyyy_outlined_20";
static NSString *const kDYYYResetButtonPositionSettingTitle = @"重置按钮位置";
static NSString *const kDYYYSpeedButtonResetPositionSettingIdentifier = DYYY_RESET_SPEED_BUTTON_POSITION_KEY;
static NSString *const kDYYYClearButtonResetPositionSettingIdentifier = DYYY_RESET_CLEAR_BUTTON_POSITION_KEY;

static char kDYYYGeneratedSettingIconIdentifierKey;
static char kDYYYGeneratedSettingIconRetryScheduledKey;
static char kDYYYInlineOptionsSegmentedControlKey;
static char kDYYYInlineOptionsIdentifierKey;
static char kDYYYInlineTextFieldKey;
static char kDYYYInlineTextFieldIdentifierKey;
static char kDYYYArrowOriginalHiddenKey;
static char kDYYYArrowOriginalAlphaKey;
static char kDYYYArrowHiddenIdentifierKey;
static char kDYYYDetailOriginalHiddenKey;
static char kDYYYDetailHiddenIdentifierKey;
static char kDYYYOriginalInlineSubtitleKey;
static char kDYYYInlineSubtitleRefreshPendingKey;
#ifdef __cplusplus
extern "C" {
#endif
extern char **environ;
#ifdef __cplusplus
}
#endif

static UIImage *DYYYRenderGeneratedSettingTemplateIcon(NSString *cacheName, CGSize requestedSize, void (^drawBlock)(CGContextRef context, CGSize targetSize)) {
    CGSize targetSize = requestedSize;
    if (targetSize.width <= 0 || targetSize.height <= 0) {
        targetSize = CGSizeMake(20, 20);
    }

    static NSCache<NSString *, UIImage *> *imageCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      imageCache = [[NSCache alloc] init];
      imageCache.countLimit = 24;
    });

    NSString *cacheKey = [NSString stringWithFormat:@"%@-%@", cacheName, NSStringFromCGSize(targetSize)];
    UIImage *cachedImage = [imageCache objectForKey:cacheKey];
    if (cachedImage) {
        return cachedImage;
    }

    UIGraphicsBeginImageContextWithOptions(targetSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (!context) {
        UIGraphicsEndImageContext();
        return nil;
    }

    if (drawBlock) {
        drawBlock(context, targetSize);
    }

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    image = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    if (image) {
        [imageCache setObject:image forKey:cacheKey];
    }
    return image;
}

static UIImage *DYYYFeedNowPlayingIcon(CGSize requestedSize) {
    return DYYYRenderGeneratedSettingTemplateIcon(@"feed-now-playing", requestedSize, ^(CGContextRef context, CGSize targetSize) {
      CGContextScaleCTM(context, targetSize.width / 20.0, targetSize.height / 20.0);
      UIColor *iconColor = [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];
      [iconColor setFill];
      [iconColor setStroke];

      UIBezierPath *capsule = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(1.25, 5.25, 17.5, 9.5) cornerRadius:4.7];
      [capsule appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(2.75, 6.75, 14.5, 6.5) cornerRadius:3.2]];
      capsule.usesEvenOddFillRule = YES;
      [capsule fill];

      UIBezierPath *play = [UIBezierPath bezierPath];
      [play moveToPoint:CGPointMake(8.05, 7.438)];
      [play addCurveToPoint:CGPointMake(8.95682, 6.93014)
              controlPoint1:CGPointMake(8.05, 6.97219)
              controlPoint2:CGPointMake(8.55983, 6.68648)];
      [play addLineToPoint:CGPointMake(13.2548, 9.56814)];
      [play addCurveToPoint:CGPointMake(13.2548, 10.4319)
              controlPoint1:CGPointMake(13.6332, 9.80046)
              controlPoint2:CGPointMake(13.6332, 10.1995)];
      [play addLineToPoint:CGPointMake(8.95682, 13.0699)];
      [play addCurveToPoint:CGPointMake(8.05, 12.562)
              controlPoint1:CGPointMake(8.55983, 13.3135)
              controlPoint2:CGPointMake(8.05, 13.0278)];
      [play closePath];
      [play fill];

      CGContextSetBlendMode(context, kCGBlendModeClear);
      CGContextSetLineCap(context, kCGLineCapRound);
      CGContextSetLineWidth(context, 2.35);
      CGContextMoveToPoint(context, 3.6, 2.65);
      CGContextAddLineToPoint(context, 16.4, 17.35);
      CGContextStrokePath(context);

      CGContextSetBlendMode(context, kCGBlendModeNormal);
      CGContextSetStrokeColorWithColor(context, iconColor.CGColor);
      CGContextSetLineWidth(context, 1.5);
      CGContextMoveToPoint(context, 3.6, 2.65);
      CGContextAddLineToPoint(context, 16.4, 17.35);
      CGContextStrokePath(context);
    });
}

static UIImage *DYYYEnableHighFPSIcon(CGSize requestedSize) {
    return DYYYRenderGeneratedSettingTemplateIcon(@"enable-high-fps", requestedSize, ^(CGContextRef context, CGSize targetSize) {
      CGContextScaleCTM(context, targetSize.width / 20.0, targetSize.height / 20.0);
      UIColor *iconColor = [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];
      [iconColor setStroke];
      [iconColor setFill];
      CGContextSetLineWidth(context, 1.55);
      CGContextSetLineCap(context, kCGLineCapRound);
      CGContextSetLineJoin(context, kCGLineJoinRound);

      // 屏幕外框，呼应「帧率 / 刷新」
      UIBezierPath *screen = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.1, 2.4, 13.8, 15.2) cornerRadius:2.4];
      screen.lineWidth = 1.55;
      [screen stroke];

      // 刷新圆环
      UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:CGPointMake(10.0, 9.4)
                                                          radius:3.55
                                                      startAngle:(-55.0 * M_PI / 180.0)
                                                        endAngle:(235.0 * M_PI / 180.0)
                                                       clockwise:YES];
      ring.lineWidth = 1.55;
      [ring stroke];

      // 环末端箭头
      UIBezierPath *arrow = [UIBezierPath bezierPath];
      [arrow moveToPoint:CGPointMake(12.55, 5.55)];
      [arrow addLineToPoint:CGPointMake(14.35, 5.05)];
      [arrow addLineToPoint:CGPointMake(13.55, 6.85)];
      arrow.lineWidth = 1.45;
      arrow.lineCapStyle = kCGLineCapRound;
      arrow.lineJoinStyle = kCGLineJoinRound;
      [arrow stroke];

      // 底部速度短条，暗示更高刷新
      UIBezierPath *bars = [UIBezierPath bezierPath];
      [bars moveToPoint:CGPointMake(6.4, 15.55)];
      [bars addLineToPoint:CGPointMake(8.0, 15.55)];
      [bars moveToPoint:CGPointMake(9.15, 14.85)];
      [bars addLineToPoint:CGPointMake(11.35, 14.85)];
      [bars moveToPoint:CGPointMake(12.5, 14.15)];
      [bars addLineToPoint:CGPointMake(14.5, 14.15)];
      bars.lineWidth = 1.45;
      bars.lineCapStyle = kCGLineCapRound;
      [bars stroke];
    });
}

static UIImage *DYYYShowFPSOverlayIcon(CGSize requestedSize) {
    return DYYYRenderGeneratedSettingTemplateIcon(@"show-fps-overlay", requestedSize, ^(CGContextRef context, CGSize targetSize) {
      CGContextScaleCTM(context, targetSize.width / 20.0, targetSize.height / 20.0);
      UIColor *iconColor = [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];
      [iconColor setStroke];
      [iconColor setFill];
      CGContextSetLineWidth(context, 1.55);
      CGContextSetLineCap(context, kCGLineCapRound);
      CGContextSetLineJoin(context, kCGLineJoinRound);

      // 浮窗胶囊外形
      UIBezierPath *pill = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2.4, 6.4, 15.2, 7.2) cornerRadius:3.6];
      pill.lineWidth = 1.55;
      [pill stroke];

      // 三条高度递进的柱，表示实时帧率
      UIBezierPath *bars = [UIBezierPath bezierPath];
      [bars moveToPoint:CGPointMake(5.6, 11.4)];
      [bars addLineToPoint:CGPointMake(5.6, 9.6)];
      [bars moveToPoint:CGPointMake(8.5, 11.4)];
      [bars addLineToPoint:CGPointMake(8.5, 8.5)];
      [bars moveToPoint:CGPointMake(11.4, 11.4)];
      [bars addLineToPoint:CGPointMake(11.4, 7.7)];
      [bars moveToPoint:CGPointMake(14.3, 11.4)];
      [bars addLineToPoint:CGPointMake(14.3, 8.9)];
      bars.lineWidth = 1.55;
      bars.lineCapStyle = kCGLineCapRound;
      [bars stroke];
    });
}

static UIImage *DYYYCommentPausePlaybackIcon(CGSize requestedSize) {
    return DYYYRenderGeneratedSettingTemplateIcon(@"comment-pause-playback", requestedSize, ^(CGContextRef context, CGSize targetSize) {
      CGContextScaleCTM(context, targetSize.width / 20.0, targetSize.height / 20.0);
      UIColor *iconColor = [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];
      [iconColor setFill];

      UIBezierPath *bubble = [UIBezierPath bezierPath];
      [bubble moveToPoint:CGPointMake(18.2295, 9.19579)];
      [bubble addCurveToPoint:CGPointMake(9.99951, 1.77002)
              controlPoint1:CGPointMake(18.2295, 5.01896)
              controlPoint2:CGPointMake(14.465, 1.77002)];
      [bubble addCurveToPoint:CGPointMake(1.76953, 9.1959)
              controlPoint1:CGPointMake(5.53405, 1.77002)
              controlPoint2:CGPointMake(1.76953, 5.01897)];
      [bubble addCurveToPoint:CGPointMake(9.37823, 16.1374)
              controlPoint1:CGPointMake(1.76953, 13.2087)
              controlPoint2:CGPointMake(5.29956, 15.8541)];
      [bubble addLineToPoint:CGPointMake(9.37823, 17.3396)];
      [bubble addCurveToPoint:CGPointMake(10.5834, 18.078)
              controlPoint1:CGPointMake(9.37823, 17.9499)
              controlPoint2:CGPointMake(10.0237, 18.3639)];
      [bubble addCurveToPoint:CGPointMake(15.6612, 14.5993)
              controlPoint1:CGPointMake(11.2208, 17.7525)
              controlPoint2:CGPointMake(13.9782, 16.2991)];
      [bubble addCurveToPoint:CGPointMake(18.2295, 9.19579)
              controlPoint1:CGPointMake(17.2249, 13.0198)
              controlPoint2:CGPointMake(18.2295, 11.2807)];
      [bubble closePath];

      [bubble moveToPoint:CGPointMake(9.99951, 3.23002)];
      [bubble addCurveToPoint:CGPointMake(16.7695, 9.19579)
              controlPoint1:CGPointMake(13.8188, 3.23002)
              controlPoint2:CGPointMake(16.7695, 5.97659)];
      [bubble addCurveToPoint:CGPointMake(14.6236, 13.5721)
              controlPoint1:CGPointMake(16.7695, 10.7555)
              controlPoint2:CGPointMake(16.035, 12.1465)];
      [bubble addCurveToPoint:CGPointMake(10.8382, 16.2821)
              controlPoint1:CGPointMake(13.5418, 14.6648)
              controlPoint2:CGPointMake(11.9072, 15.6785)];
      [bubble addLineToPoint:CGPointMake(10.8382, 14.7027)];
      [bubble addLineToPoint:CGPointMake(10.1082, 14.7027)];
      [bubble addCurveToPoint:CGPointMake(3.22953, 9.1959)
              controlPoint1:CGPointMake(6.20144, 14.7027)
              controlPoint2:CGPointMake(3.22953, 12.3416)];
      [bubble addCurveToPoint:CGPointMake(9.99951, 3.23002)
              controlPoint1:CGPointMake(3.22953, 5.97658)
              controlPoint2:CGPointMake(6.1803, 3.23002)];
      [bubble closePath];
      bubble.usesEvenOddFillRule = YES;
      [bubble fill];

      UIBezierPath *leftPause = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(7.8, 7.15, 1.5, 4.7) cornerRadius:0.75];
      [leftPause fill];
      UIBezierPath *rightPause = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(10.7, 7.15, 1.5, 4.7) cornerRadius:0.75];
      [rightPause fill];
    });
}

static UIImage *DYYYMiniProgramJumpingAdsIcon(CGSize requestedSize) {
    return DYYYRenderGeneratedSettingTemplateIcon(@"mini-program-jumping-ads-v2", requestedSize, ^(CGContextRef context, CGSize targetSize) {
      CGContextScaleCTM(context, targetSize.width / 20.0, targetSize.height / 20.0);
      UIColor *iconColor = [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];
      [iconColor setStroke];
      CGContextSetLineWidth(context, 1.55);
      CGContextSetLineCap(context, kCGLineCapRound);
      CGContextSetLineJoin(context, kCGLineJoinRound);

      UIBezierPath *tiles = [UIBezierPath bezierPath];
      [tiles appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.0, 3.0, 5.2, 5.2) cornerRadius:1.15]];
      [tiles appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(11.3, 3.3, 3.9, 3.9) cornerRadius:0.9]];
      [tiles appendPath:[UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.3, 11.3, 3.9, 3.9) cornerRadius:0.9]];
      tiles.lineWidth = 1.55;
      tiles.lineCapStyle = kCGLineCapRound;
      tiles.lineJoinStyle = kCGLineJoinRound;
      [tiles stroke];

      UIBezierPath *arrow = [UIBezierPath bezierPath];
      [arrow moveToPoint:CGPointMake(10.0, 14.3)];
      [arrow addLineToPoint:CGPointMake(16.7, 14.3)];
      [arrow moveToPoint:CGPointMake(14.1, 11.7)];
      [arrow addLineToPoint:CGPointMake(16.8, 14.3)];
      [arrow addLineToPoint:CGPointMake(14.1, 16.9)];
      arrow.lineWidth = 1.65;
      arrow.lineCapStyle = kCGLineCapRound;
      arrow.lineJoinStyle = kCGLineJoinRound;
      [arrow stroke];
    });
}

static UIImage *DYYYStickToEdgeIcon(CGSize requestedSize) {
    return DYYYRenderGeneratedSettingTemplateIcon(@"stick-to-edge", requestedSize, ^(CGContextRef context, CGSize targetSize) {
      CGContextScaleCTM(context, targetSize.width / 20.0, targetSize.height / 20.0);
      UIColor *iconColor = [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];
      [iconColor setStroke];
      [iconColor setFill];
      CGContextSetLineWidth(context, 1.55);
      CGContextSetLineCap(context, kCGLineCapRound);
      CGContextSetLineJoin(context, kCGLineJoinRound);

      UIBezierPath *screen = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(3.15, 2.35, 13.7, 15.3) cornerRadius:2.35];
      screen.lineWidth = 1.55;
      [screen stroke];

      UIBezierPath *button = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(12.05, 8.15, 3.7, 3.7)];
      button.lineWidth = 1.45;
      [button stroke];

      UIBezierPath *guides = [UIBezierPath bezierPath];
      [guides moveToPoint:CGPointMake(4.55, 6.2)];
      [guides addLineToPoint:CGPointMake(4.55, 13.8)];
      [guides moveToPoint:CGPointMake(15.45, 6.2)];
      [guides addLineToPoint:CGPointMake(15.45, 13.8)];
      guides.lineWidth = 1.35;
      guides.lineCapStyle = kCGLineCapRound;
      [guides stroke];
    });
}

static UIImage *DYYYExactInteractionCountsIcon(CGSize requestedSize) {
    return DYYYRenderGeneratedSettingTemplateIcon(@"exact-interaction-counts", requestedSize, ^(CGContextRef context, CGSize targetSize) {
      CGContextScaleCTM(context, targetSize.width / 20.0, targetSize.height / 20.0);
      UIColor *iconColor = [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];
      [iconColor setStroke];
      CGContextSetLineWidth(context, 1.55);
      CGContextSetLineCap(context, kCGLineCapRound);
      CGContextSetLineJoin(context, kCGLineJoinRound);

      UIBezierPath *frame = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2.55, 3.0, 14.9, 14.0) cornerRadius:2.2];
      frame.lineWidth = 1.55;
      [frame stroke];

      UIBezierPath *bars = [UIBezierPath bezierPath];
      [bars moveToPoint:CGPointMake(5.6, 13.9)];
      [bars addLineToPoint:CGPointMake(5.6, 11.25)];
      [bars moveToPoint:CGPointMake(9.95, 13.9)];
      [bars addLineToPoint:CGPointMake(9.95, 8.95)];
      [bars moveToPoint:CGPointMake(14.3, 13.9)];
      [bars addLineToPoint:CGPointMake(14.3, 6.65)];
      bars.lineWidth = 1.7;
      [bars stroke];

      UIBezierPath *baseline = [UIBezierPath bezierPath];
      [baseline moveToPoint:CGPointMake(4.7, 13.9)];
      [baseline addLineToPoint:CGPointMake(15.2, 13.9)];
      baseline.lineWidth = 1.35;
      [baseline stroke];
    });
}

@interface AWESettingsTableViewCell : UITableViewCell
@property(nonatomic, strong) AWESettingItemModel *itemModel;
@property(nonatomic, strong) UILabel *titleLabel;
@property(nonatomic, strong) UILabel *subTitleLabel;
@property(nonatomic, strong) UILabel *fancySubtitleLabel;
@property(nonatomic, strong) UILabel *detailLabel;
@property(nonatomic, strong) UIImageView *iconImageView;
@property(nonatomic, strong) UIImageView *arrowImageView;
@property(nonatomic, strong) UISwitch *aSwitch;
@property(nonatomic, strong) UIButton *rightButton;
@property(nonatomic, strong) UIButton *detailButton;
- (void)updateSubviews;
- (void)updateSubviewsAfterLayout;
- (void)layoutSubviews;
@end

static BOOL DYYYIsGeneratedSettingIconIdentifier(NSString *identifier) {
    return [identifier isEqualToString:kDYYYFeedNowPlayingSettingIdentifier] ||
           [identifier isEqualToString:kDYYYEnableHighFPSSettingIdentifier] ||
           [identifier isEqualToString:kDYYYShowFPSOverlaySettingIdentifier] ||
           [identifier isEqualToString:kDYYYCommentPausePlaybackSettingIdentifier] ||
           [identifier isEqualToString:kDYYYMiniProgramJumpingAdsSettingIdentifier] ||
           [identifier isEqualToString:kDYYYExactInteractionCountsSettingIdentifier] ||
           [identifier isEqualToString:kDYYYSpeedButtonStickToEdgeSettingIdentifier] ||
           [identifier isEqualToString:kDYYYClearButtonStickToEdgeSettingIdentifier];
}

static UIImage *DYYYGeneratedSettingIconForIdentifier(NSString *identifier, CGSize targetSize) {
    if ([identifier isEqualToString:kDYYYFeedNowPlayingSettingIdentifier]) {
        return DYYYFeedNowPlayingIcon(targetSize);
    }
    if ([identifier isEqualToString:kDYYYEnableHighFPSSettingIdentifier]) {
        return DYYYEnableHighFPSIcon(targetSize);
    }
    if ([identifier isEqualToString:kDYYYShowFPSOverlaySettingIdentifier]) {
        return DYYYShowFPSOverlayIcon(targetSize);
    }
    if ([identifier isEqualToString:kDYYYCommentPausePlaybackSettingIdentifier]) {
        return DYYYCommentPausePlaybackIcon(targetSize);
    }
    if ([identifier isEqualToString:kDYYYMiniProgramJumpingAdsSettingIdentifier]) {
        return DYYYMiniProgramJumpingAdsIcon(targetSize);
    }
    if ([identifier isEqualToString:kDYYYExactInteractionCountsSettingIdentifier]) {
        return DYYYExactInteractionCountsIcon(targetSize);
    }
    if ([identifier isEqualToString:kDYYYSpeedButtonStickToEdgeSettingIdentifier] ||
        [identifier isEqualToString:kDYYYClearButtonStickToEdgeSettingIdentifier]) {
        return DYYYStickToEdgeIcon(targetSize);
    }
    return nil;
}

static void DYYYApplyGeneratedSettingIconToCellInternal(AWESettingsTableViewCell *cell, BOOL scheduleRetry);

static void DYYYScheduleGeneratedSettingIconReapply(AWESettingsTableViewCell *cell) {
    if (!cell) {
        return;
    }

    if (objc_getAssociatedObject(cell, &kDYYYGeneratedSettingIconRetryScheduledKey)) {
        return;
    }

    objc_setAssociatedObject(cell, &kDYYYGeneratedSettingIconRetryScheduledKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    __weak AWESettingsTableViewCell *weakCell = cell;

    dispatch_async(dispatch_get_main_queue(), ^{
      DYYYApplyGeneratedSettingIconToCellInternal(weakCell, NO);
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.06 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      DYYYApplyGeneratedSettingIconToCellInternal(weakCell, NO);
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      AWESettingsTableViewCell *strongCell = weakCell;
      DYYYApplyGeneratedSettingIconToCellInternal(strongCell, NO);
      if (strongCell) {
          objc_setAssociatedObject(strongCell, &kDYYYGeneratedSettingIconRetryScheduledKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      }
    });
}

static BOOL DYYYSettingTextGroupCenterY(AWESettingsTableViewCell *cell, UIView *targetView, CGFloat *centerY) {
    if (!cell.titleLabel.superview || !targetView) {
        return NO;
    }

    CGRect textFrame = [cell.titleLabel convertRect:cell.titleLabel.bounds toView:targetView];
    BOOL hasTextFrame = !CGRectIsEmpty(textFrame);
    NSArray<UILabel *> *subtitleLabels = @[ cell.subTitleLabel ?: (UILabel *)NSNull.null, cell.fancySubtitleLabel ?: (UILabel *)NSNull.null ];
    for (id candidate in subtitleLabels) {
        if (![candidate isKindOfClass:UILabel.class]) {
            continue;
        }
        UILabel *label = candidate;
        if (!label.superview || label.hidden || label.alpha <= 0.01 || label.text.length == 0 || CGRectIsEmpty(label.bounds)) {
            continue;
        }
        CGRect subtitleFrame = [label convertRect:label.bounds toView:targetView];
        textFrame = hasTextFrame ? CGRectUnion(textFrame, subtitleFrame) : subtitleFrame;
        hasTextFrame = YES;
    }
    if (!hasTextFrame) {
        return NO;
    }
    if (centerY) {
        *centerY = CGRectGetMidY(textFrame);
    }
    return YES;
}

static void DYYYCenterSettingIconForSubtitle(AWESettingsTableViewCell *cell) {
    UIImageView *iconView = cell.iconImageView;
    if (!iconView.superview || iconView.hidden || CGRectGetHeight(iconView.bounds) <= 0.0) {
        return;
    }
    if (cell.itemModel.subTitle.length == 0) {
        iconView.transform = CGAffineTransformIdentity;
        return;
    }

    CGFloat textCenterY = 0.0;
    if (!DYYYSettingTextGroupCenterY(cell, iconView.superview, &textCenterY)) {
        return;
    }
    CGFloat offsetY = textCenterY - iconView.center.y;
    offsetY = round(offsetY * UIScreen.mainScreen.scale) / UIScreen.mainScreen.scale;
    iconView.transform = CGAffineTransformMakeTranslation(0.0, offsetY);
}

static void DYYYApplyGeneratedSettingIconToCellInternal(AWESettingsTableViewCell *cell, BOOL scheduleRetry) {
    AWESettingItemModel *itemModel = cell.itemModel;
    UIImageView *iconView = cell.iconImageView;
    NSString *identifier = itemModel.identifier;

    if (iconView) {
        iconView.contentMode = UIViewContentModeScaleAspectFit;
        iconView.layer.contentsGravity = kCAGravityResizeAspect;
        iconView.layer.contentsRect = CGRectMake(0.0, 0.0, 1.0, 1.0);
        DYYYCenterSettingIconForSubtitle(cell);
    }

    if (!DYYYIsGeneratedSettingIconIdentifier(identifier)) {
        if (iconView) {
            objc_setAssociatedObject(iconView, &kDYYYGeneratedSettingIconIdentifierKey, nil, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        return;
    }

    if (!iconView) {
        if (scheduleRetry) {
            DYYYScheduleGeneratedSettingIconReapply(cell);
        }
        return;
    }

    UIImage *iconImage = DYYYGeneratedSettingIconForIdentifier(identifier, iconView.bounds.size);
    if (!iconImage) {
        return;
    }

    objc_setAssociatedObject(iconView, &kDYYYGeneratedSettingIconIdentifierKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    iconView.image = iconImage;
    iconView.contentMode = UIViewContentModeScaleAspectFit;
    iconView.hidden = NO;
    iconView.alpha = 1.0;
    iconView.tintColor = cell.titleLabel.textColor ?: cell.tintColor ?: [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0];

    if (scheduleRetry) {
        DYYYScheduleGeneratedSettingIconReapply(cell);
    }
}

static void DYYYApplyGeneratedSettingIconToCell(AWESettingsTableViewCell *cell) {
    DYYYApplyGeneratedSettingIconToCellInternal(cell, YES);
}

static void DYYYRemoveSegmentedControlForKey(AWESettingsTableViewCell *cell, const void *key) {
    UISegmentedControl *segmentedControl = objc_getAssociatedObject(cell, key);
    if (segmentedControl) {
        [segmentedControl removeFromSuperview];
        objc_setAssociatedObject(cell, key, nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

static NSArray<NSString *> *DYYYInlineOptionsForIdentifier(NSString *identifier) {
    NSDictionary<NSString *, NSArray<NSString *> *> *options = @{
        @"DYYYDefaultSpeed" : @[ @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x" ],
        @"DYYYLongPressSpeed" : @[ @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x" ],
        @"DYYYScheduleStyle" : @[ @"进度条两侧上下", @"进度条左侧剩余", @"进度条左侧完整", @"进度条右侧剩余", @"进度条右侧完整" ],
        @"DYYYLabelStyle" : @[ @"文案标签显示", @"文案标签隐藏", @"文案标签禁止跳转搜索" ],
        @"DYYYLiveQuality" : @[ @"蓝光帧彩", @"蓝光", @"超清", @"高清", @"标清", @"自动" ],
        @"DYYYHDRMode" : @[ @"关闭", @"全局屏蔽HDR效果", @"全局过滤HDR作品" ]
    };
    return options[identifier];
}

static CGFloat DYYYInlineOptionsRequiredWidth(NSArray<NSString *> *options) {
    UIFont *font = [UIFont systemFontOfSize:13.0];
    CGFloat width = 0.0;
    for (NSString *option in options) {
        width += MAX(42.0, ceil([option sizeWithAttributes:@{NSFontAttributeName : font}].width) + 18.0);
    }
    return width;
}

static BOOL DYYYShouldUseInlineOptions(AWESettingItemModel *itemModel, CGFloat contentWidth, CGRect titleFrame) {
    NSArray<NSString *> *options = DYYYInlineOptionsForIdentifier(itemModel.identifier);
    if (options.count < 2) {
        return NO;
    }
    if (contentWidth <= 0) {
        contentWidth = CGRectGetWidth(UIScreen.mainScreen.bounds);
    }
    CGFloat titleMaxX = CGRectGetMaxX(titleFrame);
    if (titleMaxX <= 0) {
        CGFloat titleWidth = ceil([itemModel.title sizeWithAttributes:@{NSFontAttributeName : [UIFont systemFontOfSize:16.0]}].width);
        titleMaxX = 64.0 + titleWidth;
    }
    CGFloat availableWidth = contentWidth - titleMaxX - 18.0;
    return DYYYInlineOptionsRequiredWidth(options) <= availableWidth;
}

static BOOL DYYYShouldUseInlineOptionsForCurrentScreen(AWESettingItemModel *itemModel) {
    return DYYYShouldUseInlineOptions(itemModel, CGRectGetWidth(UIScreen.mainScreen.bounds), CGRectZero);
}

static void DYYYApplyInlineOptionsToCell(AWESettingsTableViewCell *cell) {
    AWESettingItemModel *itemModel = cell.itemModel;
    NSArray<NSString *> *options = DYYYInlineOptionsForIdentifier(itemModel.identifier);
    UISegmentedControl *control = objc_getAssociatedObject(cell, &kDYYYInlineOptionsSegmentedControlKey);
    NSString *configuredIdentifier = objc_getAssociatedObject(cell, &kDYYYInlineOptionsIdentifierKey);
    BOOL shouldUseInline = options.count > 0 && DYYYShouldUseInlineOptions(itemModel, CGRectGetWidth(cell.contentView.bounds), cell.titleLabel.frame);
    if (!shouldUseInline) {
        if (control) {
            [control removeFromSuperview];
            objc_setAssociatedObject(cell, &kDYYYInlineOptionsSegmentedControlKey, nil, OBJC_ASSOCIATION_ASSIGN);
            objc_setAssociatedObject(cell, &kDYYYInlineOptionsIdentifierKey, nil, OBJC_ASSOCIATION_ASSIGN);
        }
        return;
    }

    if (!control || ![configuredIdentifier isEqualToString:itemModel.identifier]) {
        [control removeFromSuperview];
        control = [[UISegmentedControl alloc] initWithItems:options];
        [control addTarget:cell action:@selector(dyyyInlineOptionsSegmentChanged:) forControlEvents:UIControlEventValueChanged];
        control.translatesAutoresizingMaskIntoConstraints = NO;
        [cell.contentView addSubview:control];
        objc_setAssociatedObject(cell, &kDYYYInlineOptionsSegmentedControlKey, control, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &kDYYYInlineOptionsIdentifierKey, itemModel.identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
        [NSLayoutConstraint activateConstraints:@[
            [control.trailingAnchor constraintEqualToAnchor:cell.contentView.trailingAnchor constant:-18.0],
            [control.centerYAnchor constraintEqualToAnchor:cell.contentView.centerYAnchor],
            [control.widthAnchor constraintEqualToConstant:DYYYInlineOptionsRequiredWidth(options)],
            [control.heightAnchor constraintEqualToConstant:28.0]
        ]];
    }

    NSString *selectedValue = [NSUserDefaults.standardUserDefaults stringForKey:itemModel.identifier] ?: itemModel.detail ?: options.firstObject;
    NSUInteger selectedIndex = [options indexOfObject:selectedValue];
    control.selectedSegmentIndex = selectedIndex == NSNotFound ? 0 : (NSInteger)selectedIndex;
    control.enabled = itemModel.isEnable;
    control.alpha = itemModel.isEnable ? 1.0 : 0.35;
    itemModel.detail = @"";
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.accessoryView = nil;
}

static NSSet<NSString *> *DYYYInlineTextInputIdentifiers(void) {
    static NSSet<NSString *> *identifiers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      identifiers = [NSSet setWithArray:@[
          @"DYYYAvatarViewTransparency", @"DYYYCommentBlurTransparent", @"DYYYCommentContent", @"DYYYDescriptionScale",
          @"DYYYDescriptionVerticalOffset", @"DYYYElementScale", @"DYYYFilterLowLikes", @"DYYYFilterTimeLimit", @"DYYYFriendsTitle",
          @"DYYYGeonamesUsername", @"DYYYGlobalTransparency", @"DYYYIPLabelScale", @"DYYYIPLabelVerticalOffset", @"DYYYIndexTitle", @"DYYYInterfaceDownload",
          @"DYYYMsgTitle", @"DYYYNicknameScale", @"DYYYNicknameVerticalOffset", @"DYYYNotificationCornerRadius", @"DYYYRemoteConfigURL",
          @"DYYYSelfTitle",
          @"DYYYSheetBlurTransparent", @"DYYYTabBarHeight", @"DYYYTimelineVerticalPosition", @"DYYYTopBarTransparent",
          @"DYYYVideoBGColor", @"DYYYDanmuColor", @"DYYYLabelColor", @"DYYYProgressLabelColor",
          @"DYYYEnableFloatClearButtonSize", @"DYYYSpeedButtonSize", @"DYYYSpeedSettings", @"DYYYAutoHideSpeedButtonTime"
      ]];
    });
    return identifiers;
}

static NSString *DYYYInlineTextInputPlaceholder(NSString *identifier) {
    NSDictionary<NSString *, NSString *> *placeholders = @{
        @"DYYYFilterLowLikes" : @"填0关闭", @"DYYYFilterTimeLimit" : @"单位：天",
        @"DYYYInterfaceDownload" : @"解析接口以url=结尾", @"DYYYRemoteConfigURL" : @"JSON URL",
        @"DYYYEnableFloatClearButtonSize" : @"20-60",
        @"DYYYSpeedButtonSize" : @"20-60",
        @"DYYYSpeedSettings" : @"逗号分隔",
        @"DYYYAutoHideSpeedButtonTime" : @"s",
        @"DYYYCommentContent" : @"不填则默认",
        @"DYYYVideoBGColor" : @"十六进制", @"DYYYDanmuColor" : @"十六进制或 random",
        @"DYYYLabelColor" : @"十六进制", @"DYYYProgressLabelColor" : @"十六进制"
    };
    return placeholders[identifier] ?: @"不填则默认";
}

static NSSet<NSString *> *DYYYScaleSectionIdentifiers(void) {
    static NSSet<NSString *> *identifiers = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      identifiers = [NSSet setWithArray:@[
          @"DYYYElementScale", @"DYYYNicknameScale", @"DYYYDescriptionScale", @"DYYYIPLabelScale", @"DYYYNicknameVerticalOffset",
          @"DYYYDescriptionVerticalOffset", @"DYYYIPLabelVerticalOffset", @"DYYYTabBarHeight"
      ]];
    });
    return identifiers;
}

static UIKeyboardType DYYYInlineTextInputKeyboardType(NSString *identifier) {
    if ([DYYYScaleSectionIdentifiers() containsObject:identifier]) {
        return UIKeyboardTypeDefault;
    }
    NSSet<NSString *> *decimalIdentifiers = [NSSet setWithArray:@[
        @"DYYYAvatarViewTransparency", @"DYYYCommentBlurTransparent", @"DYYYGlobalTransparency", @"DYYYNotificationCornerRadius",
        @"DYYYSheetBlurTransparent", @"DYYYTimelineVerticalPosition", @"DYYYTopBarTransparent", @"DYYYEnableFloatClearButtonSize",
        @"DYYYSpeedButtonSize", @"DYYYAutoHideSpeedButtonTime"
    ]];
    if ([identifier isEqualToString:@"DYYYFilterLowLikes"] || [identifier isEqualToString:@"DYYYFilterTimeLimit"]) {
        return UIKeyboardTypeNumberPad;
    }
    return [decimalIdentifiers containsObject:identifier] ? UIKeyboardTypeDecimalPad : UIKeyboardTypeDefault;
}

static NSString *DYYYInlineTextInputCurrentValue(NSString *identifier) {
    id value = [NSUserDefaults.standardUserDefaults objectForKey:identifier];
    if ([value isKindOfClass:NSString.class]) {
        return value;
    }
    if ([value isKindOfClass:NSNumber.class]) {
        return [(NSNumber *)value stringValue];
    }
    if ([identifier isEqualToString:@"DYYYEnableFloatClearButtonSize"]) {
        return @"40";
    }
    if ([identifier isEqualToString:@"DYYYSpeedButtonSize"]) {
        return @"35";
    }
    if ([identifier isEqualToString:@"DYYYSpeedSettings"]) {
        NSString *saved = [NSUserDefaults.standardUserDefaults stringForKey:identifier];
        return saved.length > 0 ? saved : @"1.0,1.25,1.5,2.0";
    }
    if ([identifier isEqualToString:@"DYYYAutoHideSpeedButtonTime"]) {
        if ([NSUserDefaults.standardUserDefaults objectForKey:identifier] == nil) {
            return @"30";
        }
        return [NSString stringWithFormat:@"%.0f", [NSUserDefaults.standardUserDefaults doubleForKey:identifier]];
    }
    if ([identifier isEqualToString:@"DYYYRemoteConfigURL"]) {
        return DYYY_DEFAULT_ABTEST_URL;
    }
    return @"";
}

static CGFloat DYYYInlineTextInputPreferredWidth(NSString *identifier, CGFloat contentWidth) {
    NSSet<NSString *> *compactIdentifiers = [NSSet setWithArray:@[
        @"DYYYAvatarViewTransparency", @"DYYYCommentBlurTransparent", @"DYYYDescriptionScale", @"DYYYDescriptionVerticalOffset",
        @"DYYYElementScale", @"DYYYEnableFloatClearButtonSize", @"DYYYSpeedButtonSize", @"DYYYAutoHideSpeedButtonTime",
        @"DYYYFilterLowLikes", @"DYYYFilterTimeLimit", @"DYYYGlobalTransparency",
        @"DYYYIPLabelScale", @"DYYYIPLabelVerticalOffset", @"DYYYNicknameScale", @"DYYYNicknameVerticalOffset", @"DYYYNotificationCornerRadius",
        @"DYYYSheetBlurTransparent", @"DYYYTabBarHeight", @"DYYYTimelineVerticalPosition", @"DYYYTopBarTransparent"
    ]];
    NSSet<NSString *> *longIdentifiers = [NSSet setWithArray:@[
        @"DYYYCommentContent", @"DYYYInterfaceDownload", @"DYYYRemoteConfigURL", @"DYYYSpeedSettings"
    ]];
    if ([compactIdentifiers containsObject:identifier]) {
        return MIN(contentWidth * 0.34, 132.0);
    }
    if ([longIdentifiers containsObject:identifier]) {
        return MIN(contentWidth * 0.46, 184.0);
    }
    return MIN(contentWidth * 0.40, 160.0);
}

static NSString *DYYYCommitInlineTextInput(AWESettingItemModel *itemModel, NSString *text) {
    NSString *identifier = itemModel.identifier;
    NSString *trimmed = [text ?: @"" stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    NSString *value = [identifier isEqualToString:@"DYYYCommentContent"] ? (text ?: @"") : trimmed;

    if ([identifier isEqualToString:@"DYYYFilterLowLikes"]) {
        NSScanner *scanner = [NSScanner scannerWithString:value];
        NSInteger number = 0;
        if (![scanner scanInteger:&number] || !scanner.isAtEnd) {
            [DYYYUtils showToast:@"请输入有效的数字"];
            return nil;
        }
        value = [NSString stringWithFormat:@"%ld", (long)MAX(number, 0)];
        [DYYYSettingsHelper setUserDefaults:value forKey:identifier];
    } else if ([identifier isEqualToString:@"DYYYEnableFloatClearButtonSize"]) {
        NSInteger size = value.integerValue;
        if (size < 20 || size > 60) {
            [DYYYUtils showToast:@"请输入20-60之间的有效数值"];
            return nil;
        }
        [NSUserDefaults.standardUserDefaults setFloat:size forKey:identifier];
        value = [NSString stringWithFormat:@"%ld", (long)size];
        reloadClearButtonConfiguration();
    } else if ([identifier isEqualToString:@"DYYYSpeedButtonSize"]) {
        NSInteger size = value.integerValue;
        if (size < 20 || size > 60) {
            [DYYYUtils showToast:@"请输入20-60之间的有效数值"];
            return nil;
        }
        [NSUserDefaults.standardUserDefaults setFloat:size forKey:identifier];
        value = [NSString stringWithFormat:@"%ld", (long)size];
        speedButtonSize = size;
        DYYYRefreshFloatSpeedButton();
    } else if ([identifier isEqualToString:@"DYYYSpeedSettings"]) {
        if (value.length == 0) {
            [DYYYUtils showToast:@"请输入有效的倍速数值"];
            return nil;
        }
        [DYYYSettingsHelper setUserDefaults:value forKey:identifier];
        updateSpeedButtonUI();
    } else if ([identifier isEqualToString:@"DYYYAutoHideSpeedButtonTime"]) {
        if (value.length == 0) {
            [DYYYUtils showToast:@"请输入有效的时间"];
            return nil;
        }
        NSScanner *scanner = [NSScanner scannerWithString:value];
        double seconds = 0.0;
        if (![scanner scanDouble:&seconds] || seconds <= 0.0 || !scanner.isAtEnd) {
            [DYYYUtils showToast:@"请输入有效的时间"];
            return nil;
        }
        [NSUserDefaults.standardUserDefaults setFloat:seconds forKey:identifier];
        value = [NSString stringWithFormat:@"%.0f", seconds];
        if (speedButton) {
            if (speedButton.isEdgeHidden) {
                [speedButton dyyy_restoreFromEdgeHidden];
            } else {
                [speedButton resetFadeTimer];
            }
        }
    } else {
        [DYYYSettingsHelper setUserDefaults:value forKey:identifier];
    }

    if ([identifier isEqualToString:@"DYYYInterfaceDownload"]) {
        [DYYYSettingsHelper updateDependentItemsForSetting:identifier value:value];
    }
    [DYYYSettingsHelper handleConflictsAndDependenciesForSetting:identifier isEnabled:(value.length > 0)];
    itemModel.detail = value;
    [itemModel refreshCell];
    return value;
}

static void DYYYRemoveInlineTextField(AWESettingsTableViewCell *cell) {
    UITextField *textField = objc_getAssociatedObject(cell, &kDYYYInlineTextFieldKey);
    if (textField) {
        if (cell.accessoryView == textField)
            cell.accessoryView = nil;
        [textField removeFromSuperview];
        objc_setAssociatedObject(cell, &kDYYYInlineTextFieldKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(cell, &kDYYYInlineTextFieldIdentifierKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }
}

static void DYYYApplyInlineTextFieldToCell(AWESettingsTableViewCell *cell) {
    AWESettingItemModel *itemModel = cell.itemModel;
    NSString *identifier = itemModel.identifier;
    if (![DYYYInlineTextInputIdentifiers() containsObject:identifier]) {
        DYYYRemoveInlineTextField(cell);
        return;
    }

    itemModel.cellTappedBlock = nil;
    UITextField *textField = objc_getAssociatedObject(cell, &kDYYYInlineTextFieldKey);
    NSString *configuredIdentifier = objc_getAssociatedObject(cell, &kDYYYInlineTextFieldIdentifierKey);
    if (!textField || ![configuredIdentifier isEqualToString:identifier]) {
        DYYYRemoveInlineTextField(cell);
        textField = [[UITextField alloc] initWithFrame:CGRectMake(0.0, 0.0, 148.0, 32.0)];
        textField.borderStyle = UITextBorderStyleNone;
        textField.clearButtonMode = UITextFieldViewModeWhileEditing;
        textField.textAlignment = NSTextAlignmentCenter;
        textField.font = [UIFont systemFontOfSize:13.0];
        textField.returnKeyType = UIReturnKeyDone;
        textField.layer.cornerRadius = 6.0;
        textField.layer.borderWidth = 0.5;
        textField.layer.masksToBounds = YES;
        [textField addTarget:cell action:@selector(dyyyInlineTextEditingDidBegin:) forControlEvents:UIControlEventEditingDidBegin];
        [textField addTarget:cell action:@selector(dyyyInlineTextEditingDidEnd:) forControlEvents:UIControlEventEditingDidEnd];
        [textField addTarget:cell action:@selector(dyyyInlineTextReturn:) forControlEvents:UIControlEventEditingDidEndOnExit];
        [cell.contentView addSubview:textField];
        objc_setAssociatedObject(cell, &kDYYYInlineTextFieldKey, textField, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        objc_setAssociatedObject(cell, &kDYYYInlineTextFieldIdentifierKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
    }

    NSString *placeholder = DYYYInlineTextInputPlaceholder(identifier);
    BOOL usesLightBackground = [DYYYUtils usesDouyinLightBackground];
    UIColor *textColor = usesLightBackground ? [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:1.0]
                                               : [UIColor colorWithWhite:1.0 alpha:0.90];
    UIColor *placeholderColor = usesLightBackground ? [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:0.46]
                                                      : [UIColor colorWithWhite:1.0 alpha:0.46];
    UIColor *fieldColor = usesLightBackground ? [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:0.05]
                                                : [UIColor colorWithWhite:1.0 alpha:0.08];
    UIColor *borderColor = usesLightBackground ? [UIColor colorWithRed:22.0 / 255.0 green:24.0 / 255.0 blue:35.0 / 255.0 alpha:0.14]
                                                 : [UIColor colorWithWhite:1.0 alpha:0.18];
    textField.placeholder = placeholder;
    textField.attributedPlaceholder = [[NSAttributedString alloc] initWithString:placeholder
                                                                      attributes:@{ NSForegroundColorAttributeName : placeholderColor }];
    textField.textColor = textColor;
    textField.tintColor = textColor;
    textField.backgroundColor = fieldColor;
    textField.layer.borderColor = borderColor.CGColor;
    textField.keyboardAppearance = usesLightBackground ? UIKeyboardAppearanceDefault : UIKeyboardAppearanceDark;
    textField.keyboardType = DYYYInlineTextInputKeyboardType(identifier);
    textField.enabled = itemModel.isEnable;
    textField.alpha = itemModel.isEnable ? 1.0 : 0.35;
    if (!textField.isFirstResponder) {
        textField.text = DYYYInlineTextInputCurrentValue(identifier);
    }

    if (textField.superview != cell.contentView) {
        [textField removeFromSuperview];
        [cell.contentView addSubview:textField];
    }
    if (cell.accessoryView == textField)
        cell.accessoryView = nil;

    CGFloat contentWidth = CGRectGetWidth(cell.contentView.bounds);
    CGFloat rightEdge = contentWidth - 32.0;
    NSArray<UIView *> *nativeRightViews = @[ cell.arrowImageView ?: (UIView *)NSNull.null, cell.detailLabel ?: (UIView *)NSNull.null ];
    for (id candidate in nativeRightViews) {
        if (![candidate isKindOfClass:UIView.class] || ![(UIView *)candidate superview])
            continue;
        CGRect candidateFrame = [(UIView *)candidate convertRect:[(UIView *)candidate bounds] toView:cell.contentView];
        CGFloat candidateRight = CGRectGetMaxX(candidateFrame);
        if (candidateRight > contentWidth * 0.55 && candidateRight <= contentWidth + 1.0) {
            rightEdge = candidateRight;
            break;
        }
    }

    CGRect titleFrame = cell.titleLabel.superview ? [cell.titleLabel convertRect:cell.titleLabel.bounds toView:cell.contentView] : CGRectZero;
    CGFloat availableWidth = rightEdge - CGRectGetMaxX(titleFrame) - 12.0;
    CGFloat desiredWidth = DYYYInlineTextInputPreferredWidth(identifier, contentWidth);
    CGFloat fieldWidth = MIN(desiredWidth, MAX(availableWidth, 84.0));
    fieldWidth = MIN(fieldWidth, MAX(rightEdge - 12.0, 72.0));
    textField.frame = CGRectMake(rightEdge - fieldWidth, MAX((CGRectGetHeight(cell.contentView.bounds) - 32.0) * 0.5, 4.0), fieldWidth, 32.0);
    cell.accessoryType = UITableViewCellAccessoryNone;
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
}

static BOOL DYYYCellUsesInlineControl(AWESettingsTableViewCell *cell) {
    UIView *options = objc_getAssociatedObject(cell, &kDYYYInlineOptionsSegmentedControlKey);
    UIView *textField = objc_getAssociatedObject(cell, &kDYYYInlineTextFieldKey);
    return options.superview != nil || textField != nil;
}

static void DYYYSetInlineCellChrome(AWESettingsTableViewCell *cell) {
    BOOL usesInlineControl = DYYYCellUsesInlineControl(cell);
    NSString *identifier = cell.itemModel.identifier ?: @"";
    UIImageView *arrow = cell.arrowImageView;
    NSString *hiddenArrowIdentifier = objc_getAssociatedObject(arrow, &kDYYYArrowHiddenIdentifierKey);
    if (arrow && hiddenArrowIdentifier.length > 0 && ![hiddenArrowIdentifier isEqualToString:identifier]) {
        objc_setAssociatedObject(arrow, &kDYYYArrowHiddenIdentifierKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(arrow, &kDYYYArrowOriginalHiddenKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(arrow, &kDYYYArrowOriginalAlphaKey, nil, OBJC_ASSOCIATION_ASSIGN);
        hiddenArrowIdentifier = nil;
    }
    if (usesInlineControl && arrow) {
        if (![hiddenArrowIdentifier isEqualToString:identifier]) {
            objc_setAssociatedObject(arrow, &kDYYYArrowOriginalHiddenKey, @(arrow.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(arrow, &kDYYYArrowOriginalAlphaKey, @(arrow.alpha), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(arrow, &kDYYYArrowHiddenIdentifierKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        arrow.hidden = YES;
        arrow.alpha = 0.0;
    } else if (arrow && hiddenArrowIdentifier.length > 0) {
        NSNumber *originalHidden = objc_getAssociatedObject(arrow, &kDYYYArrowOriginalHiddenKey);
        NSNumber *originalAlpha = objc_getAssociatedObject(arrow, &kDYYYArrowOriginalAlphaKey);
        arrow.hidden = originalHidden ? originalHidden.boolValue : arrow.hidden;
        arrow.alpha = originalAlpha ? originalAlpha.doubleValue : arrow.alpha;
        objc_setAssociatedObject(arrow, &kDYYYArrowHiddenIdentifierKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(arrow, &kDYYYArrowOriginalHiddenKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(arrow, &kDYYYArrowOriginalAlphaKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }

    UILabel *detailLabel = cell.detailLabel;
    NSString *hiddenDetailIdentifier = objc_getAssociatedObject(detailLabel, &kDYYYDetailHiddenIdentifierKey);
    if (detailLabel && hiddenDetailIdentifier.length > 0 && ![hiddenDetailIdentifier isEqualToString:identifier]) {
        objc_setAssociatedObject(detailLabel, &kDYYYDetailHiddenIdentifierKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(detailLabel, &kDYYYDetailOriginalHiddenKey, nil, OBJC_ASSOCIATION_ASSIGN);
        hiddenDetailIdentifier = nil;
    }
    if (usesInlineControl && detailLabel) {
        if (![hiddenDetailIdentifier isEqualToString:identifier]) {
            objc_setAssociatedObject(detailLabel, &kDYYYDetailOriginalHiddenKey, @(detailLabel.hidden), OBJC_ASSOCIATION_RETAIN_NONATOMIC);
            objc_setAssociatedObject(detailLabel, &kDYYYDetailHiddenIdentifierKey, identifier, OBJC_ASSOCIATION_COPY_NONATOMIC);
        }
        detailLabel.hidden = YES;
    } else if (detailLabel && hiddenDetailIdentifier.length > 0) {
        NSNumber *originalHidden = objc_getAssociatedObject(detailLabel, &kDYYYDetailOriginalHiddenKey);
        detailLabel.hidden = originalHidden ? originalHidden.boolValue : detailLabel.hidden;
        objc_setAssociatedObject(detailLabel, &kDYYYDetailHiddenIdentifierKey, nil, OBJC_ASSOCIATION_ASSIGN);
        objc_setAssociatedObject(detailLabel, &kDYYYDetailOriginalHiddenKey, nil, OBJC_ASSOCIATION_ASSIGN);
    }

    if (usesInlineControl) {
        cell.accessoryType = UITableViewCellAccessoryNone;
        cell.accessoryView = nil;
    }

    NSInteger cellType = cell.itemModel.cellType;
    if (cellType == 6 || cellType == 37) {
        arrow.hidden = YES;
        arrow.alpha = 0.0;
        cell.accessoryType = UITableViewCellAccessoryNone;
    } else if (!usesInlineControl && (cellType == 20 || cellType == 26) && cell.itemModel.cellTappedBlock != nil) {
        arrow.hidden = NO;
        arrow.alpha = 1.0;
    }
}

static NSString *DYYYWrappedSubtitleForWidth(NSString *source, UIFont *font, CGFloat maxWidth) {
    if (source.length == 0 || maxWidth <= 0.0) {
        return source ?: @"";
    }

    UIFont *measurementFont = font ?: [UIFont systemFontOfSize:13.0];
    NSString *normalized = [source stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
    NSMutableString *result = [NSMutableString string];
    NSMutableString *line = [NSMutableString string];
    NSDictionary *attributes = @{NSFontAttributeName : measurementFont};

    [normalized enumerateSubstringsInRange:NSMakeRange(0, normalized.length)
                                   options:NSStringEnumerationByComposedCharacterSequences
                                usingBlock:^(NSString *substring, NSRange substringRange, NSRange enclosingRange, BOOL *stop) {
                                  NSString *candidate = [line stringByAppendingString:substring];
                                  CGFloat candidateWidth = ceil([candidate sizeWithAttributes:attributes].width);
                                  if (line.length > 0 && candidateWidth > maxWidth) {
                                      while ([line hasSuffix:@" "]) {
                                          [line deleteCharactersInRange:NSMakeRange(line.length - 1, 1)];
                                      }
                                      if (result.length > 0) {
                                          [result appendString:@"\n"];
                                      }
                                      [result appendString:line];
                                      [line setString:[substring isEqualToString:@" "] ? @"" : substring];
                                  } else {
                                      [line appendString:substring];
                                  }
                                }];

    if (line.length > 0) {
        if (result.length > 0) {
            [result appendString:@"\n"];
        }
        [result appendString:line];
    }
    return result.length > 0 ? result : normalized;
}

static void DYYYSetWrappedSubtitle(UILabel *label, NSString *source, CGFloat maxWidth) {
    NSString *wrapped = DYYYWrappedSubtitleForWidth(source, label.font, maxWidth);
    if ([label.text isEqualToString:wrapped]) {
        return;
    }

    if (label.attributedText.length > 0) {
        NSDictionary *attributes = [label.attributedText attributesAtIndex:0 effectiveRange:NULL];
        label.attributedText = [[NSAttributedString alloc] initWithString:wrapped attributes:attributes];
    } else {
        label.text = wrapped;
    }
    label.numberOfLines = 0;
    label.lineBreakMode = NSLineBreakByWordWrapping;
}

static void DYYYApplySubtitleSafeSpacing(AWESettingsTableViewCell *cell) {
    NSMutableArray<UIView *> *rightViews = [NSMutableArray array];
    if (cell.aSwitch) [rightViews addObject:cell.aSwitch];
    if (cell.rightButton) [rightViews addObject:cell.rightButton];
    if (cell.detailButton) [rightViews addObject:cell.detailButton];
    UIView *optionsControl = objc_getAssociatedObject(cell, &kDYYYInlineOptionsSegmentedControlKey);
    UIView *inlineTextField = objc_getAssociatedObject(cell, &kDYYYInlineTextFieldKey);
    if (optionsControl) [rightViews addObject:optionsControl];
    if (inlineTextField) [rightViews addObject:inlineTextField];
    NSMutableArray<UILabel *> *subtitleLabels = [NSMutableArray array];
    if (cell.subTitleLabel) [subtitleLabels addObject:cell.subTitleLabel];
    if (cell.fancySubtitleLabel) [subtitleLabels addObject:cell.fancySubtitleLabel];
    for (UILabel *label in subtitleLabels) {
        if (!label.superview || label.hidden || CGRectIsEmpty(label.frame)) {
            continue;
        }
        UIView *labelContainer = label.superview;
        CGFloat contentRight = CGRectGetMaxX([cell.contentView convertRect:cell.contentView.bounds toView:labelContainer]);
        CGFloat rightBoundary = contentRight - 12.0;
        for (UIView *view in rightViews) {
            if (!view.hidden && view.alpha > 0.01) {
                CGRect controlFrame;
                if (view.superview) {
                    controlFrame = [view convertRect:view.bounds toView:labelContainer];
                    if (view == inlineTextField &&
                        (CGRectGetMinX(controlFrame) <= CGRectGetMinX(label.frame) || CGRectGetMaxX(controlFrame) > contentRight + 1.0)) {
                        controlFrame.origin.x = contentRight - CGRectGetWidth(view.bounds) - 12.0;
                    }
                } else if (view == inlineTextField) {
                    controlFrame = CGRectMake(contentRight - CGRectGetWidth(view.bounds) - 12.0, 0.0, CGRectGetWidth(view.bounds), CGRectGetHeight(view.bounds));
                } else {
                    continue;
                }
                rightBoundary = MIN(rightBoundary, CGRectGetMinX(controlFrame) - 16.0);
            }
        }
        CGRect frame = label.frame;
        CGFloat maxWidth = MAX(rightBoundary - CGRectGetMinX(frame), 44.0);
        BOOL needsMeasuredWrapping = inlineTextField && inlineTextField.superview;
        if (needsMeasuredWrapping && cell.itemModel.subTitle.length > 0) {
            AWESettingItemModel *itemModel = cell.itemModel;
            NSString *originalSubtitle = objc_getAssociatedObject(itemModel, &kDYYYOriginalInlineSubtitleKey);
            if (originalSubtitle.length == 0) {
                originalSubtitle = itemModel.subTitle;
                objc_setAssociatedObject(itemModel, &kDYYYOriginalInlineSubtitleKey, originalSubtitle, OBJC_ASSOCIATION_COPY_NONATOMIC);
            }
            NSString *wrappedSubtitle = DYYYWrappedSubtitleForWidth(originalSubtitle, label.font, maxWidth);
            DYYYSetWrappedSubtitle(label, originalSubtitle, maxWidth);
            if (![itemModel.subTitle isEqualToString:wrappedSubtitle]) {
                itemModel.subTitle = wrappedSubtitle;
                if (![objc_getAssociatedObject(itemModel, &kDYYYInlineSubtitleRefreshPendingKey) boolValue]) {
                    objc_setAssociatedObject(itemModel, &kDYYYInlineSubtitleRefreshPendingKey, @YES, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                    __weak AWESettingItemModel *weakItemModel = itemModel;
                    dispatch_async(dispatch_get_main_queue(), ^{
                      AWESettingItemModel *strongItemModel = weakItemModel;
                      if (strongItemModel) {
                          objc_setAssociatedObject(strongItemModel, &kDYYYInlineSubtitleRefreshPendingKey, nil, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
                          [strongItemModel refreshCell];
                      }
                    });
                }
            }
            continue;
        }
        frame.size.width = maxWidth;
        label.frame = frame;
        label.preferredMaxLayoutWidth = maxWidth;
        label.numberOfLines = 0;
        label.lineBreakMode = NSLineBreakByWordWrapping;
    }
}

static void DYYYApplyInlineControlsToCell(AWESettingsTableViewCell *cell) {
    cell.detailLabel.transform = CGAffineTransformIdentity;
    DYYYApplyInlineOptionsToCell(cell);
    DYYYApplyInlineTextFieldToCell(cell);
    DYYYSetInlineCellChrome(cell);
    DYYYApplySubtitleSafeSpacing(cell);
    DYYYCenterSettingIconForSubtitle(cell);
}

static void DYYYRemoveRemoteConfigObserver(void) {
    if (dyyyRemoteConfigChangedToken) {
        [[NSNotificationCenter defaultCenter] removeObserver:dyyyRemoteConfigChangedToken];
        dyyyRemoteConfigChangedToken = nil;
    }
}

static NSString *DYYYStringOrEmpty(id value) {
    return [value isKindOfClass:[NSString class]] ? (NSString *)value : @"";
}

static NSString *DYYYShellQuotedString(NSString *string) {
    NSString *safeString = [string ?: @"" stringByReplacingOccurrencesOfString:@"'" withString:@"'\\''"];
    return [NSString stringWithFormat:@"'%@'", safeString];
}

static NSString *DYYYPreferredLaunchURLString(void) {
    NSArray *urlTypes = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleURLTypes"];
    NSMutableArray<NSString *> *schemes = [NSMutableArray array];
    for (NSDictionary *urlType in urlTypes) {
        if (![urlType isKindOfClass:[NSDictionary class]]) {
            continue;
        }
        NSArray *urlSchemes = urlType[@"CFBundleURLSchemes"];
        for (NSString *scheme in urlSchemes) {
            if ([scheme isKindOfClass:[NSString class]] && scheme.length > 0) {
                [schemes addObject:scheme];
            }
        }
    }

    for (NSString *preferredScheme in @[ @"snssdk1128", @"aweme" ]) {
        for (NSString *scheme in schemes) {
            if ([scheme caseInsensitiveCompare:preferredScheme] == NSOrderedSame) {
                return [NSString stringWithFormat:@"%@://", scheme];
            }
        }
    }

    for (NSString *scheme in schemes) {
        NSString *lowercaseScheme = scheme.lowercaseString;
        if ([lowercaseScheme hasPrefix:@"snssdk"] &&
            [lowercaseScheme rangeOfString:@"sync"].location == NSNotFound &&
            [lowercaseScheme rangeOfString:@"lucky"].location == NSNotFound &&
            [lowercaseScheme rangeOfString:@"share"].location == NSNotFound &&
            [lowercaseScheme rangeOfString:@"pay"].location == NSNotFound) {
            return [NSString stringWithFormat:@"%@://", scheme];
        }
    }

    return nil;
}

static NSArray<NSString *> *DYYYApplicationRelaunchTargets(void) {
    NSMutableArray<NSString *> *targets = [NSMutableArray array];
    NSString *launchURLString = DYYYPreferredLaunchURLString();
    if (launchURLString.length > 0) {
        [targets addObject:launchURLString];
    }

    NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
    if (bundleIdentifier.length > 0 && ![targets containsObject:bundleIdentifier]) {
        [targets addObject:bundleIdentifier];
    }

    return targets;
}

static BOOL DYYYSpawnApplicationRelaunchTaskAfterDelay(NSTimeInterval delay) {
    NSArray<NSString *> *targets = DYYYApplicationRelaunchTargets();
    if (targets.count == 0) {
        return NO;
    }

    NSMutableArray<NSString *> *quotedTargets = [NSMutableArray arrayWithCapacity:targets.count];
    for (NSString *target in targets) {
        [quotedTargets addObject:DYYYShellQuotedString(target)];
    }
    NSString *targetList = [quotedTargets componentsJoinedByString:@" "];
    NSString *command = [NSString stringWithFormat:@"log='/tmp/dyyy-relaunch.log'; : > \"$log\"; export PATH=/var/jb/usr/bin:/var/jb/bin:/usr/bin:/bin:/usr/sbin:/sbin:${PATH:-}; uid=%u; echo \"start $(date)\" >> \"$log\"; sleep %.2f; open_target() { target=\"$1\"; echo \"open $target\" >> \"$log\"; for tool in /var/jb/usr/bin/uiopen /usr/bin/uiopen; do if [ -x \"$tool\" ]; then /bin/launchctl asuser \"$uid\" \"$tool\" \"$target\" >> \"$log\" 2>&1 && exit 0; \"$tool\" \"$target\" >> \"$log\" 2>&1 && exit 0; fi; done; if command -v uiopen >/dev/null 2>&1; then uiopen \"$target\" >> \"$log\" 2>&1 && exit 0; fi; }; for target in %@; do open_target \"$target\"; done; echo 'failed' >> \"$log\"; exit 1",
                         (unsigned)getuid(), MAX(delay, 0.0), targetList];

    NSArray<NSString *> *shellCandidates = @[ @"/var/jb/bin/sh", @"/var/jb/usr/bin/sh", @"/bin/sh", @"/usr/bin/sh" ];
    for (NSString *shellPath in shellCandidates) {
        pid_t pid = 0;
        posix_spawnattr_t attributes;
        posix_spawnattr_init(&attributes);
        posix_spawn_file_actions_t fileActions;
        posix_spawn_file_actions_init(&fileActions);
        posix_spawn_file_actions_addopen(&fileActions, STDIN_FILENO, "/dev/null", O_RDONLY, 0);
        posix_spawn_file_actions_addopen(&fileActions, STDOUT_FILENO, "/dev/null", O_WRONLY, 0);
        posix_spawn_file_actions_addopen(&fileActions, STDERR_FILENO, "/dev/null", O_WRONLY, 0);
#ifdef POSIX_SPAWN_SETSID
        posix_spawnattr_setflags(&attributes, POSIX_SPAWN_SETSID);
#else
        posix_spawnattr_setflags(&attributes, POSIX_SPAWN_SETPGROUP);
        posix_spawnattr_setpgroup(&attributes, 0);
#endif
        char *const argv[] = { (char *)shellPath.fileSystemRepresentation, (char *)"-c", (char *)command.UTF8String, NULL };
        int spawnResult = posix_spawn(&pid, shellPath.fileSystemRepresentation, &fileActions, &attributes, argv, environ);
        posix_spawn_file_actions_destroy(&fileActions);
        posix_spawnattr_destroy(&attributes);
        if (spawnResult == 0) {
            return YES;
        }
    }

    return NO;
}

static void DYYYRestartApplicationAfterDelay(NSTimeInterval delay) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(MAX(delay, 0.0) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      if (!DYYYSpawnApplicationRelaunchTaskAfterDelay(1.15)) {
          return;
      }

      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        UIApplication *application = [UIApplication sharedApplication];
        SEL suspendSelector = NSSelectorFromString(@"suspend");
        if ([application respondsToSelector:suspendSelector]) {
            ((void (*)(id, SEL))objc_msgSend)(application, suspendSelector);
        }

        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
          exit(0);
        });
      });
    });
}

static NSMutableDictionary<NSString *, NSMutableDictionary *> *DYYYSettingsSearchIndexMap(void) {
    static NSMutableDictionary<NSString *, NSMutableDictionary *> *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      map = [NSMutableDictionary dictionary];
    });
    return map;
}

static NSMutableArray<NSString *> *DYYYSettingsSearchIndexKeys(void) {
    static NSMutableArray<NSString *> *keys = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
      keys = [NSMutableArray array];
    });
    return keys;
}

static NSArray<NSDictionary *> *DYYYSettingsSearchEntriesForSections(NSString *categoryTitle, NSArray *sections) {
    if (categoryTitle.length == 0 || sections.count == 0) {
        return @[];
    }

    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];

    for (AWESettingSectionModel *section in sections) {
        if (![section respondsToSelector:@selector(itemArray)]) {
            continue;
        }

        NSString *sectionTitle = DYYYStringOrEmpty(section.sectionHeaderTitle);
        NSString *path = sectionTitle.length > 0 ? [NSString stringWithFormat:@"%@ - %@", categoryTitle, sectionTitle] : categoryTitle;

        for (id itemObject in section.itemArray) {
            if (![itemObject isKindOfClass:NSClassFromString(@"AWESettingItemModel")]) {
                continue;
            }

            AWESettingItemModel *item = (AWESettingItemModel *)itemObject;
            if (item.title.length == 0) {
                continue;
            }

            NSString *identifier = item.identifier.length > 0 ? item.identifier : item.title;
            NSString *entryKey = [NSString stringWithFormat:@"%@|%@|%@", path, identifier, item.title];
            NSString *searchableText = [NSString stringWithFormat:@"%@ %@", item.title ?: @"", item.subTitle ?: @""];
            [entries addObject:@{@"entryKey" : entryKey, @"path" : path, @"item" : item, @"searchableText" : searchableText}];
        }
    }

    return entries;
}

static void DYYYRegisterSearchSections(NSString *categoryTitle, NSArray *sections) {
    NSMutableDictionary *indexMap = DYYYSettingsSearchIndexMap();
    NSMutableArray *orderedKeys = DYYYSettingsSearchIndexKeys();

    for (NSDictionary *entry in DYYYSettingsSearchEntriesForSections(categoryTitle, sections)) {
        NSString *entryKey = entry[@"entryKey"];
        if (!indexMap[entryKey]) {
            [orderedKeys addObject:entryKey];
        }
        NSMutableDictionary *storedEntry = [entry mutableCopy];
        [storedEntry removeObjectForKey:@"entryKey"];
        indexMap[entryKey] = storedEntry;
    }
}

static NSArray<NSDictionary *> *DYYYSettingsSearchEntries(void) {
    NSMutableArray<NSDictionary *> *entries = [NSMutableArray array];
    NSDictionary *indexMap = DYYYSettingsSearchIndexMap();
    for (NSString *key in DYYYSettingsSearchIndexKeys()) {
        NSDictionary *entry = indexMap[key];
        if (entry) {
            [entries addObject:entry];
        }
    }
    return entries;
}

static void DYYYResetSettingsSearchIndex(void) {
    [DYYYSettingsSearchIndexMap() removeAllObjects];
    [DYYYSettingsSearchIndexKeys() removeAllObjects];
    DYYYSettingsSearchIndexBuilt = NO;
}

static void DYYYRefreshSearchItemValue(AWESettingItemModel *item) {
    if (item.identifier.length == 0) {
        return;
    }

    id savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
    if (item.cellType == 6 || item.cellType == 37) {
        item.isSwitchOn = [savedValue respondsToSelector:@selector(boolValue)] ? [savedValue boolValue] : NO;
    } else if (savedValue) {
        if ([savedValue isKindOfClass:[NSString class]]) {
            item.detail = savedValue;
        } else if ([savedValue respondsToSelector:@selector(stringValue)]) {
            item.detail = [savedValue stringValue];
        }
    }

    [DYYYSettingsHelper applyDependencyRulesForItem:item];
}

static BOOL DYYYSettingsUsesDouyinLightBackground(void) {
    return [DYYYUtils usesDouyinLightBackground];
}

static UIColor *DYYYSettingsColorFromARGB(NSUInteger argb) {
    CGFloat alpha = ((argb >> 24) & 0xFF) / 255.0;
    CGFloat red = ((argb >> 16) & 0xFF) / 255.0;
    CGFloat green = ((argb >> 8) & 0xFF) / 255.0;
    CGFloat blue = (argb & 0xFF) / 255.0;
    return [UIColor colorWithRed:red green:green blue:blue alpha:alpha];
}

static UIColor *DYYYSettingsSearchContainerColor(BOOL usesLightBackground) {
    // 将抖音 BGCard2 合成到 BGDoubleRow 后再赋值，保持搜索框原有 alpha=1。
    (void)usesLightBackground;
    return [DYYYUtils douyinOpaqueSettingsCardBackgroundColor];
}

static UIColor *DYYYSettingsSearchTextColor(BOOL usesLightBackground) {
    // AWEUIColor TextPrimary: d=E6FFFFFF, dl=FF161823.
    return DYYYSettingsColorFromARGB(usesLightBackground ? 0xFF161823 : 0xE6FFFFFF);
}

static UIColor *DYYYSettingsSearchPlaceholderColor(BOOL usesLightBackground) {
    // AWEUIColor TextSecondary: d=C0FFFFFF, dl=C0161823.
    return DYYYSettingsColorFromARGB(usesLightBackground ? 0xC0161823 : 0xC0FFFFFF);
}

@interface DYYYSettingsSearchCoordinator : NSObject <UITextFieldDelegate, UIGestureRecognizerDelegate>
@property(nonatomic, weak) AWESettingBaseViewController *settingsVC;
@property(nonatomic, weak) UINavigationController *navigationController;
@property(nonatomic, assign) BOOL previousInteractivePopGestureEnabled;
@property(nonatomic, assign) BOOL hasStoredInteractivePopGestureEnabled;
@property(nonatomic, strong) AWESettingsViewModel *viewModel;
@property(nonatomic, copy) NSArray *originalSections;
@property(nonatomic, copy) NSArray<NSDictionary *> *searchEntries;
@property(nonatomic, strong) UIView *headerView;
@property(nonatomic, strong) UIView *containerView;
@property(nonatomic, strong) UITextField *searchTextField;
@property(nonatomic, strong) UIScreenEdgePanGestureRecognizer *searchBackGestureRecognizer;
@property(nonatomic, strong) UIView *centerPlaceholderView;
@property(nonatomic, strong) UIImageView *leftIconView;
@property(nonatomic, strong) UIImageView *centerIconView;
@property(nonatomic, strong) UILabel *centerPlaceholderLabel;
@property(nonatomic, assign) UIEdgeInsets tableContentInsetBeforeSearchHeader;
@property(nonatomic, assign) UIEdgeInsets tableScrollIndicatorInsetsBeforeSearchHeader;
@property(nonatomic, assign) BOOL hasInstalledPinnedHeaderInsets;
- (instancetype)initWithSettingsVC:(AWESettingBaseViewController *)settingsVC viewModel:(AWESettingsViewModel *)viewModel originalSections:(NSArray *)sections searchEntries:(NSArray<NSDictionary *> *)entries;
- (void)installSearchHeader;
- (void)installPinnedHeaderInsetsForTableView:(UITableView *)tableView;
- (void)restorePinnedHeaderInsets;
- (void)installNavigationInterceptors;
- (void)applyThemeColors;
- (void)updateLayout;
- (void)updateSearchPlaceholderVisibilityAnimated:(BOOL)animated;
- (BOOL)isTopSettingsViewController;
- (void)updateNavigationGestureState;
- (void)restoreNavigationGestureState;
- (BOOL)handleBackNavigationRequest;
@end

@implementation DYYYSettingsSearchCoordinator

- (instancetype)initWithSettingsVC:(AWESettingBaseViewController *)settingsVC viewModel:(AWESettingsViewModel *)viewModel originalSections:(NSArray *)sections searchEntries:(NSArray<NSDictionary *> *)entries {
    self = [super init];
    if (self) {
        _settingsVC = settingsVC;
        _viewModel = viewModel;
        _originalSections = [sections copy];
        _searchEntries = [entries copy];
    }
    return self;
}

- (void)installSearchHeader {
    [self.settingsVC view];
    UITableView *tableView = self.settingsVC.tableView;
    if (!tableView) {
        return;
    }

    // 直接进入子页时 tableView 可能尚未完成首次布局，宽度仍为 0。
    // 禁止用 width - 32 创建负宽度视图，否则 UIKit 会留下非零 bounds.origin。
    CGFloat initialWidth = MAX(CGRectGetWidth(tableView.bounds), CGRectGetWidth(self.settingsVC.view.bounds));
    initialWidth = MAX(0.0, initialWidth);
    CGFloat initialContainerWidth = MAX(0.0, initialWidth - 32.0);

    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, initialWidth, 44)];
    self.headerView.backgroundColor = [UIColor clearColor];
    self.headerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;

    self.containerView = [[UIView alloc] initWithFrame:CGRectMake(16, 0, initialContainerWidth, 44)];
    self.containerView.layer.cornerRadius = 12;
    self.containerView.layer.masksToBounds = NO;
    self.containerView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.headerView addSubview:self.containerView];

    self.searchTextField = [[UITextField alloc] initWithFrame:self.containerView.bounds];
    self.searchTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.searchTextField.backgroundColor = [UIColor clearColor];
    self.searchTextField.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    self.searchTextField.clearButtonMode = UITextFieldViewModeWhileEditing;
    self.searchTextField.returnKeyType = UIReturnKeySearch;
    self.searchTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.searchTextField.spellCheckingType = UITextSpellCheckingTypeNo;
    self.searchTextField.delegate = self;
    self.searchTextField.accessibilityLabel = @"DYYY设置搜索";

    UIView *leftView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 38, 30)];
    self.leftIconView = [[UIImageView alloc] initWithFrame:CGRectMake(14, 5, 18, 18)];
    self.leftIconView.image = [UIImage systemImageNamed:@"magnifyingglass"];
    self.leftIconView.contentMode = UIViewContentModeScaleAspectFit;
    [leftView addSubview:self.leftIconView];
    self.searchTextField.leftView = leftView;
    self.searchTextField.leftViewMode = UITextFieldViewModeNever;
    [self.searchTextField addTarget:self action:@selector(searchTextDidChange:) forControlEvents:UIControlEventEditingChanged];
    [self.containerView addSubview:self.searchTextField];

    self.centerPlaceholderView = [[UIView alloc] initWithFrame:CGRectZero];
    self.centerPlaceholderView.userInteractionEnabled = NO;
    [self.containerView addSubview:self.centerPlaceholderView];

    self.centerIconView = [[UIImageView alloc] initWithImage:[UIImage systemImageNamed:@"magnifyingglass"]];
    self.centerIconView.contentMode = UIViewContentModeScaleAspectFit;
    [self.centerPlaceholderView addSubview:self.centerIconView];

    self.centerPlaceholderLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.centerPlaceholderLabel.text = @"搜索设置项";
    self.centerPlaceholderLabel.font = [UIFont systemFontOfSize:16 weight:UIFontWeightRegular];
    [self.centerPlaceholderView addSubview:self.centerPlaceholderLabel];

    [self.settingsVC.view addSubview:self.headerView];
    [self installPinnedHeaderInsetsForTableView:tableView];
    [self applyThemeColors];
    [self updateLayout];
    [self installNavigationInterceptors];
    [self updateNavigationGestureState];
}

- (void)installPinnedHeaderInsetsForTableView:(UITableView *)tableView {
    if (!tableView || self.hasInstalledPinnedHeaderInsets) {
        return;
    }

    self.tableContentInsetBeforeSearchHeader = tableView.contentInset;
    self.tableScrollIndicatorInsetsBeforeSearchHeader = tableView.scrollIndicatorInsets;
    BOOL shouldKeepAtTop = !tableView.window || tableView.contentOffset.y <= -tableView.adjustedContentInset.top + 1.0;

    UIEdgeInsets contentInset = tableView.contentInset;
    contentInset.top += CGRectGetHeight(self.headerView.bounds);
    tableView.contentInset = contentInset;

    UIEdgeInsets indicatorInsets = tableView.scrollIndicatorInsets;
    indicatorInsets.top += CGRectGetHeight(self.headerView.bounds);
    tableView.scrollIndicatorInsets = indicatorInsets;
    self.hasInstalledPinnedHeaderInsets = YES;

    if (shouldKeepAtTop) {
        [tableView setContentOffset:CGPointMake(tableView.contentOffset.x, -tableView.adjustedContentInset.top) animated:NO];
    }
}

- (void)restorePinnedHeaderInsets {
    UITableView *tableView = self.settingsVC.tableView;
    if (!tableView || !self.hasInstalledPinnedHeaderInsets) {
        return;
    }

    UIEdgeInsets contentInset = tableView.contentInset;
    contentInset.top = self.tableContentInsetBeforeSearchHeader.top;
    tableView.contentInset = contentInset;

    UIEdgeInsets indicatorInsets = tableView.scrollIndicatorInsets;
    indicatorInsets.top = self.tableScrollIndicatorInsetsBeforeSearchHeader.top;
    tableView.scrollIndicatorInsets = indicatorInsets;
    self.hasInstalledPinnedHeaderInsets = NO;
}

- (void)updateLayout {
    UITableView *tableView = self.settingsVC.tableView;
    if (!tableView || !self.headerView || !self.containerView || !self.centerPlaceholderView || !self.leftIconView || !self.centerIconView || !self.centerPlaceholderLabel) {
        return;
    }

    [self applyThemeColors];

    CGFloat width = tableView.bounds.size.width;
    if (width <= 0) {
        return;
    }

    UIView *settingsView = self.settingsVC.view;
    UIView *tableSuperview = tableView.superview;
    if (!settingsView || !tableSuperview) {
        return;
    }

    CGRect tableFrame = [tableSuperview convertRect:tableView.frame toView:settingsView];
    CGFloat automaticTopInset = MAX(0.0, tableView.adjustedContentInset.top - tableView.contentInset.top);
    CGFloat containerWidth = MAX(0.0, width - 32.0);
    self.headerView.frame = CGRectMake(CGRectGetMinX(tableFrame), CGRectGetMinY(tableFrame) + automaticTopInset, width, 44);
    self.containerView.frame = CGRectMake(16, 0, containerWidth, 44);
    // containerView 是非滚动的自有承载视图，bounds 原点必须始终为零。
    self.containerView.bounds = CGRectMake(0, 0, containerWidth, 44);
    self.containerView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.containerView.bounds cornerRadius:self.containerView.layer.cornerRadius].CGPath;
    self.searchTextField.frame = self.containerView.bounds;
    self.headerView.backgroundColor = UIColor.clearColor;

    [self updateSearchPlaceholderVisibilityAnimated:NO];
    [settingsView bringSubviewToFront:self.headerView];

    [self installNavigationInterceptors];
    [self updateNavigationGestureState];
}

- (CGRect)placeholderFrameForLeftAlignment:(BOOL)leftAligned {
    CGFloat iconSize = 18.0;
    CGFloat spacing = 8.0;
    CGSize labelSize = [self.centerPlaceholderLabel.text sizeWithAttributes:@{NSFontAttributeName : self.centerPlaceholderLabel.font}];
    CGFloat placeholderWidth = iconSize + spacing + ceil(labelSize.width);
    CGFloat placeholderHeight = MAX(iconSize, ceil(labelSize.height));
    self.centerIconView.frame = CGRectMake(0, (placeholderHeight - iconSize) / 2.0, iconSize, iconSize);
    self.centerPlaceholderLabel.frame = CGRectMake(iconSize + spacing, 0, ceil(labelSize.width), placeholderHeight);

    CGFloat containerWidth = CGRectGetWidth(self.containerView.bounds);
    CGFloat containerHeight = CGRectGetHeight(self.containerView.bounds);
    CGFloat targetX = leftAligned ? 14.0 : (containerWidth - placeholderWidth) / 2.0;
    targetX = MAX(0.0, MIN(targetX, containerWidth - placeholderWidth));
    return CGRectMake(targetX, (containerHeight - placeholderHeight) / 2.0, placeholderWidth, placeholderHeight);
}

- (void)updateSearchPlaceholderVisibility {
    [self updateSearchPlaceholderVisibilityAnimated:NO];
}

- (NSString *)trimmedSearchText {
    return [self.searchTextField.text ?: @"" stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (void)updateSearchPlaceholderVisibilityAnimated:(BOOL)animated {
    BOOL hasSearchText = self.searchTextField.text.length > 0;
    BOOL showPlaceholderView = !hasSearchText;
    BOOL leftAligned = self.searchTextField.isEditing;
    CGRect targetFrame = [self placeholderFrameForLeftAlignment:leftAligned];
    CGFloat targetPlaceholderAlpha = showPlaceholderView ? 1.0 : 0.0;

    self.searchTextField.placeholder = nil;
    self.searchTextField.attributedPlaceholder = nil;
    self.searchTextField.leftViewMode = (self.searchTextField.isEditing || hasSearchText) ? UITextFieldViewModeAlways : UITextFieldViewModeNever;
    if (showPlaceholderView) {
        self.centerPlaceholderView.hidden = NO;
        self.leftIconView.alpha = 0.0;
    }

    void (^animations)(void) = ^{
      self.centerPlaceholderView.frame = targetFrame;
      self.centerPlaceholderView.alpha = targetPlaceholderAlpha;
      if (!showPlaceholderView) {
          self.leftIconView.alpha = 1.0;
      }
    };

    void (^completion)(BOOL) = ^(BOOL finished) {
      if (!showPlaceholderView && finished) {
          self.centerPlaceholderView.hidden = YES;
      }
    };

    if (animated && self.centerPlaceholderView.superview) {
        [UIView animateWithDuration:0.26
                              delay:0
             usingSpringWithDamping:0.88
              initialSpringVelocity:0.0
                            options:UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                         animations:animations
                         completion:completion];
    } else {
        animations();
        if (!showPlaceholderView) {
            self.centerPlaceholderView.hidden = YES;
        }
    }
}

- (void)applyThemeColors {
    BOOL usesLightBackground = DYYYSettingsUsesDouyinLightBackground();
    UIColor *containerColor = DYYYSettingsSearchContainerColor(usesLightBackground);
    UIColor *textColor = DYYYSettingsSearchTextColor(usesLightBackground);
    UIColor *placeholderColor = DYYYSettingsSearchPlaceholderColor(usesLightBackground);

    self.containerView.backgroundColor = containerColor;
    self.containerView.layer.shadowColor = UIColor.blackColor.CGColor;
    self.containerView.layer.shadowOpacity = usesLightBackground ? 0.08 : 0.16;
    self.containerView.layer.shadowOffset = CGSizeMake(0, 3.0);
    self.containerView.layer.shadowRadius = 3.5;
    self.searchTextField.textColor = textColor;
    self.searchTextField.tintColor = textColor;
    self.searchTextField.keyboardAppearance = usesLightBackground ? UIKeyboardAppearanceDefault : UIKeyboardAppearanceDark;
    self.leftIconView.tintColor = placeholderColor;
    self.centerIconView.tintColor = placeholderColor;
    self.centerPlaceholderLabel.textColor = placeholderColor;
    [self updateSearchPlaceholderVisibility];
}

- (NSArray *)sectionsForSearchText:(NSString *)searchText {
    NSString *query = [searchText lowercaseString];
    if (query.length == 0) {
        return self.originalSections;
    }

    NSMutableDictionary<NSString *, NSMutableArray *> *groupedItems = [NSMutableDictionary dictionary];
    NSMutableArray<NSString *> *orderedPaths = [NSMutableArray array];
    for (NSDictionary *entry in self.searchEntries) {
        NSString *searchableText = [entry[@"searchableText"] lowercaseString];
        if (![searchableText containsString:query]) {
            continue;
        }

        AWESettingItemModel *item = entry[@"item"];
        DYYYRefreshSearchItemValue(item);
        NSString *path = entry[@"path"] ?: @"DYYY";
        NSMutableArray *items = groupedItems[path];
        if (!items) {
            items = [NSMutableArray array];
            groupedItems[path] = items;
            [orderedPaths addObject:path];
        }
        [items addObject:item];
    }

    NSMutableArray *sections = [NSMutableArray array];
    for (NSString *path in orderedPaths) {
        NSArray *items = groupedItems[path];
        if (items.count == 0) {
            continue;
        }

        AWESettingSectionModel *section = [[NSClassFromString(@"AWESettingSectionModel") alloc] init];
        section.sectionHeaderTitle = path;
        section.sectionHeaderHeight = 40;
        section.type = 0;
        section.itemArray = items;
        [sections addObject:section];
    }

    if (sections.count == 0) {
        AWESettingSectionModel *emptySection = [[NSClassFromString(@"AWESettingSectionModel") alloc] init];
        emptySection.sectionHeaderTitle = @"未找到相关设置";
        emptySection.sectionHeaderHeight = 40;
        emptySection.type = 0;
        emptySection.itemArray = @[];
        [sections addObject:emptySection];
    }

    return sections;
}

- (void)searchTextDidChange:(UITextField *)textField {
    // 输入过程中不要反复叠加占位视图和列表的过渡动画，避免阻塞文字即时显示。
    [self updateSearchPlaceholderVisibilityAnimated:NO];
    self.viewModel.sectionDataArray = [self sectionsForSearchText:[self trimmedSearchText]];
    [self.settingsVC.tableView reloadData];
    [self updateNavigationGestureState];
}

- (BOOL)isSearchInteractionActive {
    return self.searchTextField.isFirstResponder || [self trimmedSearchText].length > 0;
}

- (BOOL)handleBackNavigationRequest {
    UINavigationController *navigationController = self.settingsVC.navigationController ?: self.navigationController;
    if (navigationController && navigationController.topViewController != self.settingsVC) {
        return NO;
    }
    if (![self isSearchInteractionActive]) {
        return NO;
    }

    self.searchTextField.text = @"";
    [self.searchTextField resignFirstResponder];
    [self updateSearchPlaceholderVisibilityAnimated:YES];
    self.viewModel.sectionDataArray = self.originalSections;
    [UIView transitionWithView:self.settingsVC.tableView
                      duration:0.18
                       options:UIViewAnimationOptionTransitionCrossDissolve | UIViewAnimationOptionBeginFromCurrentState | UIViewAnimationOptionAllowUserInteraction
                    animations:^{
                      [self.settingsVC.tableView reloadData];
                    }
                    completion:nil];
    [self updateNavigationGestureState];
    return YES;
}

- (void)installNavigationInterceptors {
    UINavigationController *navigationController = self.settingsVC.navigationController;
    if (!navigationController) {
        return;
    }

    self.navigationController = navigationController;
    // 系统返回手势代理由宿主导航控制器管理；搜索态改用独立边缘手势，
    // 避免多个设置页协调器互相保存为 previous delegate 并形成代理环。
    if (!self.searchBackGestureRecognizer) {
        self.searchBackGestureRecognizer = [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(handleSearchBackGesture:)];
        self.searchBackGestureRecognizer.edges = UIRectEdgeLeft;
        self.searchBackGestureRecognizer.delegate = (id<UIGestureRecognizerDelegate>)self;
        self.searchBackGestureRecognizer.enabled = NO;
        [self.settingsVC.view addGestureRecognizer:self.searchBackGestureRecognizer];
    }

    UIGestureRecognizer *popGesture = navigationController.interactivePopGestureRecognizer;
    if ([self isTopSettingsViewController] && popGesture && !self.hasStoredInteractivePopGestureEnabled) {
        self.previousInteractivePopGestureEnabled = popGesture.enabled;
        self.hasStoredInteractivePopGestureEnabled = YES;
    }
}

- (BOOL)isTopSettingsViewController {
    UINavigationController *navigationController = self.settingsVC.navigationController ?: self.navigationController;
    return navigationController && navigationController.topViewController == self.settingsVC;
}

- (void)updateNavigationGestureState {
    UINavigationController *navigationController = self.settingsVC.navigationController ?: self.navigationController;
    if (![self isTopSettingsViewController]) {
        self.searchBackGestureRecognizer.enabled = NO;
        return;
    }

    UIGestureRecognizer *popGesture = navigationController.interactivePopGestureRecognizer;
    BOOL searchActive = [self isSearchInteractionActive];

    if (popGesture) {
        if (!self.hasStoredInteractivePopGestureEnabled) {
            self.previousInteractivePopGestureEnabled = popGesture.enabled;
            self.hasStoredInteractivePopGestureEnabled = YES;
        }
        if (searchActive) {
            popGesture.enabled = NO;
        } else {
            popGesture.enabled = self.previousInteractivePopGestureEnabled;
        }
    }

    self.searchBackGestureRecognizer.enabled = searchActive;
}

- (void)restoreNavigationGestureState {
    UINavigationController *navigationController = self.settingsVC.navigationController ?: self.navigationController;
    UIGestureRecognizer *popGesture = navigationController.interactivePopGestureRecognizer;
    if (popGesture && self.hasStoredInteractivePopGestureEnabled) {
        popGesture.enabled = self.previousInteractivePopGestureEnabled;
    }
    self.hasStoredInteractivePopGestureEnabled = NO;
    self.searchBackGestureRecognizer.enabled = NO;
}

- (void)handleSearchBackGesture:(UIScreenEdgePanGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
        [self handleBackNavigationRequest];
    }
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    if (gestureRecognizer != self.searchBackGestureRecognizer) {
        return YES;
    }
    return [self isTopSettingsViewController] && [self isSearchInteractionActive];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    [self updateSearchPlaceholderVisibilityAnimated:YES];
    [self updateNavigationGestureState];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    [self updateSearchPlaceholderVisibilityAnimated:YES];
    [self updateNavigationGestureState];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return NO;
}

- (void)dealloc {
    [self restoreNavigationGestureState];
    [self restorePinnedHeaderInsets];
}

@end

static void DYYYAttachSettingsSearchHeader(AWESettingBaseViewController *settingsVC, AWESettingsViewModel *viewModel, NSArray *sections, NSArray<NSDictionary *> *searchEntries) {
    if (!settingsVC || !viewModel || sections.count == 0) {
        return;
    }

    DYYYSettingsSearchCoordinator *coordinator =
        [[DYYYSettingsSearchCoordinator alloc] initWithSettingsVC:settingsVC viewModel:viewModel originalSections:sections searchEntries:searchEntries ?: @[]];
    objc_setAssociatedObject(settingsVC, &kDYYYSettingsSearchCoordinatorKey, coordinator, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

    dispatch_async(dispatch_get_main_queue(), ^{
      [coordinator installSearchHeader];
    });
}

static void DYYYAttachSubSettingsSearchHeader(AWESettingBaseViewController *settingsVC, NSString *title, NSArray *sections) {
    AWESettingsViewModel *viewModel = objc_getAssociatedObject(settingsVC, &kViewModelKey);
    NSArray<NSDictionary *> *searchEntries = DYYYSettingsSearchEntriesForSections(title, sections);
    DYYYAttachSettingsSearchHeader(settingsVC, viewModel, sections, searchEntries);
}

static void DYYYBuildSettingsSearchIndexIfNeeded(NSArray<AWESettingItemModel *> *categoryItems) {
    if (DYYYSettingsSearchIndexBuilt) {
        return;
    }

    DYYYSettingsSearchIndexBuilt = YES;
    DYYYBuildingSettingsSearchIndex = YES;
    for (AWESettingItemModel *item in categoryItems) {
        if (item.cellTappedBlock) {
            item.cellTappedBlock();
        }
    }
    DYYYBuildingSettingsSearchIndex = NO;
}

%hook AWESettingBaseViewController
- (BOOL)useCardUIStyle {
    return YES;
}

- (AWESettingBaseViewModel *)viewModel {
    AWESettingBaseViewModel *original = %orig;
    if (!original)
        return objc_getAssociatedObject(self, &kViewModelKey);
    return original;
}

- (void)viewWillAppear:(BOOL)animated {
    %orig;
    self.tableView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
    AWESettingsViewModel *settingsViewModel = (AWESettingsViewModel *)[self viewModel];
    for (AWESettingSectionModel *section in settingsViewModel.sectionDataArray) {
        for (AWESettingItemModel *item in section.itemArray) {
            if ([item.identifier isEqualToString:@"DYYYEnableLoginBypass"]) {
                item.isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:item.identifier];
                [item refreshCell];
                break;
            }
        }
    }
    DYYYSettingsSearchCoordinator *coordinator = objc_getAssociatedObject(self, &kDYYYSettingsSearchCoordinatorKey);
    [coordinator applyThemeColors];
    [coordinator installNavigationInterceptors];
    [coordinator updateNavigationGestureState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [DYYYKeyboardAvoidanceCoordinator restoreForViewController:self animated:NO];
    DYYYSettingsSearchCoordinator *coordinator = objc_getAssociatedObject(self, &kDYYYSettingsSearchCoordinatorKey);
    [coordinator restoreNavigationGestureState];
    %orig;
}

- (void)didSelectItemModel:(AWESettingItemModel *)itemModel {
    if ([itemModel.identifier hasPrefix:@"DYYY"] && !itemModel.isEnable) {
        return;
    }
    %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    AWESettingsTableViewCell *cell = (AWESettingsTableViewCell *)[tableView cellForRowAtIndexPath:indexPath];
    AWESettingItemModel *itemModel = [cell isKindOfClass:%c(AWESettingsTableViewCell)] ? cell.itemModel : nil;
    if ([itemModel.identifier hasPrefix:@"DYYY"] && !itemModel.isEnable) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        return;
    }
    %orig;
}

- (void)viewDidLayoutSubviews {
    %orig;
    DYYYSettingsSearchCoordinator *coordinator = objc_getAssociatedObject(self, &kDYYYSettingsSearchCoordinatorKey);
    [coordinator updateLayout];
    for (AWESettingsTableViewCell *cell in self.tableView.visibleCells) {
        if ([cell isKindOfClass:%c(AWESettingsTableViewCell)]) {
            DYYYApplyGeneratedSettingIconToCell(cell);
            DYYYApplyInlineControlsToCell(cell);
        }
    }
}

- (void)dealloc {
    DYYYRemoveRemoteConfigObserver();
    %orig;
}
%end

%hook UINavigationController

- (UIViewController *)popViewControllerAnimated:(BOOL)animated {
    DYYYSettingsSearchCoordinator *coordinator = objc_getAssociatedObject(self.topViewController, &kDYYYSettingsSearchCoordinatorKey);
    if ([coordinator handleBackNavigationRequest]) {
        return nil;
    }

    return %orig;
}

%end

%hook AWESettingsTableViewCell

- (void)setItemModel:(AWESettingItemModel *)itemModel {
    self.iconImageView.transform = CGAffineTransformIdentity;
    self.detailLabel.transform = CGAffineTransformIdentity;
    %orig;
    DYYYApplyGeneratedSettingIconToCell(self);
    DYYYApplyInlineControlsToCell(self);
}

- (void)prepareForReuse {
    %orig;
    self.iconImageView.transform = CGAffineTransformIdentity;
    self.detailLabel.transform = CGAffineTransformIdentity;
}

- (void)updateSubviews {
    %orig;
    DYYYApplyGeneratedSettingIconToCell(self);
    DYYYApplyInlineControlsToCell(self);
}

- (void)updateSubviewsAfterLayout {
    %orig;
    DYYYApplyGeneratedSettingIconToCell(self);
    DYYYApplyInlineControlsToCell(self);
}

- (void)layoutSubviews {
    %orig;
    DYYYApplyGeneratedSettingIconToCell(self);
    DYYYApplyInlineControlsToCell(self);
}

%new
- (void)dyyyInlineTextEditingDidBegin:(UITextField *)textField {
    UIResponder *responder = self;
    while ((responder = responder.nextResponder)) {
        if ([responder isKindOfClass:%c(AWESettingBaseViewController)]) {
            AWESettingBaseViewController *settingsVC = (AWESettingBaseViewController *)responder;
            [DYYYKeyboardAvoidanceCoordinator beginAvoidingInputView:textField inViewController:settingsVC scrollView:settingsVC.tableView];
            break;
        }
    }
}

%new
- (void)dyyyInlineTextReturn:(UITextField *)textField {
    [textField resignFirstResponder];
}

%new
- (void)dyyyInlineTextEditingDidEnd:(UITextField *)textField {
    AWESettingItemModel *itemModel = self.itemModel;
    NSString *configuredIdentifier = objc_getAssociatedObject(self, &kDYYYInlineTextFieldIdentifierKey);
    if (!itemModel.isEnable || ![configuredIdentifier isEqualToString:itemModel.identifier]) {
        textField.text = DYYYInlineTextInputCurrentValue(itemModel.identifier);
        return;
    }
    NSString *committedValue = DYYYCommitInlineTextInput(itemModel, textField.text);
    textField.text = committedValue ?: DYYYInlineTextInputCurrentValue(itemModel.identifier);
}

%new
- (void)dyyyInlineOptionsSegmentChanged:(UISegmentedControl *)segmentedControl {
    AWESettingItemModel *itemModel = self.itemModel;
    NSArray<NSString *> *options = DYYYInlineOptionsForIdentifier(itemModel.identifier);
    NSInteger selectedIndex = segmentedControl.selectedSegmentIndex;
    if (!itemModel.isEnable || selectedIndex < 0 || selectedIndex >= (NSInteger)options.count) {
        return;
    }

    NSString *selectedValue = options[(NSUInteger)selectedIndex];
    [DYYYSettingsHelper setUserDefaults:selectedValue forKey:itemModel.identifier];
    itemModel.detail = @"";
    [itemModel refreshCell];
    DYYYApplyInlineOptionsToCell(self);
}

%end

// 隐藏掉天气Label
%hook AWELeftSideBarWeatherLabel
- (id)initWithFrame:(CGRect)frame {
    id orig = %orig;
    self.hidden = YES;
    return orig;
}

- (void)drawTextInRect:(CGRect)rect {
    // 不做任何绘制，彻底隐藏
}
%end

%hook AWELeftSideBarWeatherView
- (void)layoutSubviews {
    %orig;
    self.hidden = YES;
}
%end

@interface AWELeftSideBarTopIconHorizontalView : UIView
@end

%hook AWELeftSideBarTopIconHorizontalView

- (void)didMoveToSuperview {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *accessibilityLabel = self.accessibilityLabel;
        if (![accessibilityLabel isEqualToString:@"设置"]) {
            return;
        }
        UIView *targetSuperView = self.superview.superview.superview ?: self;
        UIButton *oldBtn = (UIButton *)[targetSuperView viewWithTag:232323];
        if (oldBtn) {
            [oldBtn removeFromSuperview];
        }
        UIButton *dyyyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        dyyyBtn.tag = 232323;
        dyyyBtn.accessibilityLabel = @"DYYYSettingsButton";
        [dyyyBtn setTitle:@"DYYY" forState:UIControlStateNormal];

        UIColor *titleColor = [DYYYUtils isDarkMode] ? [UIColor whiteColor] : [UIColor blackColor];
        [dyyyBtn setTitleColor:titleColor forState:UIControlStateNormal];

        dyyyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        CGRect frame = self.frame;
        dyyyBtn.frame = CGRectMake(frame.origin.x + frame.size.width - 40 - 2, 8, 60, 32);
        dyyyBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        dyyyBtn.layer.cornerRadius = 8;
        dyyyBtn.clipsToBounds = YES;
        [dyyyBtn addTarget:self action:@selector(dyyyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [targetSuperView addSubview:dyyyBtn];
    });
}

%new
- (void)dyyyButtonTapped {
    UIViewController *targetVC = [DYYYSettingsHelper findViewController:self];
    if (!targetVC) {
        UIWindow *activeWindow = [DYYYUtils getActiveWindow];
        targetVC = activeWindow.rootViewController ?: [DYYYUtils topView];
        while (targetVC.presentedViewController) {
            targetVC = targetVC.presentedViewController;
        }
    }
    BOOL hasAgreed = [DYYYSettingsHelper getUserDefaults:@"DYYYUserAgreementAccepted"];
    showDYYYSettingsVC(targetVC, hasAgreed);
}
%end

@interface AWELeftSideBarTopRightLayoutView : UIView
@end

%hook AWELeftSideBarTopRightLayoutView

- (void)didMoveToSuperview {
    %orig;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *accessibilityLabel = self.accessibilityLabel;
        if (![accessibilityLabel isEqualToString:@"设置"]) {
            return;
        }
        UIView *targetSuperView = self.superview.superview.superview ?: self;
        UIButton *oldBtn = (UIButton *)[targetSuperView viewWithTag:232323];
        if (oldBtn) {
            [oldBtn removeFromSuperview];
        }
        UIButton *dyyyBtn = [UIButton buttonWithType:UIButtonTypeSystem];
        dyyyBtn.tag = 232323;
        dyyyBtn.accessibilityLabel = @"DYYYSettingsButton";
        [dyyyBtn setTitle:@"DYYY" forState:UIControlStateNormal];

        UIColor *titleColor = [DYYYUtils isDarkMode] ? [UIColor whiteColor] : [UIColor blackColor];
        [dyyyBtn setTitleColor:titleColor forState:UIControlStateNormal];

        dyyyBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        CGRect frame = self.frame;
        dyyyBtn.frame = CGRectMake(frame.origin.x + frame.size.width - 60 - 10 - 2, 8, 60, 32);
        dyyyBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
        dyyyBtn.layer.cornerRadius = 8;
        dyyyBtn.clipsToBounds = YES;
        [dyyyBtn addTarget:self action:@selector(dyyyButtonTapped) forControlEvents:UIControlEventTouchUpInside];
        [targetSuperView addSubview:dyyyBtn];
    });
}

%new
- (void)dyyyButtonTapped {
    UIViewController *targetVC = [DYYYSettingsHelper findViewController:self];
    if (!targetVC) {
        UIWindow *activeWindow = [DYYYUtils getActiveWindow];
        targetVC = activeWindow.rootViewController ?: [DYYYUtils topView];
        while (targetVC.presentedViewController) {
            targetVC = targetVC.presentedViewController;
        }
    }
    BOOL hasAgreed = [DYYYSettingsHelper getUserDefaults:@"DYYYUserAgreementAccepted"];
    showDYYYSettingsVC(targetVC, hasAgreed);
}
%end

%hook AWELeftSideBarEntranceView
- (void)leftSideBarEntranceViewTapped:(UITapGestureRecognizer *)gesture {
    if (![[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYEntrance"]) {
        %orig;
        return;
    }

    UIViewController *feedVC = [DYYYSettingsHelper findViewController:self];
    if (![feedVC isKindOfClass:%c(AWEFeedContainerViewController)]) {
        UIWindow *activeWindow = [DYYYUtils getActiveWindow];
        feedVC = activeWindow.rootViewController ?: [DYYYUtils topView];
        while (feedVC && ![feedVC isKindOfClass:%c(AWEFeedContainerViewController)]) {
            feedVC = feedVC.presentedViewController;
        }
    }

    if (feedVC) {
        [DYYYSettingsHelper openSettingsWithViewController:feedVC];
    } else {
        %orig;
    }
}
%end

%hook UIView
%new
+ (void)openDYYYSettingsFromSender:(UITapGestureRecognizer *)sender {
    UIView *targetView = objc_getAssociatedObject(sender, "targetView");
    if (targetView) {
        [DYYYSettingsHelper openSettingsFromView:targetView];
    }
}
%end

#ifdef __cplusplus
extern "C"
#endif
void showDYYYSettingsVC(UIViewController *rootVC, BOOL hasAgreed) {
    AWESettingBaseViewController *settingsVC = [[%c(AWESettingBaseViewController) alloc] init];
    settingsVC.colorStyle = 2;
    if (!hasAgreed) {
        [DYYYSettingsHelper showAboutDialog:@"用户协议"
                                    message:@"本插件为开源项目\n仅供学习交流用途\n如有侵权请联系, GitHub 仓库：huami1314/DYYY\n请遵守当地法律法规, "
                                            @"逆向工程仅为学习目的\n盗用源码进行商业用途/发布但未标记开源项目必究\n详情请参阅项目内 MIT 许可证\n\n请输入\"我已阅读并同意继续使用\"以继续"
                                  onConfirm:^{
                                    [DYYYSettingsHelper showUserAgreementAlert];
                                  }];
    }

    // 等待视图加载并使用KVO安全访问属性
    dispatch_async(dispatch_get_main_queue(), ^{
      if ([settingsVC.view isKindOfClass:[UIView class]]) {
          for (UIView *subview in settingsVC.view.subviews) {
              if ([subview isKindOfClass:%c(AWENavigationBar)]) {
                  AWENavigationBar *navigationBar = (AWENavigationBar *)subview;
                  if ([navigationBar respondsToSelector:@selector(titleLabel)]) {
                      navigationBar.titleLabel.text = DYYY_NAME;
                  }
                  break;
              }
          }
      }
    });

    AWESettingsViewModel *viewModel = [[%c(AWESettingsViewModel) alloc] init];
    viewModel.colorStyle = 2;

    // 创建主分类列表
    AWESettingSectionModel *mainSection = [[%c(AWESettingSectionModel) alloc] init];
    mainSection.sectionHeaderTitle = @"功能";
    mainSection.sectionHeaderHeight = 40;
    mainSection.type = 0;
    NSMutableArray<AWESettingItemModel *> *mainItems = [NSMutableArray array];

    // 创建基本设置分类项
    AWESettingItemModel *basicSettingItem = [[%c(AWESettingItemModel) alloc] init];
    basicSettingItem.identifier = @"DYYYBasicSettings";
    basicSettingItem.title = @"基本设置";
    basicSettingItem.type = 0;
    basicSettingItem.svgIconImageName = @"ic_gearsimplify_outlined_20";
    basicSettingItem.cellType = 26;
    basicSettingItem.colorStyle = 2;
    basicSettingItem.isEnable = YES;
    basicSettingItem.cellTappedBlock = ^{
      // 创建基本设置二级界面的设置项
      NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];

      // 【播放控制】
      NSMutableArray<AWESettingItemModel *> *playbackItems = [NSMutableArray array];
      NSArray *playbackSettings = @[
          @{
              @"identifier" : @"DYYYEnableAutoPlay",
              @"title" : @"启用自动播放",
              @"subTitle" : @"暂时仅支持推荐、搜索和个人主页的自动连播",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_play_outlined_12"
          },
          @{
              @"identifier" : @"DYYYEnableBackgroundListen",
              @"title" : @"启用后台播放",
              @"subTitle" : @"使受到后台播放限制的视频可以在后台继续播放",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_play_outlined_12"
          },
          @{
              @"identifier" : @"DYYYDisableCastVPNCheck",
              @"title" : @"忽略投屏 VPN 检测",
              @"subTitle" : @"开启后在连接 VPN 时也可以正常投屏",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_tv_outlined_20"
          },
          @{@"identifier" : @"DYYYDefaultSpeed",
            @"title" : @"设置默认倍速",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_speed_outlined_20"},
          @{@"identifier" : @"DYYYLongPressSpeed",
            @"title" : @"设置长按倍速",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_speed_outlined_20"},
          @{
              @"identifier" : @"DYYYEnableLongPressSpeedGesture",
              @"title" : @"上下控制倍速",
              @"subTitle" : @"长按时可通过上下滑动调整倍速",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_speed_outlined_20"
          }
      ];

      for (NSDictionary *dict in playbackSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          if ([item.identifier isEqualToString:@"DYYYDefaultSpeed"]) {
              NSString *savedSpeed = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYDefaultSpeed"];
              item.detail = savedSpeed ?: @"1.0x";
              item.cellTappedBlock = ^{
                if (DYYYShouldUseInlineOptionsForCurrentScreen(item))
                    return;
                NSArray *speedOptions = @[ @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x" ];
                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYDefaultSpeed"
                                                   optionsArray:speedOptions
                                                     headerText:@"选择默认倍速"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          } else if ([item.identifier isEqualToString:@"DYYYLongPressSpeed"]) {
              NSString *savedSpeed = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLongPressSpeed"];
              item.detail = savedSpeed ?: @"2.0x";
              item.cellTappedBlock = ^{
                if (DYYYShouldUseInlineOptionsForCurrentScreen(item))
                    return;
                NSArray *speedOptions = @[ @"0.75x", @"1.0x", @"1.25x", @"1.5x", @"2.0x", @"2.5x", @"3.0x" ];
                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYLongPressSpeed"
                                                   optionsArray:speedOptions
                                                     headerText:@"选择右侧长按倍速"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }

          [playbackItems addObject:item];
      }

      // 【进度显示】
      NSMutableArray<AWESettingItemModel *> *progressItems = [NSMutableArray array];
      NSArray *progressSettings = @[
          @{
              @"identifier" : @"DYYYShowScheduleDisplay",
              @"title" : @"显示进度时长",
              @"subTitle" : @"强制显示所有视频的进度条和时长",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_playertime_outlined_20"
          },
          @{@"identifier" : @"DYYYScheduleStyle",
            @"title" : @"进度时长样式",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYProgressLabelColor",
            @"title" : @"进度标签颜色",
            @"detail" : @"十六进制",
            @"cellType" : @26,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYTimelineVerticalPosition",
            @"title" : @"进度纵轴位置",
            @"detail" : @"-12.5",
            @"cellType" : @26,
            @"imageName" : @"ic_playertime_outlined_20"},
          @{@"identifier" : @"DYYYHideVideoProgress",
            @"title" : @"隐藏视频进度",
            @"subTitle" : @"隐藏视频进度条",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_playertime_outlined_20"}
      ];

      for (NSDictionary *dict in progressSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          if ([item.identifier isEqualToString:@"DYYYScheduleStyle"]) {
              NSString *savedStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYScheduleStyle"];
              item.detail = savedStyle ?: @"默认";
              item.cellTappedBlock = ^{
                if (DYYYShouldUseInlineOptionsForCurrentScreen(item))
                    return;
                NSArray *styleOptions = @[ @"进度条两侧上下", @"进度条左侧剩余", @"进度条左侧完整", @"进度条右侧剩余", @"进度条右侧完整" ];
                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYScheduleStyle"
                                                   optionsArray:styleOptions
                                                     headerText:@"选择进度时长样式"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }
          [progressItems addObject:item];
      }

      // 【弹幕】
      NSMutableArray<AWESettingItemModel *> *danmuItems = [NSMutableArray array];
      NSArray *danmuSettings = @[
          @{@"identifier" : @"DYYYEnableDanmuColor",
            @"title" : @"启用弹幕改色",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_dansquare_outlined_20"},
          @{
              @"identifier" : @"DYYYDanmuColor",
              @"title" : @"自定弹幕颜色",
              @"subTitle" : @"填入 random 使用随机颜色弹幕",
              @"detail" : @"十六进制",
              @"cellType" : @20,
              @"imageName" : @"ic_dansquarenut_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDanmuRainbowRotating",
              @"title" : @"旋转彩虹弹幕",
              @"subTitle" : @"启用后将覆盖上面的自定义弹幕颜色",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_dansquarenut_outlined_20"
          }
      ];

      for (NSDictionary *dict in danmuSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [danmuItems addObject:item];
      }

      // 【属地标签】
      NSMutableArray<AWESettingItemModel *> *areaLabelItems = [NSMutableArray array];
      NSArray *areaLabelSettings = @[
          @{@"identifier" : @"DYYYEnableArea",
            @"title" : @"时间属地显示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_location_outlined_20"},
          @{
              @"identifier" : @"DYYYGeonamesUsername",
              @"title" : @"国外解析账号",
              @"subTitle" : @"使用 Geonames.org 账号解析国外 IP 属地",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_ip_outlined_12"
          },
          @{@"identifier" : @"DYYYLabelColor",
            @"title" : @"属地标签颜色",
            @"detail" : @"十六进制",
            @"cellType" : @26,
            @"imageName" : @"ic_location_outlined_20"},
          @{
              @"identifier" : @"DYYYEnableRandomGradient",
              @"title" : @"属地随机渐变",
              @"subTitle" : @"启用后将覆盖上面的属地标签颜色",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_location_outlined_20"
          },
          @{@"identifier" : @"DYYYLabelStyle",
            @"title" : @"文案标签样式",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_tag_outlined_20"}
      ];

      for (NSDictionary *dict in areaLabelSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          if ([item.identifier isEqualToString:@"DYYYLabelStyle"]) {
              NSString *savedStyle = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLabelStyle"];
              item.detail = savedStyle ?: @"默认";
              item.cellTappedBlock = ^{
                if (DYYYShouldUseInlineOptionsForCurrentScreen(item))
                    return;
                NSArray *styleOptions = @[ @"文案标签显示", @"文案标签隐藏", @"文案标签禁止跳转搜索" ];
                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYLabelStyle"
                                                   optionsArray:styleOptions
                                                     headerText:@"选择文案标签样式"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }
          [areaLabelItems addObject:item];
      }

      // 【画质帧率】
      NSMutableArray<AWESettingItemModel *> *qualityItems = [NSMutableArray array];
      NSArray *qualitySettings = @[
          @{@"identifier" : kDYYYEnableHighFPSSettingIdentifier,
            @"title" : kDYYYEnableHighFPSSettingTitle,
            @"subTitle" : @"开启后使用设备最高可用帧率，负载过重时会自动降档；可能增加耗电，按需开启。",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : kDYYYEnableHighFPSSVGIconName},
          @{@"identifier" : kDYYYShowFPSOverlaySettingIdentifier,
            @"title" : kDYYYShowFPSOverlaySettingTitle,
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : kDYYYShowFPSOverlaySVGIconName},
          @{@"identifier" : @"DYYYEnableVideoHighestQuality",
            @"title" : @"提高视频画质",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_squaretriangletwo_outlined_20"},
          @{@"identifier" : @"DYYYHDRMode",
            @"title" : @"全局HDR设置",
            @"subTitle" : @"开启并选择后全局屏蔽HDR效果/过滤HDR作品。",
            @"detail" : @"关闭",
            @"cellType" : @26,
            @"imageName" : @"ic_sun_outlined"}
      ];

      for (NSDictionary *dict in qualitySettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          if ([item.identifier isEqualToString:kDYYYEnableHighFPSSettingIdentifier]) {
              void (^originalSwitchChangedBlock)(void) = item.switchChangedBlock;
              item.switchChangedBlock = ^{
                if (originalSwitchChangedBlock) {
                    originalSwitchChangedBlock();
                }
                BOOL enabled = [DYYYSettingsHelper getUserDefaults:kDYYYEnableHighFPSSettingIdentifier];
                DYYYApplyHighFPSSettingChange(enabled);
                DYYYApplyFPSOverlaySettingChange();
              };
          } else if ([item.identifier isEqualToString:kDYYYShowFPSOverlaySettingIdentifier]) {
              void (^originalSwitchChangedBlock)(void) = item.switchChangedBlock;
              item.switchChangedBlock = ^{
                if (originalSwitchChangedBlock) {
                    originalSwitchChangedBlock();
                }
                DYYYApplyFPSOverlaySettingChange();
              };
          } else if ([item.identifier isEqualToString:@"DYYYHDRMode"]) {
              NSString *savedMode = [[NSUserDefaults standardUserDefaults] stringForKey:@"DYYYHDRMode"] ?: @"关闭";
              item.detail = savedMode;
              item.cellTappedBlock = ^{
                if (DYYYShouldUseInlineOptionsForCurrentScreen(item))
                    return;
                NSArray *options = @[ @"关闭", @"全局屏蔽HDR效果", @"全局过滤HDR作品" ];
                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYHDRMode"
                                                   optionsArray:options
                                                     headerText:@"选择 HDR 处理模式"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }

          [qualityItems addObject:item];
      }

      // 【直播】
      NSMutableArray<AWESettingItemModel *> *liveItems = [NSMutableArray array];
      NSArray *liveSettings = @[
          @{@"identifier" : @"DYYYLiveQuality",
            @"title" : @"默认直播画质",
            @"detail" : @"自动",
            @"cellType" : @26,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYEnableLiveRealCount",
            @"title" : @"直播真实人数",
            @"subTitle" : @"直播显示具体的在线人数",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYShowLiveDuration",
            @"title" : @"显示开播时长",
            @"subTitle" : @"在直播间左上角显示主播已开播时间",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_clock_outlined_20"},
          @{@"identifier" : @"DYYYDisableLivePCDN",
            @"title" : @"屏蔽直播PCDN功能",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_video_outlined_20"}
      ];

      for (NSDictionary *dict in liveSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          if ([item.identifier isEqualToString:@"DYYYLiveQuality"]) {
              NSString *savedQuality = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYLiveQuality"] ?: @"自动";
              item.detail = savedQuality;
              item.cellTappedBlock = ^{
                if (DYYYShouldUseInlineOptionsForCurrentScreen(item))
                    return;
                NSArray *qualities = @[ @"蓝光帧彩", @"蓝光", @"超清", @"高清", @"标清", @"自动" ];
                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYLiveQuality"
                                                   optionsArray:qualities
                                                     headerText:@"选择默认直播画质\n无对应画质时会切换到比选择画质低一级的画质"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 item.detail = selectedValue;
                                                 [item refreshCell];
                                               }];
              };
          }
          [liveItems addObject:item];
      }

      // 【推荐过滤】
      NSMutableArray<AWESettingItemModel *> *filterItems = [NSMutableArray array];
      NSArray *filterSettings = @[
          @{@"identifier" : @"DYYYSkipLive",
            @"title" : @"推荐过滤直播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_video_outlined_20"},
          @{
              @"identifier" : @"DYYYSkipAllLive",
              @"title" : @"全部过滤直播",
              @"subTitle" : @"开启后屏蔽直播页面之外的所有直播",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_video_outlined_20"
          },
          @{
              @"identifier" : @"DYYYSkipHotSpot",
              @"title" : @"推荐过滤热点",
              @"subTitle" : @"开启后会过滤推荐中的商品、团购、热点等",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_squaretriangletwo_outlined_20"
          },
          @{@"identifier" : @"DYYYSkipPhoto",
            @"title" : @"推荐过滤图文",
            @"subTitle" : @"开启后会过滤全部图文类型",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYSkipPhotoText",
            @"title" : @"推荐过滤文字",
            @"subTitle" : @"开启后会过滤带有文字标签的图文",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYSkipFriendsVideo",
            @"title" : @"推荐过滤朋友视频",
            @"subTitle" : @"开启后会过滤朋友的作品",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYSkipMusic",
            @"title" : @"推荐过滤音乐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYSkipAIInteraction",
            @"title" : @"推荐过滤AI互动",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_video_outlined_20"},
          @{@"identifier" : @"DYYYFilterLowLikes",
            @"title" : @"推荐过滤低赞",
            @"detail" : @"0",
            @"cellType" : @26,
            @"imageName" : @"ic_thumbsdown_outlined_20"},
          @{@"identifier" : @"DYYYFilterUsers",
            @"title" : @"推荐过滤用户",
            @"subTitle" : @"支持直接填写用户UID；建议通过长按面板添加",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_userban_outlined_20"},
          @{@"identifier" : @"DYYYFilterKeywords",
            @"title" : @"推荐过滤文案",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_tag_outlined_20"},
          @{@"identifier" : @"DYYYFilterProp",
            @"title" : @"推荐过滤拍同款",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_tag_outlined_20"},
          @{
              @"identifier" : @"DYYYFilterTimeLimit",
              @"subTitle" : @"开启后只会推荐最近 N 天内发布的视频\n谨慎开启，最低建议为 10 天",
              @"title" : @"推荐视频时限",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_playertime_outlined_20"
          }
      ];

      for (NSDictionary *dict in filterSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          if ([item.identifier isEqualToString:@"DYYYFilterLowLikes"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterLowLikes"];
              item.detail = savedValue ?: @"0";
              item.cellTappedBlock = nil;
          } else if ([item.identifier isEqualToString:@"DYYYFilterUsers"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterUsers"] ?: @"";
                NSArray *keywordArray = savedKeywords.length > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"过滤用户列表" keywords:keywordArray];
                keywordListView.addItemTitle = @"添加用户UID";
                keywordListView.editItemTitle = @"编辑用户";
                keywordListView.inputPlaceholder = @"请输入用户UID";
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@","];
                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYFilterUsers"];
                  item.detail = keywordString;
                  [item refreshCell];
                };
                [keywordListView show];
              };
          } else if ([item.identifier isEqualToString:@"DYYYFilterKeywords"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterKeywords"] ?: @"";
                NSArray *keywordArray = savedKeywords.length > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤关键词" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@","];
                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYFilterKeywords"];
                  item.detail = keywordString;
                  [item refreshCell];
                };
                [keywordListView show];
              };
          } else if ([item.identifier isEqualToString:@"DYYYFilterTimeLimit"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterTimeLimit"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = nil;
          } else if ([item.identifier isEqualToString:@"DYYYFilterProp"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterProp"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                NSString *savedKeywords = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYFilterProp"] ?: @"";
                NSArray *keywordArray = savedKeywords.length > 0 ? [savedKeywords componentsSeparatedByString:@","] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置过滤词（支持部分匹配）" keywords:keywordArray];
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@","];
                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYFilterProp"];
                  item.detail = keywordString;
                  [item refreshCell];
                };
                [keywordListView show];
              };
          }
          [filterItems addObject:item];
      }

      // 【广告与弹窗】
      NSMutableArray<AWESettingItemModel *> *adsItems = [NSMutableArray array];
      NSArray *adsSettings = @[
          @{@"identifier" : @"DYYYNoAds",
            @"title" : @"启用屏蔽广告",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_ad_outlined_20"},
          @{@"identifier" : kDYYYMiniProgramJumpingAdsSettingIdentifier,
            @"title" : @"小程序跳广告",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_ad_outlined_20"},
          @{@"identifier" : @"DYYYHideTeenMode",
            @"title" : @"移除青少年弹窗",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_personcircleclean_outlined_20"},
          @{@"identifier" : @"DYYYNoUpdates",
            @"title" : @"屏蔽抖音检测更新",
            @"subTitle" : @"屏蔽抖音应用的版本更新",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_circletop_outlined"}
      ];

      for (NSDictionary *dict in adsSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [adsItems addObject:item];
      }

      // 【隐私】
      NSMutableArray<AWESettingItemModel *> *privacyItems = [NSMutableArray array];
      NSArray *privacySettings = @[
          @{@"identifier" : @"DYYYCommentExactTime",
            @"title" : @"评论具体时间",
            @"subTitle" : @"开启后评论区将显示具体的发布时间而非相对时间",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_clock_outlined_20"},
          @{@"identifier" : @"DYYYDisableProfileVisitRecordUpload",
            @"title" : @"禁用访客记录上传",
            @"subTitle" : @"访问用户主页时不上传该访问记录",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYDisableAwemeViewRecordUpload",
            @"title" : @"禁用作品浏览记录上传",
            @"subTitle" : @"浏览作品时不上传该作品浏览记录",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYDisableFeedNowPlayingInfo",
            @"title" : kDYYYFeedNowPlayingSettingTitle,
            @"subTitle" : @"开启后禁止信息流视频播放信息显示在灵动岛",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : kDYYYFeedNowPlayingSVGIconName}
      ];

      for (NSDictionary *dict in privacySettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          if ([item.identifier isEqualToString:kDYYYFeedNowPlayingSettingIdentifier]) {
              void (^originalSwitchChangedBlock)(void) = item.switchChangedBlock;
              item.switchChangedBlock = ^{
                if (originalSwitchChangedBlock) {
                    originalSwitchChangedBlock();
                }
                DYYYApplyFeedNowPlayingSettingChange([DYYYSettingsHelper getUserDefaults:kDYYYFeedNowPlayingSettingIdentifier]);
              };
          }
          [privacyItems addObject:item];
      }

      // 【二次确认】
      NSMutableArray<AWESettingItemModel *> *securityItems = [NSMutableArray array];
      NSArray *securitySettings = @[
          @{@"identifier" : @"DYYYFollowTips",
            @"title" : @"关注二次确认",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_userplus_outlined_20"},
          @{@"identifier" : @"DYYYCollectTips",
            @"title" : @"收藏二次确认",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_star_outlined_20"}
      ];

      for (NSDictionary *dict in securitySettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [securityItems addObject:item];
      }

      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"播放控制" items:playbackItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"进度显示" items:progressItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"弹幕" items:danmuItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"属地标签" items:areaLabelItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"直播" items:liveItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"画质帧率" items:qualityItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"推荐过滤"
                                                         footerTitle:@"请不要同时开启过多过滤推荐项目，这会增大视频流加载延迟。"
                                                               items:filterItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"隐私" items:privacyItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"二次确认" items:securityItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"广告与弹窗" items:adsItems]];

      DYYYRegisterSearchSections(@"基本设置", sections);
      if (DYYYBuildingSettingsSearchIndex) {
          return;
      }

      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"基本设置" sections:sections];
      DYYYAttachSubSettingsSearchHeader(subVC, @"基本设置", sections);
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };
    [mainItems addObject:basicSettingItem];

    // 创建界面设置分类项
    AWESettingItemModel *uiSettingItem = [[%c(AWESettingItemModel) alloc] init];
    uiSettingItem.identifier = @"DYYYUISettings";
    uiSettingItem.title = @"界面设置";
    uiSettingItem.type = 0;
    uiSettingItem.svgIconImageName = @"ic_ipadiphone_outlined";
    uiSettingItem.cellType = 26;
    uiSettingItem.colorStyle = 2;
    uiSettingItem.isEnable = YES;
    uiSettingItem.cellTappedBlock = ^{
      // 创建界面设置二级界面的设置项
      NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];

      // 【首页布局】
      NSMutableArray<AWESettingItemModel *> *homeLayoutItems = [NSMutableArray array];
      NSArray *homeLayoutSettings = @[
          @{
              @"identifier" : @"DYYYVideoBGColor",
              @"title" : @"视频背景颜色",
              @"subTitle" : @"可以自定义部分横屏视频的背景颜色",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_tv_outlined_20"
          },
          @{@"identifier" : @"DYYYHideStatusbar",
            @"title" : @"隐藏系统顶栏",
            @"subTitle" : @"隐藏系统状态栏",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYEnablePure",
            @"title" : @"启用首页净化",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_rectangleportraittriangle_outlined_20"},
          @{@"identifier" : @"DYYYEnableFullScreen",
            @"title" : @"启用首页全屏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_fullscreen_outlined_16"}
      ];

      for (NSDictionary *dict in homeLayoutSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [homeLayoutItems addObject:item];
      }

      // 【透明度设置】分类
      NSMutableArray<AWESettingItemModel *> *transparencyItems = [NSMutableArray array];
      NSArray *transparencySettings = @[
          @{@"identifier" : @"DYYYTopBarTransparent",
            @"title" : @"设置顶栏透明",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_module_outlined_20"},
          @{@"identifier" : @"DYYYGlobalTransparency",
            @"title" : @"设置全局透明",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_eye_outlined_20"},
          @{@"identifier" : @"DYYYAvatarViewTransparency",
            @"title" : @"首页头像透明",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_user_outlined_20"},
          @{@"identifier" : @"DYYYEnableCommentBlur",
            @"title" : @"评论区毛玻璃",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_comment_outlined_20"},
          @{@"identifier" : @"DYYYEnableNotificationTransparency",
            @"title" : @"通知栏毛玻璃",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_comment_outlined_20"},
          @{@"identifier" : @"DYYYNotificationCornerRadius",
            @"title" : @"通知圆角半径",
            @"detail" : @"默认12",
            @"cellType" : @26,
            @"imageName" : @"ic_comment_outlined_20"},
          @{@"identifier" : @"DYYYCommentBlurTransparent",
            @"title" : @"毛玻璃透明度",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_eye_outlined_20"},
      ];

      for (NSDictionary *dict in transparencySettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [transparencyItems addObject:item];
      }

      // 【缩放与大小】分类
      NSMutableArray<AWESettingItemModel *> *scaleItems = [NSMutableArray array];
      NSArray *scaleSettings = @[
          @{@"identifier" : @"DYYYElementScale",
            @"title" : @"右侧栏缩放度",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_zoomin_outlined_20"},
          @{@"identifier" : @"DYYYNicknameScale",
            @"title" : @"昵称缩放控制",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_zoomin_outlined_20"},
          @{@"identifier" : @"DYYYDescriptionScale",
            @"title" : @"文案缩放控制",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_zoomin_outlined_20"},
          @{@"identifier" : @"DYYYIPLabelScale",
            @"title" : @"属地缩放控制",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_zoomin_outlined_20"},
          @{@"identifier" : @"DYYYNicknameVerticalOffset",
            @"title" : @"昵称Y轴距离",
            @"detail" : @"上移为正下移为负",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
          @{@"identifier" : @"DYYYDescriptionVerticalOffset",
            @"title" : @"文案Y轴距离",
            @"detail" : @"上移为正下移为负",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
          @{@"identifier" : @"DYYYIPLabelVerticalOffset",
            @"title" : @"属地Y轴距离",
            @"detail" : @"上移为正下移为负",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
          @{@"identifier" : @"DYYYTabBarHeight",
            @"title" : @"修改底栏高度",
            @"detail" : @"默认为空",
            @"cellType" : @26,
            @"imageName" : @"ic_pensketch_outlined_20"},
      ];

      for (NSDictionary *dict in scaleSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          [scaleItems addObject:item];
      }

      // 【标题自定义】分类
      NSMutableArray<AWESettingItemModel *> *titleItems = [NSMutableArray array];
      NSArray *titleSettings = @[
          @{@"identifier" : @"DYYYModifyTopTabText",
            @"title" : @"设置顶栏标题",
            @"detail" : @"标题=修改#标题=修改",
            @"cellType" : @26,
            @"imageName" : @"ic_tag_outlined_20"},
          @{@"identifier" : @"DYYYIndexTitle",
            @"title" : @"设置首页标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_squaretriangle_outlined_20"},
          @{@"identifier" : @"DYYYFriendsTitle",
            @"title" : @"设置朋友标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_usertwo_outlined_20"},
          @{@"identifier" : @"DYYYMsgTitle",
            @"title" : @"设置消息标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_msg_outlined_20"},
          @{@"identifier" : @"DYYYSelfTitle",
            @"title" : @"设置我的标题",
            @"detail" : @"不填默认",
            @"cellType" : @26,
            @"imageName" : @"ic_user_outlined_20"},
          @{@"identifier" : @"DYYYCommentContent",
            @"title" : @"设置评论填充",
            @"detail" : @"不填则默认",
            @"cellType" : @26,
            @"imageName" : @"ic_comment_outlined_20"},
      ];

      for (NSDictionary *dict in titleSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];
          if ([item.identifier isEqualToString:@"DYYYModifyTopTabText"]) {
              NSString *savedValue = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYModifyTopTabText"];
              item.detail = savedValue ?: @"";
              item.cellTappedBlock = ^{
                NSString *savedPairs = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYModifyTopTabText"] ?: @"";
                NSArray *pairArray = savedPairs.length > 0 ? [savedPairs componentsSeparatedByString:@"#"] : @[];
                DYYYKeywordListView *keywordListView = [[DYYYKeywordListView alloc] initWithTitle:@"设置顶栏标题" keywords:pairArray];
                keywordListView.addItemTitle = @"添加标题修改";
                keywordListView.editItemTitle = @"编辑标题修改";
                keywordListView.inputPlaceholder = @"原标题=新标题";
                keywordListView.onConfirm = ^(NSArray *keywords) {
                  NSString *keywordString = [keywords componentsJoinedByString:@"#"];
                  [DYYYSettingsHelper setUserDefaults:keywordString forKey:@"DYYYModifyTopTabText"];
                  item.detail = keywordString;
                  [item refreshCell];
                };
                [keywordListView show];
              };
          }
          [titleItems addObject:item];
      }

      // 【图标自定义】分类
      NSMutableArray<AWESettingItemModel *> *iconItems = [NSMutableArray array];

      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconLikeBefore" title:@"未点赞图标" svgIcon:@"ic_heart_outlined_20" saveFile:@"like_before.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconLikeAfter" title:@"已点赞图标" svgIcon:@"ic_heart_filled_20" saveFile:@"like_after.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconComment" title:@"评论的图标" svgIcon:@"ic_comment_outlined_20" saveFile:@"comment.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconUnfavorite" title:@"未收藏图标" svgIcon:@"ic_star_outlined_20" saveFile:@"unfavorite.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconFavorite" title:@"已收藏图标" svgIcon:@"ic_star_filled_20" saveFile:@"favorite.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconShare" title:@"分享的图标" svgIcon:@"ic_share_outlined" saveFile:@"share.png"]];
      [iconItems addObject:[DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYIconPlus" title:@"拍摄的图标" svgIcon:@"ic_camera_outlined" saveFile:@"tab_plus.png"]];

      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"首页布局" items:homeLayoutItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"透明度设置" items:transparencyItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"缩放与大小" items:scaleItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"标题自定义" items:titleItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"图标自定义" items:iconItems]];
      // 创建并组织所有section
      DYYYRegisterSearchSections(@"界面设置", sections);
      if (DYYYBuildingSettingsSearchIndex) {
          return;
      }

      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"界面设置" sections:sections];
      DYYYAttachSubSettingsSearchHeader(subVC, @"界面设置", sections);
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };

    [mainItems addObject:uiSettingItem];

    // 创建隐藏设置分类项
    AWESettingItemModel *hideSettingItem = [[%c(AWESettingItemModel) alloc] init];
    hideSettingItem.identifier = @"DYYYHideSettings";
    hideSettingItem.title = @"隐藏设置";
    hideSettingItem.type = 0;
    hideSettingItem.svgIconImageName = @"ic_eyeslash_outlined_20";
    hideSettingItem.cellType = 26;
    hideSettingItem.colorStyle = 2;
    hideSettingItem.isEnable = YES;
    hideSettingItem.cellTappedBlock = ^{
      // 创建隐藏设置二级界面的设置项

      // 【主界面元素】分类
      NSMutableArray<AWESettingItemModel *> *mainUiItems = [NSMutableArray array];
      NSArray *mainUiSettings = @[
          @{
              @"identifier" : @"DYYYHideBottomBg",
              @"title" : @"隐藏底栏背景",
              @"subTitle" : @"完全透明化底栏，可能需要配合首页全屏使用",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideBottomDot",
            @"title" : @"隐藏底栏红点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideDoubleColumnEntry",
              @"title" : @"隐藏双列箭头",
              @"subTitle" : @"隐藏底栏首页旁的双列箭头",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideShopButton",
            @"title" : @"隐藏底栏商城",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMessageButton",
            @"title" : @"隐藏底栏消息",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideFriendsButton",
            @"title" : @"隐藏底栏朋友",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePlusButton",
            @"title" : @"隐藏底栏加号",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMyButton",
            @"title" : @"隐藏底栏我的",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideComment",
            @"title" : @"隐藏底栏评论",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideHotSearch",
            @"title" : @"隐藏底栏热榜",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePadTabBarElements",
            @"title" : @"精简平板底栏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTopBarBadge",
            @"title" : @"隐藏顶栏红点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];

      for (NSDictionary *dict in mainUiSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [mainUiItems addObject:item];
      }

      // 【视频播放界面】分类
      NSMutableArray<AWESettingItemModel *> *videoUiItems = [NSMutableArray array];
      NSArray *videoUiSettings = @[
          @{@"identifier" : @"DYYYHideEntry",
            @"title" : @"隐藏全屏观看",
            @"subTitle" : @"原始位置可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYRemoveEntry",
            @"title" : @"移除全屏观看",
            @"subTitle" : @"完全移除不可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLOTAnimationView",
            @"title" : @"隐藏头像加号",
            @"subTitle" : @"原始位置可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideFollowPromptView",
            @"title" : @"移除头像加号",
            @"subTitle" : @"完全移除不可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLikeLabel",
            @"title" : @"隐藏点赞数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLabel",
            @"title" : @"隐藏评论数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCollectLabel",
            @"title" : @"隐藏收藏数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideShareLabel",
            @"title" : @"隐藏分享数值",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLikeButton",
            @"title" : @"隐藏点赞按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentButton",
            @"title" : @"隐藏评论按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCollectButton",
            @"title" : @"隐藏收藏按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideShareButton",
            @"title" : @"隐藏分享按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAvatarButton",
            @"title" : @"隐藏头像及周边",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAvatarLive",
            @"title" : @"隐藏头像直播提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMusicButton",
            @"title" : @"隐藏音乐按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : kDYYYHideRecommendAppDownloadSettingIdentifier,
            @"title" : @"隐藏推荐应用下载",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideGradient",
              @"title" : @"隐藏遮罩效果",
              @"subTitle" : @"移除视频文案或图片滑条可能出现的黑色背景遮罩效果，但可能对部分视频的文案可读性产生一定影响。",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideBack",
            @"title" : @"隐藏返回按钮",
            @"subTitle" : @"主页视频左上角的返回按钮",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];

      for (NSDictionary *dict in videoUiSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [videoUiItems addObject:item];
      }

      // 【侧边栏】分类
      NSMutableArray<AWESettingItemModel *> *sidebarItems = [NSMutableArray array];
      NSArray *sidebarSettings = @[
          @{@"identifier" : @"DYYYHideSidebarRecentApps",
            @"title" : @"隐藏常用小程序",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSidebarRecentUsers",
            @"title" : @"隐藏常访问的人",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSidebarDot",
            @"title" : @"隐藏侧栏红点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLeftSideBar",
            @"title" : @"隐藏左侧边栏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];

      for (NSDictionary *dict in sidebarSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [sidebarItems addObject:item];
      }

      // 【消息页与我的页】分类
      NSMutableArray<AWESettingItemModel *> *messageAndMineItems = [NSMutableArray array];
      NSArray *messageAndMineSettings = @[
          @{@"identifier" : @"DYYYHidePushBanner",
            @"title" : @"隐藏通知权限提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMessageTabRedPacket",
            @"title" : @"隐藏消息顶栏红包",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAvatarList",
            @"title" : @"隐藏消息头像列表",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAvatarBubble",
            @"title" : @"隐藏消息头像气泡",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideButton",
            @"title" : @"隐藏我的添加朋友",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideFamiliar",
            @"title" : @"隐藏朋友日常按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGroupShop",
            @"title" : @"隐藏群聊商店按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGroupLiveIndicator",
            @"title" : @"隐藏群头像直播中",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGroupInputActionBar",
            @"title" : @"隐藏聊天页工具栏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideReply",
            @"title" : @"隐藏底部私信回复",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePostView",
            @"title" : @"隐藏我的页发作品",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMessageTabStarMall",
            @"title" : @"隐藏消息星光商城",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMineAvatarPlus",
            @"title" : @"隐藏我的页头像加号",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideMineAICreation",
            @"title" : @"隐藏我的创作AI作品",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];
      for (NSDictionary *dict in messageAndMineSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [messageAndMineItems addObject:item];
      }

      // 【提示与位置信息】分类
      NSMutableArray<AWESettingItemModel *> *infoItems = [NSMutableArray array];
      NSArray *infoSettings = @[
          @{@"identifier" : @"DYYYHideLiveView",
            @"title" : @"隐藏关注顶端",
            @"subTitle" : @"隐藏关注页顶端的直播列表",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideConcernCapsuleView",
              @"title" : @"隐藏关注直播",
              @"subTitle" : @"隐藏关注页顶端的 N 个直播",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideMenuView",
              @"title" : @"隐藏同城顶端",
              @"subTitle" : @"隐藏同城页顶端的团购等菜单",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideNearbyCapsuleView",
            @"title" : @"隐藏吃喝玩乐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideDiscover",
            @"title" : @"隐藏右上搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentDiscover",
            @"title" : @"隐藏评论搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideInteractionSearch",
            @"title" : @"隐藏相关搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideSearchBubble",
              @"title" : @"隐藏弹出热搜",
              @"subTitle" : @"从右上搜索位置处弹出的热搜白框",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideSearchSame",
            @"title" : @"隐藏搜索同款",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSearchEntrance",
            @"title" : @"隐藏顶部搜索框",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideSearchEntranceIndicator",
            @"title" : @"隐藏搜索框背景",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideDanmuButton",
            @"title" : @"隐藏弹幕按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCancelMute",
            @"title" : @"隐藏静音按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideQuqishuiting",
            @"title" : @"隐藏去汽水听",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGongChuang",
            @"title" : @"屏蔽共创信息",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideHotspot",
            @"title" : @"隐藏热点提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideRecommendTips",
            @"title" : @"隐藏推荐提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideBottomRelated",
            @"title" : @"隐藏底部相关",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideShareContentView",
            @"title" : @"隐藏分享提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideAntiAddictedNotice",
            @"title" : @"隐藏作者声明及风险提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideFeedAnchorContainer",
              @"title" : @"隐藏视频锚点",
              @"detail" : @"",
              @"cellType" : @6,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideLocation",
            @"title" : @"隐藏视频定位",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideChallengeStickers",
            @"title" : @"隐藏挑战贴纸",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideEditTag",
            @"title" : @"隐藏互动贴纸",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplateLabel",
            @"title" : @"隐藏精选标签",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideFriendRecommend",
            @"title" : @"隐藏好友推荐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplateTags",
            @"title" : @"隐藏校园提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideHisShop",
            @"title" : @"隐藏作者店铺",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTopBarLine",
            @"title" : @"隐藏顶栏横线",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplateVideo",
            @"title" : @"隐藏视频合集",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideTemplatePlaylet",
            @"title" : @"隐藏短剧合集",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveGIF",
            @"title" : @"隐藏动图标签",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideItemTag",
            @"title" : @"隐藏笔记标签",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideBottomInteraction",
              @"title" : @"隐藏底部互动",
              @"subTitle" : @"隐藏底部出现的分享等互动",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideCameraLocation",
            @"title" : @"隐藏相机定位",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentViews",
            @"title" : @"隐藏评论视图",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentTips",
            @"title" : @"隐藏评论提示",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLiveCapsuleView",
              @"title" : @"隐藏直播提示",
              @"subTitle" : @"隐藏所有的直播中提示",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideStoryProgressSlide",
            @"title" : @"隐藏视频滑条",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideDotsIndicator",
            @"title" : @"隐藏图片滑条",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideChapterProgress",
              @"title" : @"隐藏章节进度",
              @"subTitle" : @"隐藏可能出现在视频上方或者下方的章节进度条",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHidePopover",
            @"title" : @"隐藏上次看到",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHidePrivateMessages",
            @"title" : @"隐藏分享私信",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideRightLabel",
            @"title" : @"隐藏昵称右侧",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideChapterPoints",
            @"title" : @"隐藏章节要点",
            @"subTitle" : @"隐藏昵称旁边的章节要点按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHidePendantGroup",
              @"title" : @"隐藏红包悬浮",
              @"subTitle" : @"隐藏抖音极速版和抖音部分视频的红包悬浮按钮，可能失效，不修复。",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideScancode",
              @"title" : @"隐藏输入扫码",
              @"subTitle" : @"隐藏点击搜索后输入框右部的扫码按钮",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHidePauseVideoRelatedWord",
              @"title" : @"隐藏暂停相关",
              @"subTitle" : @"隐藏暂停视频后出现的相关词条",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideKeyboardAI",
              @"title" : @"隐藏键盘 AI",
              @"subTitle" : @"隐藏搜索下方的 AI 和语音搜索按钮",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          }
      ];

      for (NSDictionary *dict in infoSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [infoItems addObject:item];
      }

      // 【直播界面净化】分类
      NSMutableArray<AWESettingItemModel *> *livestreamItems = [NSMutableArray array];
      NSArray *livestreamSettings = @[
          @{@"identifier" : @"DYYYHideLivePlayground",
            @"title" : @"隐藏直播广场",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideEnterLive",
            @"title" : @"隐藏进入直播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomClose",
            @"title" : @"隐藏关闭按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomFullscreen",
            @"title" : @"隐藏横屏按钮",
            @"subTitle" : @"原始位置可点击",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideGiftPavilion",
            @"title" : @"隐藏礼物展馆",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomClear",
            @"title" : @"隐藏退出清屏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideLiveRoomMirroring",
            @"title" : @"隐藏投屏按钮",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLiveRoomShareCompanion",
              @"title" : @"隐藏直播伴侣提示",
              @"subTitle" : @"隐藏直播间分享面板中的直播伴侣下载提示",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideLiveDiscovery",
            @"title" : @"隐藏直播发现",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLiveDetail",
              @"title" : @"隐藏直播热榜",
              @"subTitle" : @"隐藏用户下方的小时榜、人气榜、热度等信息",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideTouchView",
              @"title" : @"隐藏红包悬浮",
              @"subTitle" : @"隐藏用户下方的红包、积分等悬浮按钮",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideKTVSongIndicator",
            @"title" : @"隐藏直播点歌",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLiveGoodsMsg",
              @"title" : @"隐藏商品推广",
              @"subTitle" : @"隐藏直播间右下角的商品和右上角的推广",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideLiveLikeAnimation",
            @"title" : @"隐藏点赞动画",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{
              @"identifier" : @"DYYYHideLivePopup",
              @"title" : @"隐藏进场特效",
              @"subTitle" : @"隐藏会员用户进入直播间时出现在弹幕顶部的动画特效",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideLiveDanmaku",
              @"title" : @"隐藏滚动弹幕",
              @"subTitle" : @"隐藏直播间管理员发送的特殊横向滚动弹幕",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideLiveHotMessage",
              @"title" : @"隐藏大家在说",
              @"subTitle" : @"隐藏出现在弹幕顶部的大家说热搜词",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideStickerView",
              @"title" : @"隐藏文字贴纸",
              @"subTitle" : @"隐藏主播设置的预约直播和文字贴纸",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHideGroupComponent",
              @"title" : @"隐藏礼物挑战",
              @"subTitle" : @"隐藏主播设置的发送礼物做挑战列表",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{@"identifier" : @"DYYYHideCellularAlert",
            @"title" : @"隐藏流量提醒",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}

      ];
      for (NSDictionary *dict in livestreamSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [livestreamItems addObject:item];
      }

      // 【长按面板】分类
      NSMutableArray<AWESettingItemModel *> *modernpanels = [NSMutableArray array];
      NSArray *modernpanelSettings = @[
          @{
              @"identifier" : @"DYYYSimplifyLongPressPanel",
              @"title" : @"精简长按面板",
              @"subTitle" : @"开启后将隐藏所有原始面板选项，只保留 DYYY 自定义功能",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_eyeslash_outlined_16"
          },
          @{
              @"identifier" : @"DYYYHidePanelItems",
              @"title" : @"隐藏面板项目",
              @"subTitle" : @"输入要隐藏的按钮名称，多个用逗号分隔\n支持精确匹配和部分匹配，不区分大小写\n例如：举报,倍速,投屏,弹幕",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_eyeslash_outlined_16"
          }
      ];

      for (NSDictionary *dict in modernpanelSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];

          // 特殊处理隐藏面板项目选项（文本输入）
          if ([item.identifier isEqualToString:@"DYYYHidePanelItems"]) {
              NSString *savedItems = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYHidePanelItems"];
              item.detail = savedItems.length > 0 ? savedItems : @"";
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSString *defaultText = item.detail ?: @"";
                [DYYYSettingsHelper showTextInputAlert:@"隐藏面板项目"
                                           defaultText:defaultText
                                           placeholder:@"例如：举报,倍速,投屏,弹幕"
                                             onConfirm:^(NSString *text) {
                                               NSString *trimmedText = [text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
                                               [DYYYSettingsHelper setUserDefaults:trimmedText forKey:@"DYYYHidePanelItems"];
                                               item.detail = trimmedText ?: @"";
                                               [item refreshCell];
                                             }
                                              onCancel:nil];
              };
          }

          [modernpanels addObject:item];
      }

      // 【长按评论分类】
      NSMutableArray<AWESettingItemModel *> *commentpanel = [NSMutableArray array];
      NSArray *commentpanelSettings = @[
          @{@"identifier" : @"DYYYHideCommentShareToFriends",
            @"title" : @"隐藏评论分享",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressFavorite",
            @"title" : @"隐藏评论收藏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressCopy",
            @"title" : @"隐藏评论复制",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressSaveImage",
            @"title" : @"隐藏评论保存",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressReport",
            @"title" : @"隐藏评论举报",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressSearch",
            @"title" : @"隐藏评论搜索",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressDaily",
            @"title" : @"隐藏评论转发日常",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressVideoReply",
            @"title" : @"隐藏评论视频回复",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"},
          @{@"identifier" : @"DYYYHideCommentLongPressPictureSearch",
            @"title" : @"隐藏评论识别图片",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_eyeslash_outlined_16"}
      ];
      for (NSDictionary *dict in commentpanelSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [commentpanel addObject:item];
      }
      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"主界面元素" items:mainUiItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"视频播放界面" items:videoUiItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"侧边栏元素" items:sidebarItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"消息页与我的页" items:messageAndMineItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"提示与位置信息" items:infoItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"直播间界面" items:livestreamItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"隐藏面板功能" footerTitle:@"隐藏视频长按面板中的功能" items:modernpanels]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"隐藏长按评论功能" footerTitle:@"隐藏评论长按面板中的功能" items:commentpanel]];
      DYYYRegisterSearchSections(@"隐藏设置", sections);
      if (DYYYBuildingSettingsSearchIndex) {
          return;
      }

      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"隐藏设置" sections:sections];
      DYYYAttachSubSettingsSearchHeader(subVC, @"隐藏设置", sections);
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };
    [mainItems addObject:hideSettingItem];

    // 创建顶栏移除分类项
    AWESettingItemModel *removeSettingItem = [[%c(AWESettingItemModel) alloc] init];
    removeSettingItem.identifier = @"DYYYRemoveSettings";
    removeSettingItem.title = @"顶栏移除";
    removeSettingItem.type = 0;
    removeSettingItem.svgIconImageName = @"ic_doublearrowup_outlined_20";
    removeSettingItem.cellType = 26;
    removeSettingItem.colorStyle = 2;
    removeSettingItem.isEnable = YES;
    removeSettingItem.cellTappedBlock = ^{
      // 创建顶栏移除二级界面的设置项
      NSMutableArray<AWESettingItemModel *> *removeSettingsItems = [NSMutableArray array];
      NSArray *removeSettings = @[
          @{@"identifier" : @"DYYYHideHotContainer",
            @"title" : @"移除推荐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideFriend",
            @"title" : @"移除朋友",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideFollow",
            @"title" : @"移除关注",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideMediumVideo",
            @"title" : @"移除精选",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideMall",
            @"title" : @"移除商城",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideNearby",
            @"title" : @"移除同城",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideGroupon",
            @"title" : @"移除团购",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideTabLive",
            @"title" : @"移除直播",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHidePadHot",
            @"title" : @"移除热点",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideHangout",
            @"title" : @"移除经验",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHidePlaylet",
            @"title" : @"移除短剧",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideCinema",
            @"title" : @"移除看剧",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideKidsV2",
            @"title" : @"移除少儿",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideGame",
            @"title" : @"移除游戏",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"},
          @{@"identifier" : @"DYYYHideMediumVideo",
            @"title" : @"移除长视频",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_xmark_outlined_20"}
      ];

      for (NSDictionary *dict in removeSettings) {
          AWESettingItemModel *item = [[%c(AWESettingItemModel) alloc] init];
          item.identifier = dict[@"identifier"];
          item.title = dict[@"title"];
          NSString *savedDetail = [[NSUserDefaults standardUserDefaults] objectForKey:item.identifier];
          item.detail = savedDetail ?: dict[@"detail"];
          item.type = 1000;
          item.svgIconImageName = dict[@"imageName"];
          item.cellType = [dict[@"cellType"] integerValue];
          item.colorStyle = 2;
          item.isEnable = YES;
          item.isSwitchOn = [DYYYSettingsHelper getUserDefaults:item.identifier];
          __weak AWESettingItemModel *weakItem = item;
          item.switchChangedBlock = ^{
            __strong AWESettingItemModel *strongItem = weakItem;
            if (strongItem) {
                BOOL isSwitchOn = !strongItem.isSwitchOn;
                strongItem.isSwitchOn = isSwitchOn;
                [DYYYSettingsHelper setUserDefaults:@(isSwitchOn) forKey:strongItem.identifier];
            }
          };
          [removeSettingsItems addObject:item];
      }

      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"顶栏选项" items:removeSettingsItems]];

      DYYYRegisterSearchSections(@"顶栏移除", sections);
      if (DYYYBuildingSettingsSearchIndex) {
          return;
      }

      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"顶栏移除" sections:sections];
      DYYYAttachSubSettingsSearchHeader(subVC, @"顶栏移除", sections);
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };
    [mainItems addObject:removeSettingItem];

    // 创建增强设置分类项
    AWESettingItemModel *enhanceSettingItem = [[%c(AWESettingItemModel) alloc] init];
    enhanceSettingItem.identifier = @"DYYYEnhanceSettings";
    enhanceSettingItem.title = @"增强设置";
    enhanceSettingItem.type = 0;
    enhanceSettingItem.svgIconImageName = @"ic_squaresplit_outlined_20";
    enhanceSettingItem.cellType = 26;
    enhanceSettingItem.colorStyle = 2;
    enhanceSettingItem.isEnable = YES;
    enhanceSettingItem.cellTappedBlock = ^{
      // 创建增强设置二级界面的设置项
      NSMutableDictionary *cellTapHandlers = [NSMutableDictionary dictionary];

      // 【账号与登录】
      NSMutableArray<AWESettingItemModel *> *accountItems = [NSMutableArray array];
      AWESettingItemModel *loginBypassItem = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYEnableLoginBypass",
          @"title" : @"启用绕登录",
          @"subTitle" : @"开启后可绕过登录时低版本/风险提示，登录成功后自动关闭",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : kDYYYLoginBypassSVGIconName
      }];
      [accountItems addObject:loginBypassItem];

      // 【长按面板设置】分类
      NSMutableArray<AWESettingItemModel *> *longPressItems = [NSMutableArray array];
      NSArray *longPressSettings = @[
          @{@"identifier" : @"DYYYLongPressSaveVideo",
            @"title" : @"长按保存当前视频",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveCover",
            @"title" : @"长按保存视频封面",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveAudio",
            @"title" : @"长按保存视频音乐",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveCurrentImage",
            @"title" : @"长按保存当前图片",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressSaveAllImages",
            @"title" : @"长按保存所有图片",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_boxarrowdown_outlined"},
          @{@"identifier" : @"DYYYLongPressCreateVideo",
            @"title" : @"长按面板制作视频",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_videosearch_outlined_20"},
          @{@"identifier" : @"DYYYLongPressCopyText",
            @"title" : @"长按复制视频文案",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_rectangleonrectangleup_outlined_20"},
          @{@"identifier" : @"DYYYLongPressCopyLink",
            @"title" : @"长按复制分享链接",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_rectangleonrectangleup_outlined_20"},
          @{@"identifier" : @"DYYYLongPressApiDownload",
            @"title" : @"长按接口解析下载",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_cloudarrowdown_outlined_20"},
          @{@"identifier" : @"DYYYLongPressFilterUser",
            @"title" : @"长按面板过滤用户",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_userban_outlined_20"},
          @{@"identifier" : @"DYYYLongPressFilterTitle",
            @"title" : @"长按面板过滤文案",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_funnel_outlined_20"},
          @{@"identifier" : @"DYYYLongPressTimerClose",
            @"title" : @"长按定时关闭抖音",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_c_alarm_outlined"}
      ];

      for (NSDictionary *dict in longPressSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          [longPressItems addObject:item];
      }

      // 【媒体保存】分类
      NSMutableArray<AWESettingItemModel *> *downloadItems = [NSMutableArray array];
      NSArray *downloadSettings = @[
          @{
              @"identifier" : kDYYYAlbumMediaDescriptionSettingIdentifier,
              @"title" : @"保存作品信息",
              @"detail" : @"",
              @"cellType" : @6,
              @"imageName" : @"ic_cloudarrowdown_outlined_20"
          },
          @{
              @"identifier" : @"DYYYInterfaceDownload",
              @"title" : @"接口解析保存媒体",
              @"subTitle" : @"填入自定义的解析接口，标准格式请查阅 Github 仓库内的 README 文件",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_cloudarrowdown_outlined_20"
          },
          @{@"identifier" : @"DYYYShowAllVideoQuality",
            @"title" : @"接口显示清晰选项",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_hamburgernut_outlined_20"},
          @{@"identifier" : @"DYYYEnableSheetBlur",
            @"title" : @"保存面板玻璃效果",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_list_outlined"},
          @{@"identifier" : @"DYYYSheetBlurTransparent",
            @"title" : @"面板毛玻璃透明度",
            @"detail" : @"0-1小数",
            @"cellType" : @26,
            @"imageName" : @"ic_eye_outlined_20"},
          @{@"identifier" : @"DYYYCommentLivePhotoNotWaterMark",
            @"title" : @"移除评论实况水印",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_livephoto_outlined_20"},
          @{@"identifier" : @"DYYYCommentNotWaterMark",
            @"title" : @"移除评论图片水印",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_removeimage_outlined_20"},
        @{
            @"identifier" : @"DYYYForceDownloadCommentImage",
            @"title" : @"保存评论区图片",
            @"subTitle" : @"长按评论可保存所有实况和图片",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_image_outlined"
        },
        @{
            @"identifier" : @"DYYYForceDownloadCommentAudio",
            @"title" : @"保存评论区语音",
            @"subTitle" : @"长按语音评论可下载并分享",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_playbackquaver_outlined"
        },
        @{
            @"identifier" : @"DYYYForceDownloadEmotion",
            @"title" : @"保存评论区表情包",
            @"subTitle" : @"长按评论或者长按表情包",
            @"detail" : @"",
            @"cellType" : @37,
            @"imageName" : @"ic_emoji_outlined"
        },
          @{@"identifier" : @"DYYYForceDownloadPreviewEmotion",
            @"title" : @"保存预览页表情包",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_emoji_outlined"},
          @{@"identifier" : @"DYYYForceDownloadIMEmotion",
            @"title" : @"保存聊天页表情包",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_emoji_outlined"},
          @{@"identifier" : @"DYYYHapticFeedbackEnabled",
            @"title" : @"下载完成震动反馈",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_gearsimplify_outlined_20"}
      ];

      for (NSDictionary *dict in downloadSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict cellTapHandlers:cellTapHandlers];

          // 相册作品信息默认关闭；首次展示设置页时同步默认值，
          // 避免 UI 和保存链路对缺少 key 的默认判断不一致。
          if ([item.identifier isEqualToString:kDYYYAlbumMediaDescriptionSettingIdentifier] &&
              ![[NSUserDefaults standardUserDefaults] objectForKey:kDYYYAlbumMediaDescriptionSettingIdentifier]) {
              [DYYYSettingsHelper setUserDefaults:@NO forKey:kDYYYAlbumMediaDescriptionSettingIdentifier];
              item.isSwitchOn = NO;
          }

          // 特殊处理接口解析保存媒体选项
          if ([item.identifier isEqualToString:@"DYYYInterfaceDownload"]) {
              // 获取已保存的接口URL
              NSString *savedURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYInterfaceDownload"];
              item.detail = savedURL.length > 0 ? savedURL : @"不填关闭";
              item.cellTappedBlock = nil;
          }
          [downloadItems addObject:item];
      }

      // 【ABTest】分类
      NSMutableArray<AWESettingItemModel *> *hotUpdateItems = [NSMutableArray array];
      NSArray *hotUpdateSettings = @[
          @{@"identifier" : @"DYYYABTestBlockEnabled",
            @"title" : @"禁止下发配置",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_fire_outlined_20"},
          @{@"identifier" : @"DYYYABTestModeString",
            @"title" : @"配置应用方式",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_enterpriseservice_outlined"},
          @{@"identifier" : @"DYYYRemoteConfigURL",
            @"title" : @"远程配置地址",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_cloudarrowdown_outlined_20"},
          @{@"identifier" : @"DYYYCheckUpdate",
            @"title" : @"检查配置更新",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_cloudarrowdown_outlined_20"},
          @{@"identifier" : @"SaveCurrentABTestData",
            @"title" : @"导出当前配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_memorycard_outlined_20"},
          @{@"identifier" : @"SaveABTestConfigFile",
            @"title" : @"导出本地配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_memorycard_outlined_20"},
          @{@"identifier" : @"LoadABTestConfigFile",
            @"title" : @"导入本地配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_phonearrowup_outlined_20"},
          @{@"identifier" : @"DeleteABTestConfigFile",
            @"title" : @"删除本地配置",
            @"detail" : @"",
            @"cellType" : @26,
            @"imageName" : @"ic_trash_outlined_20"}
      ];

      // --- 声明一个__block变量来持有SaveABTestConfigFileitem ---
      __block AWESettingItemModel *saveABTestConfigFileItemRef = nil;
      __block AWESettingItemModel *remoteURLItemRef = nil;
      __block AWESettingItemModel *checkUpdateItemRef = nil;
      __block AWESettingItemModel *loadConfigItemRef = nil;
      __block AWESettingItemModel *deleteConfigItemRef = nil;
      // --- 定义一个用于刷新SaveABTestConfigFileitem的局部block ---
      void (^refreshSaveABTestConfigFileItem)(void) = ^{
        if (!saveABTestConfigFileItemRef)
            return;

        // 在后台队列执行文件状态检查和大小获取
        dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
          __weak AWESettingItemModel *weakSaveItem = saveABTestConfigFileItemRef;
          __strong AWESettingItemModel *strongSaveItem = weakSaveItem;
          if (!strongSaveItem) {
              return;
          }

          NSFileManager *fileManager = [NSFileManager defaultManager];
          NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
          NSString *documentsDirectory = [paths firstObject];
          NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
          NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

          NSString *loadingStatus = [DYYYABTestHook isLocalConfigLoaded] ? @"已加载：" : @"未加载：";

          NSString *detailText = nil;
          BOOL isItemEnable = NO;

          if (![fileManager fileExistsAtPath:jsonFilePath]) {
              detailText = [NSString stringWithFormat:@"%@ (文件不存在)", loadingStatus];
              isItemEnable = NO;
          } else {
              unsigned long long jsonFileSize = 0;
              NSError *attributesError = nil;
              NSDictionary *attributes = [fileManager attributesOfItemAtPath:jsonFilePath error:&attributesError];
              if (!attributesError && attributes) {
                  jsonFileSize = [attributes fileSize];
                  detailText = [NSString stringWithFormat:@"%@ %@", loadingStatus, [DYYYUtils formattedSize:jsonFileSize]];
                  isItemEnable = YES;
              } else {
                  detailText = [NSString stringWithFormat:@"%@ (读取失败: %@)", loadingStatus, attributesError.localizedDescription ?: @"未知错误"];
                  isItemEnable = NO;
              }
          }

          // 回到主线程更新 UI
          dispatch_async(dispatch_get_main_queue(), ^{
            // 在主线程更新 UI 前检查 item 是否仍然存在
            __strong AWESettingItemModel *strongSaveItemAgain = weakSaveItem;
            if (strongSaveItemAgain) {
                strongSaveItemAgain.detail = detailText;
                strongSaveItemAgain.isEnable = isItemEnable;
                [strongSaveItemAgain refreshCell];
            }
          });
        });
      };

      void (^refreshConfigConflictState)(void) = ^{
        BOOL remoteMode = [DYYYABTestHook isRemoteMode];
        BOOL localLoaded = [DYYYABTestHook isLocalConfigLoaded];
        if (remoteMode) {
            if (loadConfigItemRef) {
                loadConfigItemRef.isEnable = NO;
                [loadConfigItemRef refreshCell];
            }
            if (deleteConfigItemRef) {
                deleteConfigItemRef.isEnable = NO;
                [deleteConfigItemRef refreshCell];
            }
            if (remoteURLItemRef) {
                remoteURLItemRef.isEnable = YES;
                [remoteURLItemRef refreshCell];
            }
            if (checkUpdateItemRef) {
                checkUpdateItemRef.isEnable = YES;
                [checkUpdateItemRef refreshCell];
            }
        } else if (localLoaded) {
            if (remoteURLItemRef) {
                remoteURLItemRef.isEnable = NO;
                [remoteURLItemRef refreshCell];
            }
            if (checkUpdateItemRef) {
                checkUpdateItemRef.isEnable = NO;
                [checkUpdateItemRef refreshCell];
            }
            if (loadConfigItemRef) {
                loadConfigItemRef.isEnable = YES;
                [loadConfigItemRef refreshCell];
            }
            if (deleteConfigItemRef) {
                deleteConfigItemRef.isEnable = YES;
                [deleteConfigItemRef refreshCell];
            }
        } else {
            if (remoteURLItemRef) {
                remoteURLItemRef.isEnable = YES;
                [remoteURLItemRef refreshCell];
            }
            if (checkUpdateItemRef) {
                checkUpdateItemRef.isEnable = YES;
                [checkUpdateItemRef refreshCell];
            }
            if (loadConfigItemRef) {
                loadConfigItemRef.isEnable = YES;
                [loadConfigItemRef refreshCell];
            }
            if (deleteConfigItemRef) {
                deleteConfigItemRef.isEnable = YES;
                [deleteConfigItemRef refreshCell];
            }
        }
      };

      [[NSNotificationCenter defaultCenter] addObserverForName:DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION
                                                        object:nil
                                                         queue:[NSOperationQueue mainQueue]
                                                    usingBlock:^(NSNotification *_Nonnull note) {
                                                      refreshConfigConflictState();
                                                    }];

      for (NSDictionary *dict in hotUpdateSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];

          if ([item.identifier isEqualToString:@"DYYYABTestBlockEnabled"]) {
              item.switchChangedBlock = ^{
                BOOL newValue = !item.isSwitchOn;

                if (newValue) {
                    [DYYYBottomAlertView showAlertWithTitle:@"禁止 ABTest 下发配置"
                        message:@"这将暂停接收测试新功能的推送。确定要继续吗？"
                        avatarURL:nil
                        cancelButtonText:@"取消"
                        confirmButtonText:@"确定"
                        cancelAction:^{
                          item.isSwitchOn = !newValue;
                          [item refreshCell];
                        }
                        closeAction:nil
                        confirmAction:^{
                          item.isSwitchOn = newValue;
                          [DYYYSettingsHelper setUserDefaults:@(newValue) forKey:@"DYYYABTestBlockEnabled"];

                          [DYYYABTestHook setABTestBlockEnabled:newValue];
                        }];
                } else {
                    item.isSwitchOn = newValue;
                    [DYYYSettingsHelper setUserDefaults:@(newValue) forKey:@"DYYYABTestBlockEnabled"];
                    [DYYYUtils showToast:@"已允许 ABTest 下发配置，重启后生效。"];
                }
              };
          } else if ([item.identifier isEqualToString:@"DYYYABTestModeString"]) {
              BOOL isPatchMode = [DYYYABTestHook isPatchMode];
              if ([DYYYABTestHook isRemoteMode]) {
                  item.detail = isPatchMode ? @"远程模式(覆写)" : @"远程模式(替换)";
              } else {
                  item.detail = isPatchMode ? @"覆写模式" : @"替换模式";
              }

              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSString *currentMode = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYABTestModeString"] ?: @"替换模式：忽略原配置，使用新数据";

                NSArray *modeOptions = @[ @"覆写模式：保留原设置，覆盖同名项", @"替换模式：忽略原配置，使用新数据", DYYY_REMOTE_MODE_STRING ];

                [DYYYOptionsSelectionView showWithPreferenceKey:@"DYYYABTestModeString"
                                                   optionsArray:modeOptions
                                                     headerText:@"选择本地配置的应用方式"
                                                 onPresentingVC:topView()
                                               selectionChanged:^(NSString *selectedValue) {
                                                 BOOL isPatchMode = [DYYYABTestHook isPatchMode];
                                                 if ([DYYYABTestHook isRemoteMode]) {
                                                     item.detail = isPatchMode ? @"远程模式(覆写)" : @"远程模式(替换)";
                                                 } else {
                                                     item.detail = isPatchMode ? @"覆写模式" : @"替换模式";
                                                 }

                                                 BOOL wasRemote = [[NSUserDefaults standardUserDefaults] boolForKey:DYYY_REMOTE_CONFIG_FLAG_KEY];

                                                 if ([selectedValue isEqualToString:DYYY_REMOTE_MODE_STRING]) {
                                                     [[NSUserDefaults standardUserDefaults] setBool:YES forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                                                     refreshConfigConflictState();
                                                 } else {
                                                     if (wasRemote) {
                                                         [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                                                         refreshConfigConflictState();
                                                     }
                                                 }

                                                 if (![selectedValue isEqualToString:currentMode]) {
                                                     [DYYYABTestHook applyFixedABTestData];
                                                 }
                                                 [item refreshCell];
                                               }];
              };
          } else if ([item.identifier isEqualToString:@"DYYYRemoteConfigURL"]) {
              remoteURLItemRef = item;
              NSString *savedURL = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYRemoteConfigURL"];
              item.detail = savedURL.length > 0 ? savedURL : DYYY_DEFAULT_ABTEST_URL;
              item.cellTappedBlock = nil;
          } else if ([item.identifier isEqualToString:@"DYYYCheckUpdate"]) {
              checkUpdateItemRef = item;
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                [DYYYUtils showToast:@"正在检查更新..."];
                [DYYYABTestHook checkForRemoteConfigUpdate:YES];
              };
          } else if ([item.identifier isEqualToString:@"SaveCurrentABTestData"]) {
              item.detail = @"(获取中...)";
              item.isEnable = NO;

              // 在后台队列获取数据并更新 UI
              dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                __weak AWESettingItemModel *weakItem = item;
                __strong AWESettingItemModel *strongItem = weakItem;
                if (!strongItem) {
                    return;
                }

                NSDictionary *currentData = [DYYYABTestHook getCurrentABTestData];

                NSString *detailText = nil;
                BOOL isItemEnable = NO;
                NSData *jsonDataForSize = nil;

                if (!currentData) {
                    detailText = @"(获取失败)";
                    isItemEnable = NO;
                } else {
                    NSError *serializationError = nil;
                    jsonDataForSize = [NSJSONSerialization dataWithJSONObject:currentData options:NSJSONWritingPrettyPrinted error:&serializationError];
                    if (!serializationError && jsonDataForSize) {
                        detailText = [DYYYUtils formattedSize:jsonDataForSize.length];
                        isItemEnable = YES;
                    } else {
                        detailText = [NSString stringWithFormat:@"(序列化失败: %@)", serializationError.localizedDescription ?: @"未知错误"];
                        isItemEnable = NO;
                    }
                }

                // 回到主线程更新 UI
                dispatch_async(dispatch_get_main_queue(), ^{
                  __strong AWESettingItemModel *strongItemAgain = weakItem;
                  if (strongItemAgain) {
                      strongItemAgain.detail = detailText;
                      strongItemAgain.isEnable = isItemEnable;
                      [strongItemAgain refreshCell];
                  }
                });
              });

              item.cellTappedBlock = ^{
                NSDictionary *currentData = [DYYYABTestHook getCurrentABTestData];

                if (!currentData) {
                    [DYYYUtils showToast:@"ABTest 配置获取失败"];
                    return;
                }

                NSError *error;
                NSData *sortedJsonData = [NSJSONSerialization dataWithJSONObject:currentData options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];

                if (error) {
                    [DYYYUtils showToast:@"ABTest 配置序列化失败"];
                    return;
                }

                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
                NSString *timestamp = [formatter stringFromDate:[NSDate date]];
                NSString *tempFile = [NSString stringWithFormat:@"ABTest_Config_%@.json", timestamp];
                NSString *tempFilePath = [DYYYUtils cachePathForFilename:tempFile];

                BOOL success = [sortedJsonData writeToFile:tempFilePath atomically:YES];

                if (!success) {
                    [DYYYUtils showToast:@"临时文件创建失败"];
                    return;
                }

                NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
                UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURLs:@[ tempFileURL ] inMode:UIDocumentPickerModeExportToService];

                DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
                pickerDelegate.tempFilePath = tempFilePath;
                pickerDelegate.completionBlock = ^(NSURL *url) {
                  [DYYYUtils showToast:@"ABTest 配置已保存"];
                };

                static char kABTestPickerDelegateKey;
                documentPicker.delegate = pickerDelegate;
                objc_setAssociatedObject(documentPicker, &kABTestPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                UIViewController *topVC = topView();
                [topVC presentViewController:documentPicker animated:YES completion:nil];
              };
          } else if ([item.identifier isEqualToString:@"SaveABTestConfigFile"]) {
              item.detail = @"(获取中...)";

              saveABTestConfigFileItemRef = item;
              refreshSaveABTestConfigFileItem();

              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths firstObject];

                NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
                NSString *jsonFilePath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

                NSData *jsonData = [NSData dataWithContentsOfFile:jsonFilePath];
                if (!jsonData) {
                    [DYYYUtils showToast:@"本地配置获取失败"];
                    return;
                }

                NSError *error;
                NSDictionary *originalData = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&error];
                if (error || ![originalData isKindOfClass:[NSDictionary class]]) {
                    [DYYYUtils showToast:@"本地配置序列化失败"];
                    return;
                }

                NSData *sortedJsonData = [NSJSONSerialization dataWithJSONObject:originalData options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];
                if (error || !sortedJsonData) {
                    [DYYYUtils showToast:@"排序数据序列化失败"];
                    return;
                }

                // 创建临时文件
                NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
                [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
                NSString *timestamp = [formatter stringFromDate:[NSDate date]];
                NSString *tempFile = [NSString stringWithFormat:@"abtest_data_fixed_%@.json", timestamp];
                NSString *tempFilePath = [DYYYUtils cachePathForFilename:tempFile];

                if (![sortedJsonData writeToFile:tempFilePath atomically:YES]) {
                    [DYYYUtils showToast:@"临时文件创建失败"];
                    return;
                }

                UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURLs:@[ [NSURL fileURLWithPath:tempFilePath] ]
                                                                                                               inMode:UIDocumentPickerModeExportToService];

                DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
                pickerDelegate.tempFilePath = tempFilePath;
                pickerDelegate.completionBlock = ^(NSURL *url) {
                  [DYYYUtils showToast:@"本地配置已保存"];
                };

                static char kABTestConfigPickerDelegateKey;
                documentPicker.delegate = pickerDelegate;
                objc_setAssociatedObject(documentPicker, &kABTestConfigPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                UIViewController *topVC = topView();
                [topVC presentViewController:documentPicker animated:YES completion:nil];
              };
          } else if ([item.identifier isEqualToString:@"LoadABTestConfigFile"]) {
              loadConfigItemRef = item;
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                BOOL isPatchMode = [DYYYABTestHook isPatchMode];

                NSString *confirmTitle, *confirmMessage;
                if (isPatchMode) {
                    confirmTitle = @"覆写模式";
                    confirmMessage = @"\n导入后将保留原设置并覆盖同名项，\n\n点击确定后继续操作。\n";
                } else {
                    confirmTitle = @"替换模式";
                    confirmMessage = @"\n导入后将忽略原设置并使用新数据，\n\n点击确定后继续操作。\n";
                }
                DYYYAboutDialogView *confirmDialog = [[DYYYAboutDialogView alloc] initWithTitle:confirmTitle message:confirmMessage];
                confirmDialog.onConfirm = ^{
                  UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[ @"public.json" ] inMode:UIDocumentPickerModeImport];

                  DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
                  pickerDelegate.completionBlock = ^(NSURL *url) {
                    // Delegate 回调通常在主线程，但文件操作和 Hook 调用应在后台
                    dispatch_async(dispatch_get_global_queue(QOS_CLASS_USER_INITIATED, 0), ^{
                      __weak AWESettingItemModel *weakSaveItem = saveABTestConfigFileItemRef;

                      NSURL *sourceURL = url; // 用户选择的源文件 URL

                      NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                      NSString *documentsDirectory = [paths firstObject];
                      NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
                      NSURL *destinationURL = [NSURL fileURLWithPath:[dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"]];

                      NSFileManager *fileManager = [NSFileManager defaultManager];
                      NSError *error = nil;
                      BOOL success = NO;
                      NSString *message = nil;

                      if (![fileManager fileExistsAtPath:dyyyFolderPath]) {
                          [fileManager createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:&error];
                          if (error) {
                              message = [NSString stringWithFormat:@"创建目录失败: %@", error.localizedDescription];
                          }
                      }

                      if (!message) {
                          // 在同一个目录下创建一个临时文件 URL 以确保原子性
                          NSString *tempFileName = [NSUUID UUID].UUIDString;
                          NSURL *temporaryURL = [NSURL fileURLWithPath:[dyyyFolderPath stringByAppendingPathComponent:tempFileName]];

                          if ([fileManager copyItemAtURL:sourceURL toURL:temporaryURL error:&error]) {
                              if ([fileManager replaceItemAtURL:destinationURL withItemAtURL:temporaryURL backupItemName:nil options:0 resultingItemURL:nil error:&error]) {
                                  [DYYYABTestHook cleanLocalABTestData];
                                  [DYYYABTestHook loadLocalABTestConfig];
                                  [DYYYABTestHook applyFixedABTestData];
                                  [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                                  [[NSNotificationCenter defaultCenter] postNotificationName:DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION object:nil];
                                  success = YES;
                                  message = @"配置已导入，部分设置需重启应用后生效";
                              } else {
                                  [fileManager removeItemAtURL:temporaryURL error:nil];
                                  message = [NSString stringWithFormat:@"导入失败 (替换文件失败): %@", error.localizedDescription];
                              }
                          } else {
                              message = [NSString stringWithFormat:@"导入失败 (复制到临时文件失败): %@", error.localizedDescription];
                          }
                      }
                      // 回到主线程显示 Toast 和更新 UI
                      dispatch_async(dispatch_get_main_queue(), ^{
                        __strong AWESettingItemModel *strongSaveItemAgain = weakSaveItem;

                        // 无论成功与否，都显示 Toast 告知用户结果
                        NSString *message = success ? @"配置已导入，部分设置需重启应用后生效" : [NSString stringWithFormat:@"导入失败: %@", error.localizedDescription];
                        [DYYYUtils showToast:message];

                        // 仅在导入成功且 item 仍然存在时更新 UI
                        if (success && strongSaveItemAgain) {
                            refreshSaveABTestConfigFileItem();
                            refreshConfigConflictState();
                        }
                      });
                    });
                  };

                  static char kPickerDelegateKey;
                  documentPicker.delegate = pickerDelegate;
                  objc_setAssociatedObject(documentPicker, &kPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

                  UIViewController *topVC = topView();
                  [topVC presentViewController:documentPicker animated:YES completion:nil];
                };
                [confirmDialog show];
              };
          } else if ([item.identifier isEqualToString:@"DeleteABTestConfigFile"]) {
              deleteConfigItemRef = item;
              item.cellTappedBlock = ^{
                if (!item.isEnable)
                    return;
                NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                NSString *documentsDirectory = [paths firstObject];
                NSString *dyyyFolderPath = [documentsDirectory stringByAppendingPathComponent:@"DYYY"];
                NSString *configPath = [dyyyFolderPath stringByAppendingPathComponent:@"abtest_data_fixed.json"];

                if ([[NSFileManager defaultManager] fileExistsAtPath:configPath]) {
                    NSError *error = nil;
                    BOOL success = [[NSFileManager defaultManager] removeItemAtPath:configPath error:&error];

                    NSString *message = success ? @"本地配置已删除成功" : [NSString stringWithFormat:@"删除失败: %@", error.localizedDescription];
                    [DYYYUtils showToast:message];

                    if (success) {
                        [DYYYABTestHook cleanLocalABTestData];
                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:DYYY_REMOTE_CONFIG_FLAG_KEY];
                        [[NSNotificationCenter defaultCenter] postNotificationName:DYYY_REMOTE_CONFIG_CHANGED_NOTIFICATION object:nil];
                        // 删除成功后修改 SaveABTestConfigFile item 的状态
                        saveABTestConfigFileItemRef.detail = @"(文件已删除)";
                        saveABTestConfigFileItemRef.isEnable = NO;
                        [saveABTestConfigFileItemRef refreshCell];
                        refreshConfigConflictState();
                    }
                } else {
                    [DYYYUtils showToast:@"本地配置不存在"];
                }
              };
          }

          [hotUpdateItems addObject:item];
      }
      refreshConfigConflictState();

      // 【交互增强】分类
      NSMutableArray<AWESettingItemModel *> *interactionItems = [NSMutableArray array];
      NSArray *interactionSettings = @[
          @{
              @"identifier" : kDYYYExactInteractionCountsSettingIdentifier,
              @"title" : @"显示详细互动数",
              @"detail" : @"",
              @"cellType" : @6,
              @"imageName" : kDYYYExactInteractionCountsSVGIconName
          },
          @{
              @"identifier" : @"DYYYDisableSettingsGesture",
              @"title" : @"禁用双指长按入口",
              @"subTitle" : @"开启后将禁用双指长按弹出的设置入口，开启或者关闭此选项都需要重启抖音以生效",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_gearsimplify_outlined_20"
          },
          @{
              @"identifier" : @"DYYYEntrance",
              @"title" : @"左侧边栏快捷入口",
              @"subTitle" : @"将侧边栏替换为 DYYY 快捷入口",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_circlearrowin_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDisableSidebarGesture",
              @"title" : @"禁止侧滑进入边栏",
              @"subTitle" : @"禁止在首页最左边的页面时右滑进入侧边栏",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_circlearrowin_outlined_20"
          },
          @{
              @"identifier" : @"DYYYVideoGesture",
              @"title" : @"横屏视频交互增强",
              @"subTitle" : @"启用横屏视频的手势功能",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_phonearrowdown_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDisableAutoEnterLive",
              @"title" : @"禁用自动进入直播",
              @"subTitle" : @"禁止顶栏直播下自动进入直播间",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_video_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDisableAutoHideLive",
              @"title" : @"禁止直播标签收缩",
              @"subTitle" : @"禁止直播类型选择标签自动收缩成直播发现标签",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_video_outlined_20"
          },
          @{@"identifier" : @"DYYYEnableSaveAvatar",
            @"title" : @"启用保存他人头像",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_personcircleclean_outlined_20"},
          @{@"identifier" : @"DYYYCommentCopyText",
            @"title" : @"复制评论移除昵称",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_at_outlined_20"},
          @{
              @"identifier" : @"DYYYBioCopyText",
              @"title" : @"长按简介复制简介",
              @"subTitle" : @"长按个人主页的简介复制",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_rectangleonrectangleup_outlined_20"
          },
          @{
              @"identifier" : @"DYYYLongPressCopyTextEnabled",
              @"title" : @"长按文案复制文案",
              @"subTitle" : @"长按视频左下角的文案复制",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_rectangleonrectangleup_outlined_20"
          },
          @{
              @"identifier" : @"DYYYMusicCopyText",
              @"title" : @"评论音乐点击复制",
              @"subTitle" : @"含有音乐的视频打开评论区时，移除顶部歌曲去汽水听，点击复制歌曲名",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_quaver_outlined_20"
          },
          @{@"identifier" : @"DYYYAutoSelectOriginalPhoto",
            @"title" : @"启用自动勾选原图",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_image_outlined_20"},
          @{
              @"identifier" : @"DYYYEnableModernPanel",
              @"title" : @"启用新版长按面板",
              @"subTitle" : @"启用抖音灰度测试的新版长按面板",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_squaresplit_outlined_20"
          },
          @{@"identifier" : @"DYYYLongPressPanelBlur",
            @"title" : @"长按面板玻璃效果",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_squaresplit_outlined_20"},
          @{@"identifier" : @"DYYYLongPressPanelDark",
            @"title" : @"长按面板深色模式",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_sun_outlined"},
          @{
              @"identifier" : @"DYYYDefaultEnterWorks",
              @"title" : @"资料默认进入作品",
              @"subTitle" : @"禁止个人资料页自动进入橱窗等页面",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_playsquarestack_outlined_20"
          },
          @{@"identifier" : @"DYYYDisableHomeRefresh",
            @"title" : @"禁用点击首页刷新",
            @"detail" : @"",
            @"cellType" : @6,
            @"imageName" : @"ic_arrowcircle_outlined_20"},
          @{
              @"identifier" : @"DYYYDisableDoubleTapLike",
              @"title" : @"禁用双击视频点赞",
              @"subTitle" : @"同时会禁用官方纯净模式的双击点赞",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_thumbsup_outlined_20"
          },
          @{
              @"identifier" : @"DYYYEnableDoubleOpenComment",
              @"title" : @"启用双击打开评论",
              @"subTitle" : @"与“双击打开菜单”互斥",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_comment_outlined_20"
          },
          @{
              @"identifier" : @"DYYYCommentShowDanmaku",
              @"title" : @"查看评论显示弹幕",
              @"subTitle" : @"打开评论区时保持弹幕可见",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_dansquare_outlined_20"
          },
          @{
              @"identifier" : kDYYYCommentPausePlaybackSettingIdentifier,
              @"title" : @"查看评论暂停播放",
              @"subTitle" : @"打开评论区时暂停当前播放",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : kDYYYCommentPausePlaybackSVGIconName
          },
          @{
              @"identifier" : @"DYYYEnableDoubleTapMenu",
              @"title" : @"启用双击打开菜单",
              @"subTitle" : @"与“双击打开评论”互斥，下方自定义",
              @"detail" : @"",
              @"cellType" : @37,
              @"imageName" : @"ic_xiaoxihuazhonghua_outlined_20"
          },
          @{
              @"identifier" : @"DYYYDoubleTapMenuSettings",
              @"title" : @"设置双击菜单项目",
              @"subTitle" : @"自定义双击打开菜单需要显示的项目",
              @"detail" : @"",
              @"cellType" : @20,
              @"imageName" : @"ic_squaresplit_outlined_20"
          }
      ];

      for (NSDictionary *dict in interactionSettings) {
          AWESettingItemModel *item = [DYYYSettingsHelper createSettingItem:dict];
          if ([item.identifier isEqualToString:@"DYYYDoubleTapMenuSettings"]) {
              __weak AWESettingItemModel *weakItem = item;
              item.cellTappedBlock = ^{
                __strong AWESettingItemModel *strongItem = weakItem;
                if (!strongItem || !strongItem.isEnable)
                    return;
                NSMutableArray<AWESettingItemModel *> *doubleTapItems = [NSMutableArray array];
                NSArray *doubleTapFunctions = @[
                    @{@"identifier" : @"DYYYDoubleTapDownload",
                      @"title" : @"保存视频/图片",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_boxarrowdown_outlined"},
                    @{@"identifier" : @"DYYYDoubleTapDownloadAudio",
                      @"title" : @"保存音频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_boxarrowdown_outlined"},
                    @{@"identifier" : @"DYYYDoubleInterfaceDownload",
                      @"title" : @"接口保存",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_cloudarrowdown_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleCreateVideo",
                      @"title" : @"制作视频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_videosearch_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapCopyDesc",
                      @"title" : @"复制文案",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_rectangleonrectangleup_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapComment",
                      @"title" : @"打开评论",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_comment_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapLike",
                      @"title" : @"点赞视频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_heart_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapshowDislikeOnVideo",
                      @"title" : @"长按面板",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_xiaoxihuazhonghua_outlined_20"},
                    @{@"identifier" : @"DYYYDoubleTapshowSharePanel",
                      @"title" : @"分享视频",
                      @"detail" : @"",
                      @"cellType" : @6,
                      @"imageName" : @"ic_share_outlined"},
                ];

                for (NSDictionary *dict in doubleTapFunctions) {
                    AWESettingItemModel *functionItem = [DYYYSettingsHelper createSettingItem:dict];
                    [doubleTapItems addObject:functionItem];
                }
                NSMutableArray *sections = [NSMutableArray array];
                [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"设置双击菜单项目" items:doubleTapItems]];
                AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"设置双击菜单项目" sections:sections];
                [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
              };
          }

          if ([item.identifier isEqualToString:@"DYYYLongPressPanelDark"]) {
              BOOL isDarkPanelEnabled = [DYYYSettingsHelper getUserDefaults:item.identifier];
              item.svgIconImageName = isDarkPanelEnabled ? @"ic_moon_outlined" : @"ic_sun_outlined";

              void (^originalSwitchChangedBlock)(void) = item.switchChangedBlock;

              __weak AWESettingItemModel *weakItem = item;
              item.switchChangedBlock = ^{
                __strong AWESettingItemModel *strongItem = weakItem;
                if (!strongItem)
                    return;

                if (originalSwitchChangedBlock) {
                    originalSwitchChangedBlock();
                }

                if (strongItem.isSwitchOn) {
                    strongItem.svgIconImageName = @"ic_moon_outlined";
                } else {
                    strongItem.svgIconImageName = @"ic_sun_outlined";
                }
                [strongItem refreshCell];
              };
          }

          [interactionItems addObject:item];
      }

      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"长按面板设置" items:longPressItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"媒体保存" items:downloadItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"交互增强" items:interactionItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"账号与登录" items:accountItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"ABTest"
                                                         footerTitle:@"允许用户导出或导入抖音的 ABTest 配置。远程配置由 Nathalie 维护，在应用启动时自动更新远程配置。"
                                                               items:hotUpdateItems]];
      DYYYRegisterSearchSections(@"增强设置", sections);
      if (DYYYBuildingSettingsSearchIndex) {
          return;
      }

      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"增强设置" sections:sections];
      DYYYAttachSubSettingsSearchHeader(subVC, @"增强设置", sections);
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };

    [mainItems addObject:enhanceSettingItem];

    // 创建悬浮按钮设置分类项
    AWESettingItemModel *floatButtonSettingItem = [[%c(AWESettingItemModel) alloc] init];
    floatButtonSettingItem.identifier = @"DYYYFloatButtonSettings";
    floatButtonSettingItem.title = @"悬浮按钮";
    floatButtonSettingItem.type = 0;
    floatButtonSettingItem.svgIconImageName = @"ic_gongchuang_outlined_20";
    floatButtonSettingItem.cellType = 26;
    floatButtonSettingItem.colorStyle = 2;
    floatButtonSettingItem.isEnable = YES;
    floatButtonSettingItem.cellTappedBlock = ^{
      // 创建悬浮按钮设置二级界面的设置项

      // 快捷倍速section
      NSMutableArray<AWESettingItemModel *> *speedButtonItems = [NSMutableArray array];

      AWESettingItemModel *enableSpeedButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYEnableFloatSpeedButton",
                @"title" : @"启用快捷倍速按钮",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_xspeed_outlined"}];
      [speedButtonItems addObject:enableSpeedButton];

      AWESettingItemModel *speedStickToEdgeItem = [DYYYSettingsHelper
          createSettingItem:@{
              @"identifier" : kDYYYSpeedButtonStickToEdgeSettingIdentifier,
              @"title" : kDYYYStickToEdgeSettingTitle,
              @"detail" : @"",
              @"cellType" : @6,
              @"imageName" : kDYYYStickToEdgeSVGIconName
          }];
      [speedButtonItems addObject:speedStickToEdgeItem];

      AWESettingItemModel *autoHideSpeedButtonItem = [DYYYSettingsHelper
          createSettingItem:@{
              @"identifier" : @"DYYYAutoHideSpeedButton",
              @"title" : @"自动隐藏快捷倍速按钮",
              @"detail" : @"",
              @"cellType" : @6,
              @"imageName" : @"ic_eyeslash_outlined_16"
          }];
      [speedButtonItems addObject:autoHideSpeedButtonItem];

      AWESettingItemModel *autoHideSpeedTimeItem = [[%c(AWESettingItemModel) alloc] init];
      autoHideSpeedTimeItem.identifier = @"DYYYAutoHideSpeedButtonTime";
      autoHideSpeedTimeItem.title = @"隐藏快捷倍速按钮时间";
      CGFloat currentAutoHideTime = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYAutoHideSpeedButtonTime"];
      if (currentAutoHideTime <= 0.0) {
          currentAutoHideTime = 30.0;
      }
      autoHideSpeedTimeItem.detail = [NSString stringWithFormat:@"%.0f", currentAutoHideTime];
      autoHideSpeedTimeItem.type = 0;
      autoHideSpeedTimeItem.svgIconImageName = @"ic_speed_outlined_20";
      autoHideSpeedTimeItem.cellType = 26;
      autoHideSpeedTimeItem.colorStyle = 2;
      autoHideSpeedTimeItem.isEnable = YES;
      autoHideSpeedTimeItem.cellTappedBlock = nil;
      [speedButtonItems addObject:autoHideSpeedTimeItem];

      AWESettingItemModel *speedResetPositionItem = [[%c(AWESettingItemModel) alloc] init];
      speedResetPositionItem.identifier = kDYYYSpeedButtonResetPositionSettingIdentifier;
      speedResetPositionItem.title = kDYYYResetButtonPositionSettingTitle;
      speedResetPositionItem.detail = @"";
      speedResetPositionItem.type = 0;
      speedResetPositionItem.svgIconImageName = @"ic_switch_outlined";
      speedResetPositionItem.cellType = 26;
      speedResetPositionItem.colorStyle = 2;
      speedResetPositionItem.isEnable = YES;
      speedResetPositionItem.cellTappedBlock = ^{
        if (![DYYYSettingsHelper getUserDefaults:@"DYYYEnableFloatSpeedButton"]) {
            return;
        }
        if (speedButton) {
            [speedButton resetToDefaultPosition];
        } else {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:@"DYYYSpeedButtonCenterXPercent"];
            [defaults removeObjectForKey:@"DYYYSpeedButtonCenterYPercent"];
        }
        [DYYYUtils showToast:@"已重置按钮位置"];
      };
      [speedButtonItems addObject:speedResetPositionItem];

      AWESettingItemModel *speedSettingsItem = [[%c(AWESettingItemModel) alloc] init];
      speedSettingsItem.identifier = @"DYYYSpeedSettings";
      speedSettingsItem.title = @"快捷倍速数值设置";
      speedSettingsItem.type = 0;
      speedSettingsItem.svgIconImageName = @"ic_speed_outlined_20";
      speedSettingsItem.cellType = 26;
      speedSettingsItem.colorStyle = 2;
      speedSettingsItem.isEnable = YES;
      NSString *savedSpeedSettings = [[NSUserDefaults standardUserDefaults] objectForKey:@"DYYYSpeedSettings"];
      if (!savedSpeedSettings || savedSpeedSettings.length == 0) {
          savedSpeedSettings = @"1.0,1.25,1.5,2.0";
      }
      speedSettingsItem.detail = savedSpeedSettings;
      speedSettingsItem.cellTappedBlock = nil;

      AWESettingItemModel *autoRestoreSpeedItem = [[%c(AWESettingItemModel) alloc] init];
      autoRestoreSpeedItem.identifier = @"DYYYAutoRestoreSpeed";
      autoRestoreSpeedItem.title = @"自动恢复默认倍速";
      autoRestoreSpeedItem.detail = @"";
      autoRestoreSpeedItem.type = 1000;
      autoRestoreSpeedItem.svgIconImageName = @"ic_switch_outlined";
      autoRestoreSpeedItem.cellType = 6;
      autoRestoreSpeedItem.colorStyle = 2;
      autoRestoreSpeedItem.isEnable = YES;
      autoRestoreSpeedItem.isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYAutoRestoreSpeed"];
      autoRestoreSpeedItem.switchChangedBlock = ^{
        BOOL newValue = !autoRestoreSpeedItem.isSwitchOn;
        autoRestoreSpeedItem.isSwitchOn = newValue;
        [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:@"DYYYAutoRestoreSpeed"];
      };
      [speedButtonItems addObject:autoRestoreSpeedItem];

      AWESettingItemModel *showXItem = [[%c(AWESettingItemModel) alloc] init];
      showXItem.identifier = @"DYYYSpeedButtonShowX";
      showXItem.title = @"倍速按钮显示后缀";
      showXItem.detail = @"";
      showXItem.type = 1000;
      showXItem.svgIconImageName = @"ic_pensketch_outlined_20";
      showXItem.cellType = 6;
      showXItem.colorStyle = 2;
      showXItem.isEnable = YES;
      showXItem.isSwitchOn = [[NSUserDefaults standardUserDefaults] boolForKey:@"DYYYSpeedButtonShowX"];
      showXItem.switchChangedBlock = ^{
        BOOL newValue = !showXItem.isSwitchOn;
        showXItem.isSwitchOn = newValue;
        [[NSUserDefaults standardUserDefaults] setBool:newValue forKey:@"DYYYSpeedButtonShowX"];
        showSpeedX = newValue;
        updateSpeedButtonUI();
      };
      [speedButtonItems addObject:showXItem];

      AWESettingItemModel *buttonSizeItem = [[%c(AWESettingItemModel) alloc] init];
      buttonSizeItem.identifier = @"DYYYSpeedButtonSize";
      buttonSizeItem.title = @"快捷倍速按钮大小";
      CGFloat currentButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYSpeedButtonSize"] ?: 35;
      buttonSizeItem.detail = [NSString stringWithFormat:@"%.0f", currentButtonSize];
      buttonSizeItem.type = 0;
      buttonSizeItem.svgIconImageName = @"ic_zoomin_outlined_20";
      buttonSizeItem.cellType = 26;
      buttonSizeItem.colorStyle = 2;
      buttonSizeItem.isEnable = YES;
      buttonSizeItem.cellTappedBlock = nil;
      [speedButtonItems addObject:buttonSizeItem];
      [speedButtonItems addObject:speedSettingsItem];

      NSMutableArray<AWESettingItemModel *> *speedDependentItems = [NSMutableArray array];
      for (AWESettingItemModel *item in speedButtonItems) {
          if (item != enableSpeedButton) {
              [speedDependentItems addObject:item];
          }
      }
      void (^refreshSpeedDependentItems)(void) = ^{
        for (AWESettingItemModel *item in speedDependentItems) {
            [DYYYSettingsHelper applyDependencyRulesForItem:item];
            [item refreshCell];
        }
      };
      refreshSpeedDependentItems();

      void (^originalAutoHideSwitchChangedBlock)(void) = autoHideSpeedButtonItem.switchChangedBlock;
      autoHideSpeedButtonItem.switchChangedBlock = ^{
        if (originalAutoHideSwitchChangedBlock) {
            originalAutoHideSwitchChangedBlock();
        }
        BOOL autoHideEnabled = [NSUserDefaults.standardUserDefaults boolForKey:@"DYYYAutoHideSpeedButton"];
        if (speedButton) {
            if (!autoHideEnabled && speedButton.isEdgeHidden) {
                [speedButton dyyy_restoreFromEdgeHidden];
            } else {
                [speedButton resetFadeTimer];
            }
        }
        refreshSpeedDependentItems();
      };

      void (^originalSpeedStickSwitchChangedBlock)(void) = speedStickToEdgeItem.switchChangedBlock;
      speedStickToEdgeItem.switchChangedBlock = ^{
        if (originalSpeedStickSwitchChangedBlock) {
            originalSpeedStickSwitchChangedBlock();
        }
        if (speedButton) {
            if (speedButton.isEdgeHidden && !speedButton.dyyyEdgeHiddenByClearMode) {
                [speedButton dyyy_restoreFromEdgeHidden];
            }
            [speedButton loadSavedPosition];
            [speedButton resetFadeTimer];
        }
        refreshSpeedDependentItems();
      };

      void (^originalSpeedSwitchChangedBlock)(void) = enableSpeedButton.switchChangedBlock;
      enableSpeedButton.switchChangedBlock = ^{
        if (originalSpeedSwitchChangedBlock) {
            originalSpeedSwitchChangedBlock();
        }
        BOOL newEnabled = [NSUserDefaults.standardUserDefaults boolForKey:@"DYYYEnableFloatSpeedButton"];
        if (!newEnabled) {
            hideSpeedButton();
        }
        isFloatSpeedButtonEnabled = newEnabled;
        if (newEnabled) {
            showSpeedButton();
            DYYYRefreshFloatSpeedButton();
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
              DYYYRefreshFloatSpeedButton();
            });
        } else if (speedButton) {
            speedButton.hidden = YES;
        }
        refreshSpeedDependentItems();
      };

      // 一键清屏section
      NSMutableArray<AWESettingItemModel *> *clearButtonItems = [NSMutableArray array];

      // 清屏按钮
      AWESettingItemModel *enableClearButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYEnableFloatClearButton",
                @"title" : @"一键清屏按钮",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_eyeslash_outlined_16"}];
      [clearButtonItems addObject:enableClearButton];

      AWESettingItemModel *clearStickToEdgeItem = [DYYYSettingsHelper
          createSettingItem:@{
              @"identifier" : kDYYYClearButtonStickToEdgeSettingIdentifier,
              @"title" : kDYYYStickToEdgeSettingTitle,
              @"detail" : @"",
              @"cellType" : @6,
              @"imageName" : kDYYYStickToEdgeSVGIconName
          }];
      [clearButtonItems addObject:clearStickToEdgeItem];

      AWESettingItemModel *clearResetPositionItem = [[%c(AWESettingItemModel) alloc] init];
      clearResetPositionItem.identifier = kDYYYClearButtonResetPositionSettingIdentifier;
      clearResetPositionItem.title = kDYYYResetButtonPositionSettingTitle;
      clearResetPositionItem.detail = @"";
      clearResetPositionItem.type = 0;
      clearResetPositionItem.svgIconImageName = @"ic_switch_outlined";
      clearResetPositionItem.cellType = 26;
      clearResetPositionItem.colorStyle = 2;
      clearResetPositionItem.isEnable = YES;
      clearResetPositionItem.cellTappedBlock = ^{
        if (![DYYYSettingsHelper getUserDefaults:@"DYYYEnableFloatClearButton"]) {
            return;
        }
        if (hideButton) {
            [hideButton resetToDefaultPosition];
        } else {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults removeObjectForKey:@"DYYYHideButtonCenterXPercent"];
            [defaults removeObjectForKey:@"DYYYHideButtonCenterYPercent"];
        }
        [DYYYUtils showToast:@"已重置按钮位置"];
      };
      [clearButtonItems addObject:clearResetPositionItem];

      // 添加清屏按钮大小配置项

      // 添加清屏按钮大小配置项
      AWESettingItemModel *clearButtonSizeItem = [[%c(AWESettingItemModel) alloc] init];
      clearButtonSizeItem.identifier = @"DYYYEnableFloatClearButtonSize";
      clearButtonSizeItem.title = @"清屏按钮大小";
      // 获取当前的按钮大小，如果没有设置则默认为40
      CGFloat currentClearButtonSize = [[NSUserDefaults standardUserDefaults] floatForKey:@"DYYYEnableFloatClearButtonSize"] ?: 40;
      clearButtonSizeItem.detail = [NSString stringWithFormat:@"%.0f", currentClearButtonSize];
      clearButtonSizeItem.type = 0;
      clearButtonSizeItem.svgIconImageName = @"ic_zoomin_outlined_20";
      clearButtonSizeItem.cellType = 26;
      clearButtonSizeItem.colorStyle = 2;
      clearButtonSizeItem.isEnable = YES;
      clearButtonSizeItem.cellTappedBlock = nil;
      [clearButtonItems addObject:clearButtonSizeItem];

      // 添加清屏按钮自定义图标选项
      AWESettingItemModel *clearButtonIcon = [DYYYSettingsHelper createIconCustomizationItemWithIdentifier:@"DYYYClearButtonIcon"
                                                                                                     title:@"清屏按钮图标"
                                                                                                   svgIcon:@"ic_roaming_outlined"
                                                                                                  saveFile:@"qingping.gif"];

      [clearButtonItems addObject:clearButtonIcon];
      // 清屏隐藏弹幕
      AWESettingItemModel *hideDanmakuButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYHideDanmaku",
                @"title" : @"清屏隐藏弹幕",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_eyeslash_outlined_16"}];
      [clearButtonItems addObject:hideDanmakuButton];

      AWESettingItemModel *enableqingButton = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYRemoveTimeProgress",
          @"title" : @"清屏移除进度",
          @"subTitle" : @"清屏状态下完全移除时间进度条",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:enableqingButton];
      // 清屏隐藏时间进度
      AWESettingItemModel *enableqingButton1 = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideTimeProgress",
          @"title" : @"清屏隐藏进度",
          @"subTitle" : @"原始位置可拖动时间进度条",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:enableqingButton1];
      AWESettingItemModel *hideSliderButton = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideSlider",
          @"title" : @"清屏隐藏滑条",
          @"subTitle" : @"清屏状态下隐藏多图片下方的滑条",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideSliderButton];
      AWESettingItemModel *hideChapterButton = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideChapter",
          @"title" : @"清屏隐藏章节",
          @"subTitle" : @"清屏状态下隐藏部分视频出现的章节进度显示",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideChapterButton];
      AWESettingItemModel *hideTabButton = [DYYYSettingsHelper
          createSettingItem:
              @{@"identifier" : @"DYYYHideTabBar",
                @"title" : @"清屏隐藏底栏",
                @"detail" : @"",
                @"cellType" : @6,
                @"imageName" : @"ic_eyeslash_outlined_16"}];
      [clearButtonItems addObject:hideTabButton];
      AWESettingItemModel *hideSpeedButtonItem = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideSpeed",
          @"title" : @"清屏隐藏倍速",
          @"subTitle" : @"清屏状态下隐藏DYYY的倍速按钮",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideSpeedButtonItem];
      // 清屏后隐藏清屏按钮自身（仍可点击恢复）
      AWESettingItemModel *hideClearButtonOnTap = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideClearButtonOnTap",
          @"title" : @"清屏隐藏清屏按钮",
          @"subTitle" : @"清屏后隐藏清屏按钮自身，原位置仍可点击恢复",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideClearButtonOnTap];
      AWESettingItemModel *hidePauseVideoIcon = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHidePauseVideoIcon",
          @"title" : @"清屏隐藏暂停图标",
          @"subTitle" : @"清屏状态下隐藏视频中央的播放/暂停图标",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hidePauseVideoIcon];
      AWESettingItemModel *hideStatusBarOnClear = [DYYYSettingsHelper createSettingItem:@{
          @"identifier" : @"DYYYHideStatusBarOnClear",
          @"title" : @"清屏隐藏状态栏",
          @"subTitle" : @"清屏状态下隐藏系统顶部状态栏",
          @"detail" : @"",
          @"cellType" : @37,
          @"imageName" : @"ic_eyeslash_outlined_16"
      }];
      [clearButtonItems addObject:hideStatusBarOnClear];
      NSMutableArray<AWESettingItemModel *> *clearDependentItems = [NSMutableArray array];
      for (AWESettingItemModel *item in clearButtonItems) {
          if (item != enableClearButton) {
              [clearDependentItems addObject:item];
          }
      }
      void (^refreshClearDependentItems)(void) = ^{
        for (AWESettingItemModel *item in clearDependentItems) {
            [DYYYSettingsHelper applyDependencyRulesForItem:item];
            [item refreshCell];
        }
      };

      refreshClearDependentItems();

      for (AWESettingItemModel *item in clearButtonItems) {
          void (^originalClearSwitchChangedBlock)(void) = item.switchChangedBlock;
          if (!originalClearSwitchChangedBlock) {
              continue;
          }
          item.switchChangedBlock = ^{
            originalClearSwitchChangedBlock();
            reloadClearButtonConfiguration();
            if (item == enableClearButton) {
                refreshClearDependentItems();
            }
          };
      }

      // 创建并组织所有section
      NSMutableArray *sections = [NSMutableArray array];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"快捷倍速" items:speedButtonItems]];
      [sections addObject:[DYYYSettingsHelper createSectionWithTitle:@"一键清屏" items:clearButtonItems]];

      DYYYRegisterSearchSections(@"悬浮按钮", sections);
      if (DYYYBuildingSettingsSearchIndex) {
          return;
      }

      // 创建并推入二级设置页面
      AWESettingBaseViewController *subVC = [DYYYSettingsHelper createSubSettingsViewController:@"悬浮按钮" sections:sections];
      DYYYAttachSubSettingsSearchHeader(subVC, @"悬浮按钮", sections);
      [rootVC.navigationController pushViewController:(UIViewController *)subVC animated:YES];
    };
    [mainItems addObject:floatButtonSettingItem];

    // 创建备份设置分类
    AWESettingSectionModel *backupSection = [[%c(AWESettingSectionModel) alloc] init];
    backupSection.sectionHeaderTitle = @"备份";
    backupSection.sectionHeaderHeight = 40;
    backupSection.type = 0;
    NSMutableArray<AWESettingItemModel *> *backupItems = [NSMutableArray array];

    AWESettingItemModel *backupItem = [[%c(AWESettingItemModel) alloc] init];
    backupItem.identifier = @"DYYYBackupSettings";
    backupItem.title = @"备份设置";
    backupItem.detail = @"";
    backupItem.type = 0;
    backupItem.svgIconImageName = @"ic_memorycard_outlined_20";
    backupItem.cellType = 26;
    backupItem.colorStyle = 0;
    backupItem.isEnable = YES;
    backupItem.cellTappedBlock = ^{
      // 获取所有以DYYY开头的NSUserDefaults键值
      NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
      NSDictionary *allDefaults = [defaults dictionaryRepresentation];
      NSMutableDictionary *dyyySettings = [NSMutableDictionary dictionary];

      for (NSString *key in allDefaults.allKeys) {
          if ([key hasPrefix:@"DYYY"]) {
              dyyySettings[key] = [defaults objectForKey:key];
          }
      }

      // 查找并添加图标文件
      NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
      NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];
      NSArray *iconFileNames = @[ @"like_before.png", @"like_after.png", @"comment.png", @"unfavorite.png", @"favorite.png", @"share.png", @"tab_plus.png", @"qingping.gif" ];
      NSMutableDictionary *iconBase64Dict = [NSMutableDictionary dictionary];

      for (NSString *iconFileName in iconFileNames) {
          NSString *iconPath = [dyyyFolderPath stringByAppendingPathComponent:iconFileName];
          if ([[NSFileManager defaultManager] fileExistsAtPath:iconPath]) {
              // 读取图片数据并转换为Base64
              NSData *imageData = [NSData dataWithContentsOfFile:iconPath];
              if (imageData) {
                  NSString *base64String = [imageData base64EncodedStringWithOptions:0];
                  iconBase64Dict[iconFileName] = base64String;
              }
          }
      }

      // 将图标Base64数据添加到备份设置中
      if (iconBase64Dict.count > 0) {
          dyyySettings[@"DYYYIconsBase64"] = iconBase64Dict;
      }

      // 转换为JSON数据
      NSError *error;
      id jsonObject = DYYYJSONSafeObject(dyyySettings);
      NSData *sortedJsonData = [NSJSONSerialization dataWithJSONObject:jsonObject options:NSJSONWritingPrettyPrinted | NSJSONWritingSortedKeys error:&error];
      if (error) {
          [DYYYUtils showToast:@"备份失败：无法序列化设置数据"];
          return;
      }

      NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
      [formatter setDateFormat:@"yyyyMMdd_HHmmss"];
      NSString *timestamp = [formatter stringFromDate:[NSDate date]];
      NSString *backupFileName = [NSString stringWithFormat:@"DYYY_Backup_%@.json", timestamp];
      NSString *tempFilePath = [DYYYUtils cachePathForFilename:backupFileName];
      BOOL success = [sortedJsonData writeToFile:tempFilePath atomically:YES];
      if (!success) {
          [DYYYUtils showToast:@"备份失败：无法创建临时文件"];
          return;
      }

      // 创建文档选择器让用户选择保存位置
      NSURL *tempFileURL = [NSURL fileURLWithPath:tempFilePath];
      UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithURLs:@[ tempFileURL ] inMode:UIDocumentPickerModeExportToService];
      DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
      pickerDelegate.tempFilePath = tempFilePath; // 设置临时文件路径
      pickerDelegate.completionBlock = ^(NSURL *url) {
        // 备份成功
        [DYYYUtils showToast:@"备份成功"];
      };
      static char kDYYYBackupPickerDelegateKey;
      documentPicker.delegate = pickerDelegate;
      objc_setAssociatedObject(documentPicker, &kDYYYBackupPickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
      UIViewController *topVC = topView();
      [topVC presentViewController:documentPicker animated:YES completion:nil];
    };
    [backupItems addObject:backupItem];

    // 添加恢复设置
    AWESettingItemModel *restoreItem = [[%c(AWESettingItemModel) alloc] init];
    restoreItem.identifier = @"DYYYRestoreSettings";
    restoreItem.title = @"恢复设置";
    restoreItem.detail = @"";
    restoreItem.type = 0;
    restoreItem.svgIconImageName = @"ic_phonearrowup_outlined_20";
    restoreItem.cellType = 26;
    restoreItem.colorStyle = 0;
    restoreItem.isEnable = YES;
    restoreItem.cellTappedBlock = ^{
      UIDocumentPickerViewController *documentPicker = [[UIDocumentPickerViewController alloc] initWithDocumentTypes:@[ @"public.json", @"public.text" ] inMode:UIDocumentPickerModeImport];
      documentPicker.allowsMultipleSelection = NO;

      // 设置委托
      DYYYBackupPickerDelegate *pickerDelegate = [[DYYYBackupPickerDelegate alloc] init];
      pickerDelegate.completionBlock = ^(NSURL *url) {
        if (!url) {
            dispatch_async(dispatch_get_main_queue(), ^{
              [DYYYUtils showToast:@"未选择备份文件"];
            });
            return;
        }

        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
          NSData *jsonData = [NSData dataWithContentsOfURL:url];
          if (!jsonData) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"无法读取备份文件"];
              });
              return;
          }

          NSError *jsonError;
          NSDictionary *dyyySettings = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&jsonError];
          if (jsonError || ![dyyySettings isKindOfClass:[NSDictionary class]]) {
              dispatch_async(dispatch_get_main_queue(), ^{
                [DYYYUtils showToast:@"备份文件格式错误"];
              });
              return;
          }

          NSDictionary *iconBase64Dict = dyyySettings[@"DYYYIconsBase64"];
          if (iconBase64Dict && [iconBase64Dict isKindOfClass:[NSDictionary class]]) {
              NSString *documentsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
              NSString *dyyyFolderPath = [documentsPath stringByAppendingPathComponent:@"DYYY"];
              NSFileManager *fileManager = [NSFileManager defaultManager];
              if (![fileManager fileExistsAtPath:dyyyFolderPath]) {
                  [fileManager createDirectoryAtPath:dyyyFolderPath withIntermediateDirectories:YES attributes:nil error:nil];
              }

              for (NSString *iconFileName in iconBase64Dict) {
                  NSString *base64String = iconBase64Dict[iconFileName];
                  if (![base64String isKindOfClass:[NSString class]]) {
                      continue;
                  }
                  NSData *imageData = [[NSData alloc] initWithBase64EncodedString:base64String options:0];
                  if (imageData) {
                      NSString *iconPath = [dyyyFolderPath stringByAppendingPathComponent:iconFileName];
                      [imageData writeToFile:iconPath atomically:YES];
                  }
              }

              NSMutableDictionary *cleanSettings = [dyyySettings mutableCopy];
              [cleanSettings removeObjectForKey:@"DYYYIconsBase64"];
              dyyySettings = cleanSettings;
          }

          NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
          for (NSString *key in dyyySettings) {
              [defaults setObject:dyyySettings[key] forKey:key];
          }

          dispatch_async(dispatch_get_main_queue(), ^{
            [DYYYUtils showToast:@"设置已恢复，请重启应用以应用所有更改"];
            [restoreItem refreshCell];
          });
        });
      };

      static char kDYYYRestorePickerDelegateKey;
      documentPicker.delegate = pickerDelegate;
      objc_setAssociatedObject(documentPicker, &kDYYYRestorePickerDelegateKey, pickerDelegate, OBJC_ASSOCIATION_RETAIN_NONATOMIC);

      UIViewController *topVC = topView();
      [topVC presentViewController:documentPicker animated:YES completion:nil];
    };
    [backupItems addObject:restoreItem];
    backupSection.itemArray = backupItems;

    // 创建清理section
    AWESettingSectionModel *cleanupSection = [[%c(AWESettingSectionModel) alloc] init];
    cleanupSection.sectionHeaderTitle = @"清理";
    cleanupSection.sectionHeaderHeight = 40;
    cleanupSection.type = 0;
    NSMutableArray<AWESettingItemModel *> *cleanupItems = [NSMutableArray array];
    AWESettingItemModel *cleanSettingsItem = [[%c(AWESettingItemModel) alloc] init];
    cleanSettingsItem.identifier = @"DYYYCleanSettings";
    cleanSettingsItem.title = @"清除设置";
    cleanSettingsItem.detail = @"";
    cleanSettingsItem.type = 0;
    cleanSettingsItem.svgIconImageName = @"ic_trash_outlined_20";
    cleanSettingsItem.cellType = 26;
    cleanSettingsItem.colorStyle = 2;
    cleanSettingsItem.isEnable = YES;
    cleanSettingsItem.cellTappedBlock = ^{
      [DYYYBottomAlertView showAlertWithTitle:@"清除设置"
          message:@"请选择要清除的设置类型"
          avatarURL:nil
          cancelButtonText:@"清除抖音设置"
          confirmButtonText:@"清除插件设置"
          cancelAction:^{
            // 清除抖音设置的确认对话框
            [DYYYBottomAlertView showAlertWithTitle:@"清除抖音设置"
                                            message:@"确定要清除抖音所有设置吗？\n这将无法恢复，应用会自动退出！"
                                          avatarURL:nil
                                   cancelButtonText:@"取消"
                                  confirmButtonText:@"确定"
                                       cancelAction:nil
                                        closeAction:nil
                                      confirmAction:^{
                                        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
                                        if (paths.count > 0) {
                                            NSString *preferencesPath = [paths.firstObject stringByAppendingPathComponent:@"Preferences"];
                                            NSString *bundleIdentifier = [[NSBundle mainBundle] bundleIdentifier];
                                            NSString *plistPath = [preferencesPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist", bundleIdentifier]];

                                            NSError *error = nil;
                                            [[NSFileManager defaultManager] removeItemAtPath:plistPath error:&error];

                                            if (!error) {
                                                [DYYYUtils showToast:@"抖音设置已清除，应用即将退出"];

                                                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                                                  exit(0);
                                                });
                                            } else {
                                                [DYYYUtils showToast:[NSString stringWithFormat:@"清除失败: %@", error.localizedDescription]];
                                            }
                                        }
                                      }];
          }
          closeAction:^{
          }
          confirmAction:^{
            // 清除插件设置的确认对话框
            [DYYYBottomAlertView showAlertWithTitle:@"清除插件设置"
                                            message:@"确定要清除所有插件设置吗？\n这将无法恢复！"
                                          avatarURL:nil
                                   cancelButtonText:@"取消"
                                  confirmButtonText:@"确定"
                                       cancelAction:nil
                                        closeAction:nil
                                      confirmAction:^{
                                        // 获取所有以DYYY开头的NSUserDefaults键值并清除
                                        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                                        NSDictionary *allDefaults = [defaults dictionaryRepresentation];

                                        for (NSString *key in allDefaults.allKeys) {
                                            if ([key hasPrefix:@"DYYY"]) {
                                                [defaults removeObjectForKey:key];
                                            }
                                        }
                                        [DYYYUtils showToast:@"插件设置已清除，请重启应用"];
                                      }];
          }];
    };
    [cleanupItems addObject:cleanSettingsItem];

    NSArray<NSString *> *customDirs = @[ @"Application Support", @"BDByteCast", @"kitelog" ];
    NSMutableSet<NSString *> *uniquePaths = [NSMutableSet set];
    NSString *temporaryDirectory = NSTemporaryDirectory();
    if (temporaryDirectory.length > 0) {
        [uniquePaths addObject:temporaryDirectory];
    }
    NSString *cachesDirectory = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES).firstObject;
    if (cachesDirectory.length > 0) {
        [uniquePaths addObject:cachesDirectory];
    }
    NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES).firstObject;
    if (libraryDir.length > 0) {
        for (NSString *sub in customDirs) {
            NSString *fullPath = [libraryDir stringByAppendingPathComponent:sub];
            if ([[NSFileManager defaultManager] fileExistsAtPath:fullPath]) {
                [uniquePaths addObject:fullPath];
            }
        }
    }
    NSArray<NSString *> *allPaths = [uniquePaths allObjects];

    AWESettingItemModel *cleanCacheItem = [[%c(AWESettingItemModel) alloc] init];
    __weak AWESettingItemModel *weakCleanCacheItem = cleanCacheItem;
    cleanCacheItem.identifier = @"DYYYCleanCache";
    cleanCacheItem.title = @"清理缓存";
    cleanCacheItem.type = 0;
    cleanCacheItem.svgIconImageName = @"ic_broom_outlined";
    cleanCacheItem.cellType = 26;
    cleanCacheItem.colorStyle = 2;
    cleanCacheItem.isEnable = NO;
    cleanCacheItem.detail = @"计算中...";
    __block unsigned long long initialSize = 0;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
      for (NSString *basePath in allPaths) {
          initialSize += [DYYYUtils directorySizeAtPath:basePath];
      }
      dispatch_async(dispatch_get_main_queue(), ^{
        __strong AWESettingItemModel *strongCleanCacheItem = weakCleanCacheItem;
        if (strongCleanCacheItem) {
            strongCleanCacheItem.detail = [DYYYUtils formattedSize:initialSize];
            strongCleanCacheItem.isEnable = YES;
            [strongCleanCacheItem refreshCell];
        }
      });
    });
    cleanCacheItem.cellTappedBlock = ^{
      __strong AWESettingItemModel *strongCleanCacheItem = weakCleanCacheItem;
      if (!strongCleanCacheItem || !strongCleanCacheItem.isEnable) {
          return;
      }
      // Disable the button to prevent multiple triggers
      strongCleanCacheItem.isEnable = NO;
      strongCleanCacheItem.detail = @"清理中...";
      [strongCleanCacheItem refreshCell];

      dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        for (NSString *basePath in allPaths) {
            [DYYYUtils removeAllContentsAtPath:basePath];
        }

        // 修复搜索界面的猜你想搜和猜你想看
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSString *activeMetadataFilePath = libraryDir.length > 0 ? [libraryDir stringByAppendingPathComponent:@"Application Support/gurd_cache/.active_metadata"] : nil;
        if (activeMetadataFilePath.length > 0 && [fileManager fileExistsAtPath:activeMetadataFilePath]) {
            [fileManager removeItemAtPath:activeMetadataFilePath error:nil];
        }

        unsigned long long afterSize = 0;
        for (NSString *basePath in allPaths) {
            afterSize += [DYYYUtils directorySizeAtPath:basePath];
        }

        unsigned long long clearedSize = (initialSize > afterSize) ? (initialSize - afterSize) : 0;

        dispatch_async(dispatch_get_main_queue(), ^{
          [DYYYUtils showToast:[NSString stringWithFormat:@"已清理 %@ 缓存，请手动重启抖音", [DYYYUtils formattedSize:clearedSize]]];

          strongCleanCacheItem.detail = [DYYYUtils formattedSize:afterSize];
          strongCleanCacheItem.isEnable = YES;
          [strongCleanCacheItem refreshCell];
          DYYYRestartApplicationAfterDelay(1.2);
        });
      });
    };
    [cleanupItems addObject:cleanCacheItem];

    cleanupSection.itemArray = cleanupItems;

    // 创建关于分类
    AWESettingSectionModel *aboutSection = [[%c(AWESettingSectionModel) alloc] init];
    aboutSection.sectionHeaderTitle = @"关于";
    aboutSection.sectionHeaderHeight = 40;
    aboutSection.type = 0;
    NSMutableArray<AWESettingItemModel *> *aboutItems = [NSMutableArray array];

    // 添加关于
    AWESettingItemModel *aboutItem = [[%c(AWESettingItemModel) alloc] init];
    aboutItem.identifier = @"DYYYAbout";
    aboutItem.title = @"关于插件";
    aboutItem.detail = DYYY_VERSION;
    aboutItem.type = 0;
    aboutItem.iconImageName = @"awe-settings-icon-about";
    aboutItem.cellType = 26;
    aboutItem.colorStyle = 2;
    aboutItem.isEnable = YES;
    aboutItem.cellTappedBlock = ^{
      [DYYYSettingsHelper showAboutDialog:@"关于DYYY"
                                  message:@"DYYY · VexCove Edition\n"
                                          @"版本：" DYYY_VERSION @"\n\n"
                                          @"感谢使用 DYYY\n\n"
                                          @"本项目基于 Wtrwx/DYYY 继续开发与维护\n"
                                          @"感谢 huami 开源 DYYY\n"
                                          @"感谢 @维他 的二次开发贡献\n"
                                          @"感谢 huami group 群友的支持与赞助\n\n"
                                          @"Telegram\n"
                                          @"• huami：@huamidev\n"
                                          @"• 维他：@vita_app\n"
                                          @"• VexCove：@VexLabs1\n\n"
                                          @"GitHub\n"
                                          @"• 原始开源仓库：huami1314/DYYY\n"
                                          @"• 上游仓库：Wtrwx/DYYY\n"
                                          @"• 当前维护仓库：VexCove/DYYY"
                                onConfirm:nil];
    };
    [aboutItems addObject:aboutItem];

    AWESettingItemModel *licenseItem = [[%c(AWESettingItemModel) alloc] init];
    licenseItem.identifier = @"DYYYLicense";
    licenseItem.title = @"开源协议";
    licenseItem.detail = @"MIT License";
    licenseItem.type = 0;
    licenseItem.iconImageName = @"awe-settings-icon-opensource-notice";
    licenseItem.cellType = 26;
    licenseItem.colorStyle = 2;
    licenseItem.isEnable = YES;
    licenseItem.cellTappedBlock = ^{
      [DYYYSettingsHelper showAboutDialog:@"MIT License"
                                  message:@"Copyright (c) 2024 huami.\n\n"
                                          @"Permission is hereby granted, free of charge, to any person obtaining a copy "
                                          @"of this software and associated documentation files (the \"Software\"), to deal "
                                          @"in the Software without restriction, including without limitation the rights "
                                          @"to use, copy, modify, merge, publish, distribute, sublicense, and/or sell "
                                          @"copies of the Software, and to permit persons to whom the Software is "
                                          @"furnished to do so, subject to the following conditions:\n\n"
                                          @"The above copyright notice and this permission notice shall be included in all "
                                          @"copies or substantial portions of the Software.\n\n"
                                          @"THE SOFTWARE IS PROVIDED \"AS IS\", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR "
                                          @"IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, "
                                          @"FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE "
                                          @"AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER "
                                          @"LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, "
                                          @"OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE "
                                          @"SOFTWARE."
                                onConfirm:nil];
    };
    [aboutItems addObject:licenseItem];
    mainSection.itemArray = mainItems;
    aboutSection.itemArray = aboutItems;

    DYYYResetSettingsSearchIndex();
    DYYYBuildSettingsSearchIndexIfNeeded(mainItems);
    DYYYRegisterSearchSections(@"DYYY", @[ cleanupSection, backupSection, aboutSection ]);

    NSArray *rootSections = @[ mainSection, cleanupSection, backupSection, aboutSection ];
    viewModel.sectionDataArray = rootSections;
    objc_setAssociatedObject(settingsVC, &kViewModelKey, viewModel, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    DYYYAttachSettingsSearchHeader(settingsVC, viewModel, rootSections, DYYYSettingsSearchEntries());
    [rootVC.navigationController pushViewController:(UIViewController *)settingsVC animated:YES];
}

%hook AWESettingsViewModel
- (NSArray *)sectionDataArray {
    NSArray *originalSections = %orig;
    BOOL sectionExists = NO;
    BOOL isMainSettingsPage = NO;

    // 遍历检查是否已存在DYYY部分
    for (AWESettingSectionModel *section in originalSections) {
        if ([section.sectionHeaderTitle isEqualToString:DYYY_NAME]) {
            sectionExists = YES;
        }
        if ([section.sectionHeaderTitle isEqualToString:@"账号"]) {
            isMainSettingsPage = YES;
        }
    }

    if (isMainSettingsPage && !sectionExists) {
        AWESettingItemModel *dyyyItem = [[%c(AWESettingItemModel) alloc] init];
        dyyyItem.identifier = DYYY_NAME;
        dyyyItem.title = DYYY_NAME;
        dyyyItem.detail = DYYY_VERSION;
        dyyyItem.type = 0;
        dyyyItem.svgIconImageName = @"ic_sapling_outlined";
        dyyyItem.cellType = 26;
        dyyyItem.colorStyle = 2;
        dyyyItem.isEnable = YES;
        dyyyItem.cellTappedBlock = ^{
          UIViewController *rootVC = self.controllerDelegate;
          BOOL hasAgreed = [DYYYSettingsHelper getUserDefaults:@"DYYYUserAgreementAccepted"];
          showDYYYSettingsVC(rootVC, hasAgreed);
        };

        AWESettingSectionModel *newSection = [[%c(AWESettingSectionModel) alloc] init];
        newSection.itemArray = @[ dyyyItem ];
        newSection.type = 0;
        newSection.sectionHeaderHeight = 40;
        newSection.sectionHeaderTitle = @"DYYY";

        NSMutableArray *newSections = [NSMutableArray arrayWithArray:originalSections];
        [newSections insertObject:newSection atIndex:0];
        return newSections;
    }
    return originalSections;
}
%end
