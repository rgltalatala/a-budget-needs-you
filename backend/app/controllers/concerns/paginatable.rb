module Paginatable
  extend ActiveSupport::Concern

  DEFAULT_PER_PAGE = 20
  MAX_PER_PAGE = 100

  included do
    # Helper to parse includes from params (if not in BaseController)
    def parse_includes_param
      return [] unless params[:include].present?
      params[:include].split(",").map(&:strip)
    end
    # Helper method to paginate a collection
    def paginate_collection(collection)
      page = params[:page].to_i
      per_page = params[:per_page].to_i

      # Validate and set defaults
      page = 1 if page < 1
      per_page = DEFAULT_PER_PAGE if per_page < 1
      per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE

      # Use offset and limit for pagination (no kaminari needed)
      offset = (page - 1) * per_page
      total_count = collection.count
      paginated = collection.limit(per_page).offset(offset)
      total_pages = (total_count.to_f / per_page).ceil

      {
        data: paginated,
        meta: {
          current_page: page,
          per_page: per_page,
          total_pages: total_pages > 0 ? total_pages : 1,
          total_count: total_count
        }
      }
    end

    # Helper method to render paginated collection with serializer
    def render_paginated(collection, serializer_class)
      paginated_result = paginate_collection(collection)
      includes = parse_includes_param
      # Convert to array to ensure proper serialization
      data_array = paginated_result[:data].to_a
      serialized_data = serializer_class.serialize(data_array, includes: includes)
      
      render json: {
        data: serialized_data,
        meta: paginated_result[:meta]
      }
    end

    private

    def parse_includes_param
      return [] unless params[:include].present?
      params[:include].split(",").map(&:strip)
    end
  end
end
