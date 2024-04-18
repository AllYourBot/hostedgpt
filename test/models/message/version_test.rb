require "test_helper"

class Message::VersionTest < ActiveSupport::TestCase
  test "latest_version_for_conversation" do
    assert_equal 8, conversations(:versioned).messages.count
    assert_equal 6, conversations(:versioned).messages.latest_version_for_conversation.count
    assert_equal [0.1, 1.1, 2.2, 3.2, 4.2, 5.2],
      conversations(:versioned).messages.latest_version_for_conversation.map(&:full_version)
    assert_equal [0.1, 1.1, 2.2, 3.2, 4.2, 5.2],
      conversations(:versioned).messages.for_conversation_version(2).map(&:full_version)
  end

  test "for_conversation_version" do
    assert_equal [0.1, 1.1, 2.1, 3.1], conversations(:versioned).messages.for_conversation_version(1).map(&:full_version)
    assert_equal [0.1, 1.1, 2.2, 3.2, 4.2, 5.2], conversations(:versioned).messages.for_conversation_version(2).map(&:full_version)
  end

  test "creating a message with branched true FAILS if branched_from_version is null" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "What is your name?", index: 2, version: 3, branched: true)
    end
  end

  test "creating a message with branched_from_version specified FAILS if branched is not true" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "What is your name?", index: 2, version: 3, branched_from_version: 2)
    end
  end

  test "creating a message with branched true AND branched_from_version specified SUCCEEDS" do
    Current.user = users(:keith)
    conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "What is your name?", index: 2, version: 3, branched: true, branched_from_version: 2)
  end

  test "creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION fails if the VERSION is SKIPPING a number" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(index: 2, version: 4, assistant: assistants(:samantha), content_text: "What is your name?")
    end
  end

  test "creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION fails if the VERSION is EARLIER than it should be" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(index: 5, version: 1, assistant: assistants(:samantha), content_text: "What is your name?")
    end
  end

  test "creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION fails if the INDEX is skipping a number" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(index: 7, version: 2, assistant: assistants(:samantha), content_text: "What is your name?")
    end
  end

  test "creating a message for a new conversation autosets the version & index properly" do
    Current.user = users(:keith)
    m0 = Message.create!(assistant: assistants(:samantha), content_text: "Hello")

    assert_equal 0, m0.index
    assert_equal 1, m0.version

    m1 = m0.conversation.messages.latest_version_for_conversation.last
    assert_equal 1, m1.index
    assert_equal 1, m1.version
  end

  test "creating a new message WITHOUT INDEX and WITHOUT VERSION on an existing multi-versioned conversation autosets version & index properly — adding to end of last conversation" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

    m = conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "Do you like the food?")

    assert_equal 6, m.index
    assert_equal 2, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2,
           6.2,
           7.2
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(2)
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "creating a new messages for a SPECIFIC INDEX but WITHOUT VERSION autosets version properly - creating a new version where one does not exist" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "Do you like living in this city?", index: 4, branched: true, branched_from_version: 2)

    assert_equal 4, m.index
    assert_equal 3, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
                4.3,
                5.3
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(3)
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(2)
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "Take 2 of - creating a new messages for a SPECIFIC INDEX but WITHOUT VERSION autosets version properly - creating a new version where a branch already occurred" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "What is your name?", index: 2, branched: true, branched_from_version: 2)

    assert_equal 2, m.index
    assert_equal 3, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
      1.1,
                2.3,
                3.3
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(3)
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(2)
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "Take 3 of - creating a new messages for a SPECIFIC INDEX but WITHOUT VERSION autosets version properly - at the end so don't create a new version" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "What is your name?", index: 6)

    assert_equal 6, m.index
    assert_equal 2, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2,
           6.2,
           7.2
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(1)
    msg_versions = [
      0.1,
      1.1,
      2.1,
      3.1
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "Take 4 of - creating a new messages for a SPECIFIC INDEX but WITHOUT VERSION autosets version properly - when higher up in the chain" do
    # See comment block in conversations.yml for :versioned to visualize the messages

    # We're about to edit message #1 and what should get created is version 3 even though there is no version 2
    Current.user = users(:keith)
    m = conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "What is your name?", index: 1, branched: true, branched_from_version: 1)

    assert_equal 1, m.index
    assert_equal 3, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
               1.3,
               2.3
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(3)
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(2)
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "creating a new message WITHOUT INDEX but SPECIFIED VERSION raises an error" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(version: 3, assistant: assistants(:samantha), content_text: "What is your name?")
    end
  end

  test "creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION succeeds - the point it branches" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.create!(assistant: assistants(:samantha), content_text: "What is your name?", index: 2, version: 3, branched: true, branched_from_version: 1)

    assert_equal 2, m.index
    assert_equal 3, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
      1.1,
                2.3,
                3.3
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(3)
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(2)
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "Take 2 - creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION succeeds - at end of LATEST version branch" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.create!(index: 6, version: 2, assistant: assistants(:samantha), content_text: "What is your name?")

    assert_equal 6, m.index
    assert_equal 2, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2,
           6.2,
           7.2
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(1)
    msg_versions = [
      0.1,
      1.1,
      2.1,
      3.1
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "Take 3 - creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION succeeds - at end of PREVIOUS version branch" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

    m = conversations(:versioned).messages.create!(index: "4", version: "1", assistant: assistants(:samantha), content_text: "What is your name?")

    assert_equal 4, m.index
    assert_equal 1, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
           4.2,
           5.2,
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(1)
    msg_versions = [
      0.1,
      1.1,
      2.1,
      3.1,
      4.1,
      5.1,
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "Take 4 - creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION succeeds - its the first message in a conversation" do
    Current.user = users(:keith)
    c = Conversation.create!(user: users(:keith), assistant: assistants(:samantha))

    m = c.messages.create!(index: 0, version: 1, assistant: assistants(:samantha), content_text: "What is your name?")

    assert_equal 0, m.index
    assert_equal 1, m.version

    assert_equal [0.1, 1.1], c.messages.latest_version_for_conversation.map(&:full_version)
  end

  test "versions is empty at non-branch nodes ABOVE any branchess" do
    assert conversations(:versioned).messages.for_conversation_version(1).first.versions.empty?
    assert conversations(:versioned).messages.for_conversation_version(2).first.versions.empty?
    assert conversations(:versioned).messages.for_conversation_version(1).second.versions.empty?
    assert conversations(:versioned).messages.for_conversation_version(2).second.versions.empty?
  end

  test "versions is empty at non-branch nodes BELOW any branchess" do
    assert conversations(:versioned).messages.for_conversation_version(1).fourth.versions.empty?
    assert conversations(:versioned).messages.for_conversation_version(2).fourth.versions.empty?
  end

  test "versions is populated correctly at branch nodes" do
    assert_equal [1,2], conversations(:versioned).messages.for_conversation_version(1).third.versions
    assert_equal [1,2], conversations(:versioned).messages.for_conversation_version(2).third.versions
  end

  test "versioned2 - traverse a complex path in which an older branch was continued" do
    # See comment block in conversations.yml for :versioned2 to visualize the messages
    Current.user = users(:keith)
    c = conversations(:versioned2).messages.for_conversation_version(4)
    msg_versions = [
      0.1,
      1.1,
           2.2,
           3.2,
                4.4,
    ]
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "versioned2 - continue a conversation on an older branch" do
    # See comment block in conversations.yml for :versioned2 to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned2).messages.create!(assistant: assistants(:samantha), content_text: "hello", role: :assistant, index: 3, version: 1)

    assert_equal 3, m.index
    assert_equal 1, m.version

    m2 = conversations(:versioned2).messages.create!(assistant: assistants(:samantha), content_text: "hello edited", role: :user, index: 3, branched: true, branched_from_version: 1)

    assert_equal 3, m2.index
    assert_equal 6, m2.version

    c = conversations(:versioned2).messages.for_conversation_version(6)
    msg_versions = [
      0.1,
      1.1,
      2.1,
                          3.6,
                          4.6,
    ]
    assert_equal msg_versions, c.map(&:full_version)

    m3 = conversations(:versioned2).messages.create!(assistant: assistants(:samantha), content_text: "hello edited", role: :user, index: 2, branched: true, branched_from_version: 5)

    assert_equal 2, m3.index
    assert_equal 7, m3.version
    assert_equal msg_versions, c.reload.map(&:full_version)
  end
end
