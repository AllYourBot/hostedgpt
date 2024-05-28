module ViewHelpers

  private

  def assert_contains_text(selector, text)
    assert_select selector, 1, "#{selector} was not found" do |element|
      assert element.text.include?(text), "Element #{selector} did not contain '#{text}' (#{element.text.remove("\n")})"
    end
  end
end
