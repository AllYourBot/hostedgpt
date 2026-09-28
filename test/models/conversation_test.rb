require "test_helper"

class ConversationTest < ActiveSupport::TestCase
  test "has an associated user" do
    assert_instance_of User, conversations(:greeting).user
  end

  test "has an associated assistant" do
    assert_instance_of Assistant, conversations(:greeting).assistant
  end

  test "has associated messages" do
    assert_instance_of Message, conversations(:greeting).messages.first
  end

  test "has associated runs" do
    assert_instance_of Run, conversations(:greeting).runs.first
  end

  test "has associated steps" do
    assert_instance_of Step, conversations(:greeting).steps.first
  end

  test "has associated last_assistant_message but can also be nil" do
    c = Conversation.create!(user: users(:keith), assistant: assistants(:samantha))
    assert_nil c.last_assistant_message
    assert_instance_of Message, conversations(:greeting).last_assistant_message
  end

  test "simple create works" do
    assert_nothing_raised do
      Conversation.create!(
        user: users(:keith),
        assistant: assistants(:samantha)
      )
    end
  end

  test "Conversation should not be created with duplicate external ids" do
    Conversation.create!(
      user: users(:keith),
      assistant: assistants(:samantha),
      external_id: "dup1"
    )

    assert_raise ActiveRecord::RecordNotUnique do
      Conversation.create!(
        user: users(:keith),
        assistant: assistants(:mandela_gpt4),
        external_id: "dup1"
      )
    end
  end

  test "associations are deleted upon destroy" do
    conversation = conversations(:greeting)
    message_count = conversation.messages.count * -1
    run_count = conversation.runs.count * -1
    step_count = conversation.steps.count * -1

    assert_difference "Message.count", message_count do
      assert_difference "Run.count", run_count do
        assert_difference "Step.count", step_count do
          conversations(:greeting).destroy
        end
      end
    end
  end

  test "conversations are destroyed when user is destroyed" do
    conversation = conversations(:greeting)
    conversation.user.destroy
    assert_raises ActiveRecord::RecordNotFound do
      conversation.reload
    end
  end

  test "the title of a conversation is automatically set when the second message is created by the job" do
    assistants(:samantha).language_model.update!(supports_tools: false)

    perform_enqueued_jobs do
      TestClient::OpenAI.stub :text, "{\"topic\":\"Hear me\"}" do
        conversation = users(:keith).conversations.create!(assistant: assistants(:samantha))
        assert_nil conversation.title

        conversation.messages.create!(assistant: conversation.assistant, role: :user, content_text: "Can you hear me?")

        latest_message = conversation.latest_message_for_version(:latest)
        assert latest_message.assistant?

        GetNextAIMessageJob.perform_now(users(:keith).id, latest_message.id, assistants(:samantha).id)

        assert_equal "Hear me", conversation.reload.title
      end
    end
  end

  test "#matching_query matches titles and message content" do
    user = users(:keith)

    found = user.conversations.matching_query("test").map(&:id).sort

    assert_equal [
      conversations(:attachment).id,  # matches title
      conversations(:attachments).id, # matches title
      conversations(:ruby_version).id # matches "test" inside "latest" in message content
    ].sort, found
  end

  test "#matching_query treats % and _ as literal characters, not patterns" do
    user = users(:keith)
    percent = user.conversations.create!(assistant: assistants(:samantha), title: "100% coverage")
    underscore = user.conversations.create!(assistant: assistants(:samantha), title: "plain")
    underscore.messages.create!(assistant: assistants(:samantha), role: :user, content_text: "snake_case notes")
    plain = user.conversations.create!(assistant: assistants(:samantha), title: "plain alpha beta")

    assert_includes user.conversations.matching_query("%").map(&:id), percent.id
    assert_not_includes user.conversations.matching_query("%").map(&:id), plain.id
    assert_includes user.conversations.matching_query("_").map(&:id), underscore.id
    assert_not_includes user.conversations.matching_query("_").map(&:id), plain.id
  end

  test ".reacted_nav_for_user is empty when the user reacted to nothing" do
    user = User.create!(first_name: "John", last_name: "Doe")

    assert_empty Conversation.reacted_nav_for_user(user)
  end

  test "ordered follows position once conversations have been dragged into shape" do
    user = users(:keith)
    ids = user.conversations.ordered.pluck(:id).rotate
    Conversation.reposition(user, ids)

    assert_equal ids, user.conversations.ordered.pluck(:id)
  end

  test "#grouped_by_increasing_time_interval_for_user restores the six recency groups with pins excluded" do
    Timecop.freeze(Time.current.beginning_of_day + 12.hours) do
      user = User.create!(first_name: "John", last_name: "Doe")
      stamp_for = {
        "Today" => Time.current,
        "Yesterday" => 1.day.ago,
        "This Week" => 3.days.ago,
        "This Month" => 2.weeks.ago,
        "Last Month" => 6.weeks.ago,
        "Older" => 1.year.ago
      }
      by_group = stamp_for.transform_values do |at|
        conversation = user.conversations.create!(assistant: assistants(:samantha))
        conversation.update_column(:updated_at, at)
        conversation
      end

      grouped = Conversation.grouped_by_increasing_time_interval_for_user(user)

      assert_equal stamp_for.keys, grouped.keys
      stamp_for.each_key do |group|
        assert_equal [by_group[group].id], grouped[group].map(&:id), "expected only this conversation in #{group}"
      end

      by_group["Today"].pin!(user)

      regrouped = Conversation.grouped_by_increasing_time_interval_for_user(user)
      assert_not_includes regrouped.keys, "Today"
      assert_not_includes regrouped.values.flat_map { |rel| rel.map(&:id) }, by_group["Today"].id
      assert_includes Conversation.pinned_for(user).map(&:id), by_group["Today"].id
    end
  end

  test "nav_for_user orders unpinned conversations by recency, not hand position" do
    user = users(:keith)
    old = conversations(:greeting)
    newer = conversations(:ruby_version)
    old.update_column(:updated_at, 1.month.ago)
    newer.update_column(:updated_at, 1.day.ago)
    old.update_column(:position, -9999) # top by hand order, stale by recency

    ids = Conversation.nav_for_user(user).map(&:id)

    assert ids.index(newer.id) < ids.index(old.id), "expected recency order, not position order"
  end

  test "a reply moves its conversation to the top of the most recent group" do
    user = users(:keith)
    old = conversations(:greeting)
    old.update_column(:updated_at, 1.month.ago)
    assert_not_equal old.id, Conversation.nav_for_user(user).first.id

    Current.user = user
    old.messages.create!(assistant: old.assistant, role: :user, content_text: "still thinking about this")

    grouped = Conversation.grouped_by_increasing_time_interval_for_user(user)
    assert_equal old.id, grouped["Today"].first.id
    assert_equal old.id, Conversation.nav_for_user(user).first.id
  end

  test "a reply in a pinned conversation leaves pin order unchanged" do
    user = users(:keith)
    first = conversations(:greeting)
    second = conversations(:ruby_version)
    first.pin!(user)
    second.pin!(user)
    order_before = Conversation.pinned_for(user).pluck(:id, :position)

    Current.user = user
    second.messages.create!(assistant: second.assistant, role: :user, content_text: "hello again")

    assert_equal order_before, Conversation.pinned_for(user).pluck(:id, :position)
  end

  test "sidebar nav scopes preload toggle state with no per-row queries" do
    user = users(:keith)
    other = users(:rob)
    pinned = conversations(:greeting)
    bookmarked = conversations(:ruby_version)
    pinned.pin!(user)
    bookmarked.bookmark!(user)
    pinned.react!("❤️", user)
    pinned.react!("👍", other)

    scopes = {
      "unpinned list" => Conversation.nav_for_user(user),
      "pinned section" => Conversation.pinned_nav_for_user(user),
      "bookmarks view" => Conversation.bookmarked_nav_for_user(user),
      "reactions view" => Conversation.reacted_nav_for_user(user),
      "search" => Conversation.nav_for_user(user, "test")
    }

    scopes.each do |name, scope|
      rows = scope.to_a
      assert_not_empty rows, "expected rows for #{name}"

      assert_no_queries do
        rows.each do |conversation|
          conversation.pinned?(user)
          conversation.bookmarked?(user)
          conversation.user_reacted?("❤️", user)
          conversation.reaction_counts
          conversation.user_emojis(user)
        end
      end
    end

    # The preloaded answers match the database answers.
    assert_not_includes Conversation.nav_for_user(user).map(&:id), pinned.id
    assert_includes Conversation.pinned_nav_for_user(user).map(&:id), pinned.id

    preloaded_pin = Conversation.pinned_nav_for_user(user).find(pinned.id)
    assert preloaded_pin.pinned?(user)
    assert_not preloaded_pin.bookmarked?(user)
    assert preloaded_pin.user_reacted?("❤️", user)
    assert_not preloaded_pin.user_reacted?("❤️", other)
    assert_equal({ "❤️" => 1, "👍" => 1 }, preloaded_pin.reaction_counts)
    assert_equal Set["❤️"], preloaded_pin.user_emojis(user)
    assert_equal Set["👍"], preloaded_pin.user_emojis(other)

    preloaded_bookmark = Conversation.bookmarked_nav_for_user(user).find(bookmarked.id)
    assert preloaded_bookmark.bookmarked?(user)
    assert_not preloaded_bookmark.pinned?(user)
  end

  test "sidebar nav scopes preload toggle associations instead of includes" do
    user = users(:keith)
    pinned = conversations(:greeting)
    bookmarked = conversations(:ruby_version)
    pinned.pin!(user)
    bookmarked.bookmark!(user)
    pinned.react!("❤️", user)
    bookmarked.react!("❤️", user)

    scopes = {
      "unpinned list" => Conversation.nav_for_user(user),
      "pinned section" => Conversation.pinned_nav_for_user(user),
      "bookmarks view" => Conversation.bookmarked_nav_for_user(user),
      "reactions view" => Conversation.reacted_nav_for_user(user),
      "search" => Conversation.nav_for_user(user, "test"),
      "bookmarks search" => Conversation.bookmarked_nav_for_user(user, "test"),
      "reactions search" => Conversation.reacted_nav_for_user(user, "test")
    }

    scopes.each do |name, scope|
      assert_not_empty scope.to_a, "expected rows for #{name}"
      assert_empty scope.includes_values, "expected no includes on #{name} (preload keeps the DISTINCT shape)"
      %w[assistant pins bookmarks reactions].each do |association|
        assert_includes scope.preload_values.map(&:to_s), association, "expected #{association} preloaded on #{name}"
      end
    end
  end

  test "bookmarked_nav_for_user narrows by search before applying membership" do
    user = users(:keith)
    match = user.conversations.create!(assistant: assistants(:samantha), title: "Bookmark probe alpha zeta9")
    other = user.conversations.create!(assistant: assistants(:samantha), title: "Bookmark probe unrelated qwerty7")
    match.bookmark!(user)
    other.bookmark!(user)

    found = Conversation.bookmarked_nav_for_user(user, "zeta9").map(&:id)

    assert_includes found, match.id
    assert_not_includes found, other.id
  end

  test "reacted_nav_for_user narrows by search before applying membership" do
    user = users(:keith)
    match = user.conversations.create!(assistant: assistants(:samantha), title: "Reaction probe alpha zeta8")
    other = user.conversations.create!(assistant: assistants(:samantha), title: "Reaction probe unrelated qwerty6")
    match.react!("❤️", user)
    other.react!("❤️", user)

    found = Conversation.reacted_nav_for_user(user, "zeta8").map(&:id)

    assert_includes found, match.id
    assert_not_includes found, other.id
  end

  test "pinned_nav_for_user is empty during search even with pins present" do
    user = users(:keith)
    pinned = conversations(:greeting)
    pinned.pin!(user)

    assert_includes Conversation.pinned_nav_for_user(user).map(&:id), pinned.id
    assert_empty Conversation.pinned_nav_for_user(user, "test")
    assert_empty Conversation.pinned_nav_for_user(user, "Meeting")
  end

  test "sidebar nav query shape stays constant as lists grow" do
    user = users(:keith)

    baseline = count_sidebar_queries(user, nil)
    baseline_search = count_sidebar_queries(user, "test")

    5.times do |i|
      user.conversations.create!(assistant: assistants(:samantha), title: "Growth probe #{i}")
    end

    assert_equal baseline, count_sidebar_queries(user, nil), "expected constant query shape as the list grows"
    assert_equal baseline_search, count_sidebar_queries(user, "test"), "expected constant query shape as the list grows"
  end

  private

  def count_sidebar_queries(user, query)
    counter = 0
    subscriber = ActiveSupport::Notifications.subscribe("sql.active_record") do |*, payload|
      counter += 1 unless payload[:cached] || payload[:name] == "SCHEMA"
    end
    Conversation.nav_for_user(user, query).to_a.each do |conversation|
      conversation.pinned?(user)
      conversation.bookmarked?(user)
      conversation.user_reacted?("❤️", user)
      conversation.reaction_counts
      conversation.user_emojis(user)
    end
    counter
  ensure
    ActiveSupport::Notifications.unsubscribe(subscriber)
  end
end
