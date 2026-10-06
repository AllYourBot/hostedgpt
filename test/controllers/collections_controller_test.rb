require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:keith)
    login_as @user
  end

  test "index shows a box with the name and description of each of the user's collections" do
    get collections_url

    assert_response :success
    assert_select "#conversation #{selector_for(collections(:recipes))}" do
      assert_select "a[href='#{edit_collection_path(collections(:recipes))}'][data-turbo-frame='_top']"
      assert_select "[data-role='name']", "Recipes"
      assert_select "[data-role='description']", "Weeknight dinners and family favorites"
    end
  end

  test "index leaves out another user's collections" do
    get collections_url

    assert_select "#conversation #{selector_for(collections(:taxes))}", count: 0
  end

  test "sidebar lists the user's collections under a link to the collections page" do
    get new_assistant_message_url(@user.assistants.ordered.first)

    assert_select "#collections a[href='#{collections_path}']", text: "Collections"
    assert_select "#collections menu a[data-role='new-collection'][href='#{new_collection_path}']", "New Collection"
    assert_select "#collections a[data-role='collection'][href='#{edit_collection_path(collections(:recipes))}']", "Recipes"
  end

  test "sidebar hides collections past the first few behind a show all button" do
    Collection::MAX_LIST_DISPLAY.times { |x| @user.collections.create!(name: "Shelf #{x + 1}") }

    get new_assistant_message_url(@user.assistants.ordered.first)

    @user.collections.ordered.each_with_index do |collection, index|
      hidden = index >= Collection::MAX_LIST_DISPLAY
      assert_select "#collections a.hidden#{selector_for(collection)}", { count: hidden ? 1 : 0 }, "#{collection.name} hidden should be #{hidden}"
    end
    assert_select "#collections button[data-role='show-all-collections']:not(.hidden)", "Show All"
  end

  test "sidebar hides the show all button when there are only a few collections" do
    get new_assistant_message_url(@user.assistants.ordered.first)

    assert_select "#collections button.hidden[data-role='show-all-collections']"
  end

  test "new shows the form beside the main sidebar rather than the settings menu" do
    get new_collection_url

    assert_response :success
    assert_contains_text "main", "New Collection"
    assert_select "#nav-container #collections"
    assert_select "#nav-container section#menu", false, "settings menu should not render"
  end

  test "should create collection" do
    assert_difference("Collection.count") do
      post collections_url, params: { collection: { name: "Books", description: "To read this year" } }
    end

    collection = Collection.last
    assert_redirected_to edit_collection_url(collection)
    assert_equal [@user, "Books", "To read this year"], [collection.user, collection.name, collection.description]
  end

  test "create shows errors when the name IS BLANK" do
    assert_no_difference("Collection.count") do
      post collections_url, params: { collection: { name: "" } }
    end

    assert_response :unprocessable_content
    assert_contains_text "main", "Name can't be blank"
  end

  test "edit shows the form beside the main sidebar rather than the settings menu" do
    get edit_collection_url(collections(:recipes))

    assert_response :success
    assert_select "input#collection_name[value='Recipes']"
    assert_select "input#collection_description[value='Weeknight dinners and family favorites']"
    assert_select "#nav-container #collections a[data-role='collection']", "Recipes"
    assert_select "#files ##{ActionView::RecordIdentifier.dom_id(documents(:lasagna_recipe))}", /lasagna.pdf/
    assert_select "#files form[action='#{collection_documents_path(collections(:recipes))}'] input[type=file]"
    assert_select "#nav-container section#menu", false, "settings menu should not render"
  end

  test "should update collection" do
    patch collection_url(collections(:recipes)), params: { collection: { name: "Dinners", description: "Quick ones" } }

    assert_redirected_to edit_collection_url(collections(:recipes))
    assert_equal ["Dinners", "Quick ones"], collections(:recipes).reload.slice(:name, :description).values
  end

  test "update shows errors when the name IS BLANK" do
    patch collection_url(collections(:recipes)), params: { collection: { name: "" } }

    assert_response :unprocessable_content
    assert_contains_text "main", "Name can't be blank"
  end

  test "should destroy collection" do
    assert_difference("Collection.count", -1) do
      delete collection_url(collections(:recipes))
    end

    assert_redirected_to collections_url
  end

  test "edit redirects to collections when the collection BELONGS TO ANOTHER USER" do
    get edit_collection_url(collections(:taxes))

    assert_redirected_to collections_url
  end

  private

  def selector_for(collection) = "##{ActionView::RecordIdentifier.dom_id(collection)}"
end
