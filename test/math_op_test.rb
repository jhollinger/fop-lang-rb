require 'test_helper'

class MathOpTest < Minitest::Test
  def test_add_one
    f = Fop("release-{N}.{N+1}.{N=0}")
    assert_equal [
      "Text release-",
      "N",
      "Text .",
      "N + 1",
      "Text .",
      "N = 0",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.121.0", f.apply("release-5.120.1")
  end

  def test_add_one_hundred
    f = Fop("release-{N}.{N+100}.{N=0}")
    assert_equal [
      "Text release-",
      "N",
      "Text .",
      "N + 100",
      "Text .",
      "N = 0",
    ], f.nodes.map(&:to_s)
    assert_equal "release-5.220.0", f.apply("release-5.120.1")
  end
end
