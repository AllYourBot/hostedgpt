# A PNG image a tool produced, carried base64-encoded inside the tool result
# (Toolbox::Image returns it as json_of_generated_image). GetNextAIMessageJob
# redacts the payload from the saved tool message and hands it here so the
# assistant reply that describes the image carries it as a Document.
class GeneratedImage
  def initialize(base64_data)
    @base64_data = base64_data
  end

  def attach_to!(message)
    return if @base64_data.blank?

    tempfile = Tempfile.new(["generated", ".png"])
    tempfile.binmode
    tempfile.write(Base64.decode64(@base64_data))
    tempfile.rewind

    document = Document.new(message: message, assistant: message.assistant, user: message.user, purpose: :assistants_output)
    document.file.attach(io: tempfile, filename: "generated.png", content_type: "image/png")
    message.documents << document
  ensure
    tempfile&.close
    tempfile&.unlink
  end
end
