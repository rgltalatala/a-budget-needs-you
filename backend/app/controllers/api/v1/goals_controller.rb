module Api
  module V1
    class GoalsController < BaseController
      include Authenticable
      include Paginatable

      before_action :set_goal, only: [:show, :update, :destroy]

      # GET /api/v1/goals
      def index
        @goals = current_user.goals

        # Filter by category_id if provided
        if params[:category_id].present?
          category = current_user.categories.find_by(id: params[:category_id])
          @goals = @goals.where(category_id: category.id) if category
        end

        @goals = @goals.by_goal_type(params[:goal_type]) if params[:goal_type].present?

        render_paginated(@goals, Api::V1::GoalSerializer)
      end

      # GET /api/v1/goals/:id
      def show
        render json: serialize_object(@goal, Api::V1::GoalSerializer)
      end

      # POST /api/v1/goals
      def create
        @goal = current_user.goals.build(goal_params)

        # Ensure category belongs to current user
        category = current_user.categories.find_by(id: goal_params[:category_id])
        unless category
          return render json: {
            error: "Invalid category",
            message: "Category must belong to the current user"
          }, status: :unprocessable_entity
        end

        if @goal.save
          render json: serialize_object(@goal, Api::V1::GoalSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @goal.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/goals/:id
      def update
        if @goal.update(goal_params)
          render json: serialize_object(@goal, Api::V1::GoalSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @goal.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/goals/:id
      def destroy
        @goal.destroy
        head :no_content
      end

      private

      def set_goal
        @goal = current_user.goals.find(params[:id])
      end

      def goal_params
        params.require(:goal).permit(:category_id, :goal_type, :target_amount, :target_date)
      end
    end
  end
end
