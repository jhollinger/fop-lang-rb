require 'test_helper'

class ParserTest < Minitest::Test
  def test_compile_text
    f, errors = Fop.compile('release-5.125.0')
    assert_equal [], errors
    assert_equal [
      "Text release-5.125.0",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_match_exp
    f, errors = Fop.compile('{N}')
    assert_equal [], errors
    assert_equal [
      "N",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_regex
    f, errors = Fop.compile('/[a-z]+/')
    assert_equal [], errors
    assert_equal [
      "/^[a-z]+/",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_text_and_match_and_regex
    f, errors = Fop.compile('release/-|_/{N}')
    assert_equal [], errors
    assert_equal [
      "Text release",
      "/^-|_/",
      "N",
    ], f.nodes.map(&:to_s)
  end

  def test_escaping
    f, errors = Fop.compile('release\/-|_\/\{N\}')
    assert_equal [], errors
    assert_equal [
      "Text release/-|_/{N}",
    ], f.nodes.map(&:to_s)
  end
end
