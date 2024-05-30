class Toolbox::Memory < Toolbox

  describe :remember_detail_about_user, <<~S
    This will commit details to memory so that in all future conversations with the user this knowledge will be available to us.
    Use this function any any time the user tell us something about them which seems like the kind of a thing a person would expect
    us to remember about them, or if the user explicitly indicates they want us to remember something they've told us.
  S

  def remember_detail_about_user(detail_s:)
    raise "Current user & message needs to be set" unless Current.user && Current.message

    Current.user.memories.create!(detail: detail_s, message: Current.message)
    "This has been remembered"
  end
end
