class Toolbox::Memory < Toolbox

  describe :remember_detail_about_user, <<~S
    This will commit details to memory so that in all future conversations with the user this knowledge will be available to us.
    Use this function any any time the user explicitly indicates they want us to remember. Or if they don't explicitly indicate,
    also remember if the user tell us something about themselves which seems like the kind of a thing a friend or personal
    assistant might want to know. This includes personal preferences, favorites, hobbies or things they value, the names of people that
    are important to them, dates of significance, and recurring activities or routines — also remember revisions or elaborations
    on any of these things which you've already remembered.
    Memories are shared with all of the user's assistants. Set only_for_this_assistant to true when the user asks that only you
    remember it, or when the detail is only about how the user wants you in particular to help them.
  S

  def remember_detail_about_user(detail_s:, is_only_for_this_assistant: false)
    raise "Current user & message needs to be set" unless Current.user && Current.message

    conversation_messages = Current.message.conversation.messages.for_conversation_version(Current.message.version)
    related_message = conversation_messages.where("messages.id < ?", Current.message.id).last
    assistant = Current.message.assistant if is_only_for_this_assistant.to_b
    Current.user.memories.create!(detail: detail_s, message: related_message, assistant:)
    {
      message_to_user: "Memory updated"
    }
  end
end
