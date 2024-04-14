module Message::DocumentImage
  extend ActiveSupport::Concern

  included do
    has_many :documents, dependent: :destroy

    accepts_nested_attributes_for :documents
  end

  def has_document_image?(variant = nil)
    has_image = documents.present? && documents.first.file.attached?
    if has_image && variant
      has_image = documents.first.has_file_variant_processed?(variant)
    end

    !!has_image
  end

  def document_image_path(variant, fallback: nil)
    return nil unless has_document_image?

    if documents.first.has_file_variant_processed?(variant)
      documents.first.fully_processed_url(variant)
    elsif fallback.nil?
      documents.first.redirect_to_processed_path(variant)
    else
      fallback
    end
  end
end
