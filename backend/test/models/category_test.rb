# frozen_string_literal: true

require "test_helper"

class CategoryTest < ActiveSupport::TestCase
  setup do
    @user = users(:one)
    @group = category_groups(:one)
    @existing = categories(:one)
  end

  test "rejects duplicate name in same category group (case insensitive)" do
    dup = Category.new(user: @user, category_group: @group, name: @existing.name.upcase)
    assert_not dup.valid?
    assert dup.errors[:name].present?
  end

  test "allows same name in different category groups" do
    other_group = category_groups(:two)
    cat = Category.new(user: @user, category_group: other_group, name: @existing.name)
    assert cat.valid?, cat.errors.full_messages.inspect
  end
end
