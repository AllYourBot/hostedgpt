require "test_helper"

class RegistrationContextTest < ActiveSupport::TestCase
  def user_params
    { password: "1234#{SecureRandom.alphanumeric(5)}" }
  end

  def person_params
    { email: "example@g.com" }
  end

  test "it creates user and person when valid" do
    context = RegistrationContext.new person_params, user_params

    assert context.run
    assert_instance_of User, context.user
    assert_instance_of Person, context.person
  end

  test "it returns errors when password is invalid" do
    context = RegistrationContext.new person_params, {password: ""}
    refute context.run
    assert context.errors[:password].present?
  end

  test "it returns errors when email is invalid" do
    context = RegistrationContext.new({ email: "" }, user_params)
    refute context.run
    assert context.errors[:email].present?
  end

  test "it doesn't create the user or person when invalid" do
    context = RegistrationContext.new({ email: "" }, { password: "" })

    assert_no_changes "User.count" do
      assert_no_changes "Person.count" do
        refute context.run
      end
    end
  end

  test "it creates an assistant and a coversation when valid" do
    context = RegistrationContext.new person_params, user_params
    assert context.run

    assert_instance_of Conversation, context.first_conversation
  end
end
