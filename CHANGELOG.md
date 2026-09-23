# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

## [Unreleased]

## [1.11.0] - 2026-09-23

### Compatibility

Upgrade steps when moving from 1.10.x. Literal JSON strings are sent unchanged.

- **nice_hash 1.21 / string_pattern 2.5** are now required (`nice_hash ~> 1.21`). Ruby 3.0 or newer is required, which already matched nice_hash 1.19.
- Values produced with `generate(seed:)` or `generate_n(seed:)` differ from nice_hash 1.19. `:uuid`, `:iban` and `:luhn` are not repeatable from `seed:`.
- `StringPattern.block_list` matches literals. If an entry was a regular expression, set `StringPattern.block_list_regexp = true`.
- A `Regexp` used as a pattern must match the whole string.
- A one-element pattern array such as `[:"3:L"]` generates 1 to 5 strings. This includes connection headers, which are still generated once when the client is created.
- A pattern symbol or shorthand in a request body or request header (`:"10-20:L"`, `:"a|b"`, `:uuid`, `:email`, `:iban`, `:luhn`, `[:iban, "DE"]`, `[:luhn, 15]`, `Range`, `Regexp`, `DateTime`, `Boolean`) is expanded before the request is sent. Previously `:uuid` was sent as the text `"uuid"`. Strings such as `"10:N"` or `"a|b"` are still sent as written.
- `validate_response` treats string keys the same as symbol keys, so a match that used to fail on key type can now be `ok: true`. An expected value that is a pattern can also be `ok: true` when the response value fits that pattern. Before, a symbol pattern failed the structure check because its class was not the class of the response value.

### Added

- Request `data` and per-request headers expand nice_hash pattern symbols and shorthands (`:uuid`, `:email`, `:iban`, `:luhn`, checksum pairs, one-element pattern arrays, ranges, regexps, `DateTime`, `Boolean`) on each request.
- `NiceHttp.validate_response` accepts string or symbol keys. When the expected structure contains patterns, those fields are checked with `NiceHash.validate`. `explain: true` adds `:explain` (`valid`, `errors`, `message`, `index`) when a pattern fails.

### Fixed

- Logging a response with no `content-type` no longer raises, so cookie handling after the log still runs.
- Reconnecting after a dropped connection on POST, PUT, PATCH, DELETE and HEAD keeps the response body.

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
