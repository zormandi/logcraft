# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Changed
- The initial context is now fully dynamic; it can be either a Hash or a lambda/Proc returning a Hash.
  Using a Hash with lambda values is no longer supported.
- Renamed `initial_context` configuration setting to `global_context` everywhere.

### Added
- The provided RSpec matchers can now take other matchers as part of the log expectation.

## [1.0.0.rc] - 2022-06-26
### Added
- Logcraft was rewritten from the ground up, based on its predecessor: [Ezlog](https://github.com/emartech/ezlog).
