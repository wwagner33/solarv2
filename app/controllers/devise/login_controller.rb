class Devise::LoginController < Devise::SessionsController

  skip_before_filter :check_concurrent_session
  prepend_before_action :verify_user_data

  def create
    # @return = verify_user_data

    case @return
    when 1; redirect_to login_path, alert: t('devise.failure.invalid_login_si3')
    when 2; redirect_to login_path, alert: t('devise.failure.invalid_login')
    when 3; redirect_to login_path, alert: t("users.errors.ma.selfregistration").html_safe
    when 4; redirect_to login_path, alert: t("users.errors.ma.changed_username", new_username: @previous_username).html_safe
    when 5
      super
      current_user.session_token = Devise.friendly_token
      user_session[:token] = current_user.session_token
      current_user.save(validate: false)
    when 0; redirect_to login_path
    end

  rescue CanCan::AccessDenied
    # something
  rescue => error
    # something
  end

  protected

  def auth_options
    { scope: resource_name, recall: "#{controller_path}#new" }
  end

  def verify_user_data
    @return = 0

    return if params[:user].blank?
    user = User.where("lower(username) = :login OR cpf = :login", login: params[:user][:login].try(:downcase)).first
    correct_password = user.valid_password?(params[:user][:password]) unless user.blank?

    if user.nil?
      @return = if !User::MODULO_ACADEMICO.nil?
        user = User.import_user_by_username(params[:user][:login].try(:downcase))
        if user.nil?
          1
        else
          verify_user_data
        end
      else
        2
      end
      # return if user.nil?
    else
      if user.integrated && !user.on_blacklist? && !user.selfregistration
        user.synchronize
        @return = 3 unless user.selfregistration
        correct_password = user.valid_password?(params[:user][:password])
      elsif (user.integrated && !user.on_blacklist? && !correct_password)
        user.synchronize
        user = User.where("lower(username) = :login OR cpf = :login", login: params[:user][:login].try(:downcase)).first
        correct_password = user.valid_password?(params[:user][:password])
      end
      unless correct_password
        previous_user = User.where("lower(previous_username) = :login", login: params[:user][:login].try(:downcase))
        previous_user = previous_user.collect{|puser| puser if puser.valid_password?(params[:user][:password])}
        previous_user = previous_user.compact.first
        unless previous_user.blank?
          @return = 4
          @previous_username = previous_user.username
        else
          user = User.import_user_by_username(params[:user][:login].try(:downcase))
        end
      end

      @return = 5 if user.blank?
      @return = 5 unless @return != 0 || (user.integrated && !user.on_blacklist? && !user.selfregistration)

      @return
    end
  end

  def set_flash_message!(key, kind, options = {})
    message = find_message(kind, options)
    if options[:now]
      flash.now[key] = message if message.present?
    else
      flash[key] = message if message.present?
    end
  end

end
