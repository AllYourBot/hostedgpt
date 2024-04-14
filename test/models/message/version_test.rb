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

  test "creating a message for a new conversation autosets the version & index properly" do
    Current.user = users(:keith)
    m0 = Message.create!(assistant: assistants(:samantha), content_text: "Hello")

    assert_equal 0, m0.index
    assert_equal 1, m0.version

    m1 = m0.conversation.messages.latest_version_for_conversation.last
    assert_equal 1, m1.index
    assert_equal 1, m1.version
  end

  test "creating a new message WITHOUT INDEX and WITHOUT VERSION on an existing multi-versioned conversation autosets version & index properly" do
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
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

    m = conversations(:versioned).messages.create!(index: 4, assistant: assistants(:samantha), content_text: "Do you like living in this city?")

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
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

    m = conversations(:versioned).messages.create!(index: 2, assistant: assistants(:samantha), content_text: "What is your name?")

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

  test "Take 3 of - creating a new messages for a SPECIFIC INDEX but WITHOUT VERSION autosets version properly - not creating a new version" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

    m = conversations(:versioned).messages.create!(index: 6, assistant: assistants(:samantha), content_text: "What is your name?")

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

  test "Take 4 of - creating a new messages for a SPECIFIC INDEX but WITHOUT VERSION autosets version properly - overwriting a previous version" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

    m = conversations(:versioned).messages.create!(index: 1, assistant: assistants(:samantha), content_text: "What is your name?")

    assert_equal 1, m.index
    assert_equal 2, m.version

    c = conversations(:versioned).messages.latest_version_for_conversation
    msg_versions = [
      0.1,
           1.2,
           2.2
    ]
    assert_equal msg_versions, c.map(&:full_version)

    c = conversations(:versioned).messages.for_conversation_version(2)
    assert_equal msg_versions, c.map(&:full_version)
  end

  test "creating a new message WITHOUT INDEX but SPECIFIED VERSION raises an error" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(version: 3, assistant: assistants(:samantha), content_text: "What is your name?")
    end
  end

  test "creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION succeeds" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

    m = conversations(:versioned).messages.create!(index: 2, version: 3, assistant: assistants(:samantha), content_text: "What is your name?")

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

  test "Take 2 - creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION succeeds - its hanging at the end" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    m = conversations(:versioned).messages.latest_version_for_conversation.last

    assert_equal 5, m.index
    assert_equal 2, m.version

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

  test "Take 3 - creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION succeeds - its the first one" do
    # See comment block in conversations.yml for :versioned to visualize the messages
    Current.user = users(:keith)
    c = Conversation.create!(user: users(:keith), assistant: assistants(:samantha))

    m = c.messages.create!(index: 0, version: 1, assistant: assistants(:samantha), content_text: "What is your name?")

    assert_equal 0, m.index
    assert_equal 1, m.version

    assert_equal [0.1, 1.1], c.messages.latest_version_for_conversation.map(&:full_version)
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
      conversations(:versioned).messages.create!(index: 4, version: 1, assistant: assistants(:samantha), content_text: "What is your name?")
    end
  end

  test "creating a new messages for a SPECIFIC INDEX and SPECIFIC VERSION fails if the INDEX is skipping a number" do
    Current.user = users(:keith)

    assert_raises ActiveRecord::RecordInvalid do
      conversations(:versioned).messages.create!(index: 7, version: 2, assistant: assistants(:samantha), content_text: "What is your name?")
    end
  end
end
