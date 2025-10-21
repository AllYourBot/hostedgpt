class Document < ApplicationRecord
  belongs_to :user
  belongs_to :assistant, optional: true
  belongs_to :message, optional: true

  has_one_attached :file

  enum :purpose, %w[fine-tune fine-tune-results assistants assistants_output].index_by(&:to_sym)

  attribute :purpose, default: :assistants

  before_validation :set_default_user, on: :create
  before_validation :set_default_filename, on: :create
  before_validation :set_default_bytes, on: :create

  validates :purpose, :filename, :bytes, presence: true
  validate :file_present

  def has_image?(variant = nil)
    return false unless file.attached? && file.content_type&.start_with?("image/")

    if variant.present?
      return has_file_variant_processed?(variant)
    end

    true
  end

  def image_variant(variant)
    return nil unless file.attached? && file.content_type&.start_with?("image/")

    case variant.to_sym
    when :small
      file.variant(resize_to_limit: [650, 490])
    when :large
      file.variant(resize_to_limit: [1200, 900])
    else
      file
    end
  end

  def image_url(variant, fallback: nil)
    return nil unless has_image?

    if Rails.application.config.x.app_url.blank?
      file_data_url(variant)
    elsif has_file_variant_processed?(variant)
      fully_processed_url(variant)
    elsif fallback.nil?
      redirect_to_processed_path(variant)
    else
      fallback
    end
  end

  def has_file_variant_processed?(variant)
    return false unless file.attached? && file.content_type&.start_with?("image/")

    variant_obj = image_variant(variant)
    return false unless variant_obj

    r = variant_obj.key && ActiveStorage::Blob.service.exist?(variant_obj.key)
    !!r
  end

  def fully_processed_url(variant)
    return nil unless file.attached? && file.content_type&.start_with?("image/")

    variant_obj = image_variant(variant)
    return nil unless variant_obj

    variant_obj.processed.url
  end

  def redirect_to_processed_path(variant)
    return nil unless file.attached? && file.content_type&.start_with?("image/") && variant.present?

    variant_obj = image_variant(variant)
    return nil unless variant_obj

    Rails.application.routes.url_helpers.rails_representation_url(
      variant_obj,
      only_path: true
    )
  end

  def file_base64(variant = :large)
    return nil if !file.attached?

    if file.content_type&.start_with?("image/")
      variant_obj = image_variant(variant)
      return nil unless variant_obj

      wait_for_file_variant_to_process!(variant.to_sym)
      file_contents = variant_obj.processed.download
    else
      # For non-image files, just return the raw file content
      file_contents = file.download
    end

    Base64.strict_encode64(file_contents)
  end

  private

  def file_data_url(variant = :large)
    "data:#{file.blob.content_type};base64,#{file_base64(variant)}"
  end

  def set_default_user
    self.user ||= message.conversation.user
  end

  def set_default_filename
    self.filename ||= file.filename.to_s
  end

  def set_default_bytes
    self.bytes ||= file.byte_size
  end

  def file_present
    errors.add(:file, I18n.t("app.models.document.errors.file.attached")) unless file.attached?
  end

  def wait_for_file_variant_to_process!(variant)
    return false unless file&.attached? && file.content_type&.start_with?("image/")

    variant_obj = image_variant(variant)
    return false unless variant_obj

    variant_obj.processed # this blocks until processing is done
  end
end
