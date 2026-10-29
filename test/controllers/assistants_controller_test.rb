require "test_helper"

class AssistantsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:keith)
    @assistant = @user.assistants.ordered.first
    login_as @user
  end

  test "index redirects to conversation if assistants_page is disabled" do
    stub_features(assistants_page: false) do
      get assistants_url
    end
    assert_redirected_to new_assistant_message_path(@assistant)
  end

  test "index shows assistants if assistants_page is enabled" do
    stub_features(assistants_page: true) do
      get assistants_url
    end
    assert_response :success
  end

  test "index puts a New Assistant link beside the Assistants heading in the nav column" do
    stub_features(assistants_page: true) do
      get assistants_url
    end
    assert_response :success
    assert_select "a[href=?]", assistants_path, { text: I18n.t("app.navigation.assistants") }, "The Assistants heading should still link to the assistants page"
    assert_select "a[data-role='new-assistant'][href=?] [data-tip=?]", new_settings_assistant_path, I18n.t("app.settings.assistants.menu.new"), { count: 1 }, "The Assistants heading should have a plus icon that opens the New Assistant page"
  end

  test "index should mark the assistant cards that HAVE context files" do
    stub_features(assistants_page: true) do
      get assistants_url
    end
    assert_response :success

    assert_select "#card_assistant_#{assistants(:samantha).id} [data-role='context-files'][title=?]", I18n.t("app.assistants.ui.context_files"), { count: 1 },
      "The card of the assistant with an uploaded context file should show the context files icon"
    assert_select "[id^='card_assistant_'] [data-role='context-files']", { count: 1 }, "Cards of assistants without context files should not show the icon"
  end

  test "index redirects to conversation on a mobile device even if assistants_page is enabled" do
    stub_features(assistants_page: true) do
      get assistants_url, headers: { "User-Agent" => "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1" }
    end
    assert_redirected_to new_assistant_message_path(@assistant)
  end

  test "reorder saves the order the ids arrive in" do
    ids = @user.assistants.ordered.pluck(:id).rotate

    post reorder_assistants_url, params: { ids: ids }

    assert_response :no_content
    assert_equal ids, @user.assistants.ordered.pluck(:id)
  end

  test "reorder leaves another user's assistants alone" do
    rob_assistant = assistants(:rob_gpt4)

    post reorder_assistants_url, params: { ids: [rob_assistant.id] }

    assert_response :no_content
    assert_nil rob_assistant.reload.position
  end
end
