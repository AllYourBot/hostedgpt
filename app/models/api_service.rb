class APIService < ApplicationRecord
  encrypts :access_token

  DRIVERS = %w(Anthropic OpenAI)

  belongs_to :user
  validates :url, format: URI::DEFAULT_PARSER.make_regexp(%w[http https]),  if: -> { url.present? }
  validates :name, :url, presence: true
  validates :driver, inclusion: { in: DRIVERS }

  scope :ordered, -> { order(:name) }

  def destroy
    raise ActiveRecord::ReadOnlyError 'System model cannot be deleted' if user.blank?
    if user.destroy_in_progress?
      super
    else
      update!(deleted_at: Time.now)
    end
  end
end
