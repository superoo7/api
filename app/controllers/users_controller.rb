class UsersController < ApplicationController
  # Create or Update user's encrypted_token
  # POST /users.json
  def create
    if @user = User.find_by(username: user_params[:username])
      @user.encrypted_token = user_params[:encrypted_token]
    else
      @user = User.new(user_params)
    end

    @users.session_count += 1

    if @user.save
      render json: @user, status: :ok
    else
      render json: { error: @user.errors.full_messages.first }, status: :unprocessable_entity
    end
  end

  private
    def user_params
      params.require(:user).permit(:username, :encrypted_token)
    end
end