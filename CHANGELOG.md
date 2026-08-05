# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.0.0] - Unreleased
### Added
- Added support for Rails 8.0.
- Added `ActionController::LogSubscriber` to replace `RequestLogger`.

### Changed
- Reorganized log fields to follow Datadog's logical grouping.
- Changed the scale of the duration field from ms to ns.
- Reorganized Rails "extensions".

### Removed
- Dropped support for end-of-life Ruby and Rails versions.
- Dropped support for legacy Rails log subscriber handling.

## [2.3] - 2026-07-28
### Changed
- Replaced `OpenStruct` with a plain `Struct` for the internal STDOUT log device, removing the reliance on
  `ostruct` — which is no longer a default gem in current Ruby versions. The Struct is now created once and
  shared instead of per logger.
  (https://github.com/zormandi/logcraft/pull/13, https://github.com/zormandi/logcraft/pull/14)

Thanks to [@jbigler](https://github.com/jbigler) for both contributions.

## [2.2.1] - 2023-12-19
### Fixed
- Fixed an issue where logs were duplicated (once in JSON, once in plain text) when running the Rails console.
  (https://github.com/zormandi/logcraft/issues/7)
- Fixed an issue that prevented using Logcraft and Sentry-Rails together with the default configuration.
  (https://github.com/zormandi/logcraft/issues/6)

## [2.2] - 2023-10-23
### Added
- Added support for Rails 7.1.

## [2.1] - 2023-06-13
### Added
- Added support for custom log formatters.

## [2.0.1] - 2022-10-07
### Fixed
- Fixed a bug where request log tracing didn't work with the DataDog integration. Had to move up logging
  the request to the point where the middleware is done processing instead of where we originally had it;
  at the time when the response body was closed. We lost some precision in terms of measuring request duration
  but some context (e.g. DataDog active trace) would not be available otherwise.

## [2.0.0] - 2022-07-31
### Added
- Added the option to change the log level or suppress logging of unhandled errors which are, in fact,
  handled by Rails (e.g. 404 Not Found).

### Changed
- The initial context is now fully dynamic; it can be either a Hash or a lambda/Proc returning a Hash.
  Using a Hash with lambda values is no longer supported.
- Renamed `initial_context` configuration setting to `global_context` everywhere.

### Fixed
- Fixed a bug where the request ID was missing from the access log.

### Added
- The provided RSpec matchers can now take other matchers as part of the log expectation.

## [1.0.0.rc] - 2022-06-26
### Added
- Logcraft was rewritten from the ground up, based on its predecessor: [Ezlog](https://github.com/emartech/ezlog).
