module Api
  module V1
    class UserSerializer < BaseSerializer
      def serialize_item(item)
        return nil if item.nil?
        
        {
          id: item.id.to_s,
          email: item.email,
          name: item.name,
          created_at: item.created_at&.iso8601,
          updated_at: item.updated_at&.iso8601
        }
      end
    end
  end
end
