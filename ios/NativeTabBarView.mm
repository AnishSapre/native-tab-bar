#import "NativeTabBarView.h"

#import <react/renderer/components/NativeTabBarSpec/ComponentDescriptors.h>
#import <react/renderer/components/NativeTabBarSpec/EventEmitters.h>
#import <react/renderer/components/NativeTabBarSpec/Props.h>
#import <react/renderer/components/NativeTabBarSpec/RCTComponentViewHelpers.h>

#import <React/RCTConversions.h>
#import <React/RCTFabricComponentsPlugins.h>
#import <React/RCTLog.h>
#import <QuartzCore/QuartzCore.h>

using namespace facebook::react;

@interface NativeTabBarView () <RCTNativeTabBarViewProtocol, UITabBarDelegate, UIGestureRecognizerDelegate>
@end

@implementation NativeTabBarView {
  UITabBar *_tabBar;
  CGFloat _reportedHeight;
  // Tab already reported on finger lift; didSelectItem for it is then skipped.
  NSInteger _earlyIndex;
  CFTimeInterval _liftTime;
}

+ (ComponentDescriptorProvider)componentDescriptorProvider
{
  return concreteComponentDescriptorProvider<NativeTabBarComponentDescriptor>();
}

- (instancetype)initWithFrame:(CGRect)frame
{
  if (self = [super initWithFrame:frame]) {
    static const auto defaultProps = std::make_shared<const NativeTabBarProps>();
    _props = defaultProps;

    _tabBar = [[UITabBar alloc] initWithFrame:CGRectZero];
    _tabBar.delegate = self;
    [self addSubview:_tabBar];
    _earlyIndex = -1;

    // On iOS 26 UIKit only calls didSelectItem once the glass selection has finished
    // moving, so the new tab started loading late. Watch the touch ourselves and report
    // the tab under the finger as soon as it lifts. Never interferes with the bar's own
    // handling (no cancelling or delaying of its touches).
    UILongPressGestureRecognizer *lift =
        [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleTouch:)];
    lift.minimumPressDuration = 0;
    lift.allowableMovement = CGFLOAT_MAX;
    lift.cancelsTouchesInView = NO;
    lift.delaysTouchesBegan = NO;
    lift.delaysTouchesEnded = NO;
    lift.delegate = self;
    [_tabBar addGestureRecognizer:lift];
  }
  return self;
}

// The React view is taller than the bar (it reserves room for the floating iOS 26 bar);
// only touches on the bar itself are ours, the rest fall through to the screen.
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event
{
  UIView *hit = [super hitTest:point withEvent:event];
  if (hit == self) {
    return nil;
  }
  return hit;
}

- (void)layoutSubviews
{
  [super layoutSubviews];
  // UITabBar sizes itself, including the home-indicator area when it sits at the
  // bottom of the window. Pin it to the bottom of our view.
  CGSize fit = [_tabBar sizeThatFits:self.bounds.size];
  _tabBar.frame = CGRectMake(0, self.bounds.size.height - fit.height, self.bounds.size.width, fit.height);

  if (fit.height != _reportedHeight && _eventEmitter) {
    _reportedHeight = fit.height;
    std::static_pointer_cast<const NativeTabBarEventEmitter>(_eventEmitter)
        ->onBarHeight(NativeTabBarEventEmitter::OnBarHeight{.height = fit.height});
  }
}

- (void)updateEventEmitter:(const EventEmitter::Shared &)eventEmitter
{
  [super updateEventEmitter:eventEmitter];
  // Report the height again once we can.
  _reportedHeight = 0;
  [self setNeedsLayout];
}

static UIImage *SymbolImage(const std::string &name)
{
  if (name.empty()) {
    return nil;
  }
  return [UIImage systemImageNamed:[NSString stringWithUTF8String:name.c_str()]];
}

