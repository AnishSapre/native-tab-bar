# native-tab-bar

Apple's `UITabBar` for React Native. On iOS 26 that is the real **liquid glass** tab bar:
the glass selection lens, drag-to-switch along the bar and press feedback all come from
UIKit, not an imitation. Includes a drop-in `tabBar` for React Navigation's bottom tabs.

## Requirements

- React Native 0.76+ with the **New Architecture** (Fabric). This is a Fabric component;
  it has no old-architecture (Paper) implementation.
- **iOS only.** On Android the component renders nothing, so check `isAvailable` (or
  `Platform.OS`) and render your own fallback there.
- The liquid glass look needs **iOS 26+** (built with the iOS 26 SDK or later). On earlier
  iOS you get the classic system look. `hasLiquidGlass` tells you which one is showing.

## Install

```sh
npm install native-tab-bar
cd ios && pod install
```

Then rebuild the app (a Metro reload is not enough for new native code).

## Usage with React Navigation (v6 or v7)

```tsx
import { createBottomTabNavigator } from '@react-navigation/bottom-tabs'
import { NativeTabBar, isAvailable, useNativeTabBarHeight } from 'native-tab-bar'

const Tab = createBottomTabNavigator()

export function Tabs() {
  return (
    <Tab.Navigator
      // iOS: Apple's tab bar. Android: React Navigation's default bar.
      tabBar={isAvailable ? props => <NativeTabBar {...props} tintColor="#4D2E97" /> : undefined}
      screenOptions={{ headerShown: false }}
    >
      <Tab.Screen
        name="Home"
        component={Home}
        options={{ tabBarSystemImage: 'house', tabBarSelectedSystemImage: 'house.fill' }}
      />
      <Tab.Screen
        name="Profile"
        component={Profile}
        options={{ tabBarSystemImage: 'person', tabBarSelectedSystemImage: 'person.fill' }}
      />
    </Tab.Navigator>
  )
}

// The bar floats over your content on iOS 26: pad scrolling content by its height.
function Home() {
  const tabBarHeight = useNativeTabBarHeight()
  return <ScrollView contentContainerStyle={{ paddingBottom: tabBarHeight }}>{/* … */}</ScrollView>
}
```

- Icons are [SF Symbols](https://developer.apple.com/sf-symbols/) names
  (`tabBarSystemImage`, `tabBarSelectedSystemImage`), not images or React components.
- Labels come from `tabBarLabel` (string) or `title`, else the route name.
- `tabPress` is emitted as usual, so `e.preventDefault()` in a listener works.
- `tabBarStyle: { display: 'none' }` on the focused screen hides the bar.
- `tabBarButtonTestID` (or `tabBarTestID`) sets each tab's accessibility identifier.
- TypeScript: `tabBarSystemImage` isn't in React Navigation's option types; cast the
  options or declare them in your own type augmentation.

## Usage without a navigator

```tsx
import { TabBar } from 'native-tab-bar'

<TabBar
  items={[
    { key: 'home', title: 'Home', systemImage: 'house', selectedSystemImage: 'house.fill' },
    { key: 'settings', title: 'Settings', systemImage: 'gearshape', selectedSystemImage: 'gearshape.fill' },
  ]}
  selectedIndex={index}
  onSelect={setIndex}
/>
```

`TabBar` pins itself to the bottom of its parent; touches outside the bar pass through.

| Prop | Type | |
|---|---|---|
| `items` | `{ key, title, systemImage, selectedSystemImage?, testID? }[]` | Tabs |
| `selectedIndex` | `number` | Controlled selection |
| `onSelect` | `(index) => void` | User picked a tab; set `selectedIndex` to accept it |
| `tintColor` | colour | Selected tab colour |
| `unselectedTintColor` | colour | Other tabs |
| `colorScheme` | `'light' \| 'dark' \| 'system'` | Default `'system'` |
| `onHeightChange` | `(height) => void` | Bar height (also `useNativeTabBarHeight()`) |

## Limitations

- Styling is Apple's: you choose the tint colours, not fonts or shapes.
- The iOS 26 "shrink on scroll" behaviour belongs to `UITabBarController` and isn't
  available to a standalone `UITabBar`.

## How it works

A small Fabric component wraps Apple's own UIKit control, so iOS draws and animates it.
React Native's codegen builds the bridge from the TypeScript spec in
`src/*NativeComponent.ts` during `pod install`.

## License

MIT © Anish Sapre
