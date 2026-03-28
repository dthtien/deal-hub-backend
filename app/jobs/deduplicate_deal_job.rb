# frozen_string_literal: true

class DeduplicateDealJob < ApplicationJob
  queue_as :low

  def perform
    duplicates_found = 0
    duplicates_merged = 0

    # Find groups of products with same store + same name (case-insensitive), different store_product_id
    groups = Product.select('LOWER(name) AS norm_name, store, COUNT(*) AS cnt')
                    .group('LOWER(name), store')
                    .having('COUNT(*) > 1')

    groups.each do |group|
      begin
        products = Product.where(store: group.store)
                          .where('LOWER(name) = ?', group.norm_name)
                          .order(created_at: :asc)
                          .to_a

        next if products.size < 2

        # Find which record has the most price_histories - that's the keeper
        keeper = products.max_by { |p| p.price_histories.count }
        duplicates = products.reject { |p| p.id == keeper.id }

        duplicates.each do |dup|
          begin
            merge_duplicate(keeper, dup)
            duplicates_found += 1
            duplicates_merged += 1
            Rails.logger.info("DeduplicateDealJob - merged product #{dup.id} into #{keeper.id} (#{keeper.name})")
          rescue => e
            Rails.logger.error("DeduplicateDealJob - failed to merge #{dup.id}: #{e.message}")
          end
        end
      rescue => e
        Rails.logger.error("DeduplicateDealJob - error processing group #{group.norm_name}/#{group.store}: #{e.message}")
      end
    end

    Rails.logger.info("DeduplicateDealJob - complete. Found: #{duplicates_found}, Merged: #{duplicates_merged}")
  end

  private

  def merge_duplicate(keeper, duplicate)
    # Transfer votes
    Vote.where(product_id: duplicate.id).each do |vote|
      # Only transfer if no existing vote from same session on keeper
      unless Vote.exists?(product_id: keeper.id, session_id: vote.session_id)
        vote.update_columns(product_id: keeper.id)
      end
    end

    # Transfer comments
    Comment.where(product_id: duplicate.id).update_all(product_id: keeper.id)

    # Transfer saved deals
    SavedDeal.where(product_id: duplicate.id).each do |sd|
      unless SavedDeal.exists?(product_id: keeper.id, session_id: sd.session_id)
        sd.update_columns(product_id: keeper.id)
      end
    end

    # Transfer price histories
    PriceHistory.where(product_id: duplicate.id).update_all(product_id: keeper.id)

    # Transfer click trackings
    ClickTracking.where(product_id: duplicate.id).update_all(product_id: keeper.id)

    # Delete the duplicate
    duplicate.delete
  end
end
