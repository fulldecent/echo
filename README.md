# Echo

[![Build and test](https://github.com/fulldecent/echo/actions/workflows/build-test.yml/badge.svg)](https://github.com/fulldecent/echo/actions/workflows/build-test.yml) [![Lint](https://github.com/fulldecent/echo/actions/workflows/lint.yml/badge.svg)](https://github.com/fulldecent/echo/actions/workflows/lint.yml)

Available on the [iOS App Store](https://apps.apple.com/us/app/echo-speech-therapy/id558585608) and the [macOS App Store](https://apps.apple.com/us/app/echo-speech-therapy/id558585608).

Hear yourself  and native speakers  to improve pronunciation.

Language practice / speech pathology / accent reduction

## Purpose

This app can help you improve pronunciation. Whether that is for speech pathology, accent reduction or studying a new language. It is extremely effective. This app does not intend to teach you all the vocabulary you need, it is not a language app, it is a pronunciation app.

See also my other app for speech pathology: [Vowel Practice](https://github.com/fulldecent/vowel-practice)

## Intro

This iOS app provides the same functionality as the website [learnwithecho.com](https://learnwithecho.com).

It is my first serious iOS app and has gone through siginificant development over the years. It has been successful and brought in good money since 2008 or so, and I hope you can study it for your own benefit or to contribute improvements.

## License

You are welcome to read and study everything here. All contents (c) William Entriken, all contributions require assigment for this copyright. Will consider a more permissive license later.

## Development

Format the Swift files the CI workflow checks, then test on the iPhone 17 simulator:

```sh
swift format format --in-place --recursive Echo EchoTests EchoUITests
xcodebuild test \
  -project Echo.xcodeproj \
  -scheme Echo \
  -destination 'platform=iOS Simulator,name=iPhone 17,OS=27.0' \
  CODE_SIGNING_ALLOWED=NO
```

`CODE_SIGNING_ALLOWED=NO` is for a machine that does not have a provisioning profile for this bundle id. This repository is an Xcode app, so the command is `xcodebuild test`.

## Releasing

Use `fix:`, `feat:` or `BREAKING CHANGE:` in commit messages. Release Please opens a pull request from those. `ci:` and `chore:` do not. Merging that pull request submits iOS and macOS for App Store review. Do not edit [VERSION](VERSION) or the marketing version by hand.

Every push to `main` runs the tests and uploads an iOS build and a macOS build to TestFlight. Both go to the internal group App Store Connect Users for this app. The Apple ID has to accept the invitation before the build appears. The marketing version comes from [VERSION](VERSION). When that version is already on sale, the upload uses the next patch and does not commit it. The review submission uses the version that was uploaded. The build number is chosen at upload time and is not committed.

Store text lives in [fastlane/metadata](fastlane/metadata) and [fastlane/metadata-macos](fastlane/metadata-macos). Screenshots are generated at release time and are not committed. What's New is the newest section of [CHANGELOG.md](CHANGELOG.md).

Release Please opens its pull request as `github-actions`. GitHub holds those checks until a person approves the workflow run.

### Setup

1. GitHub repo > Settings > Actions > General > Workflow permissions: Read and write permissions. Check "Allow GitHub Actions to create and approve pull requests".
1. Sign the Apple Developer Program agreement.
1. Repository secrets:

   - `APP_STORE_CONNECT_KEY_ID`
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY`
   - `APP_STORE_DISTRIBUTION_P12`
   - `APP_STORE_DISTRIBUTION_P12_PASSWORD`
   - `APP_STORE_MAC_INSTALLER_P12`
   - `APP_STORE_MAC_INSTALLER_P12_PASSWORD`

The workflow creates the provisioning profiles at build time. The Mac package also needs the installer certificate named in [fastlane/Fastfile](fastlane/Fastfile).

App Privacy, and whether the app uses the Advertising Identifier, stay in App Store Connect. fastlane sends the encryption answer and the third-party content answer.

Local commands, after `bundle install` with the Ruby in [.ruby-version](.ruby-version) and a gitignored `fastlane/api_key.json`:

```sh
bundle exec fastlane ship_testflight
bundle exec fastlane generate_screenshots
bundle exec fastlane upload_screenshots
bundle exec fastlane submit_app_store build_number:123 version:2.2.3
```

## References

1. This project is built based on [best practices documented in swift-app-template](https://github.com/fulldecent/swift-app-template), release 1.1.0. The [build-and-test workflow](.github/workflows/build-test.yml), the [lint workflow](.github/workflows/lint.yml), and the [release workflow](.github/workflows/release.yml) are that release's three files. [8 Ball Answer](https://github.com/fulldecent/8-ball-answer) is where the template's upload rules were confirmed. This app ships iOS and macOS, including the Mac installer certificate. The template's sample app is named Counter.
