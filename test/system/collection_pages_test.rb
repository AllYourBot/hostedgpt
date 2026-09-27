require "application_system_test_case"

# U9: card toggles on the full pages morph the card without a reload, and the sidebar
# open-page buttons navigate to their pages.
class CollectionPagesTest < ApplicationSystemTestCase
  test "card bookmark toggle flips in place without a reload" do
    user = users(:keith)
    conversation = conversations(:greeting)
    conversation.pin!(user)

    login_as(user)
    visit pinned_page_path
    path_before = current_path

    card = find("#card_conversation_#{conversation.id}")
    card.find("[data-role='bookmark']").click

    assert_selector("#card_conversation_#{conversation.id} [data-role='unbookmark']")
    assert_equal path_before, current_path
    assert conversation.reload.bookmarked?(user)
  end

  test "sidebar open-page buttons navigate to their pages" do
    user = users(:keith)
    conversations(:greeting).pin!(user)

    login_as(user)
    visit root_path

    find("[data-role='open-bookmarks-page']").click
    assert_selector("h1", text: I18n.t("app.conversations.ui.bookmarked_page_title"))
  end
end
