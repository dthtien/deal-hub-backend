class AddPlateStateToQuotes < ActiveRecord::Migration[7.1]
  def change
    add_column :quotes, :plate_state, :string
  end
end
