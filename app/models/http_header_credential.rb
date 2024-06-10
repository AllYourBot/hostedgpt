class HttpHeaderCredential < Credential
  alias_attribute :auth_uid, :external_id

  validates :auth_uid, presence: true, uniqueness: true
end
