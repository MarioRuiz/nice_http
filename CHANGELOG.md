# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.10.1] - 2026-03-24

### Fixed

- Robust HTTP method detection in request management using `caller_locations` with fallback logic, fixing Ruby 3.4 compatibility for capture/stats method keys (`GET`, `POST`, etc.).

## [1.10.0] - 2026-02-13

### Added

- `NiceHttp.validate_response(resp, expected_structure, options)` to validate JSON response structure using NiceHash.compare_structure. Optional `include_diff: true` adds a diff to the result when validation fails.
- README section "Testing with generated data" (reproducible seed, generate_n, UUID with nice_hash/string_pattern).
- README section "Validating API responses" (compare_structure, diff, pattern validation).
- README "Related gems" note for nice_hash (v1.19+) and string_pattern (v2.4+).

### Changed

- **Dependency:** nice_hash is now required as `~> 1.19`, `>= 1.19.0` (was `~> 1.18`, `>= 1.18.4`). Upgrade nice_hash to 1.19+ when upgrading nice_http.
- Headers initialization: only calls `@headers.generate` when `@headers` is a Hash and responds to `generate`, otherwise duplicates headers without generating (avoids errors in edge cases).

### Removed

- Removed dead code branch for Ruby < 2.6.0 in response handling (nice_http already requires Ruby >= 2.7).
