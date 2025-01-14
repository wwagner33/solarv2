# class OauthApplicationsController < Doorkeeper::ApplicationsController
class Oauth::ApplicationsController < Doorkeeper::ApplicationsController
  # uninitialized constant OauthApplicationsController
  before_filter :authenticate_user!

  def index
    authorize! :oauth_applications, Administration
    @applications = current_user.oauth_applications

  end

  # only needed if each application must have some owner
  def create
    authorize! :oauth_applications, Administration
    @application = Doorkeeper::Application.new(application_params)
    @application.owner = current_user if Doorkeeper.configuration.confirm_application_owner?
    if @application.save
      flash[:notice] = I18n.t(:notice, :scope => [:doorkeeper, :flash, :applications, :create])
      respond_with [:oauth, @application]
    else
      render :new
    end
  end

end
