require "test_helper"

class UserTest < ActiveSupport::TestCase
  test "has an associated person" do
    assert_instance_of Person, users(:keith).person
  end

  test "has a last_cancelled_message but can be nil" do
    assert_equal messages(:dont_know_day), users(:keith).last_cancelled_message
    assert_nil users(:rob).last_cancelled_message
  end

  test "should not validate a new user without password" do
    user = User.new
    person = Person.new(email: "example@gmail.com", personable: user)
    refute person.valid?
  end

  test "encrypts openai_key" do
    user = users(:keith)
    old_openai_key = user.openai_key
    old_cipher_text = user.ciphertext_for(:openai_key)
    user.update!(openai_key: "new one")
    assert user.reload
    refute_equal old_cipher_text, user.ciphertext_for(:openai_key)
    assert_equal "new one", user.openai_key
  end

  test "encrypts anthropic_key" do
    user = users(:keith)
    old_anthropic_key = user.anthropic_key
    old_cipher_text = user.ciphertext_for(:anthropic_key)
    user.update!(anthropic_key: "new one")
    assert user.reload
    refute_equal old_cipher_text, user.ciphertext_for(:anthropic_key)
    assert_equal "new one", user.anthropic_key
  end

  test "should validate a user with minimum information" do
    user = User.new(password: "password", password_confirmation: "password", first_name: "John", last_name: "Doe")
    person = Person.new(email: "example@gmail.com", personable: user)
    assert person.valid?
  end

  test "should validate presence of first name" do
    user = users(:keith)
    user.update(first_name: nil)
    refute user.valid?
    assert_equal ["can't be blank"], user.errors[:first_name]
  end

  test "although last name is required for create it's not required for update" do
    assert_nothing_raised do
      users(:keith).update!(last_name: nil)
    end
  end

  test "it can update a user with a password" do
    user = users(:keith)
    old_password_hash = user.password_digest
    user.update(password: "password")
    assert user.valid?
    refute_equal old_password_hash, user.password_digest
  end

  test "it can update a user without a password" do
    user = users(:keith)
    old_password_hash = user.password_digest
    user.update(first_name: "New Name")
    assert user.valid?
    assert_equal old_password_hash, user.password_digest
  end

  test "passwords must be 6 characters or longer" do
    user = User.new(first_name: "John", last_name: "Doe")
    bad_short_passwords = ["", "12345"]

    bad_short_passwords.each do |bad_password|
      user.password = bad_password
      user.valid?
      assert user.errors[:password].present?
    end

    good_password = "123456"
    user.password = good_password
    assert user.valid?
    refute user.errors[:password].present?
  end

  test "it can validate a password" do
    user = users(:keith)
    assert user.authenticate("secret")
  end

  test "it destroys assistantes on destroy" do
    assistant = assistants(:samantha)
    assistant.user.destroy
    assert_raises ActiveRecord::RecordNotFound do
      assistant.reload
    end
  end

  test "it destroys conversations on destroy" do
    conversation = conversations(:greeting)
    conversation.user.destroy
    assert_raises ActiveRecord::RecordNotFound do
      conversation.reload
    end
  end

  test "boolean values within preferences get converted back and forth properly" do
    assert_nil users(:keith).preferences[:nav_closed]
    assert_nil users(:keith).preferences[:kids]
    assert_nil users(:keith).preferences[:city]

    users(:keith).update!(preferences: {
      nav_closed: true,
      kids: 2,
      city: "Austin"
    })
    users(:keith).reload

    assert users(:keith).preferences[:nav_closed]
    assert_equal 2, users(:keith).preferences[:kids]
    assert_equal "Austin", users(:keith).preferences[:city]

    users(:keith).update!(preferences: {
      nav_closed: "false",

    })

    refute users(:keith).preferences[:nav_closed]

  end

  test "dark_mode preference defaults to system and it can update user dark_mode preference" do
    new_user = User.create!(password: 'password', first_name: 'First', last_name: 'Last')
    assert_equal "system", new_user.preferences[:dark_mode]

    new_user.update!(preferences: { dark_mode: "light" })
    assert_equal "light", new_user.preferences[:dark_mode]

    new_user.update!(preferences: { dark_mode: "dark" })

    assert_equal "dark", new_user.preferences[:dark_mode]

    new_user.update!(preferences: { dark_mode: "system" })

    assert_equal "system", new_user.preferences[:dark_mode]

  end

end
