class RegistrationsController < ApplicationController
  allow_unauthenticated_access

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    if @user.save
      redirect_to root_path
    end
  end


  private


  def user_params
    params.require(:user).permit(
      :first_name,
      :last_name,
      :email_address,
      :password
    )
  end
end
