class ContactMessagesController < ApplicationController
  before_filter :check_admin, :only => [:destroy, :edit, :list]

end
