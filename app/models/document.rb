class Document < ApplicationRecord
  belongs_to :user
  belongs_to :assistant, optional: true
  belongs_to :message, optional: true

  has_one_attached :file

  enum purpose: %w[fine-tune fine-tune-results assistants assistants_output].index_by(&:to_sym)

  validates :purpose, :filename, :bytes, presence: true

  before_validation :set_default_user, on: :create
  before_validation :set_default_purpose, on: :create
  before_validation :set_default_filename, on: :create
  before_validation :set_default_bytes, on: :create

  private

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
