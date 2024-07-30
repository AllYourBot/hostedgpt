# Specify a list of origins that are allowed to send cross-origin requests
# and connect via Websocket. Be sure to include the scheme. For example:
#
#   export ALLOWED_REQUEST_ORIGINS=https://myhost.com,https://myotherhost.com
#
if (allowed_request_origins = ENV["ALLOWED_REQUEST_ORIGINS"].to_s.split(",")).any?
  Rails.application.configure do
    config.action_cable.allowed_request_origins = allowed_request_origins

    config.middleware.insert_before 0, Rack::Cors do
      allow do
        origins allowed_request_origins

        resource "*",
          headers: :any,
          methods: [:get, :post, :put, :patch, :delete, :options, :head],
          credentials: true,
          max_age: 86400
      end
    end
  end
end
