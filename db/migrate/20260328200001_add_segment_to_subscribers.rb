# frozen_string_literal: true

class AddSegmentToSubscribers < ActiveRecord::Migration[7.1]
  def change
    add_column :subscribers, :segment, :string, default: 'new'
    add_index :subscribers, :segment
  end
end
