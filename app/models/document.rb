class Document < ApplicationRecord
  belongs_to :user
  belongs_to :assistant, optional: true
  belongs_to :message, optional: true

  has_one_attached :file

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

    base64 = file.blob.open do |file|
      Base64.strict_encode64(file.read)
    end
  end

  private

  def file_present
    errors.add(:file, "must be attached") unless file.attached?
  end

  def set_default_user
    self.user ||= message.conversation.user
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
