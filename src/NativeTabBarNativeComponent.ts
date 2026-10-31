import { codegenNativeComponent, type CodegenTypes, type ColorValue, type ViewProps } from 'react-native'

type TabItem = Readonly<{
  key: string
  title: string
  /** SF Symbol shown when the tab is not selected, e.g. "house". */
  systemImage: string
  /** SF Symbol shown when the tab is selected, e.g. "house.fill". */
  selectedSystemImage: string
  /** Accessibility identifier for UI tests (the JS bar's testID for this tab). */
  testID?: string
}>

export interface NativeProps extends ViewProps {
  items: ReadonlyArray<TabItem>
  selectedIndex: CodegenTypes.Int32
  /**
   * Bump to make the bar re-apply selectedIndex when it is unchanged, e.g. after
   * JS refused a tap the bar had already shown as selected.
   */
  selectionRevision?: CodegenTypes.Int32
  tintColor?: ColorValue
  unselectedTintColor?: ColorValue
  colorScheme?: CodegenTypes.WithDefault<'light' | 'dark' | 'system', 'system'>
  rtl?: boolean
  onTabSelect?: CodegenTypes.DirectEventHandler<Readonly<{ index: CodegenTypes.Int32 }>>
  /** Height the system bar takes, including the home-indicator area. */
  onBarHeight?: CodegenTypes.DirectEventHandler<Readonly<{ height: CodegenTypes.Double }>>
}

export default codegenNativeComponent<NativeProps>('NativeTabBar')
