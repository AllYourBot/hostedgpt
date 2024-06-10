module Authenticate::ByCookie

  # A user is authenticated by cookie AFTER they have successfully logged in through any method

  private

  def find_client_by_cookie
    Client.find_by(token: session_token) unless session_token.blank?
  end

  def session_token
    session[:client_token] || cookies.signed[:client_token]
  end
end
