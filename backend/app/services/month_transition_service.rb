# Service class to handle month transitions with carryover
class MonthTransitionService
  def self.transition_month(budget, target_month: nil, user: nil)
    new(budget, target_month, user).transition
  end

  def initialize(budget, target_month = nil, user = nil)
    @budget = budget
    @user = user || budget.user
    @target_month = target_month || Date.today.next_month.beginning_of_month
    @target_month = @target_month.beginning_of_month
  end

  def transition
    # Validate that budget belongs to user
    raise ArgumentError, "Budget does not belong to user" unless @budget.user_id == @user.id

    # Check if target month already exists (idempotency)
    existing_budget_month = @budget.budget_months.find_by(month: @target_month)
    if existing_budget_month
      return {
        budget_month: existing_budget_month,
        message: "Budget month already exists for #{@target_month.strftime('%B %Y')}",
        created: false
      }
    end

    # Use database transaction for atomicity
    ActiveRecord::Base.transaction do
      # Find previous month
      previous_month = @target_month.prev_month.beginning_of_month
      previous_budget_month = @budget.budget_months.find_by(month: previous_month)

      # Create new budget_month
      new_budget_month = @budget.budget_months.create!(
        user: @user,
        month: @target_month,
        available: 0
      )

      # Copy category structure from previous month or create defaults
      if previous_budget_month
        copy_category_structure(previous_budget_month, new_budget_month)
        # Reload to ensure category_groups are available
        new_budget_month.reload
        # Apply carryover after structure is copied
        apply_carryover(previous_budget_month, new_budget_month)
      else
        # First month - create default structure
        create_default_category_structure(new_budget_month)
      end

      # Create summary for new month
      create_summary(new_budget_month, previous_budget_month)

      # Calculate initial available amount
      BudgetService.calculate_budget_month_available(new_budget_month)

      {
        budget_month: new_budget_month.reload,
        message: "Successfully transitioned to #{@target_month.strftime('%B %Y')}",
        created: true
      }
    end
  rescue ActiveRecord::RecordInvalid => e
    raise ArgumentError, "Failed to create budget month: #{e.message}"
  rescue StandardError => e
    raise ArgumentError, "Month transition failed: #{e.message}"
  end

  private

  def copy_category_structure(source_budget_month, target_budget_month)
    # Copy all category_groups from source to target
    source_budget_month.category_groups.each do |source_cg|
      target_cg = target_budget_month.category_groups.find_or_create_by!(
        name: source_cg.name,
        user_id: @user.id
      ) do |cg|
        cg.is_default = source_cg.is_default
      end

      # Categories are global, so we don't need to copy them
      # They'll be linked via CategoryMonths in apply_carryover
    end
  end

  def create_default_category_structure(budget_month)
    # Create a default category group if none exist
    if budget_month.category_groups.empty?
      default_group = budget_month.category_groups.create!(
        name: "Default",
        user_id: @user.id,
        is_default: true
      )
    end
  end

  def apply_carryover(source_budget_month, target_budget_month)
    # Get all category_months from source month
    source_category_months = CategoryMonth
      .joins(:category_group)
      .where(category_groups: { budget_month_id: source_budget_month.id })
      .where(month: source_budget_month.month)
      .where(user_id: @user.id)

    source_category_months.each do |source_cm|
      source_cm.reload # Ensure balance is current (e.g. after calculate_balance callback)
      # Find corresponding category_group in target month by name
      source_cg = source_cm.category_group
      target_cg = target_budget_month.category_groups.find_by(
        name: source_cg.name,
        user_id: @user.id
      )
      next unless target_cg

      # Find or create category_month in target month
      target_cm = CategoryMonth.find_or_create_by!(
        category_id: source_cm.category_id,
        category_group_id: target_cg.id,
        month: target_budget_month.month,
        user_id: @user.id
      ) do |cm|
        cm.allotted = 0
        cm.spent = 0
        cm.balance = 0
      end

      # Set target month's allotted to source month's balance (remaining available) for this category.
      # e.g. Jan Misc balance $950.01 → Feb Misc starting allotted = $950.01.
      target_cm.allotted = (source_cm.balance || 0)
      target_cm.save!
    end
  end

  def create_summary(budget_month, previous_budget_month)
    carryover = 0
    if previous_budget_month
      category_carryover = CategoryCarryoverService.calculate_carryover_for_month(previous_budget_month)
      BudgetService.calculate_budget_month_available(previous_budget_month)
      prev_available = previous_budget_month.reload.available.to_f
      carryover = category_carryover + prev_available
    end

    # Create summary
    Summary.find_or_create_by!(
      budget_month_id: budget_month.id,
      user_id: @user.id
    ) do |s|
      s.budget_month = budget_month
      s.user = @user
      s.income = 0
      s.carryover = carryover
      s.available = 0
    end
  end
end
