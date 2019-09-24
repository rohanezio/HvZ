class ContactMessagesController < ApplicationController
  before_filter :check_admin, :only => [:destroy, :edit, :list]

  def new
    @admins = Person.where(is_admin: true)
    @contact_message = ContactMessage.new
  end

  def list
    if params[:all].nil?
      @messages = @current_game.contact_messages.where(visible: true).order('created_at DESC')
    else
      @messages = @current_game.contact_messages.order('created_at DESC')
    end
  end
end
