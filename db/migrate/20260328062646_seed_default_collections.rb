# frozen_string_literal: true

class SeedDefaultCollections < ActiveRecord::Migration[8.0]
  def up
    collections_data = [
      { name: 'Best Tech Deals', slug: 'best-tech-deals', description: 'Top picks in electronics, gadgets and tech accessories.', keywords: %w[laptop phone headphones tv monitor] },
      { name: 'Fashion Under $50', slug: 'fashion-under-50', description: 'Stylish fashion deals all under $50.', keywords: %w[shirt shoes dress jacket sneakers] },
      { name: 'Home & Living', slug: 'home-living', description: 'Great deals on furniture, homewares and kitchen essentials.', keywords: %w[sofa chair kitchen vacuum coffee] },
      { name: 'Sports & Outdoors', slug: 'sports-outdoors', description: 'Gear up with the best sports and outdoor deals.', keywords: %w[bike gym yoga running tennis] },
      { name: 'Gifts Under $50', slug: 'gifts-under-50', description: 'Perfect gifts for everyone, all under $50.', keywords: %w[gift present set bundle kit] },
      { name: 'Tech Gifts', slug: 'tech-gifts', description: 'Top technology gifts for the tech lover in your life.', keywords: %w[laptop tablet phone headphones speaker] },
      { name: 'Gifts for Him', slug: 'gifts-for-him', description: 'Great gift ideas for the men in your life.', keywords: %w[men mens him his male] },
      { name: 'Gifts for Her', slug: 'gifts-for-her', description: 'Wonderful gift ideas for the women in your life.', keywords: %w[women womens her ladies female] },
      { name: 'Fashion Deals', slug: 'fashion-deals', description: 'Stylish fashion deals and clothing bargains.', keywords: %w[dress shirt jacket jeans coat] },
      { name: 'Home & Kitchen', slug: 'home-kitchen', description: 'Deals on homewares, appliances and kitchen essentials.', keywords: %w[blender kettle toaster cookware bedding] },
    ]

    collections_data.each do |attrs|
      keywords = attrs.delete(:keywords)

      # Skip if already exists
      next if execute("SELECT 1 FROM collections WHERE slug = '#{attrs[:slug]}' LIMIT 1").any?

      execute <<-SQL
        INSERT INTO collections (name, slug, description, active, created_at, updated_at)
        VALUES (
          #{quote(attrs[:name])},
          #{quote(attrs[:slug])},
          #{quote(attrs[:description])},
          TRUE,
          NOW(),
          NOW()
        )
      SQL

      # Add up to 5 matching products
      collection_id = execute("SELECT id FROM collections WHERE slug = '#{attrs[:slug]}' LIMIT 1").first['id']
      keyword_conditions = keywords.map { |k| "name ILIKE '%#{k}%'" }.join(' OR ')

      products = execute(<<-SQL
        SELECT id FROM products
        WHERE (#{keyword_conditions})
          AND (expired = FALSE OR expired IS NULL)
          AND discount > 0
        ORDER BY discount DESC
        LIMIT 5
      SQL
      )

      products.each_with_index do |row, idx|
        execute <<-SQL
          INSERT INTO collection_items (collection_id, product_id, position, created_at, updated_at)
          VALUES (#{collection_id}, #{row['id']}, #{idx + 1}, NOW(), NOW())
          ON CONFLICT DO NOTHING
        SQL
      end
    end
  end

  def down
    slugs = %w[
      best-tech-deals fashion-under-50 home-living sports-outdoors
      gifts-under-50 tech-gifts gifts-for-him gifts-for-her
      fashion-deals home-kitchen
    ]
    slugs.each do |slug|
      execute("DELETE FROM collections WHERE slug = '#{slug}'")
    end
  end

  private

  def quote(str)
    ActiveRecord::Base.connection.quote(str)
  end
end
