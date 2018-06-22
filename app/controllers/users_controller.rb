class UsersController < ApplicationController
  # Create or Update user's encrypted_token
  # POST /users.json
  def create
    if @user = User.find_by(username: user_params[:username])
      unless @user.validate!(user_params[:token])
        render json: { error: 'UNAUTHORIZED' }, status: :unauthorized and return
      end
    else
      @user = User.new(
        username: user_params[:username],
        encrypted_token: Digest::SHA256.hexdigest(user_params[:token])
      )
    end

    @user.session_count += 1
    @user.last_logged_in_at = Time.now

    if @user.save
      render json: @user.as_json(only: [:username, :created_at, :blacklisted_at], methods: [:voting_weight, :diversity_score]), status: :ok
    else
      render json: { error: @user.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:username, :token)
    end
end