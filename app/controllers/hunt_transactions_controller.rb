class HuntTransactionsController < ApplicationController
  before_action :ensure_login!

  # GET /hunt_transactions.json
  def index
    @transactions = HuntTransaction.
      where('sender = ? OR receiver = ?', @current_user.username, @current_user.username).
      order('created_at DESC').
      limit(1000)

    render json: {
      balance: @current_user.hunt_balance,
      eth_address: @current_user.eth_address,
      transactions: @transactions
    }
  end

  private
    def user_params
      params.require(:user).permit(:username, :token)
    end
end