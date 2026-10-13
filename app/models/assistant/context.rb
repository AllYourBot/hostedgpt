module Assistant::Context
  extend ActiveSupport::Concern

  def context_prompt
    sections = [context_files_section, context_attachments_section].compact
    sections.join("\n\n") if sections.any?
  end

  def context_attachments
    context_documents.select { |document| natively_readable?(document) }
  end

  def natively_readable?(document)
    (document.has_image? && supports_images?) || (document.has_document_pdf? && supports_pdf?)
  end

  private

  def context_documents
    documents.order(:created_at)
  end

  def context_files_section
    files = context_documents.reject { |document| natively_readable?(document) }.filter_map do |document|
      text = document.text_content
      %|<file name="#{document.filename}">\n#{text}\n</file>| if text.present?
    end
    return if files.empty?

    "The following files have been provided as context for you. Use them when answering:\n\n" + files.join("\n\n")
  end

  def context_attachments_section
    filenames = context_attachments.map(&:filename)
    return if filenames.empty?

    "These files, attached to the first message of the conversation, have also been provided as context for you rather than sent by the user: #{filenames.join(", ")}"
  end
end
