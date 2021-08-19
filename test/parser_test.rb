require 'test_helper'

class ParserTest < Minitest::Test
  def test_compile_text
    f, errors = Fop.compile('release-5.125.0')
    assert_equal [], errors
    assert_equal [
      "[txt] release-5.125.0",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_match_exp
    f, errors = Fop.compile('{N}')
    assert_equal [], errors
    assert_equal [
      "[exp] N",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_regex_exp
    f, errors = Fop.compile('{/[0-9]{2}/}')
    assert_equal [], errors
    assert_equal [
      "[exp] ^[0-9]{2}",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_replace_exp
  end

  def test_compile_regex
    f, errors = Fop.compile('/[a-z]+/')
    assert_equal [], errors
    assert_equal [
      "[reg] ^[a-z]+",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_text_and_match_and_regex
    f, errors = Fop.compile('release/-|_/{N}')
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      "[reg] ^-|_",
      "[exp] N",
    ], f.nodes.map(&:to_s)
  end

  def test_compile_multiple_text_and_match_and_regex
    f, errors = Fop.compile('release/-|_/{N}/ +/FOO{N}')
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      "[reg] ^-|_",
      "[exp] N",
      '[reg] ^ +',
      '[txt] FOO',
      '[exp] N',
    ], f.nodes.map(&:to_s)
  end

  def test_escaping
    f, errors = Fop.compile('release\/-|_\/\{N\}')
    assert_equal [], errors
    assert_equal [
      "[txt] release/-|_/{N}",
    ], f.nodes.map(&:to_s)
  end

  def test_escaping_slash_inside_regex
    f, errors = Fop.compile('release/-|_|\//5')
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      '[reg] ^-|_|/',
      "[txt] 5",
    ], f.nodes.map(&:to_s)
  end

  def test_escaping_special_chars_inside_regex
    f, errors = Fop.compile('release/(\{\}){1}/')
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      '[reg] ^(\{\}){1}',
    ], f.nodes.map(&:to_s)
  end

  def test_auto_escaping_regex_special_chars
    f, errors = Fop.compile('release/[0-9]{2}/')
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      '[reg] ^[0-9]{2}',
    ], f.nodes.map(&:to_s)
  end
end
