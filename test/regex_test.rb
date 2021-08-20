require 'test_helper'

class RegexTest < Minitest::Test
  def test_text_and_regex
    f = Fop("release/-|_/5")
    assert_equal "release-5", f.apply("release-5")
    assert_equal "release_5", f.apply("release_5")
    assert_nil f.apply("release#5")
  end

  def test_text_and_regex_with_captures
    f = Fop("{/(release)-([0-9]+)/=$2-$1}")
    assert_equal "5-release", f.apply("release-5")
    assert_nil f.apply("foo-5")
  end
end
