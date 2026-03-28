# frozen_string_literal: true

module Admin
  class ProductsController < Admin::BaseController
    PER_PAGE = 50

    def index
      scope = Product.all
      scope = scope.where(store: params[:store]) if params[:store].present?
      scope = scope.where(expired: params[:expired] == 'true') if params[:expired].present?
      @page = (params[:page] || 1).to_i
      @total = scope.count
      @products = scope.order(created_at: :desc).offset((@page - 1) * PER_PAGE).limit(PER_PAGE)
      @stores = Product.distinct.pluck(:store).compact.sort
      @total_pages = (@total / PER_PAGE.to_f).ceil

      # Detect potential duplicates in this page
      product_keys = @products.map { |p| [p.store, p.name.to_s.downcase.strip] }
      dup_keys = Product.select('store, LOWER(TRIM(name)) AS norm_name, COUNT(*) AS cnt')
                        .group('store, LOWER(TRIM(name))')
                        .having('COUNT(*) > 1')
                        .map { |r| [r.store, r.norm_name] }
                        .to_set
      @duplicate_product_ids = @products.select { |p| dup_keys.include?([p.store, p.name.to_s.downcase.strip]) }.map(&:id).to_set
    end

    def update
      @product = Product.find(params[:id])
      field = params[:field]
      if %w[expired featured best_deal].include?(field)
        @product.update!(field => !@product[field])
      end
      redirect_to admin_products_path(request.query_parameters.except('_method')), notice: "Product ##{@product.id} updated."
    end

    def bulk_update
      ids    = Array(params[:ids])
      action = params[:action_type].to_s
      products = Product.where(id: ids)

      case action
      when 'expire'
        products.update_all(expired: true)
      when 'feature'
        products.update_all(featured: true)
      when 'unfeature'
        products.update_all(featured: false)
      end

      redirect_to admin_products_path, notice: "#{products.count} product(s) updated."
    end

    def bulk_action
      body_params = request.content_type&.include?('application/json') ? JSON.parse(request.body.read) : params.to_unsafe_h
      ids    = Array(body_params['product_ids'] || body_params[:product_ids]).map(&:to_i)
      action = (body_params['action'] || body_params[:action]).to_s
      products = Product.where(id: ids)

      case action
      when 'mark_expired'
        products.update_all(expired: true)
        notice = "#{products.count} product(s) marked as expired."
      when 'mark_flash'
        products.update_all(flash_deal: true, flash_expires_at: 24.hours.from_now)
        notice = "#{products.count} product(s) marked as flash deals."
      when 'delete'
        count = products.count
        products.destroy_all
        notice = "#{count} product(s) deleted."
      else
        notice = "Unknown action."
      end

      render json: { message: notice }
    end

    def mark_flash
      product = Product.find(params[:id])
      product.update!(flash_deal: true, flash_expires_at: 24.hours.from_now)
      redirect_to admin_products_path, notice: "Product ##{product.id} marked as flash deal."
    end

    def clone
      original = Product.find(params[:id])
      cloned = original.dup
      cloned.name = "[COPY] #{original.name}"
      cloned.store_product_id = "#{original.store_product_id}-copy-#{SecureRandom.hex(4)}"
      cloned.save!

      original.price_histories.each do |ph|
        new_ph = ph.dup
        new_ph.product_id = cloned.id
        new_ph.save!
      end

      render json: cloned.as_json, status: :created
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Product not found' }, status: :not_found
    rescue ActiveRecord::RecordInvalid => e
      render json: { error: e.message }, status: :unprocessable_entity
    end

    def bulk_update_products
      body_params = request.content_type&.include?('application/json') ? JSON.parse(request.body.read) : params.to_unsafe_h
      updates = Array(body_params['products'] || body_params[:products]).first(100)

      if updates.empty?
        return render json: { error: 'No products provided' }, status: :unprocessable_entity
      end

      valid_fields = %w[expired discount price]
      records = updates.filter_map do |item|
        id = item['id'].to_i
        next if id <= 0
        row = { id: id }
        valid_fields.each do |field|
          row[field] = item[field] if item.key?(field)
        end
        row[:updated_at] = Time.current
        row
      end

      if records.empty?
        return render json: { error: 'No valid records to update' }, status: :unprocessable_entity
      end

      Product.upsert_all(records, unique_by: :id, update_only: (valid_fields + ['updated_at']).map(&:to_sym))

      render json: { updated_count: records.size, message: "#{records.size} product(s) updated." }
    rescue JSON::ParserError
      render json: { error: 'Invalid JSON' }, status: :bad_request
    end

    def bulk_expire
      body_params = request.content_type&.include?('application/json') ? JSON.parse(request.body.read) : params.to_unsafe_h

      scope = Product.all
      if body_params['store_name'].present?
        scope = scope.where(store: body_params['store_name'])
      elsif body_params['older_than_days'].to_i > 0
        cutoff = body_params['older_than_days'].to_i.days.ago
        scope = scope.where('created_at < ?', cutoff)
      else
        return render json: { error: 'Provide store_name or older_than_days' }, status: :unprocessable_entity
      end

      count = scope.where(expired: false).update_all(expired: true)
      render json: { expired_count: count, message: "#{count} product(s) marked as expired." }
    rescue JSON::ParserError
      render json: { error: 'Invalid JSON' }, status: :bad_request
    end

    def merge
      body_params = request.content_type&.include?('application/json') ? JSON.parse(request.body.read) : params.to_unsafe_h
      primary_id   = body_params['primary_id'].to_i
      duplicate_id = body_params['duplicate_id'].to_i

      if primary_id.blank? || duplicate_id.blank? || primary_id == duplicate_id
        return render json: { error: 'primary_id and duplicate_id required and must differ' }, status: :unprocessable_entity
      end

      keeper    = Product.find(primary_id)
      duplicate = Product.find(duplicate_id)

      # Transfer associations
      Vote.where(product_id: duplicate.id).each do |vote|
        vote.update_columns(product_id: keeper.id) unless Vote.exists?(product_id: keeper.id, session_id: vote.session_id)
      end
      Comment.where(product_id: duplicate.id).update_all(product_id: keeper.id)
      SavedDeal.where(product_id: duplicate.id).each do |sd|
        sd.update_columns(product_id: keeper.id) unless SavedDeal.exists?(product_id: keeper.id, session_id: sd.session_id)
      end
      PriceHistory.where(product_id: duplicate.id).update_all(product_id: keeper.id)
      ClickTracking.where(product_id: duplicate.id).update_all(product_id: keeper.id)

      duplicate.delete

      render json: { message: "Product #{duplicate_id} merged into #{primary_id}.", primary_id: primary_id }
    rescue ActiveRecord::RecordNotFound => e
      render json: { error: e.message }, status: :not_found
    rescue JSON::ParserError
      render json: { error: 'Invalid JSON' }, status: :bad_request
    end

    def extend_expiry
      product = Product.find(params[:id])
      new_expiry = (product.flash_expires_at || Time.current) + 24.hours
      product.update!(flash_expires_at: new_expiry)
      NotificationLog.create!(
        notification_type: 'expiry_extension',
        recipient:         "admin",
        subject:           "Extended expiry for product #{product.id}: #{product.name}",
        status:            'sent'
      )
      render json: { ok: true, flash_expires_at: new_expiry.iso8601, product_id: product.id }
    rescue ActiveRecord::RecordNotFound
      render json: { error: 'Not found' }, status: :not_found
    end

    def bulk_extend
      body_params = request.content_type&.include?('application/json') ? JSON.parse(request.body.read) : params.to_unsafe_h
      ids = Array(body_params['ids']).map(&:to_i).reject(&:zero?)
      return render json: { error: 'ids required' }, status: :unprocessable_entity if ids.empty?

      extended = []
      Product.where(id: ids).find_each do |product|
        new_expiry = (product.flash_expires_at || Time.current) + 24.hours
        product.update!(flash_expires_at: new_expiry)
        NotificationLog.create!(
          notification_type: 'expiry_extension',
          recipient:         "admin",
          subject:           "Bulk extended expiry for product #{product.id}",
          status:            'sent'
        )
        extended << { id: product.id, flash_expires_at: new_expiry.iso8601 }
      end
      render json: { ok: true, extended: extended, count: extended.length }
    rescue JSON::ParserError
      render json: { error: 'Invalid JSON' }, status: :bad_request
    end
  end
end
