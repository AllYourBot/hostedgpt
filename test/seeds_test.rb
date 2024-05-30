require 'test_helper'

class SeedsTest < ActiveSupport::TestCase
  def setup
    Rails.application.load_seed 
  end

  test 'seeds run without errors' do
    assert_nothing_raised do
      load Rails.root.join('db', 'seeds.rb')
    end
  end

  test 'seeds created the expected data' do
    load Rails.root.join('db', 'seeds.rb')

    assert LanguageModel.count > 0, "Expected at least one LanguageModel to be created"
    assert Assistant.count > 0, "Expected at least one Assistant to be created"
  end
end