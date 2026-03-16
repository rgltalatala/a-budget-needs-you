class ApplicationController < ActionController::API
  rescue_from StandardError, with: :handle_server_error

  private

  def handle_server_error(exception)
    Rails.logger.error("#{exception.class}: #{exception.message}\n#{exception.backtrace&.first(10)&.join("\n")}")
    if Rails.env.production?
      render json: { error: "Internal server error" }, status: :internal_server_error
    else
      render json: {
        error: "Internal server error",
        message: exception.message,
        backtrace: exception.backtrace&.first(15)
      }, status: :internal_server_error
    end
  end
end
