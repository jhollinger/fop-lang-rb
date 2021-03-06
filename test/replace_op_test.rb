require 'test_helper'

class ReplaceOpTest < Minitest::Test
  def test_numeric_numeric_replace
    f = Fop("release-{N=16}.{N}.{N=0}")
    assert_equal "release-16.23.0", f.apply("release-5.23.9")
    assert_nil f.apply("release-5.23.W")
  end

  def test_numeric_word_replace
    f = Fop('release-{N=16}.{N}.{N=foo\ bar}')
    assert_equal "release-16.23.foo bar", f.apply("release-5.23.9")
    assert_nil f.apply("release-5.23.foo bar")
  end

  def test_numeric_clear
    f = Fop("release-{N=16}.{N}.{N=}")
    assert_equal "release-16.23.", f.apply("release-5.23.9")
  end

  def test_word_word_replace
    f = Fop("{W=release}-{N}.{N}.{N}")
    assert_equal "release-5.100.0", f.apply("foo-5.100.0")
  end

  def test_word_numeric_replace
    f = Fop("{W=090}-{N}.{N}.{N}")
    assert_equal "090-5.100.0", f.apply("foo-5.100.0")
  end

  def test_word_clear
    f = Fop("{W=}-{N}.{N}.{N}")
    assert_equal "-5.100.0", f.apply("foo-5.100.0")
  end

  def test_wildcard_replace_at_start
    # can't work b/c .* is greedy
    f = Fop("{*=}{N}.{N}.{N}")
    assert_nil f.apply("release-5.100.0")
  end

  def test_wildcard_replace_at_end
    f = Fop("release-{N}.{N}.{N}{*=-beta}")
    assert_equal "release-5.100.0", f.apply("release-5.100.0")
    assert_equal "release-5.100.0-beta", f.apply("release-5.100.0-foo")
  end

  def test_wildcard_clear
    f = Fop("release-{N}.{N}.{N}{*=}")
    assert_equal "release-5.100.0", f.apply("release-5.100.0")
    assert_equal "release-5.100.0", f.apply("release-5.100.0-foo")
  end

  def test_regex_clear
    f = Fop('rel{/(ease)?/=}-{N}.{N}.{N}')
    assert_equal "rel-1.1.1", f.apply("rel-1.1.1")
    assert_equal "rel-1.1.1", f.apply("release-1.1.1")
  end

  def test_regex_replace_with_slash
    f = Fop('rel{/(ease)?/=/ease}-{N}.{N}.{N}')
    assert_equal "rel/ease-1.1.1", f.apply("rel-1.1.1")
    assert_equal "rel/ease-1.1.1", f.apply("release-1.1.1")
  end

  def test_regex_replace_with_capture_groups
    f = Fop('A {/(B) (C)/=$2\ $1}')
    assert_equal "A C B", f.apply("A B C")
  end
end
