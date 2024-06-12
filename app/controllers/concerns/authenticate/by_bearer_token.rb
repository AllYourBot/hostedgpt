module Authenticate::ByBearerToken

  private

  def find_client_by_bearer_token
    authenticate_with_http_token do |double_token, options|
      client, client_token = parse_double_token(double_token)

      if client && client_token && ActiveSupport::SecurityUtils.secure_compare(client.token, client_token)
        client
      else
        render_unauthorized
      end
    end
  end

  def parse_double_token(double_token)
    client_id, client_token = double_token.split(':')
    client = Client.authenticated.api.find_by(id: client_id)

    [client, client_token]
  end

  def render_unauthorized
    self.headers['WWW-Authenticate'] = 'Token realm="Application"'
    render json: { error: "Authentication Bearer token was invalid" }, status: :unauthorized
  end
end
