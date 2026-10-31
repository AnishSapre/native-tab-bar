export { TabBar, type TabBarItem, type TabBarProps } from './TabBar'
export { NativeTabBar, type NativeTabBarProps } from './ReactNavigationTabBar'
export { useNativeTabBarHeight } from './heightStore'
export { isAvailable, hasLiquidGlass } from './platform'
/** The raw native view, for custom wrappers. */
export { default as NativeTabBarView } from './NativeTabBarNativeComponent'
export type { NativeProps as NativeTabBarViewProps } from './NativeTabBarNativeComponent'
