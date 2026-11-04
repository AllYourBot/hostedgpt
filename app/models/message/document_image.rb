module Message::DocumentImage
  extend ActiveSupport::Concern

  included do
    has_many :documents, dependent: :destroy

    accepts_nested_attributes_for :documents
  end

  def has_document_image?(variant = nil) = documents.any? { it.has_image?(variant) }

  def has_document_pdf? = documents.any?(&:has_document_pdf?)

  def has_documents? = documents.any? { it.file.attached? }
end
