module Api
  module V1
    class CategoryMonthsController < BaseController
      include Authenticable
      include Paginatable

      before_action :set_category_month, only: [:show, :update, :destroy]

      # GET /api/v1/category_months
      def index
        @category_months = current_user.category_months.creation_order

        if params[:category_id].present?
          category = current_user.categories.find_by(id: params[:category_id])
          @category_months = @category_months.where(category_id: category.id) if category
        end

        if params[:category_group_id].present?
          category_group = current_user.category_groups.find_by(id: params[:category_group_id])
          @category_months = @category_months.where(category_group_id: category_group.id) if category_group
        end

        if params[:month].present?
          @category_months = @category_months.for_month(params[:month])
        end

        render_paginated(@category_months, Api::V1::CategoryMonthSerializer)
      end

      # GET /api/v1/category_months/:id
      def show
        render json: serialize_object(@category_month, Api::V1::CategoryMonthSerializer)
      end

      # POST /api/v1/category_months
      def create
        @category_month = current_user.category_months.build(category_month_params)

        # Ensure category belongs to current user
        category = current_user.categories.find_by(id: category_month_params[:category_id])
        unless category
          return render json: {
            error: "Invalid category",
            message: "Category must belong to the current user"
          }, status: :unprocessable_entity
        end

        # Ensure category_group belongs to current user if provided
        if category_month_params[:category_group_id].present?
          category_group = current_user.category_groups.find_by(id: category_month_params[:category_group_id])
          unless category_group
            return render json: {
              error: "Invalid category group",
              message: "Category group must belong to the current user"
            }, status: :unprocessable_entity
          end
        end

        if @category_month.save
          render json: serialize_object(@category_month, Api::V1::CategoryMonthSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @category_month.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/category_months/:id
      def update
        if @category_month.update(category_month_params)
          render json: serialize_object(@category_month, Api::V1::CategoryMonthSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @category_month.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/category_months/:id
      def destroy
        @category_month.destroy
        head :no_content
      end

      private

      def set_category_month
        @category_month = current_user.category_months.find(params[:id])
      end

      def category_month_params
        params.require(:category_month).permit(:category_id, :category_group_id, :spent, :allotted, :balance, :month)
      end
    end
  end
end
