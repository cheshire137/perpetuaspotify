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

helpers do
  def file_time(file_name)
    File.mtime("#{settings.root}/public/#{file_name}").to_i
  end

  def asset_path(file_name)
    "/#{file_name}?t=#{file_time(file_name)}"
  end
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
  @feature_labels = SpotifyAudioFeatures::FEATURE_LABELS
  @features = @feature_labels.keys
  @feature_values = trackset.audio_features
  @seed_artist_ids = trackset.seed_artist_ids
  @seed_track_ids = trackset.seed_track_ids
  @artist_names_by_id = trackset.artist_names_by_id
  @max_seeds = SpotifyTrackset::MAX_SEEDS
  @seeds_remaining = @max_seeds - (@seed_track_ids.size +  @seed_artist_ids.size)

  # Unix time in milliseconds:
  @before_time = (Time.now.to_f * 1_000).to_i

  @error = session[:error]
  session[:error] = nil

  @playlist_url = session[:playlist_url]
  session[:playlist_url] = nil

  erb :user
end

post '/recommendations' do
  unless session[:user_id]
    status 401
    body ''
    return
  end

  @user = User.where(id: session[:user_id]).first

  unless @user
    status 404
    body ''
    return
  end

  @playlist_name = PlaylistManager::NAME
  @feature_values = {
    acousticness: params['acousticness'],
    danceability: params['danceability'],
    energy: params['energy'],
    instrumentalness: params['instrumentalness'],
    liveness: params['liveness'],
    speechiness: params['speechiness'],
    valence: params['valence']
  }
  @seed_track_ids = params['track_ids'] || []
  @seed_artist_ids = params['artist_ids'] || []
  @before_time = params['before_time']
  @max_seeds = SpotifyTrackset::MAX_SEEDS
  @seeds_remaining = @max_seeds - (@seed_track_ids.size +  @seed_artist_ids.size)

  trackset = SpotifyTrackset.new(@user, logger: logger)

  @tracks = begin
    trackset.tracks
  rescue SpotifyTrackset::Error
    status 400
    return 'Failed to get recent Spotify tracks.'
  end

  @artist_names_by_id = trackset.artist_names_by_id
  @recommendations = trackset.recommendations(
    target_features: @feature_values, track_ids: @seed_track_ids,
    artist_ids: @seed_artist_ids
  )

  @feature_labels = SpotifyAudioFeatures::FEATURE_LABELS
  @features = @feature_labels.keys

  erb :recommendations, layout: false
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
                                        ENV['SPOTIFY_CLIENT_SECRET'],
                                        logger: logger)
  tokens = spotify_auth_api.get_tokens(code, redirect_uri)

  if tokens
    access_token = tokens['access_token']
    refresh_token = tokens['refresh_token']
    spotify_api = SpotifyApi.new(access_token, logger: logger)

    if me = spotify_api.get_me
      user = User.where(email: me['email']).first_or_initialize
      user.spotify_access_token = access_token
      user.spotify_refresh_token = refresh_token
      if me['images'].size > 0
        user.icon_url = me['images'].first['url']
      end
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
