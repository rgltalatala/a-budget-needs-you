module Api
  module V1
    class CategoryGroupsController < BaseController
      include Authenticable
      include Paginatable

      before_action :set_category_group, only: [:show, :update, :destroy]

      # GET /api/v1/category_groups
      def index
        @category_groups = current_user.category_groups.creation_order

        if params[:budget_month_id].present?
          budget_month = current_user.budget_months.find_by(id: params[:budget_month_id])
          @category_groups = @category_groups.for_budget_month(budget_month) if budget_month
        end

        render_paginated(@category_groups, Api::V1::CategoryGroupSerializer)
      end

      # GET /api/v1/category_groups/:id
      def show
        render json: serialize_object(@category_group, Api::V1::CategoryGroupSerializer)
      end

      # POST /api/v1/category_groups
      def create
        @category_group = current_user.category_groups.build(category_group_params)

        # Ensure budget_month belongs to current user if provided
        if category_group_params[:budget_month_id].present?
          budget_month = current_user.budget_months.find_by(id: category_group_params[:budget_month_id])
          unless budget_month
            return render json: {
              error: "Invalid budget month",
              message: "Budget month must belong to the current user"
            }, status: :unprocessable_entity
          end
        end

        if @category_group.save
          render json: serialize_object(@category_group, Api::V1::CategoryGroupSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @category_group.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/category_groups/:id
      def update
        if @category_group.update(category_group_params)
          render json: serialize_object(@category_group, Api::V1::CategoryGroupSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @category_group.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/category_groups/:id
      def destroy
        if @category_group.categories.any? || @category_group.category_months.any?
          render json: {
            error: "Cannot delete category group",
            message: "This category group has associated categories or category months. Please remove them first."
          }, status: :unprocessable_entity
        else
          @category_group.destroy
          head :no_content
        end
      end

      private

      def set_category_group
        @category_group = current_user.category_groups.find(params[:id])
      end

      def category_group_params
        params.require(:category_group).permit(:budget_month_id, :name, :is_default)
      end
    end
  end
end
