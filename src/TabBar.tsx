import React, { useState } from 'react'
import { I18nManager, StyleSheet, type ColorValue, type StyleProp, type ViewStyle } from 'react-native'
import NativeTabBarView from './NativeTabBarNativeComponent'
import { setTabBarHeight } from './heightStore'
import { isAvailable } from './platform'

export type TabBarItem = {
  key: string
  title: string
  /** SF Symbol, e.g. "house". */
  systemImage: string
  /** SF Symbol when selected, e.g. "house.fill". Defaults to systemImage. */
  selectedSystemImage?: string
  /** Accessibility identifier for UI tests. */
  testID?: string
}

export type TabBarProps = {
  items: TabBarItem[]
  selectedIndex: number
  /** The user picked a tab. Selection is controlled: update selectedIndex to accept it. */
  onSelect: (index: number) => void
  tintColor?: ColorValue
  unselectedTintColor?: ColorValue
  colorScheme?: 'light' | 'dark' | 'system'
  /** The bar's height whenever it changes (also available through useNativeTabBarHeight). */
  onHeightChange?: (height: number) => void
  style?: StyleProp<ViewStyle>
}

/** Room for the bar before it reports its real height. */
const PLACEHOLDER_HEIGHT = 120

/**
 * Apple's UITabBar, pinned to the bottom of its parent. On iOS 26 it is the system liquid
 * glass bar (selection lens, drag to switch, press feedback). Touches outside the bar
 * itself pass through to the content behind it. Renders nothing on Android.
 */
export const TabBar = ({
  items,
  selectedIndex,
  onSelect,
  tintColor,
  unselectedTintColor,
  colorScheme = 'system',
  onHeightChange,
  style,
}: TabBarProps) => {
  const [barHeight, setBarHeight] = useState(0)
  // Bumped when a selection the bar already showed is not accepted (selectedIndex
  // unchanged), so the native bar re-syncs to selectedIndex.
  const [revision, setRevision] = useState(0)
  if (!isAvailable) return null

  return (
    <NativeTabBarView
      style={[styles.bar, { height: barHeight || PLACEHOLDER_HEIGHT }, style]}
      items={items.map(item => ({
        key: item.key,
        title: item.title,
        systemImage: item.systemImage,
        selectedSystemImage: item.selectedSystemImage ?? item.systemImage,
        testID: item.testID,
      }))}
      selectedIndex={selectedIndex}
      selectionRevision={revision}
      tintColor={tintColor}
      unselectedTintColor={unselectedTintColor}
      colorScheme={colorScheme}
      rtl={I18nManager.isRTL}
      onBarHeight={e => {
        const height = e.nativeEvent.height
        setBarHeight(height)
        setTabBarHeight(height)
        onHeightChange?.(height)
      }}
      onTabSelect={e => {
        const index = e.nativeEvent.index
        onSelect(index)
        // If the caller doesn't move selectedIndex to it, put the bar back.
        if (index !== selectedIndex) setRevision(n => n + 1)
      }}
    />
  )
}

const styles = StyleSheet.create({
  bar: { position: 'absolute', left: 0, right: 0, bottom: 0 },
})
