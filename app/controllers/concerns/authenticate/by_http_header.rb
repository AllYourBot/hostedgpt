module Authenticate::ByHttpHeader

  private

  def find_or_create_client_by_http_header
    # There is no advanced registration that happens with this authentication scheme so everything
    # is created on the fly if the credentials are present.

    return unless Feature.http_header_authentication? && auth_uid.present?

    if credential = find_credential_by_http_header || create_credential_by_http_header
      login_as(credential.user, credential: credential)
    end

    Current.client
  end

  alias_method :find_client_by_http_header, :find_or_create_client_by_http_header

  def find_credential_by_http_header
    HttpHeaderCredential.find_by(auth_uid: auth_uid)
  end

  def create_credential_by_http_header
    http_header_email = request.headers[Setting.http_header_auth_email]
    http_header_name  = request.headers[Setting.http_header_auth_name] || fallback_name_from(http_header_email)

    if Feature.registration?
      user = User.create!(name: http_header_name)
      Person.create!(personable: user, email: http_header_email)
      HttpHeaderCredential.create!(user: user, external_id: auth_uid)
    end
  end

  def auth_uid
    request.headers[Setting.http_header_auth_uid]
  end

  def fallback_name_from(email)
    first_part = email.split('@').first
    return first_part unless first_part.include?('.')

    pieces = first_part.split('.')
    pieces.first + " " + pieces.last
  end
end
