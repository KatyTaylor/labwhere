# frozen_string_literal: true

##
# This will upload multiple labware at once into existing locations.
# It can be used from a view or elsewhere.
class UploadFileForm
  include ActiveModel::Model

  attr_reader :current_user, :controller, :action, :params

  validate :check_user, :check_required_params

  def submit(params)
    @params = params
    assign_params
    @current_user = User.find_by_code(@user_code)

    if valid?
      # TODO: uploader = ManifestUploader.new(@file)
      # TODO: uploader.run
      true
    else
      false
    end
  end

  def assign_params
    @controller = params[:controller]
    @action = params[:action]
    @user_code = params[:upload_file_form][:user_code]
    @file = params[:upload_file_form][:file]
  end

  def check_user
    UserValidator.new.validate(self)
  end

  def check_required_params
    params.require([:controller, :action])
    params.require(:upload_file_form).permit([:user_code, :file]).tap do |form_params|
      form_params.require([:user_code, :file])
    end
  rescue ActionController::ParameterMissing
    errors.add(:base, 'The required fields must be filled in')
  end
end
