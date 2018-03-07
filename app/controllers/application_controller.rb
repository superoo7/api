class ApplicationController < ActionController::API
  include ActionController::HttpAuthentication::Token::ControllerMethods

  protected
    def current_user
      return @current_user unless @current_user.nil?

      authenticate_with_http_token do |token, _|
        return @current_user if @current_user = User.find_by(encrypted_token: token)
      end

      nil
    end

    def ensure_login!
      if current_user.nil?
        self.headers['WWW-Authenticate'] = 'Token realm="Application"'
        render json: { error: 'USER_NOT_FOUND' }, status: :unauthorized
      end
    end

    def check_ownership!
      if @post.author != @current_user.username && !@current_user.admin?
        render json: { error: 'FORBIDDEN' }, status: :forbidden
      end
    end

    def render_404
      render json: { error: 'NOT_FOUND' }, status: :not_found
    end
end
