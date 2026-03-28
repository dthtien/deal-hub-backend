# frozen_string_literal: true

class PopulateProductMetadataShippingDays < ActiveRecord::Migration[8.0]
  SHIPPING_MAP = {
    'ASOS'               => '2-5 days',
    'JD Sports'          => '3-7 days',
    'Myer'               => '3-5 days',
    'Office Works'       => '2-5 days',
    'JB Hi-Fi'           => '2-4 days',
    'Glue Store'         => '3-7 days',
    'Nike'               => '3-7 days',
    'Culture Kings'      => '3-7 days',
    'The Good Guys'      => '2-5 days',
    'The Iconic'         => '2-4 days',
    'Kmart'              => '3-7 days',
    'Big W'              => '3-7 days',
    'Target AU'          => '3-7 days',
    'Good Buyz'          => '5-10 days',
    'Beginning Boutique' => '3-7 days',
    'Universal Store'    => '3-7 days',
    'Lorna Jane'         => '3-5 days'
  }.freeze

  def up
    SHIPPING_MAP.each do |store_name, days|
      execute <<~SQL
        UPDATE products
        SET metadata = COALESCE(metadata, '{}') || '{"shipping_days": "#{days}"}'::jsonb
        WHERE store = '#{store_name.gsub("'", "''")}'
          AND (metadata IS NULL OR metadata->>'shipping_days' IS NULL)
      SQL
    end
  end

  def down
    execute <<~SQL
      UPDATE products
      SET metadata = metadata - 'shipping_days'
      WHERE metadata ? 'shipping_days'
    SQL
  end
end
