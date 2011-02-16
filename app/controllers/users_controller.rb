class UsersController < ApplicationController
  before_filter :check_login, :except => [:biz, :forgot, :destroy]

  def biz
    if logged_in?
      redirect_to root_path
      return
    end
    if params[:user]
      logout_keeping_session!
      @user = User.authenticate(params[:user][:email], params[:user][:password])
      if @user
        @user.update_attribute(:is_blocked, false)
        session[@user.email] = nil
        
        self.current_user = @user
        new_cookie_flag = (params[:remember_me] == "1")
        handle_remember_cookie! new_cookie_flag
        redirect_back_or_default('/')
        flash[:notice] = nil
      else
        @new_user = User.find_by_email(params[:user][:email])
        if @new_user
          if @new_user.is_blocked
            @message = "Your account is locked. Click on Forgot Password"
          else
            session[@new_user.email] = 1 if session[@new_user.email].nil?
            if session[@new_user.email]
              if session[@new_user.email] >= 3
                @new_user.update_attribute(:is_blocked, true)
                @message = "Your account is locked. Click on Forgot Password"
              else
                @message = "You have only #{3 - session[@new_user.email]} attempts"
              end
              session[@new_user.email] += 1
            end
          end
        end
        flash[:error] = "Please enter valid information"
      end
    end
  end

  def profile
    @profile = current_user.profile if current_user.profile
    if request.post?
      @profile = Profile.new(params[:profile])
      if @profile.valid?
        current_user.profile.destroy if current_user.profile
        @profile.user = current_user
        @profile.save
        flash[:notice] = "Profile saved successfully"
        redirect_to root_path
      else
        flash[:error] = "Please enter valid information"
      end
    end
  end

  def forgot
    flash.discard
    email = params[:email]
    if email and !email.strip.blank?
      @user = User.find_by_email(email)
      if @user.nil?
        flash[:error] = "No such ID, want to join?"
      else
        Notification.deliver_forgot_password(@user)
        flash[:notice] = "Yeah! Emailed you the password."
        redirect_to root_path
      end
    else
      flash[:error] = "Please enter valid information"
    end
  end

  def change_password
    if request.post?
        if params[:password].strip.blank?
          flash[:error] = "Please enter valid information"
        else
          if current_user.update_attribute("password", params[:password])
            flash[:notice] = "Password changed successfully"
            redirect_to root_path
          else
            flash[:error] = "Please enter valid information"
          end
        end
    end
  end

  def destroy
    logout_killing_session!
    session[:user_id] = nil
    flash[:notice] = "You have ended your session."
    redirect_back_or_default('/')
  end
end
