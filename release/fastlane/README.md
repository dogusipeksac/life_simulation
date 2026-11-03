fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios tf_upload

```sh
[bundle exec] fastlane ios tf_upload
```

TestFlight'a yükle, işlenmesini bekle ve What to Test metnini ekle

### ios latest_build

```sh
[bundle exec] fastlane ios latest_build
```

En son TestFlight build numarasını sorgula

### ios asc_upload

```sh
[bundle exec] fastlane ios asc_upload
```

App Store Connect sürümüne IPA ve What's New yükle (İncelemeye göndermez)

----


## Android

### android play_upload

```sh
[bundle exec] fastlane android play_upload
```

Google Play'e AAB ve sürüm notu yükle

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
