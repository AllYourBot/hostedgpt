class Toolbox::Memory < Toolbox

  describe :remember_detail_about_user, <<~S
    This will commit details to memory so that in all future conversations with the user this knowledge will be available to us.
    Use this function any any time the user explicitly indicates they want us to remember. Or if they don't explicitly indicate,
    also remember if the user tell us something about themselves which seems like the kind of a thing a friend or personal
    assistant might want to know. This includes personal preferences, favorites, hobbies or things they value, the names of people that
    are important to them, dates of significance, and recurring activities or routines — also remember revisions or elaborations
    on any of these things which you've already remembered.
  S

  def remember_detail_about_user(detail_s:)
    raise "Current user & message needs to be set" unless Current.user && Current.message

    conversation_messages = Current.message.conversation.messages.for_conversation_version(Current.message.version)
    related_message = conversation_messages.where("messages.id < ?", Current.message.id).last
    Current.user.memories.create!(detail: detail_s, message: related_message)
    {
      message_to_user: "Memory updated"
    }
  end
end
