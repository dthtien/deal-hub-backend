# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

# Seed coupons
coupons = [
  { store: 'ASOS', code: 'ASOS20', description: '20% off your order', discount_value: 20, discount_type: 'percent', verified: true },
  { store: 'ASOS', code: 'FREESHIP', description: 'Free standard shipping', discount_value: nil, discount_type: 'percent', verified: true },
  { store: 'The Iconic', code: 'ICONIC15', description: '15% off full price items', discount_value: 15, discount_type: 'percent', verified: true },
  { store: 'The Iconic', code: 'WELCOME20', description: '20% off first order', discount_value: 20, discount_type: 'percent', verified: false },
  { store: 'JB Hi-Fi', code: 'JBSAVE10', description: '$10 off orders over $100', discount_value: 10, discount_type: 'fixed', minimum_spend: '$100', verified: true },
  { store: 'Myer', code: 'MYER15', description: '15% off sitewide', discount_value: 15, discount_type: 'percent', verified: true },
  { store: 'Nike', code: 'NIKE20', description: '20% off with Member access', discount_value: 20, discount_type: 'percent', verified: false },
  { store: 'Kmart', code: 'KMART5', description: '$5 off $50+ spend', discount_value: 5, discount_type: 'fixed', minimum_spend: '$50', verified: false },
  { store: 'Culture Kings', code: 'CK10', description: '10% off streetwear', discount_value: 10, discount_type: 'percent', verified: true },
  { store: 'Office Works', code: 'OW10', description: '10% off stationery', discount_value: 10, discount_type: 'percent', verified: false },
]

coupons.each do |attrs|
  Coupon.find_or_create_by(store: attrs[:store], code: attrs[:code]) do |c|
    c.assign_attributes(attrs.merge(active: true))
  end
end
puts "Seeded #{coupons.count} coupons"

# Seed tags on top products
tag_groups = [
  ["free shipping", "limited time"],
  ["clearance", "bundle deal"],
  ["flash sale"],
  ["limited time", "flash sale"],
  ["free shipping", "clearance"],
]
Product.order(created_at: :desc).limit(10).each_with_index do |product, i|
  product.update_columns(tags: tag_groups[i % tag_groups.size])
end
puts "Seeded tags on top products"

# Seed collections
collections_data = [
  { name: 'Best Tech Deals', slug: 'best-tech-deals', description: 'Top picks in electronics, gadgets and tech accessories.', keywords: %w[laptop phone headphones tv monitor] },
  { name: 'Fashion Under $50', slug: 'fashion-under-50', description: 'Stylish fashion deals all under $50.', keywords: %w[shirt shoes dress jacket sneakers] },
  { name: 'Home & Living', slug: 'home-living', description: 'Great deals on furniture, homewares and kitchen essentials.', keywords: %w[sofa chair kitchen vacuum coffee] },
  { name: 'Sports & Outdoors', slug: 'sports-outdoors', description: 'Gear up with the best sports and outdoor deals.', keywords: %w[bike gym yoga running tennis] },
]

collections_data.each do |attrs|
  keywords = attrs.delete(:keywords)
  collection = Collection.find_or_create_by(slug: attrs[:slug]) do |c|
    c.assign_attributes(attrs.merge(active: true))
  end
  collection.update(attrs) # Update name/desc in case it changed

  # Add top 5 matching products
  if collection.collection_items.count < 5
    keyword_query = keywords.map { |k| "name ILIKE '%#{k}%'" }.join(' OR ')
    products = Product.where(keyword_query).where(expired: false).order(discount: :desc).limit(5)
    products.each_with_index do |product, idx|
      CollectionItem.find_or_create_by(collection: collection, product: product) do |ci|
        ci.position = idx + 1
      end
    end
  end
end
puts "Seeded #{Collection.count} collections"