- (void)updateProps:(Props::Shared const &)props oldProps:(Props::Shared const &)oldProps
{
  const auto &oldViewProps = *std::static_pointer_cast<NativeTabBarProps const>(_props);
  const auto &newViewProps = *std::static_pointer_cast<NativeTabBarProps const>(props);

  BOOL itemsChanged = _tabBar.items.count != newViewProps.items.size();
  if (!itemsChanged) {
    for (size_t i = 0; i < newViewProps.items.size(); i++) {
      const auto &a = oldViewProps.items.size() > i ? oldViewProps.items[i] : newViewProps.items[i];
      const auto &b = newViewProps.items[i];
      if (oldViewProps.items.size() <= i || a.key != b.key || a.title != b.title ||
          a.systemImage != b.systemImage || a.selectedSystemImage != b.selectedSystemImage ||
          a.testID != b.testID) {
        itemsChanged = YES;
        break;
      }
    }
  }

  if (itemsChanged) {
    NSMutableArray<UITabBarItem *> *items = [NSMutableArray new];
    NSInteger tag = 0;
    for (const auto &item : newViewProps.items) {
      UITabBarItem *barItem =
          [[UITabBarItem alloc] initWithTitle:[NSString stringWithUTF8String:item.title.c_str()]
                                        image:SymbolImage(item.systemImage)
                                selectedImage:SymbolImage(item.selectedSystemImage)];
      barItem.tag = tag++;
      barItem.accessibilityIdentifier = item.testID.empty()
          ? [NSString stringWithFormat:@"native_tab_%s", item.key.c_str()]
          : [NSString stringWithUTF8String:item.testID.c_str()];
      [items addObject:barItem];
    }
    [_tabBar setItems:items animated:NO];
  }

  if (oldViewProps.tintColor != newViewProps.tintColor) {
    _tabBar.tintColor = RCTUIColorFromSharedColor(newViewProps.tintColor);
  }
  if (oldViewProps.unselectedTintColor != newViewProps.unselectedTintColor) {
    _tabBar.unselectedItemTintColor = RCTUIColorFromSharedColor(newViewProps.unselectedTintColor);
  }

  if (oldViewProps.colorScheme != newViewProps.colorScheme) {
    switch (newViewProps.colorScheme) {
      case NativeTabBarColorScheme::Light:
        _tabBar.overrideUserInterfaceStyle = UIUserInterfaceStyleLight;
        break;
      case NativeTabBarColorScheme::Dark:
        _tabBar.overrideUserInterfaceStyle = UIUserInterfaceStyleDark;
        break;
      case NativeTabBarColorScheme::System:
        _tabBar.overrideUserInterfaceStyle = UIUserInterfaceStyleUnspecified;
        break;
    }
  }

  if (oldViewProps.rtl != newViewProps.rtl) {
    _tabBar.semanticContentAttribute =
        newViewProps.rtl ? UISemanticContentAttributeForceRightToLeft : UISemanticContentAttributeForceLeftToRight;
  }

  // JS owns the selection; keep the bar in step with it.
  NSInteger selected = newViewProps.selectedIndex;
  if (selected != _earlyIndex && (oldViewProps.selectedIndex != selected ||
                                  oldViewProps.selectionRevision != newViewProps.selectionRevision)) {
    // JS moved elsewhere (or refused the tap): the early report no longer applies.
    _earlyIndex = -1;
  }
  if (itemsChanged || oldViewProps.selectedIndex != newViewProps.selectedIndex ||
      oldViewProps.selectionRevision != newViewProps.selectionRevision) {
    // Skip the tab reported on finger lift: UIKit is still animating its glass
    // selection there, and setting it again would cut that short.
    if (selected >= 0 && selected < (NSInteger)_tabBar.items.count && selected != _earlyIndex &&
        _tabBar.selectedItem != _tabBar.items[selected]) {
      _tabBar.selectedItem = _tabBar.items[selected];
    }
  }

  [super updateProps:props oldProps:oldProps];
}

#pragma mark - Early selection

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
    shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)other
{
  return YES;
}

/// The item whose button is under `point`: walk up from the hit view to the element
/// VoiceOver reads as the item's title. -1 when that can't be told (the bar then
/// reports through didSelectItem as before).
- (NSInteger)itemIndexAtPoint:(CGPoint)point
{
  UIView *view = [_tabBar hitTest:point withEvent:nil];
  while (view && view != _tabBar) {
    NSString *label = view.accessibilityLabel;
    if (label.length) {
      for (UITabBarItem *item in _tabBar.items) {
        if ([label isEqualToString:item.title]) {
          return item.tag;
        }
      }
    }
    view = view.superview;
  }
  return -1;
}

- (void)handleTouch:(UILongPressGestureRecognizer *)recognizer
{
  if (recognizer.state != UIGestureRecognizerStateEnded) {
    return;
  }
  NSInteger index = [self itemIndexAtPoint:[recognizer locationInView:_tabBar]];
  _liftTime = CACurrentMediaTime();
#if DEBUG
  RCTLogInfo(@"[NativeTabBar] finger lifted on tab %ld", (long)index);
#endif
  if (index < 0 || index == [_tabBar.items indexOfObject:_tabBar.selectedItem]) {
    return;
  }
  _earlyIndex = index;
  [self emitSelect:index];
}

- (void)emitSelect:(NSInteger)index
{
  if (!_eventEmitter) {
    return;
  }
  std::static_pointer_cast<const NativeTabBarEventEmitter>(_eventEmitter)
      ->onTabSelect(NativeTabBarEventEmitter::OnTabSelect{.index = (int)index});
}

#pragma mark - UITabBarDelegate

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
#if DEBUG
  RCTLogInfo(@"[NativeTabBar] didSelectItem %ld, %.0f ms after lift", (long)item.tag,
             (CACurrentMediaTime() - _liftTime) * 1000);
#endif
  NSInteger early = _earlyIndex;
  _earlyIndex = -1;
  if (item.tag == early) {
    // Already reported on finger lift.
    return;
  }
  [self emitSelect:item.tag];
}

@end
