require 'json'
require 'set'
require 'will_paginate/array'

class UsersController < ApplicationController

  before_action :logged_in
  before_action :set_user, only: [:import, :import_playlists, :show, :edit, :update, :destroy]

  # GET /users/id/import
  def import
    spotify_user = RSpotify::User.new(current_user.spotify_hash)
    @playlists = spotify_user.playlists
  end

  def import_playlists
    playlist_ids = params[:playlist_ids]
    user_id = @user.spotify_id

    playlist_ids.each do |playlist_id|

      playlist = RSpotify::Playlist.find(user_id, playlist_id)

      if playlist.public == true && playlist.owner.id == current_user.spotify_id
        image = ""
        unless playlist.images.blank?
          image = playlist.images.first["url"]
        end

        collab = playlist.collaborative ? 1 : 0

        playlistHash = {:display_name => playlist.name,
                        :score => 1,
                        :user_id => current_user.id,
                        :image => image,
                        :collaborative => collab,
                        :followers => playlist.followers['total']}

        bot_playlist = Playlist.where(spotify_id: playlist.id).first

        new_playlist = false
        if bot_playlist
          bot_playlist.update_attributes(playlistHash)
        else
          new_playlist = true
          playlistHash["spotify_id"] = playlist.id
          playlistHash["spotify_uri"] = playlist.uri
          bot_playlist = Playlist.new(playlistHash)
        end

        if bot_playlist.save

          add_tracks(bot_playlist, playlist)

          unless new_playlist
            remove_tracks(bot_playlist, playlist)
          end
        end

      end

    end

    current_user.update_attribute(:stored_playlists, playlist_ids)
    current_user.update_attribute(:imported, true)
    flash[:success] = "Updated User's Library"
    redirect_to current_user
  end
  # GET /users
  # GET /users.json
  def index
    @users = User.all.paginate(page: params[:page])
  end

  # GET /users/id
  # GET /users/id.json
  def show
    @playlists = Playlist.where(user_id: @user.id).order("display_name ASC").paginate(page: params[:page])
  end

  # GET /users/new
  def new
    @user = User.new
  end

  private
  # Use callbacks to share common setup or constraints between actions.
  def set_user
    @user = User.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def user_params
    params.require(:user).permit(:display_name, :spotify_id, :birthday, :spotify_hash)
  end

  def add_tracks (bot_playlist, playlist)
    tracks = playlist.tracks
    added_by_array = playlist.tracks_added_by

    display_names = {}
    tracks.each do |track|

      bot_track = Track.where(spotify_id: track.id, playlist_id: bot_playlist.id).first
      user_uri = added_by_array[track.id].id

      unless display_names[user_uri]
        user = RSpotify::User.find(user_uri)
        display_names[user_uri] = user.display_name
      end

      display_user_name = display_names[user_uri]


      unless bot_track
        artist = track.artists.first
        bot_track = Track.new(:display_name => track.name,
                              :artist_name => artist.name,
                              :spotify_id => track.id,
                              :score => 1,
                              :playlist_id => bot_playlist.id,
                              :spotify_uri => track.uri,
                              :added_by_uid => user_uri,
                              :added_by_display_name => display_user_name
        )

        bot_track.save
      end
    end
  end

  def remove_tracks (bot_playlist, playlist)
    bot_tracks = Track.where(playlist_id: bot_playlist.id)
    tracks = playlist.tracks

    check_set = Set.new []
    tracks.each do |track|
      check_set.add(track.id)
    end

    bot_tracks.each do |bot_track|
      if check_set.include?(bot_track.spotify_id)
        check_set.delete(bot_track.spotify_id)
      else
        bot_track.destroy
      end
    end


  end

end
