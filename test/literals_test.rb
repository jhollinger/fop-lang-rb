require 'test_helper'

class LiteralsTest < Minitest::Test
  def test_plain_string
    f = Fop.compile("release-5.125.0")
    assert_equal [
      "Text release-5.125.0",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.125.0", f.apply("release-5.125.0")
    assert_nil f.apply("release-5.125.")
    assert_nil f.apply("elease-5.125.0")
    assert_nil f.apply("foo")
  end

  def test_leading_wildcard
    f = Fop.compile("*release-5.125.0")
    assert_equal [
      "Text *release-5.125.0",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.125.0", f.apply("release-5.125.0")
    assert_equal "foo-release-5.125.0", f.apply("foo-release-5.125.0")
    assert_nil f.apply("foo-release")
  end

  def test_middle_wildcard
    f = Fop.compile("release-*.125.0")
    assert_equal [
      "Text release-",
      "Text *.125.0",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.125.0", f.apply("release-5.125.0")
    assert_equal "release-500000.125.0", f.apply("release-500000.125.0")
    assert_equal "release-asdfasdfasdfasdfasdfasdf.125.0", f.apply("release-asdfasdfasdfasdfasdfasdf.125.0")
    assert_equal "release-.125.0", f.apply("release-.125.0")
    assert_nil f.apply("release-5")
  end

  def test_trailing_wildcard
    f = Fop.compile("release-5.125.0*")
    assert_equal [
      "Text release-5.125.0",
      "Text *",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.125.0-v2", f.apply("release-5.125.0-v2")
    assert_equal "release-5.125.0", f.apply("release-5.125.0")
    assert_nil f.apply("release-5.125.")
  end

  def test_multi_wildcard
    f = Fop.compile("*release-*5.125.0*")
    assert_equal [
      "Text *release-",
      "Text *5.125.0",
      "Text *",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.125.0", f.apply("release-5.125.0")
    assert_equal "FOOrelease-15.125.0FOO", f.apply("FOOrelease-15.125.0FOO")
    assert_nil f.apply("FOOrelease-15.125.")
  end

  def test_escape_wildcard
    f = Fop.compile('\*release-5.125.0')
    assert_equal "*release-5.125.0", f.apply("*release-5.125.0")
    assert_nil f.apply("Xrelease-5.125.0")
    assert_nil f.apply("release-5.125.0")
  end

  def test_escape_expr
    f = Fop.compile('release-\{5\}.125.0')
    assert_equal "release-{5}.125.0", f.apply("release-{5}.125.0")
    assert_nil f.apply("release-6.125.0")
  end
end
