module Message::DocumentImage
  extend ActiveSupport::Concern

  included do
    has_many :documents, dependent: :destroy

    accepts_nested_attributes_for :documents
  end

  def has_document_image?(variant = nil)
    documents.present? && documents.first.has_image?(variant)
  end

  def has_document_pdf?
    documents.present? && documents.first.file.attached? && documents.first.file.content_type == "application/pdf"
  end

  def has_documents?
    documents.present? && documents.first.file.attached?
  end

  def document_image_url(variant, fallback: nil)
    return nil unless has_document_image?

    documents.last.image_url(variant, fallback: fallback)
  end

  def document_pdf_url
    return nil unless has_document_pdf?

    documents.last.file.url
  end

  def document_filename
    return nil unless has_documents?

    documents.last.filename
  end

  def document_content_type
    return nil unless has_documents?

    documents.last.file.content_type
  end
end
