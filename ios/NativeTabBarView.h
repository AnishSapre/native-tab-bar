#import <React/RCTViewComponentView.h>
#import <UIKit/UIKit.h>

#ifndef NativeTabBarView_h
#define NativeTabBarView_h

NS_ASSUME_NONNULL_BEGIN

/// The system UITabBar as a Fabric component. On iOS 26 that is Apple's liquid glass
/// bar: the glass selection lens, drag-to-switch and press feedback all come from UIKit.
@interface NativeTabBarView : RCTViewComponentView
@end

NS_ASSUME_NONNULL_END

#endif /* NativeTabBarView_h */
