# fop_lang

Fop (Filter and OPerations language) is an experimental, tiny expression language in the vein of awk and sed. This is a Ruby implementation. It is useful for simultaneously matching and transforming text input.

```ruby
gem 'fop_lang'
```

## Release Number Example

This example takes in GitHub branch names, decides if they're release branches, and if so, increments the version number.

```ruby
  f = Fop('release-{N}.{N+1}.{N=0}')

  puts f.apply('release-5.99.1')
  =>           'release-5.100.0'

  puts f.apply('release-5')
  => nil
  # doesn't match the pattern
```

## Anatomy of a Fop expression

`Text Literal {Operation}`

The above expression contains the only two parts of Fop (except for the wildcard and escape characters).

**Text Literals**

A text literal works how it sounds: the input must match it exactly. If it matches it passes through unchanged. The only exception is the `*` (wildcard) character, which matches 0 or more of anything. Wildcards can be used anywhere except inside `{...}` (operations).

If `\` (escape) is used before the special characters `*`, `{` or `}`, then that character is treated like a text literal. It's recommended to use single-quoted Ruby strings with Fop expressions that so you don't need to double-escape.

**Operations**

Operations are the interesting part of Fop, and are specified between `{` and `}`. An Operation can consist of one to three parts:

1. Matching class (required): Defines what characters the operation will match and operate on.
  * `N` is the numeric class and will match one or more digits.
  * `A` is the alpha class and will match one or more letters (lower or upper case).
  * `W` is the word class and matches alphanumeric chars and underscores.
  * `*` is the wildcard class and greedily matches everything after it.
  * `/.../` matches on the supplied regex between the `/`'s. If you're regex contains a `/`, it must be escaped.
3. Operator (optional): What to do to the matching characters.
  * `=` Replace the matching character(s) with the given argument. If no argument is given, drop the matching chars.
  * `>` Append the following chars to the matching value.
  * `<` Prepend the following chars to the matching value.
  * `+` Perform addition on the matching number and the argument (`N` only).
  * `-` Subtract the argument from the matching number (`N` only).
5. Operator argument (required for some operators): meaning varies by operator.

## More Examples

```ruby
  f = Fop('release-{N=5}.{N+1}.{N=0}')

  puts f.apply('release-4.99.1')
  =>           'release-5.100.0'
```

```ruby
  f = Fop('rel{/(ease)?/}-{N=5}.{N+1}.{N=0}')

  puts f.apply('release-4.99.1')
  =>           'release-5.100.0'

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
