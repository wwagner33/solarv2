class AddOriginGroupAtAllocation < ActiveRecord::Migration
  def change
    add_column :allocations, :origin_group_id, :integer, null: true
    add_foreign_key :allocations, :groups, column: :origin_group_id
  end
end
