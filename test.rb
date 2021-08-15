require_relative 'lib/version_mask'

def assert_equal(correct, candidate)
  if correct == candidate
    print "."
  else
    print "F\n"
    $stderr.puts "Expected '#{candidate}' to equal '#{correct}'"
  end
end

"release-{N=5}.{N+1}.{N=0}".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text release-",
    "N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N = 0",
  ], mask.nodes.map(&:to_s)
  assert_equal "release-5.100.0", mask.apply("release-4.99.0")
}

"*release-{N=5}.{N+1}.{N=0}".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text *release-",
    "N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N = 0",
  ], mask.nodes.map(&:to_s)
}

"release-{N=5}.{N+1}.{N=0}*".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text release-",
    "N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N = 0",
    "Text *",
  ], mask.nodes.map(&:to_s)
}

"release-*-{N=5}.{N+1}.{N=0}".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text release-",
    "Text *-",
    "N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N = 0",
  ], mask.nodes.map(&:to_s)
}

"release-*{N=5}.{N+1}.{N=0}".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text release-",
    "*N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N = 0",
  ], mask.nodes.map(&:to_s)
}

"release-*{N=5}.{N+1}.{N}".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text release-",
    "*N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N",
  ], mask.nodes.map(&:to_s)
}

"release-{N=5}.{N+1}.{N=}".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text release-",
    "N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N = ",
  ], mask.nodes.map(&:to_s)
}

"release-{N=5}.{N+1}.{N}{*=}".tap { |str|
  mask = VersionMask.parse(str)
  assert_equal [
    "Text release-",
    "N = 5",
    "Text .",
    "N + 1",
    "Text .",
    "N",
    "* = ",
  ], mask.nodes.map(&:to_s)
  assert_equal "release-5.121.0", mask.apply("release-5.120.0")
  assert_equal "release-5.121.0", mask.apply("release-5.120.0-v1")
}

#puts t.apply "release-5.125.0"
