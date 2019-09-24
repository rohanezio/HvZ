class ContactMessagesController < ApplicationController
  before_filter :check_admin, :only => [:destroy, :edit, :list]

  def new
    @admins = Person.where(is_admin: true)
    @contact_message = ContactMessage.new
  end

  end

  def list
    if params[:all].nil?
      @messages = @current_game.contact_messages.where(visible: true).order('created_at DESC')
    else
      @messages = @current_game.contact_messages.order('created_at DESC')
    end
  end

  def update
    @contact_message = ContactMessage.find(params[:id])

    if @contact_message.update_attributes(params[:contact_message])
      flash[:notice] = "Note updated"
      redirect_to list_contact_messages_url
    else
      flash[:error] = @contact_message.errors.full_messages.first
      render :edit
    end
  end
end
