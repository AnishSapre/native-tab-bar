import { useSyncExternalStore } from 'react'

// The bar's height as last reported by the native view (home-indicator area included).
// Screens use it to keep their last item clear of the floating iOS 26 bar.
let height = 0
const listeners = new Set<() => void>()

export const setTabBarHeight = (next: number) => {
  if (next === height) return
  height = next
  listeners.forEach(listener => listener())
}

const subscribe = (listener: () => void) => {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}

/** Height of the native tab bar (0 until it has laid out, or on Android). */
export const useNativeTabBarHeight = () => useSyncExternalStore(subscribe, () => height, () => 0)
