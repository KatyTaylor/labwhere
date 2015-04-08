class LocationsController < ApplicationController

  before_filter :locations, only: [:index]
  
  def index
  end

  def new
    @location = Location.new
  end

  def create
    @location = Location.new(location_params)

    if @location.save
      flash[:notice] = "Location successfully created"
      redirect_to locations_path
    else
      render :new
    end
  end

  def edit
    @location = current_resource
  end

  def update
    @location = current_resource

    if @location.update_attributes(location_params)
      flash[:notice] = "Location successfully updated"
      redirect_to locations_path
    else
      render :edit
    end
  end

protected

  def locations
    @locations ||= Location.all
  end

  helper_method :locations

private

  def current_resource
    @current_resource ||= Location.find(params[:id]) if params[:id]
  end
  
  def location_params
    params.require(:location).permit(:name, :barcode, :location_type_id, :container)
  end
end
