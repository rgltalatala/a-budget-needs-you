module Api
  module V1
    class BudgetMonthsController < BaseController
      include Authenticable
      include Paginatable

      before_action :set_budget_month, only: [:show, :update, :destroy]

      # GET /api/v1/budget_months
      def index
        # Ensure this is a GET request
        raise "Index called with #{request.method} request!" unless request.get?

        # Start with user's budget_months - this ensures we only get budget_months that belong to the user
        # The association already scopes by user_id, so we're safe here
        @budget_months = current_user.budget_months

        # Filter by budget_id if provided
        if params[:budget_id].present?
          # Convert to string to ensure proper comparison
          budget_id = params[:budget_id].to_s
          # Ensure budget belongs to current user - this is important for security
          # If budget doesn't belong to user, find_by will return nil
          budget = current_user.budgets.find_by(id: budget_id)
          if budget
            # Filter by budget_id - budget_months are already scoped to current_user
            @budget_months = @budget_months.where(budget_id: budget_id)
          else
            # Return empty array if budget doesn't belong to user
            @budget_months = @budget_months.none
          end
        end

        # Filter by month if provided
        if params[:month].present?
          # Parse month string to date if needed
          begin
            month_date = params[:month].is_a?(String) ? Date.parse(params[:month]) : params[:month]
            # Filter by month - budget_months are already scoped to current_user via the association
            @budget_months = @budget_months.where(month: month_date)
          rescue ArgumentError => e
            # Invalid date format, return empty array
            @budget_months = @budget_months.none
          end
        end

        @budget_months = @budget_months.by_month_desc

        # Render the filtered results
        render_paginated(@budget_months, Api::V1::BudgetMonthSerializer)
      end

      # GET /api/v1/budget_months/:id
      def show
        render json: serialize_object(@budget_month, Api::V1::BudgetMonthSerializer)
      end

      # POST /api/v1/budget_months
      def create
        # Ensure this is a POST request - if not, something is very wrong
        unless request.post?
          Rails.logger.error "CREATE ACTION CALLED WITH #{request.method} REQUEST!"
          Rails.logger.error "Params: #{params.inspect}"
          raise "Unexpected request method in create: #{request.method}"
        end

        @budget_month = current_user.budget_months.build(budget_month_params)

        # Ensure budget belongs to current user
        budget = current_user.budgets.find_by(id: budget_month_params[:budget_id])
        unless budget
          return render json: {
            error: "Invalid budget",
            message: "Budget must belong to the current user"
          }, status: :unprocessable_entity
        end

        if @budget_month.save
          render json: serialize_object(@budget_month, Api::V1::BudgetMonthSerializer), status: :created
        else
          render json: {
            error: "Validation failed",
            message: @budget_month.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # PATCH/PUT /api/v1/budget_months/:id
      def update
        if @budget_month.update(budget_month_params)
          render json: serialize_object(@budget_month, Api::V1::BudgetMonthSerializer)
        else
          render json: {
            error: "Validation failed",
            message: @budget_month.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/budget_months/:id
      def destroy
        @budget_month.destroy
        head :no_content
      end

      # POST /api/v1/budget_months/transition
      def transition
        budget_id = params[:budget_id] || params.dig(:budget_month, :budget_id)
        target_month = params[:target_month] || params.dig(:budget_month, :target_month)
        
        unless budget_id
          return render json: {
            error: "Budget ID required",
            message: "budget_id parameter is required"
          }, status: :bad_request
        end

        # Ensure budget belongs to current user
        budget = current_user.budgets.find_by(id: budget_id)
        unless budget
          return render json: {
            error: "Budget not found",
            message: "Budget does not belong to current user"
          }, status: :not_found
        end

        # Parse target_month if provided
        parsed_target_month = nil
        if target_month.present?
          begin
            parsed_target_month = Date.parse(target_month.to_s).beginning_of_month
          rescue ArgumentError
            return render json: {
              error: "Invalid date format",
              message: "target_month must be a valid date (YYYY-MM-DD)"
            }, status: :bad_request
          end
        end

        # Perform month transition
        result = MonthTransitionService.transition_month(
          budget,
          target_month: parsed_target_month,
          user: current_user
        )

        if result[:created]
          render json: {
            budget_month: serialize_object(result[:budget_month], Api::V1::BudgetMonthSerializer),
            message: result[:message]
          }, status: :created
        else
          render json: {
            budget_month: serialize_object(result[:budget_month], Api::V1::BudgetMonthSerializer),
            message: result[:message]
          }, status: :ok
        end
      rescue ArgumentError => e
        render json: {
          error: "Transition failed",
          message: e.message
        }, status: :unprocessable_entity
      end

      private

      def set_budget_month
        @budget_month = current_user.budget_months.find(params[:id])
      end

      def budget_month_params
        # Only permit if budget_month key exists, otherwise return empty hash
        if params.has_key?(:budget_month)
          params.require(:budget_month).permit(:budget_id, :month, :available)
        else
          {}
        end
      end
    end
  end
end
