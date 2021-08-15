# version_mask

A tiny expression language implemented in Ruby focused on text matching and numerical transformations.

## Examples

```ruby
  vmask = VersionMask.parse("release-{N}.{N+1}.{N=0}")

  puts vmask.apply("release-5.99.1")
  => "release-5.100.0"

  puts vmask.apply("release-5")
  => nil
  # doesn't match the pattern
```

```ruby
  vmask = VersionMask.parse("release-{N=5}.{N+1}.{N=0}")

  puts vmask.apply("release-4.99.1")
  => "release-5.100.0"
```

```ruby
  vmask = VersionMask.parse("release-*{N=5}.{N+100}.{N=0}")

  puts vmask.apply("release-foo-4.100.1")
  => "release-foo-5.200.0"
```

```ruby
  vmask = VersionMask.parse("release-{N=5}.{N+1}.{N=0}{*=}")

  puts vmask.apply("release-4.100.1.foo.bar")
  => "release-5.101.0"
```
