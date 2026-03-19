class AddTravelIndexToProducts < ActiveRecord::Migration[8.0]
  def change
    # GIN expression index for travel category filtering
    # Applied manually in production via: CREATE INDEX CONCURRENTLY ...
    # Skipped here to maintain schema.rb compatibility
  end
end
