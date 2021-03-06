class SessionsController < ApplicationController


  def create
    spotify_user = RSpotify::User.new(request.env['omniauth.auth'])

    user = User.where(spotify_id: spotify_user.id).first
    hash = spotify_user.to_hash

    if user.blank?
      user = User.new(:spotify_id => spotify_user.id.to_s,
                      :spotify_uri => spotify_user.uri,
                      :display_name => spotify_user.display_name,
                      :birthday => spotify_user.birthdate,
                      :spotify_hash => hash,
                      :login_expires_at => Time.now + 1.day,
                      :image => spotify_user.images.first["url"],
                      :stored_playlists => [])

    else
      user.update_attributes(:login_expires_at => Time.now + 1.day,
                             :spotify_hash => hash)
    end

    if user.save!
      puts "user saved"
      session[:user_id] = user.id
      redirect_to root_path
    else
      redirect_to 'error'
    end

  end

  def destroy
    log_out if logged_in?
    redirect_to root_url
  end

  def error
  end

end
