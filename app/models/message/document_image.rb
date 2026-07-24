module Message::DocumentImage
  extend ActiveSupport::Concern

  included do
    has_many :documents, dependent: :destroy

    accepts_nested_attributes_for :documents
  end

  def has_document_image?(variant = nil)
    documents.any? { |document| document.has_image?(variant) }
  end

  def has_document_pdf?
    documents.any?(&:has_document_pdf?)
  end

  def has_documents?
    documents.any? { |document| document.file.attached? }
  end
end
