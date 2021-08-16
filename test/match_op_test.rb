require 'test_helper'

class MatchOpTest < Minitest::Test
  def test_numeric_match
    f = Fop.compile("release-{N}.{N}.0")
    assert_equal [
      "Text release-",
      "N",
      "Text .",
      "N",
      "Text .0",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.125.0", f.apply("release-5.125.0")
    assert_nil f.apply("release-N.125.0")
  end

  def test_numeric_match_with_wildcard
    f = Fop.compile("release-{N}.*{N}.0")
    assert_equal [
      "Text release-",
      "N",
      "Text .",
      "*N",
      "Text .0",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.125.0", f.apply("release-5.125.0")
    assert_equal "release-5.fffffff125.0", f.apply("release-5.fffffff125.0")
    assert_nil f.apply("release-N.125.0")
  end

  def test_alpha_match
    f = Fop.compile("release-{A}.{A}.Z")
    assert_equal [
      "Text release-",
      "A",
      "Text .",
      "A",
      "Text .Z",
    ], f.nodes.map(&:to_s)
    assert_equal "release-A.B.Z", f.apply("release-A.B.Z")
    assert_equal "release-Aasdf.Basdf.Z", f.apply("release-Aasdf.Basdf.Z")
    assert_nil f.apply("release-5.125.Z")
  end

  def test_alpha_match_with_wildcard
    f = Fop.compile("release-{A}.*{A}.Z")
    assert_equal [
      "Text release-",
      "A",
      "Text .",
      "*A",
      "Text .Z",
    ], f.nodes.map(&:to_s)
    assert_equal "release-A.B.Z", f.apply("release-A.B.Z")
    assert_equal "release-A.11010101Baa.Z", f.apply("release-A.11010101Baa.Z")
    assert_nil f.apply("release-W.125.Z")
  end

  def test_word_match
    f = Fop.compile("release-{W}.{W}.Z")
    assert_equal [
      "Text release-",
      "W",
      "Text .",
      "W",
      "Text .Z",
    ], f.nodes.map(&:to_s)
    assert_equal "release-A.Bbbb.Z", f.apply("release-A.Bbbb.Z")
    assert_equal "release-A.B_bbb.Z", f.apply("release-A.B_bbb.Z")
    assert_equal "release-A.9_bbb.Z", f.apply("release-A.9_bbb.Z")
    assert_nil f.apply("release-A.-.Z")
  end

  def test_regex_match
    f = Fop('rel{/(ease)?/}-{N}.{N}.{N}')
    assert_equal [
      "Text rel",
      "/(ease)?/",
      "Text -",
      "N",
      "Text .",
      "N",
      "Text .",
      "N",
    ], f.nodes.map(&:to_s)
    assert_equal "release-1.1.1", f.apply("release-1.1.1")
    assert_equal "rel-1.1.1", f.apply("rel-1.1.1")
    assert_nil f.apply("rel1.1.1")
  end

  def test_regex_match_with_slash
    f = Fop('rel{/(\/ease)?/}-{N}.{N}.{N}')
    assert_equal [
      "Text rel",
      '/(/ease)?/',
      "Text -",
      "N",
      "Text .",
      "N",
      "Text .",
      "N",
    ], f.nodes.map(&:to_s)
    assert_equal "rel/ease-1.1.1", f.apply("rel/ease-1.1.1")
    assert_nil f.apply("release-1.1.1")
  end

  def test_regex_with_brace
    f = Fop('rel{/(ease){0,2}/}-{N}.{N}.{N}')
    assert_equal [
      "Text rel",
      '/(ease){0,2}/',
      "Text -",
      "N",
      "Text .",
      "N",
      "Text .",
      "N",
    ], f.nodes.map(&:to_s)
    assert_equal "rel-1.1.1", f.apply("rel-1.1.1")
    assert_equal "release-1.1.1", f.apply("release-1.1.1")
    assert_equal "releaseease-1.1.1", f.apply("releaseease-1.1.1")
    assert_nil f.apply("releaseeaseease-1.1.1")
  end
end
