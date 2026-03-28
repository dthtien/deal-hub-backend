# frozen_string_literal: true

class AddUtmParamsToClickTrackings < ActiveRecord::Migration[8.0]
  def change
    add_column :click_trackings, :utm_source, :string
    add_column :click_trackings, :utm_medium, :string
    add_column :click_trackings, :utm_campaign, :string
  end
end
