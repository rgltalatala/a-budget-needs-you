module Api
  module V1
    class BaseSerializer
      def initialize(resource, options = {})
        @resource = resource
        @options = options
        @includes = parse_includes(options[:includes])
      end

      def as_json
        serialize(@resource)
      end

      def self.serialize(resource, options = {})
        new(resource, options).as_json
      end

      protected

      attr_reader :resource, :options, :includes

      def serialize(data)
        if data.respond_to?(:each) && !data.is_a?(Hash) && !data.is_a?(String)
          # Handle ActiveRecord::Relation and Arrays
          data.to_a.map { |item| serialize_item(item) }
        else
          serialize_item(data)
        end
      end

      def serialize_item(item)
        return nil if item.nil?
        # Override in subclasses
        base_attributes(item)
      end

      def base_attributes(item)
        {
          id: item.id.to_s,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }
      end

      def parse_includes(includes_param)
        return [] unless includes_param
        includes_param.is_a?(String) ? includes_param.split(",").map(&:strip) : includes_param
      end

      def include?(association)
        includes.include?(association.to_s)
      end
    end
  end
end
