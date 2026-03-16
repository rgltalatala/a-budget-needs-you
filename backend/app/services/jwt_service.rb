class JwtService
  SECRET_KEY = Rails.application.credentials.secret_key_base || "development_secret_key_change_in_production"
  ALGORITHM = "HS256"
  EXPIRATION_TIME = 24.hours

  def self.encode(payload)
    payload[:exp] = (Time.current + EXPIRATION_TIME).to_i
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end

  def self.decode(token)
    decoded = JWT.decode(token, SECRET_KEY, true, { algorithm: ALGORITHM })
    decoded[0].symbolize_keys
  rescue JWT::DecodeError, JWT::ExpiredSignature => e
    nil
  end

  def self.generate_token(user)
    encode({ user_id: user.id })
  end

  # Encode a token with custom expiry (e.g. for password reset).
  def self.encode_with_expiry(payload, duration: 1.hour)
    payload = payload.dup
    payload[:exp] = (Time.current + duration).to_i
    JWT.encode(payload, SECRET_KEY, ALGORITHM)
  end
end
