class PagesController < ApplicationController
  allow_unauthenticated_access

  def home
    if authenticated?
      @games = Game.for_user(Current.session.user)
    else
      @games = Game.none
    end
  end
end
