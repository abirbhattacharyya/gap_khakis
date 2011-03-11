# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'rubygems'
require 'open-uri'
require "csv"
require 'pdf/writer'
require 'gattica'

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time

  include AuthenticatedSystem # logged_in? and current_user
  include ApplicationHelper

  protect_from_forgery # See ActionController::RequestForgeryProtection for details

  # Scrub sensitive parameters from your log
  # filter_parameter_logging :password

  def check_login
    if logged_in?
      flash.discard
    else
      flash[:notice] = "Please login first"
      redirect_to root_path
    end
  end

  def check_emails(emails)
    return false if emails.gsub(',','').blank?
    emails.split(',').each do |email|
        unless email.strip =~ /\A([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})\Z/
          return false
        end
    end
    return true
  end
end
