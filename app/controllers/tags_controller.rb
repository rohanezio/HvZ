class TagsController < ApplicationController
  before_filter :check_is_registered

  def new
    if @logged_in_registration.is_human? and not @is_admin
      flash[:error] = "You are not a Zombie, so you cannot report tags!"
      redirect_to root_url()
      return
    end
    @tag = Tag.new
    @zombies = Registration.where(:game_id => @current_game, :faction_id => 1).
      includes(:tagged, :taggedby, :missions, :person).
      sort_by { |x| [ (x.time_until_death / 1.hour).ceil, -x.tagged.length ] }

  end

  def create
    #TODO: This is really ugly.
    params.permit!
    @tag = Tag.new(params[:tag])
    @tag.game = @current_game
    if @tag.tagee_id.nil?
      flash[:error] = "Invalid Card Code Specified!"
      redirect_to new_tag_url()
      return
    end
    if not params[:tag_meta].nil? and params[:tag_meta][:is_admin_tag] == "true"
      @tag.admin = @logged_in_person
      @tag.tagger_id = params[:tag][:tagger_id]
    end
    @tag.tagger = @logged_in_registration if @tag.tagger.nil?
    @points_given = 0
    @points_given = @tag.tagee.score*0.2 unless @tag.award_points=="0"
    @tag.score = @points_given
    unless @tag.save()
      flash[:error] = @tag.errors.full_messages.first
      redirect_to new_tag_url()
      return
    end
    Delayed::Job.enqueue SendNotification.new(:tag, @tag)
  end
end
