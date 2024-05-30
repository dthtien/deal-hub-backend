class Pagination
  DEFAULT = { page: 1, per_page: 25 }.freeze

  def initialize(scope, params = {})
    @page     = (params[:page] || DEFAULT[:page]).to_i
    @per_page = params[:per_page] || DEFAULT[:per_page]
    @scope = scope
    @exclude_count = params[:exclude_count]
  end

  def collection
    @collection ||= scope.limit(per_page).offset(offset)
  end

  def metadata
    @metadata ||= build_metadata
  end

  private

  attr_reader :page, :per_page, :scope

  def exclude_count?
    @exclude_count
  end

  def build_metadata
    metadata = { page:, per_page: }

    if exclude_count?
      metadata[:show_next_page] = next_page?
    else
      metadata[:total_count] = scope.count
      metadata[:total_pages] = (metadata[:total_count].to_f / per_page).ceil
    end

    metadata
  end

  def next_page?
    scope.limit(1).offset(offset + per_page).exists?
  end

  def offset
    (@page - 1) * @per_page
  end
end
