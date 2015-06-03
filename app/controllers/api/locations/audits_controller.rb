class Api::Locations::AuditsController < ApplicationController

  def index
    render json: current_resource
  end

private

  def current_resource
    Location.find_by_code(params[:location_barcode]).audits if params[:location_barcode]
  end

end