class ApplicationController < ActionController::API
  def render_404
    render json: { error: 'NOT_FOUND' }, status: :not_found
  end
end
