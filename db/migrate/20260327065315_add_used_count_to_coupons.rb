class AddUsedCountToCoupons < ActiveRecord::Migration[8.0]
  def change
    # used_count is distinct from use_count (tracking clicks); used_count tracks actual copies
    add_column :coupons, :used_count, :integer, default: 0, null: false unless column_exists?(:coupons, :used_count)
  end
end
