class Document < ApplicationRecord
  belongs_to :user
  belongs_to :assistant, optional: true
  belongs_to :message, optional: true

  has_one_attached :file do |file|
    file.variant :small, resize_to_limit: [650, 490], preprocessed: true
    file.variant :large, resize_to_limit: [1200, 900], preprocessed: true
  end

  enum purpose: %w[fine-tune fine-tune-results assistants assistants_output].index_by(&:to_sym)

  validates :purpose, :filename, :bytes, presence: true
  validate :file_present

  before_validation :set_default_user, on: :create
  before_validation :set_default_purpose, on: :create
  before_validation :set_default_filename, on: :create
  before_validation :set_default_bytes, on: :create

  def file_data_url
    return nil if !file.attached?

    "data:#{file.blob.content_type};base64,#{file_base64}"
  end

  def file_base64
    return nil if !file.attached?
    wait_for_file_variant_to_process!(:large)

    file_contents = file.variant(:large).processed.download
    base64 = Base64.strict_encode64(file_contents)
  end

  private

  def wait_for_file_variant_to_process!(variant)
    file.variant(variant.to_sym).processed # this blocks until processing is done
  end

  def file_present
    errors.add(:file, "must be attached") unless file.attached?
  end

  def set_default_user
    self.user ||= message.conversation.user # this won't work when multiple people are in a conversation
  end

  def set_default_purpose
    self.purpose ||= :assistants
  end

  def set_default_filename
    self.filename ||= file.filename.to_s
  end

  def set_default_bytes
    self.bytes ||= file.byte_size
  end
end
