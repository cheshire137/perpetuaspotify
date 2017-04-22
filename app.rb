require 'dotenv/load'
require 'sinatra'
require 'sinatra/activerecord'

require_relative 'models/playlist_manager'
require_relative 'models/spotify_auth_api'
require_relative 'models/spotify_api'
require_relative 'models/spotify_trackset'
require_relative 'models/user'

configure do
  file = File.new("#{settings.root}/log/#{settings.environment}.log", 'a+')
  file.sync = true

  use Rack::CommonLogger, file
end

def escape_url(url)
  URI.escape(url, Regexp.new("[^#{URI::PATTERN::UNRESERVED}]"))
end

def get_spotify_auth_url
  client_id = ENV['SPOTIFY_CLIENT_ID']
  redirect_uri = escape_url("#{request.base_url}/callback/spotify")
  scopes = ['user-read-recently-played', 'user-read-email',
            'playlist-modify-public']

  "https://accounts.spotify.com/authorize?client_id=" +
    "#{client_id}&response_type=code&redirect_uri=" +
    "#{redirect_uri}&scope=#{scopes.join('%20')}"
end

enable :sessions
set :session_secret, ENV['SESSION_SECRET']

not_found do
  status 404
  erb :not_found
end

get '/' do
  if user_id = session[:user_id]
    if user = User.where(id: user_id).first
      redirect "/user/#{user.to_param}"
      return
    end
  end

  @auth_url = get_spotify_auth_url
  erb :index
end

get '/logout' do
  session[:user_id] = nil
  redirect '/'
end

# User is authenticated with both Spotify and Slack.
get '/user/:id-:user_name' do
  unless session[:user_id].to_s == params['id'].to_s
    redirect '/'
    return
  end

  @user = User.where(id: params['id'], user_name: params['user_name']).first

  unless @user
    status 404
    erb :not_found
    return
  end

  trackset = SpotifyTrackset.new(@user, logger: logger)

  @tracks = begin
    trackset.tracks
  rescue SpotifyTrackset::Error
    status 400
    return 'Failed to get recent Spotify tracks.'
  end

  @recommendations = trackset.recommendations
  @playlist_name = PlaylistManager::NAME

  @error = session[:error]
  session[:error] = nil

  @playlist_url = session[:playlist_url]
  session[:playlist_url] = nil

  erb :user
end

# Create a playlist as the authenticated user.
post '/playlists' do
  unless session[:user_id]
    redirect '/'
    return
  end

  user = User.where(id: session[:user_id]).first

  unless user
    status 404
    erb :not_found
    return
  end

  manager = PlaylistManager.new(user, logger: logger)
  manager.sync_playlist(params['track_uris'])

  if manager.playlist
    user.spotify_playlist_id = manager.playlist.id
    user.save if user.changed?

    session[:playlist_url] = manager.playlist.url
  else
    session[:error] = 'Could not create playlist on Spotify.'
  end

  redirect "/user/#{user.to_param}"
end

# Callback for Spotify OAuth authentication.
get '/callback/spotify' do
  code = params['code']
  redirect_uri = escape_url("#{request.base_url}/callback/spotify")

  spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],
                                        ENV['SPOTIFY_CLIENT_SECRET'])
  tokens = spotify_auth_api.get_tokens(code, redirect_uri)

  if tokens
    access_token = tokens['access_token']
    refresh_token = tokens['refresh_token']
    spotify_api = SpotifyApi.new(access_token, logger: logger)

    if me = spotify_api.get_me
      user = User.where(email: me['email']).first_or_initialize
      user.spotify_access_token = access_token
      user.spotify_refresh_token = refresh_token
      user.user_name = me['id']

      if user.save
        session[:user_id] = user.id
        redirect "/user/#{user.to_param}"
      else
        status 422
        "Failed to sign in: #{user.errors.full_messages.join(', ')}"
      end
    else
      status 400
      "Failed to load Spotify profile info."
    end
  else
    status 401
    "Failed to authenticate with Spotify"
  end
end
