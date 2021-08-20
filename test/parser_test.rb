require 'test_helper'

class ParserTest < Minitest::Test
  def test_parse_text
    nodes, errors = Fop::Parser.new('release-5.125.0').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release-5.125.0",
    ], nodes.map(&:to_s)
  end

  def test_parse_wildcard_text
    nodes, errors = Fop::Parser.new('release*5.125.0').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      "[*txt] 5.125.0",
    ], nodes.map(&:to_s)
  end

  def test_parse_match_exp
    nodes, errors = Fop::Parser.new('{N}').parse
    assert_equal [], errors
    assert_equal [
      "[exp] N",
    ], nodes.map(&:to_s)
  end

  def test_wildcard_match_exp
    nodes, errors = Fop::Parser.new('*{N}').parse
    assert_equal [], errors
    assert_equal [
      "[*exp] N",
    ], nodes.map(&:to_s)
  end

  def test_parse_regex_exp
    nodes, errors = Fop::Parser.new('{/[0-9]{2}/}').parse
    assert_equal [], errors
    assert_equal [
      "[exp] [0-9]{2}",
    ], nodes.map(&:to_s)
  end

  def test_wildcard_regex
    nodes, errors = Fop::Parser.new('*/[0-9]{2}/').parse
    assert_equal [], errors
    assert_equal [
      "[*reg] [0-9]{2}",
    ], nodes.map(&:to_s)
  end

  def test_parse_clear_exp
    nodes, errors = Fop::Parser.new('{N=}').parse
    assert_equal [], errors
    assert_equal [
      "[exp] N = ",
    ], nodes.map(&:to_s)
  end

  def test_parse_replace_exp
    nodes, errors = Fop::Parser.new('{N=500}').parse
    assert_equal [], errors
    assert_equal [
      "[exp] N = 500",
    ], nodes.map(&:to_s)
  end

  def test_parse_regex
    nodes, errors = Fop::Parser.new('/[a-z]+/').parse
    assert_equal [], errors
    assert_equal [
      "[reg] [a-z]+",
    ], nodes.map(&:to_s)
  end

  def test_parse_text_and_match_and_regex
    nodes, errors = Fop::Parser.new('release/-|_/{N}').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      "[reg] -|_",
      "[exp] N",
    ], nodes.map(&:to_s)
  end

  def test_parse_multiple_text_and_match_and_regex
    nodes, errors = Fop::Parser.new('release/-|_/{N}/ +/FOO{N}').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      "[reg] -|_",
      "[exp] N",
      '[reg]  +',
      '[txt] FOO',
      '[exp] N',
    ], nodes.map(&:to_s)
  end

  def test_escaping
    nodes, errors = Fop::Parser.new('release\/-|_\/\{N\}').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release/-|_/{N}",
    ], nodes.map(&:to_s)
  end

  def test_escaping_slash_inside_regex
    nodes, errors = Fop::Parser.new('release/-|_|\//5').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      '[reg] -|_|/',
      "[txt] 5",
    ], nodes.map(&:to_s)
  end

  def test_escaping_special_chars_inside_regex
    nodes, errors = Fop::Parser.new('release/(\{\}){1}/').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      '[reg] (\{\}){1}',
    ], nodes.map(&:to_s)
  end

  def test_auto_escaping_regex_special_chars
    nodes, errors = Fop::Parser.new('release/[0-9]{2}/').parse
    assert_equal [], errors
    assert_equal [
      "[txt] release",
      '[reg] [0-9]{2}',
    ], nodes.map(&:to_s)
  end

  def test_syntax_error_unopened_exp
    _nodes, errors = Fop::Parser.new('release}asdf}').parse
    assert_equal [
      "Syntax error: Unexpected } at column 7",
      "Syntax error: Unexpected } at column 12",
    ], errors.map(&:to_s)
  end

  def test_syntax_error_unclosed_exp
    _nodes, errors = Fop::Parser.new('release{N').parse
    refute_equal [], errors
  end

  def test_syntax_error_unclosed_regex
    _nodes, errors = Fop::Parser.new('release/').parse
    refute_equal [], errors
  end

  def test_syntax_error_bad_regex
    _nodes, errors = Fop::Parser.new('release/[0-9').parse
    refute_equal [], errors
  end

  def test_syntax_error_trailing_escape
    _nodes, errors = Fop::Parser.new('release\\').parse
    refute_equal [], errors
  end
end