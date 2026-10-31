import React from 'react'
import type { ColorValue } from 'react-native'
import { TabBar } from './TabBar'
import { isAvailable } from './platform'

// The parts of React Navigation's BottomTabBarProps this uses (v6 and v7 alike), typed
// structurally so the package doesn't depend on @react-navigation/bottom-tabs.
type Route = { key: string; name: string; params?: object }
type Options = {
  title?: string
  tabBarLabel?: unknown
  tabBarButtonTestID?: string
  tabBarTestID?: string
  tabBarStyle?: unknown
  /** SF Symbol for this tab (native-tab-bar option). */
  tabBarSystemImage?: string
  /** SF Symbol when selected (native-tab-bar option). */
  tabBarSelectedSystemImage?: string
}
export type NativeTabBarProps = {
  state: { index: number; routes: Route[] }
  descriptors: Record<string, { options: Options }>
  navigation: {
    emit: (event: { type: 'tabPress'; target: string; canPreventDefault: true }) => { defaultPrevented: boolean }
    navigate: (...args: any[]) => void
  }
  tintColor?: ColorValue
  unselectedTintColor?: ColorValue
  colorScheme?: 'light' | 'dark' | 'system'
}

const flattenDisplay = (style: unknown): string | undefined => {
  if (Array.isArray(style)) return style.map(flattenDisplay).filter(Boolean).pop()
  return (style as { display?: string } | undefined)?.display
}

/**
 * Drop-in `tabBar` for React Navigation's bottom tab navigator:
 *
 *   <Tab.Navigator tabBar={props => <NativeTabBar {...props} />}>
 *     <Tab.Screen name="Home" component={Home}
 *       options={{ tabBarSystemImage: 'house', tabBarSelectedSystemImage: 'house.fill' }} />
 *
 * Fires the navigator's tabPress event (preventDefault works) and navigates like the
 * default bar. Hidden when the focused screen sets tabBarStyle: { display: 'none' }.
 * Renders nothing on Android: there, leave tabBar unset to get the default bar.
 */
export const NativeTabBar = ({ state, descriptors, navigation, tintColor, unselectedTintColor, colorScheme }: NativeTabBarProps) => {
  if (!isAvailable) return null
  const focused = state.routes[state.index]
  if (focused && flattenDisplay(descriptors[focused.key]?.options.tabBarStyle) === 'none') return null

  return (
    <TabBar
      items={state.routes.map(route => {
        const options = descriptors[route.key]?.options ?? {}
        const systemImage = options.tabBarSystemImage ?? 'circle'
        return {
          key: route.key,
          title: typeof options.tabBarLabel === 'string' ? options.tabBarLabel : options.title ?? route.name,
          systemImage,
          selectedSystemImage: options.tabBarSelectedSystemImage ?? systemImage,
          testID: options.tabBarButtonTestID ?? options.tabBarTestID,
        }
      })}
      selectedIndex={state.index}
      tintColor={tintColor}
      unselectedTintColor={unselectedTintColor}
      colorScheme={colorScheme}
      onSelect={index => {
        const route = state.routes[index]
        if (!route) return
        const event = navigation.emit({ type: 'tabPress', target: route.key, canPreventDefault: true })
        if (index !== state.index && !event.defaultPrevented) {
          navigation.navigate({ name: route.name, params: route.params, merge: true })
        }
      }}
    />
  )
}
