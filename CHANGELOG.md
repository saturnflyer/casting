# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.4] - Unreleased

## [1.0.3] - 2025-10-17

### Added

- Reissue gem for release management. (fff3226)
- Error message on no method error to include the method owner (96cee90)

### Removed

- Testing for ruby below version 3.2 (ea4b09d)

### Changed

- Handle quote and owner prefix changes in ruby 3.4 error messages (7af7b4f)
- Simplify role_for conversion of snake_case to CamelCase. (d60c0cc)
- Cache regular expressions at the SuperDelegate class level. (e11479a)

### Fixed

- Incorrect assert using a block rather than assert_raises. (09c198a)
