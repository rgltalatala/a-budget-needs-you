module Api
  module V1
    class CategoriesController < BaseController
      include Authenticable
      include Paginatable
      
      before_action :set_category, only: [:show, :update, :destroy]

      # GET /api/v1/categories
      def index
        @categories = current_user.categories
        
        @categories = @categories.by_default(params[:is_default]) if params[:is_default].present?
        
        render_paginated(@categories, Api::V1::CategorySerializer)
      end

      # GET /api/v1/categories/:id
      def show
        render json: serialize_object(@category, Api::V1::CategorySerializer)
      end

      # POST /api/v1/categories
      def create
        @category = current_user.categories.build(category_params)

        if @category.save
          render json: serialize_object(@category, Api::V1::CategorySerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @category.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/categories/:id
      def update
        if @category.update(category_params)
          render json: serialize_object(@category, Api::V1::CategorySerializer)
        else
          render json: {
            error: "Validation failed",
            message: @category.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/categories/:id
      def destroy
        @category.destroy
        head :no_content
      end

      private

      def set_category
        @category = current_user.categories.find(params[:id])
      end

      def category_params
        params.require(:category).permit(:category_group_id, :name, :is_default)
      end
    end
  end
end
