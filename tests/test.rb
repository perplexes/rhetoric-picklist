require "minitest/autorun"
require_relative "../picklist"

class TestPickList < Minitest::Test
  def test_that_non_ascii_pick_works
    order_string = File.read("tests/fixtures/orders 2018-06-16.csv")
    line_items_string = File.read("tests/fixtures/line items 2018-06-16.csv")
    lines = Picklist.parse(order_string, line_items_string)
    actual = lines.join("\n")
    # File.open("tests/fixtures/pick list 2018-06-16.csv", "wb") do |file|
    #   file.print(picklist_string)
    # end
    expected = File.read("tests/fixtures/pick list 2018-06-16.csv")

    assert_equal expected, actual
  end
end
