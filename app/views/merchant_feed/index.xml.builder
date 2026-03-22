xml.instruct! :xml, version: '1.0', encoding: 'UTF-8'
xml.rss version: '2.0', 'xmlns:g' => 'http://base.google.com/ns/1.0' do
  xml.channel do
    xml.title 'OzVFY — Best Deals in Australia'
    xml.link 'https://www.ozvfy.com'
    xml.description 'Curated deals from top Australian retailers'

    @products.each do |product|
      next if product.store_url.blank?

      xml.item do
        xml.tag!('g:id', product.store_product_id)
        xml.tag!('g:title', product.name.to_s.truncate(150))
        xml.tag!('g:description', (product.description || product.name).to_s.truncate(5000))
        xml.tag!('g:link', "https://www.ozvfy.com/deals/#{product.id}")
        xml.tag!('g:image_link', product.image_url)
        xml.tag!('g:price', format('%.2f AUD', (product.old_price.presence || product.price)))
        xml.tag!('g:sale_price', format('%.2f AUD', product.price)) if product.discount&.positive?
        xml.tag!('g:brand', product.brand.presence || 'Unknown')
        xml.tag!('g:condition', 'new')
        xml.tag!('g:availability', 'in stock')
        xml.tag!('g:google_product_category', product.categories.first.presence || 'Apparel & Accessories')
        xml.tag!('g:product_type', product.categories.join(' > ').presence || 'General')
        xml.tag!('g:store', product.store)
      end
    end
  end
end
