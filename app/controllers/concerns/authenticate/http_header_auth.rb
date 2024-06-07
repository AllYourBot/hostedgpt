module Authenticate::HttpHeaderAuth

  private

  def find_or_create_client_by_http_header
    return unless Feature.http_header_authentication? && http_header_external_id.present?

    if credential = find_credential_by_http_header || create_credential_by_http_header
      create_client_for credential.user.person
    end
  end

  alias_method :find_client_by_http_header, :find_or_create_client_by_http_header

  def find_credential_by_http_header
    Credential.find_by(external_id: http_header_external_id)
  end

  def create_credential_by_http_header
    http_header_email = request.headers[Setting.http_header_auth_email]
    http_header_name  = request.headers[Setting.http_header_auth_name] || fallback_name_from(http_header_email)

    if Feature.registration?
      user = User.create!(name: http_header_name)
      Person.create!(personable: user, email: http_header_email)
      HttpHeaderCredential.create!(user: user, external_id: http_header_external_id)
    end
  end

  def http_header_external_id
    request.headers[Setting.http_header_auth_uid]
  end

  def fallback_name_from(email)
    first_part = email.split('@').first
    return first_part if first_part.exclude('.')

    pieces = first_part.split('.')
    pieces.first + " " + pieces.last
  end
end
