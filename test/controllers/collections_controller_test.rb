require "test_helper"

class CollectionsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:keith)
    @recipes = collections(:recipes)
    login_as @user
  end

  test "index shows a box with the name and description of each of the user's collections" do
    get collections_url

    assert_response :success
    assert_select "#conversation #{selector_for(@recipes)}", 1, "The recipes collection should have a box" do
      assert_select "a[href='#{edit_collection_path(@recipes)}'][data-turbo-frame='_top']", 1, "The box should link out of the conversation frame to the edit page"
      assert_select "[data-role='name']", "Recipes"
      assert_select "[data-role='description']", "Weeknight dinners and family favorites"
    end
  end

  test "index leaves out another user's collections" do
    get collections_url

    assert_select "#conversation #{selector_for(collections(:taxes))}", { count: 0 }, "Rob's collection should not be listed for Keith"
  end

  test "sidebar lists the user's collections under a link to the collections page" do
    get new_assistant_message_url(@user.assistants.ordered.first)

    assert_select "#collections a[href='#{collections_path}']", { text: "Collections" }, "The heading should link to the collections page"
    assert_select "#collections menu a[data-role='new-collection'][href='#{new_collection_path}']", { text: "New Collection" }, "The dots menu should offer New Collection"
    assert_select "#collections a[data-role='collection'][href='#{edit_collection_path(@recipes)}']", { text: "Recipes" }, "Each collection should link to its edit page"
  end

  test "sidebar hides collections past the first few behind a show all button" do
    Collection::MAX_LIST_DISPLAY.times { |x| @user.collections.create!(name: "Shelf #{x + 1}") }

    get new_assistant_message_url(@user.assistants.ordered.first)

    @user.collections.ordered.each_with_index do |collection, index|
      hidden = index >= Collection::MAX_LIST_DISPLAY
      assert_select "#collections a.hidden#{selector_for(collection)}", { count: hidden ? 1 : 0 }, "#{collection.name} hidden should be #{hidden}"
    end
    assert_select "#collections button[data-role='show-all-collections']:not(.hidden)", { text: "Show All" }, "Show All should be visible when collections are hidden"
  end

  test "sidebar hides the show all button when there are only a few collections" do
    get new_assistant_message_url(@user.assistants.ordered.first)

    assert_select "#collections button.hidden[data-role='show-all-collections']", 1, "Show All should be hidden when every collection fits"
  end

  test "new shows the form beside the main sidebar rather than the settings menu" do
    get new_collection_url

    assert_response :success
    assert_contains_text "main", "New Collection"
    assert_select "#nav-container #collections", 1, "The main sidebar should render"
    assert_select "#nav-container section#menu", false, "The settings menu should not render"
  end

  test "should create collection" do
    assert_difference("Collection.count") do
      post collections_url, params: { collection: { name: "Books", description: "To read this year" } }
    end

    collection = Collection.last
    assert_redirected_to edit_collection_url(collection)
    assert_equal [@user, "Books", "To read this year"], [collection.user, collection.name, collection.description], "The collection should be saved for the current user"
  end

  test "create shows errors when the name IS BLANK" do
    assert_no_difference("Collection.count") do
      post collections_url, params: { collection: { name: "" } }
    end

    assert_response :unprocessable_content
    assert_contains_text "main", "Name can't be blank"
  end

  test "edit shows the form and files beside the main sidebar rather than the settings menu" do
    get edit_collection_url(@recipes)

    assert_response :success
    assert_select "input#collection_name[value='Recipes']", 1, "The name field should be filled in"
    assert_select "input#collection_description[value='Weeknight dinners and family favorites']", 1, "The description field should be filled in"
    assert_select "#files #{selector_for(documents(:lasagna_recipe))}", /lasagna.pdf/, "The uploaded file should be listed"
    assert_select "#files form[action='#{collection_documents_path(@recipes)}'] input[type=file]", 1, "There should be an upload form"
    assert_select "#nav-container #collections a[data-role='collection']", { text: "Recipes" }, "The main sidebar should render"
    assert_select "#nav-container section#menu", false, "The settings menu should not render"
  end

  test "edit says there are no files when the collection HAS NO FILES" do
    @recipes.documents.destroy_all

    get edit_collection_url(@recipes)

    assert_contains_text "#files", "No files uploaded yet."
  end

  test "should update collection" do
    patch collection_url(@recipes), params: { collection: { name: "Dinners", description: "Quick ones" } }

    assert_redirected_to edit_collection_url(@recipes)
    assert_equal ["Dinners", "Quick ones"], @recipes.reload.slice(:name, :description).values, "The name and description should be updated"
  end

  test "update shows errors when the name IS BLANK" do
    patch collection_url(@recipes), params: { collection: { name: "" } }

    assert_response :unprocessable_content
    assert_contains_text "main", "Name can't be blank"
  end

  test "should destroy collection" do
    assert_difference("Collection.count", -1) do
      delete collection_url(@recipes)
    end

    assert_redirected_to collections_url
  end

  test "edit redirects to collections when the collection BELONGS TO ANOTHER USER" do
    get edit_collection_url(collections(:taxes))

    assert_redirected_to collections_url
  end

  private

  def selector_for(record) = "##{ActionView::RecordIdentifier.dom_id(record)}"
end
