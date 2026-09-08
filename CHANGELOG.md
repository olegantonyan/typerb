# Changelog

## 0.5.0

- Variable name detection rewritten: the whole caller file is parsed instead of a single stripped line.
  Prism is used on Ruby 3.3+, `RubyVM::AbstractSyntaxTree` on 3.0-3.2. Both backends behave identically.
- Fixed `SyntaxError` escaping from `type!` and friends when the call spanned several lines
  (leading-dot chains, multi-line argument lists).
- Variable name is now reported for multi-line calls, assignments, string interpolation and chained
  receivers (`h.fetch(:a).type!(String)`).
- `subset_of!` raises `ArgumentError` instead of `NoMethodError` when the receiver is not `Enumerable`.
- Variable names are reported correctly on lines containing multibyte characters.
- Minimum Ruby is 3.0.
- Removed Guard from development dependencies.

## 0.4.0

- Added `subset_of!`.
