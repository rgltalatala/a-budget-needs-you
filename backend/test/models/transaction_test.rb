require "test_helper"

class TransactionTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @account = accounts(:one)
    # Use a category that doesn't have existing category_months in fixtures
    @category = categories(:three) # "Dining Out" category
    # Get initial balance before any test transactions
    @account.recalculate_balance!
    @initial_balance = @account.balance
    # Use a future month to avoid conflicts with fixture data
    @test_month = (Date.today + 2.months).beginning_of_month
  end

  test "should update account balance when transaction is created" do
    # Account balance already includes fixture transactions, so we need to recalculate
    @account.recalculate_balance!
    initial_balance = @account.balance

    transaction = Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: 100.00
    )

    @account.reload
    assert_equal initial_balance + 100.00, @account.balance
  end

  test "should update account balance when transaction is updated" do
    @account.recalculate_balance!
    initial_balance = @account.balance

    transaction = Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: 100.00
    )

    @account.reload
    assert_equal initial_balance + 100.00, @account.balance

    transaction.update!(amount: 150.00)
    @account.reload
    assert_equal initial_balance + 150.00, @account.balance
  end

  test "should revert account balance when transaction is destroyed" do
    @account.recalculate_balance!
    initial_balance = @account.balance

    transaction = Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: 100.00
    )

    @account.reload
    assert_equal initial_balance + 100.00, @account.balance

    transaction.destroy
    @account.reload
    assert_equal initial_balance, @account.balance
  end

  test "should create category_month when transaction is created" do
    assert_nil CategoryMonth.find_by(
      category_id: @category.id,
      month: @test_month,
      user_id: @user.id
    )

    transaction = Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: -50.00
    )

    category_month = CategoryMonth.find_by(
      category_id: @category.id,
      month: @test_month,
      user_id: @user.id
    )

    assert_not_nil category_month
    assert_equal 50.00, category_month.spent
  end

  test "should update category_month spent when transaction is created" do
    category_month = CategoryMonth.create!(
      category_id: @category.id,
      month: @test_month,
      user_id: @user.id,
      allotted: 200.00,
      spent: 0.00
    )

    Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: -50.00
    )

    category_month.reload
    assert_equal 50.00, category_month.spent
    assert_equal 150.00, category_month.balance
  end

  test "should update category_month balance when transaction is created" do
    category_month = CategoryMonth.create!(
      category_id: @category.id,
      month: @test_month,
      user_id: @user.id,
      allotted: 200.00,
      spent: 0.00
    )

    Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: -75.00
    )

    category_month.reload
    assert_equal 75.00, category_month.spent
    assert_equal 125.00, category_month.balance
  end

  test "should handle multiple transactions in same category and month" do
    category_month = CategoryMonth.create!(
      category_id: @category.id,
      month: @test_month,
      user_id: @user.id,
      allotted: 500.00,
      spent: 0.00
    )

    Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: -50.00
    )

    Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 10.days,
      amount: -75.00
    )

    category_month.reload
    assert_equal 125.00, category_month.spent
    assert_equal 375.00, category_month.balance
  end

  test "should update category_month when transaction date changes" do
    old_month = @test_month
    new_month = (@test_month + 1.month).beginning_of_month

    old_category_month = CategoryMonth.create!(
      category_id: @category.id,
      month: old_month,
      user_id: @user.id,
      allotted: 200.00,
      spent: 0.00
    )

    transaction = Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: -50.00
    )

    old_category_month.reload
    assert_equal 50.00, old_category_month.spent

    transaction.update!(date: new_month + 5.days)

    old_category_month.reload
    assert_equal 0.00, old_category_month.spent

    new_category_month = CategoryMonth.find_by(
      category_id: @category.id,
      month: new_month,
      user_id: @user.id
    )
    assert_not_nil new_category_month
    assert_equal 50.00, new_category_month.spent
  end

  test "should handle account change in transaction update" do
    new_account = accounts(:two)
    new_account.recalculate_balance!
    new_account_initial_balance = new_account.balance

    @account.recalculate_balance!
    initial_balance = @account.balance

    transaction = Transaction.create!(
      account: @account,
      category: @category,
      user: @user,
      date: @test_month + 5.days,
      amount: 100.00
    )

    @account.reload
    assert_equal initial_balance + 100.00, @account.balance

    transaction.update!(account: new_account)

    @account.reload
    assert_equal initial_balance, @account.balance

    new_account.reload
    assert_equal new_account_initial_balance + 100.00, new_account.balance
  end
end
