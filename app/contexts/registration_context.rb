class RegistrationContext < ApplicationContext
  attr_reader :user, :person, :first_conversation

  # person_params and user_params are ActiveModel::Parameters objects
  # or at a minimum a Hash of attributes
  def initialize(person_params, user_params)
    super()

    @person_params = person_params
    @user_params = user_params
  end

  def run
    @user = User.new @user_params
    @person = Person.new @person_params
    @person.personable = @user

    if @person.save
      create_initial_account
      return true
    end

    add_errors_from_model @person
    add_errors_from_model @user

    @errors.delete :personable

    false
  end

  def create_initial_account
    assistant = @user.assistants.create! name: "HostedGPT"
    @first_conversation = assistant.conversations.create! title: "HostedGPT", user: @user
  end

  def add_errors_from_model(model)
    model.errors.to_hash.each do |field, messages|
      messages.each do |message|
        @errors.add field, message
      end
    end
  end
end
