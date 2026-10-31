import { Platform } from 'react-native'

/** The native view exists on iOS only; on Android the components render nothing. */
export const isAvailable = Platform.OS === 'ios'

/** iOS 26+: the system draws the control with liquid glass. Earlier iOS gets the classic look. */
export const hasLiquidGlass = Platform.OS === 'ios' && parseInt(String(Platform.Version), 10) >= 26
