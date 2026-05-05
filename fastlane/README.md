fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

### platforms

```sh
[bundle exec] fastlane platforms
```

Print the supported release platforms

### build

```sh
[bundle exec] fastlane build
```

Run the build command part for selected platforms (default: ios,mac)

### beta

```sh
[bundle exec] fastlane beta
```

Run the beta command part for selected platforms (default: ios,mac)

### screenshots

```sh
[bundle exec] fastlane screenshots
```

Run the screenshots command part for selected platforms (default: ios,mac)

### upload_screenshots

```sh
[bundle exec] fastlane upload_screenshots
```

Run the upload_screenshots command part for selected platforms (default: ios,mac)

### release

```sh
[bundle exec] fastlane release
```

Run the release command part for selected platforms (default: ios,mac)

### full_release

```sh
[bundle exec] fastlane full_release
```

Run a full release flow for selected platforms (default: ios,mac)

### bump_version

```sh
[bundle exec] fastlane bump_version
```

Bump the marketing version. Pass bump:patch (default), bump:minor, or bump:major

### bump_build

```sh
[bundle exec] fastlane bump_build
```

Bump only the build number

----


## iOS

### ios screenshots

```sh
[bundle exec] fastlane ios screenshots
```

Prepare iOS screenshots for upload (manual staging expected)

### ios build

```sh
[bundle exec] fastlane ios build
```

Build a signed release .ipa without uploading

### ios upload_screenshots

```sh
[bundle exec] fastlane ios upload_screenshots
```

Upload staged screenshots to App Store Connect

### ios beta

```sh
[bundle exec] fastlane ios beta
```

Build a signed release .ipa and upload it to TestFlight

### ios release

```sh
[bundle exec] fastlane ios release
```

Upload the latest iOS build and submit the iOS version for review

----


## Mac

### mac screenshots

```sh
[bundle exec] fastlane mac screenshots
```

Prepare macOS screenshots for upload (manual staging expected)

### mac build

```sh
[bundle exec] fastlane mac build
```

Build a signed macOS package without uploading

### mac upload_screenshots

```sh
[bundle exec] fastlane mac upload_screenshots
```

Upload only staged macOS screenshots to App Store Connect

### mac beta

```sh
[bundle exec] fastlane mac beta
```

Build a signed macOS package and upload it to TestFlight

### mac release

```sh
[bundle exec] fastlane mac release
```

Submit the latest macOS build for App Store review

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
