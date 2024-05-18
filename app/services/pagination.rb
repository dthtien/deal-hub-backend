class Pagination
  DEFAULT = { page: 1, per_page: 25 }.freeze

  def initialize(scope, params = {})
    @page     = (params[:page] || DEFAULT[:page]).to_i
    @per_page = params[:per_page] || DEFAULT[:per_page]
    @scope = scope
    @include_count = params[:include_count] || true
  end

  def collection
    @collection ||= scope.limit(per_page).offset(offset)
  end

  def metadata
    @metadata ||= build_metadata
  end

  private

  attr_reader :page, :per_page, :scope

  def include_count?
    @include_count
  end

  def build_metadata
    metadata = { page:, per_page: }

    if include_count?
      metadata[:total_count] = scope.count
      metadata[:total_pages] = (metadata[:total_count].to_f / per_page).ceil
    end

    metadata
  end

  def offset
    (@page - 1) * @per_page
  end
end
