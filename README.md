# fop_lang

Fop (Filter and OPerations language) is a tiny, experimental language for filtering and operating on text. Think of it like awk but with the condition and action segments combined.

This is a Ruby implementation with both a library interface and a bin command.

## Installation

```bash
$ gem install fop_lang
```

You may use fop in a Ruby script:

```ruby
require 'fop_lang'

f = Fop('foo {N+1}')
f.apply('foo 1')
=> "foo 2"
f.apply('bar 1')
=> nil
```

or run `fop` from the command line:

```bash
$ echo 'foo 1' | fop 'foo {N+1}'
foo 2
$ echo 'bar 1' | fop 'foo {N+1}'
```

## Syntax

`Text /(R|r)egex/ {N+1}`

The above program demonstrates a text match, a regex match, and a match expression. If the input matches all three segments, output is given. If the input was `Text regex 5`, the output would be `Text regex 6`.

### Text match

`Text ` and ` ` in the above example.

The input must match this text exactly. Whitespace is part of the match. Wildcards (`*`) are allowed. Special characters (`*/{}\`) may be escaped with `\`.

The output of a text match will be the matching input.

### Regex match

`/(R|r)egex/` in the above example.

Regular expressions may be placed between `/`s. If the regular expression contains a `/`, you may escape it with `\`. Special regex characters like `[]()+.*` may also be escaped with `\`.

The output of a regex match will be the matching input.

### Match expression

`{N+1}` in the above example.

A match expression both matches on input and modifies that input. An expression is made up of 1 - 3 parts:

1. The match, e.g. `N` for numeric.
2. The operator, e.g. `+` for addition (optional).
3. The argument, e.g `1` for "add one" (required for most operators).

The output of a match expression will be the _modified_ matching input. If no operator is given, the output will be the matching input.

**Matches**

* `N` matches one or more consecutive digits.
* `A` matches one or more letters (lower or upper case).
* `W` matches alphanumeric chars and underscores.
* `*` greedily matches everything after it.
* `/regex/` matches on the supplied regex. Capture groups may be referenced in the argument as `$1`, `$2`, etc.

**Operators**

* `=` Replace the matching character(s) with the given argument. If no argument is given, drop the matching chars.
* `>` Append the argument to the matching value.
* `<` Prepend the argument to the matching value.
* `+` Perform addition on the matching number and the argument (`N` only).
* `-` Subtract the argument from the matching number (`N` only).

**Whitespace**

Inside of match expressions, whitespace is an optional seperator of terms, i.e. `{ N + 1 }` is the same as `{N+1}`. This means that any spaces in string arguments must be escaped. For example, replacing a word with `foo bar` looks like `{W = foo\ bar}`.

## Examples

### Release Number Example

This example takes in GitHub branch names, decides if they're release branches, and if so, increments the version number.

```ruby
  f = Fop('release-{N}.{N+1}.{N=0}')

  puts f.apply('release-5.99.1')
  =>           'release-5.100.0'

  puts f.apply('release-5')
  => nil
  # doesn't match the pattern
```

### More Examples

```ruby
  f = Fop('release-{N=5}.{N+1}.{N=0}')

  puts f.apply('release-4.99.1')
  =>           'release-5.100.0'
```

```ruby
  f = Fop('rel{/(ease)?/=}-{N=5}.{N+1}.{N=0}')

  puts f.apply('release-4.99.1')
  =>           'rel-5.100.0'

  puts f.apply('rel-4.99.1')
  =>           'rel-5.100.0'
```

```ruby
  f = Fop('release-*{N=5}.{N+100}.{N=0}')

  puts f.apply('release-foo-4.100.1')
  =>           'release-foo-5.200.0'
```

```ruby
  f = Fop('release-{N=5}.{N+1}.{N=0}{*=}')

  puts f.apply('release-4.100.1.foo.bar')
  =>           'release-5.101.0'
```

```ruby
  f = Fop('{W=version}-{N=5}.{N+1}.{N=0}')

  puts f.apply('release-4.100.1')
  =>           'version-5.101.0'
```
