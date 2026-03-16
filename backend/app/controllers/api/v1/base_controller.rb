module Api
  module V1
    class BaseController < ApplicationController
      include Authenticable
      
      # Base controller for API v1 with common error handling.
      # In production, error responses do not expose stack traces or internal details.

      rescue_from ActiveRecord::RecordNotFound, with: :record_not_found
      rescue_from ActiveRecord::RecordInvalid, with: :record_invalid
      rescue_from ActionController::ParameterMissing, with: :parameter_missing
      # StandardError handled by ApplicationController (safe production response)

      private

      def record_not_found(exception)
        payload = { error: "Record not found" }
        payload[:message] = exception.message unless Rails.env.production?
        render json: payload, status: :not_found
      end

      def record_invalid(exception)
        render json: {
          error: "Validation failed",
          message: exception.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def parameter_missing(exception)
        payload = { error: "Parameter missing" }
        payload[:message] = exception.message unless Rails.env.production?
        render json: payload, status: :bad_request
      end

      def render_error(message, status: :unprocessable_entity)
        render json: {
          error: message
        }, status: status
      end

      protected

      def serialize_resource(resource, serializer_class, options = {})
        includes = parse_includes_param
        serializer_class.serialize(resource, options.merge(includes: includes))
      end

      def parse_includes_param
        return [] unless params[:include].present?
        params[:include].split(",").map(&:strip)
      end

      # Alias for backward compatibility with existing controllers
      def serialize_object(object, serializer_class, includes: parse_includes_param)
        serialize_resource(object, serializer_class, includes: includes)
      end

      def serialize_collection(collection, serializer_class, includes: parse_includes_param)
        serializer_class.serialize(collection, includes: includes)
      end
    end
  end
end
