if (allowed_request_origins = ENV['ALLOWED_REQUEST_ORIGINS'].to_s.split(',')).any?
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
