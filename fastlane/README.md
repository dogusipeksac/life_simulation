fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## Android

### android release

```sh
[bundle exec] fastlane android release
```

Upload the selected AAB and Turkish release notes only

----


## iOS

### ios beta_upload

```sh
[bundle exec] fastlane ios beta_upload
```

Upload to TestFlight and set What to Test; do not distribute to testers

### ios app_store

```sh
[bundle exec] fastlane ios app_store
```

Upload IPA and Turkish What's New; leave review and release manual

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
