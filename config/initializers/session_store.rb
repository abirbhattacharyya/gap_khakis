# Be sure to restart your server when you modify this file.

# Your secret key for verifying cookie session data integrity.
# If you change this key, all old sessions will become invalid!
# Make sure the secret is at least 30 characters and all random, 
# no regular words or you'll be exposed to dictionary attacks.
ActionController::Base.session = {
  :key         => '_gap_khakis_session',
  :secret      => 'cdd1214c064e78b3834ca8c4ef5daf9c526ecffd8092aef348564b0fed6ff7aa8532f2fb668959d7d77ad4ad927956ceb5144fa97494673adef87f69a874c3ab'
}

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
# ActionController::Base.session_store = :active_record_store
