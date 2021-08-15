require 'test_helper'

class LiteralsTest < Minitest::Test
  def test_plain_string
    x = VersionMask.parse("release-5.125.0")
    assert_equal [
      "Text release-5.125.0",
    ], x.nodes.map(&:to_s)
    assert_equal "release-5.125.0", x.apply("release-5.125.0")
    assert_nil x.apply("release-5.125.")
    assert_nil x.apply("elease-5.125.0")
    assert_nil x.apply("foo")
  end

  def test_leading_wildcard
    x = VersionMask.parse("*release-5.125.0")
    assert_equal [
      "Text *release-5.125.0",
    ], x.nodes.map(&:to_s)
    assert_equal "release-5.125.0", x.apply("release-5.125.0")
    assert_equal "foo-release-5.125.0", x.apply("foo-release-5.125.0")
    assert_nil x.apply("foo-release")
  end

  def test_middle_wildcard
    x = VersionMask.parse("release-*.125.0")
    assert_equal [
      "Text release-",
      "Text *.125.0",
    ], x.nodes.map(&:to_s)
    assert_equal "release-5.125.0", x.apply("release-5.125.0")
    assert_equal "release-500000.125.0", x.apply("release-500000.125.0")
    assert_equal "release-asdfasdfasdfasdfasdfasdf.125.0", x.apply("release-asdfasdfasdfasdfasdfasdf.125.0")
    assert_equal "release-.125.0", x.apply("release-.125.0")
    assert_nil x.apply("release-5")
  end

  def test_trailing_wildcard
    x = VersionMask.parse("release-5.125.0*")
    assert_equal [
      "Text release-5.125.0",
      "Text *",
    ], x.nodes.map(&:to_s)
    assert_equal "release-5.125.0-v2", x.apply("release-5.125.0-v2")
    assert_equal "release-5.125.0", x.apply("release-5.125.0")
    assert_nil x.apply("release-5.125.")
  end

  def test_multi_wildcard
    x = VersionMask.parse("*release-*5.125.0*")
    assert_equal [
      "Text *release-",
      "Text *5.125.0",
      "Text *",
    ], x.nodes.map(&:to_s)
    assert_equal "release-5.125.0", x.apply("release-5.125.0")
    assert_equal "FOOrelease-15.125.0FOO", x.apply("FOOrelease-15.125.0FOO")
    assert_nil x.apply("FOOrelease-15.125.")
  end

  def test_escape_wildcard
    x = VersionMask.parse('\*release-5.125.0')
    assert_equal "*release-5.125.0", x.apply("*release-5.125.0")
    assert_nil x.apply("Xrelease-5.125.0")
    assert_nil x.apply("release-5.125.0")
  end

  def test_escape_expr
    x = VersionMask.parse('release-\{5\}.125.0')
    assert_equal "release-{5}.125.0", x.apply("release-{5}.125.0")
    assert_nil x.apply("release-6.125.0")
  end
end
