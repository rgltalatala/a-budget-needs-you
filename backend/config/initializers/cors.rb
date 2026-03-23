# Be sure to restart your server when you modify this file.

# Avoid CORS issues when API is called from the frontend app.
# Read more: https://github.com/cyu/rack-cors

require "uri"

module CorsLocalDev
  module_function

  # True when Origin is http://localhost:*, http://127.0.0.1:*, or http://[::1]:* (any port).
  def allow_origin?(origin)
    return false if origin.blank?

    uri = URI.parse(origin)
    return false unless uri.scheme == "http"

    # URI host for IPv6 loopback is the string "[::1]" (brackets included).
    ["localhost", "127.0.0.1", "::1", "[::1]"].include?(uri.host)
  rescue URI::InvalidURIError, ArgumentError
    false
  end
end

Rails.application.config.middleware.insert_before 0, Rack::Cors do
  allow do
    origins do |origin|
      if Rails.env.production?
        # In production, allow only origins listed in ALLOWED_ORIGINS (comma-separated, e.g. https://myapp.com).
        # Strip trailing slashes so "https://myapp.vercel.app/" in env still matches the browser Origin (no path).
        normalize_origin = ->(o) { o.to_s.strip.sub(%r{/+\z}, "") }
        allowed = ENV.fetch("ALLOWED_ORIGINS", "").split(",").map { normalize_origin.call(_1) }.reject(&:empty?)
        next false if origin.blank?

        allowed.include?(normalize_origin.call(origin))
      else
        # Development: allow any http origin on localhost / loopback (any port, IPv4, IPv6 [::1]).
        CorsLocalDev.allow_origin?(origin)
      end
    end

    resource "*",
      headers: :any,
      methods: [:get, :post, :put, :patch, :delete, :options, :head],
      credentials: true
  end
end
