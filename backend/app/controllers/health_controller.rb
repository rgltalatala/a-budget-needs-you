# app/controllers/health_controller.rb
class HealthController < ApplicationController
  # Liveness: app is running (no DB check).
  def index
    render json: { status: "ok" }
  end

  # Readiness: app can serve traffic (DB connectivity check). Use for load balancers / orchestrators.
  def ready
    ActiveRecord::Base.connection.execute("SELECT 1")
    render json: { status: "ok", db: "connected" }
  rescue StandardError
    render json: { status: "unavailable", db: "disconnected" }, status: :service_unavailable
  end
end
