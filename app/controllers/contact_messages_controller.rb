class ContactMessagesController < ApplicationController
  before_filter :check_admin, :only => [:destroy, :edit, :list]

  def new
    @admins = Person.where(is_admin: true)
    @contact_message = ContactMessage.new
  end
end
