class ContactMessagesController < ApplicationController
  before_filter :check_admin, :only => [:destroy, :edit, :list]

  def list
    if params[:all].nil?
      @messages = @current_game.contact_messages.where(visible: true).order('created_at DESC')
    else
      @messages = @current_game.contact_messages.order('created_at DESC')
    end
  end
end
