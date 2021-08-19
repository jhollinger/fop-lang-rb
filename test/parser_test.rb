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

  def test_compile_regex_exp
    f, errors = Fop.compile('{/[0-9]{2}/}')
    assert_equal [], errors
    assert_equal [
      "/^[0-9]{2}/",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_replace_exp
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

  def test_compile_multiple_text_and_match_and_regex
    f, errors = Fop.compile('release/-|_/{N}/ +/FOO{N}')
    assert_equal [], errors
    assert_equal [
      "Text release",
      "/^-|_/",
      "N",
      '/^ +/',
      'Text FOO',
      'N',
    ], f.nodes.map(&:to_s)
  end

  def test_escaping
    f, errors = Fop.compile('release\/-|_\/\{N\}')
    assert_equal [], errors
    assert_equal [
      "Text release/-|_/{N}",
    ], f.nodes.map(&:to_s)
  end

  def test_escaping_slash_inside_regex
    f, errors = Fop.compile('release/-|_|\//5')
    assert_equal [], errors
    assert_equal [
      "Text release",
      '/^-|_|//',
      "Text 5",
    ], f.nodes.map(&:to_s)
  end

  def test_escaping_special_chars_inside_regex
    f, errors = Fop.compile('release/(\{\}){1}/')
    assert_equal [], errors
    assert_equal [
      "Text release",
      '/^(\{\}){1}/',
    ], f.nodes.map(&:to_s)
  end

  def test_auto_escaping_regex_special_chars
    f, errors = Fop.compile('release/[0-9]{2}/')
    assert_equal [], errors
    assert_equal [
      "Text release",
      '/^[0-9]{2}/',
    ], f.nodes.map(&:to_s)
  end
end
