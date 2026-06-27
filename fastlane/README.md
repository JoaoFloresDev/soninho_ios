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

### ios sync_screenshots_initial

```sh
[bundle exec] fastlane ios sync_screenshots_initial
```

Push initial screenshots (single set per locale, 6.9") to the

App Store DEFAULT product page. Run this for first submission of a

new app, after `swift run SoninhoScreenshots initial` has

rendered the PNGs into ./screenshots/initial/<locale>/.



For A/B test (PPO experiments) post-launch use upload_ppo.py instead —

fastlane deliver does NOT support PPO experiment uploads.

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
