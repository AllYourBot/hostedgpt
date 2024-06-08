module Authenticate::LoginLogout

  private

  def login_as(user_or_person, credential:)
    client = find_or_create_client_for(user_or_person)
    client.authenticate_with! credential
    session_authenticate_with client
  end

  def find_or_create_client_for(user_or_person)
    Current.client || user_or_person.clients.create!(
      platform: :web,
      user_agent: "",
      ip_address: "",
      time_zone_offset_in_minutes: 0
    )
  end

  def reset_authentication
    session.delete(:session_token)
    cookies.delete(:client_token)
    Current.reset
  end

  def session_authenticate_with(client)
    if Current.initialize_with(client: client)
      session[:client_token] = client.token
      cookies.signed.permanent[:client_token] = { value: client.token, httponly: true, same_site: :lax }
    end
  end

  def manual_authentication_allowed?
    Feature.password_authentication? || Feature.google_authentication?
  end
end
