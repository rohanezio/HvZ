class MissionsController < ApplicationController
  before_filter :check_admin, :except => [ :show, :index ]
  autocomplete :person, :name

  def new
    @mission = Mission.new
  end

  def attendance
    params.permit!
    @mission = Mission.where(params[:id], include: { game: { registrations: :person } })
    @game = @current_game
  end


  def create
    params.permit!
    @mission = Mission.new(params[:mission])
    @mission.game = @current_game
    if @mission.save
      redirect_to list_missions_path
    else
      flash[:error] = @mission.errors.full_messages.first
      redirect_to new_mission_path
    end
  end

  def destroy
    @mission = Mission.find(params[:id])
    @mission.destroy if @mission

    redirect_to missions_url
  end

  def index
    @missions = @current_game.missions.order(:start)
  end

  def show
    @mission = Mission.find(params[:id])
  end

  def list
    @missions = @current_game.missions.sort_by(&:start)
  end

  def edit
  @mission = Mission.find(params[:id])
  end

  def update
  params.permit!
  @mission = Mission.find(params[:id])
  if @mission.update_attributes(params[:mission])
    redirect_to missions_url()
  else
    flash[:error] = "Could not save mission!"
    redirect_to root_url()
  end
  end

  def points
    params.permit!
    @mission = Mission.find(params[:id])
  end

  def save_points
    params.permit!
    @mission = Mission.find(params[:id])
    Attendance.inspect
    Mission.inspect
   # If this is a mass assignment:
    if params[:mass_points].present?
      [ :human, :zombie, :deceased ].each do |faction|
        Attendance.
          where(:id => @player_factions[faction].map(&:id)).
          update_all(:score => params[:mass_points][faction].to_i)
      end
      return redirect_to points_mission_url(@mission)
    end

    # If this is an individual assignment:
    if params[:points].present?
      params[:points].each do |id, points|
        next if points.empty?
        Attendance.find(id).update_attribute(:score, points)
      end
      return redirect_to points_mission_url(@mission)
    end
  end
end
