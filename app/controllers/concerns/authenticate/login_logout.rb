module Authenticate::LoginLogout

  def login_as(user_or_person, credential:)
    client = find_or_create_client_for(user_or_person)
    client.authenticate_with! credential
    session_authenticate_with client
  end

  def logout_current
    Current.client.logout!
    reset_authentication
  end

  private

  def find_or_create_client_for(user_or_person)
    Current.client || user_or_person.clients.create!(
      platform: :web,
      user_agent: request.user_agent,
      ip_address: request.remote_ip,
    )
  end

  def session_authenticate_with(client)
    if Current.initialize_with(client: client)
      session[:client_token] = client.token
      cookies.signed.permanent[:client_token] = { value: client.token, httponly: true, same_site: :lax }
    end
  end

  def reset_authentication
    session.delete(:client_token)
    cookies.delete(:client_token)
    Current.reset
  end

  def manual_login_allowed?
    Feature.password_authentication? || Feature.google_authentication? || Feature.microsoft_graph_authentication?
  end
end
