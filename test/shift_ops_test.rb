require 'test_helper'

class ShiftOpsTest < Minitest::Test
  def test_append
    f = Fop("A {N> 200} B")
    assert_equal [
      "Text A ",
      "N >  200",
      "Text  B",
    ], f.nodes.map(&:to_s)
    assert_equal "A 100 200 B", f.apply("A 100 B")
  end

  def test_prepend
    f = Fop("A {N<200 } B")
    assert_equal [
      "Text A ",
      "N < 200 ",
      "Text  B",
    ], f.nodes.map(&:to_s)
    assert_equal "A 200 100 B", f.apply("A 100 B")
  end
end
