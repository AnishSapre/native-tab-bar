// iOS only: Android has no native implementation, so nothing is linked there
// (the JS components render nothing on Android).
module.exports = {
  dependency: {
    platforms: {
      android: null,
    },
  },
}
