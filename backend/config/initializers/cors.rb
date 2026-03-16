# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Read more: https://github.com/cyu/rack-cors

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |origin|
      if Rails.env.production?
        # In production, allow only origins listed in ALLOWED_ORIGINS (comma-separated, e.g. https://myapp.com).
        allowed = ENV.fetch("ALLOWED_ORIGINS", "").split(",").map(&:strip).reject(&:empty?)
        allowed.include?(origin)
      else
        # Development: allow localhost frontend and backend.
        origin == "http://localhost:3000" || origin == "http://127.0.0.1:3000" || origin == "http://localhost:3001" || origin == "http://127.0.0.1:3001"
      end
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
