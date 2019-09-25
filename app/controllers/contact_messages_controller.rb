class ContactMessagesController < ApplicationController
  before_filter :check_admin, :only => [:destroy, :edit, :list]

  def new
    @admins = Person.where(is_admin: true)
  end
end
