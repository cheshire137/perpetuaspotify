class PlaylistManager
  NAME = 'Perpetuaspotify'.freeze

  attr_reader :playlist

  def initialize(user, logger:)
    @user = user
    @logger = logger
    @api = SpotifyApi.new(@user.spotify_access_token, logger: @logger)
  end

  def sync_playlist(track_uris)
    @playlist = if @user.spotify_playlist_id
      replace_playlist(track_uris)
    else
      create_playlist(track_uris)
    end
  end

  private

  def base_playlist_args(track_uris)
    { user_id: @user.user_name, track_uris: track_uris }
  end

  def replace_playlist(track_uris)
    playlist_args = base_playlist_args(track_uris)
    playlist_args[:playlist_id] = @user.spotify_playlist_id

    @api.replace_playlist(playlist_args)
  rescue Fetcher::Unauthorized
    if @user.update_spotify_tokens(logger: @logger)
      @api = SpotifyApi.new(@user.spotify_access_token, logger: @logger)
      @api.replace_playlist(playlist_args)
    end
  end

  def create_playlist(track_uris)
    playlist_args = base_playlist_args(track_uris)
    playlist_args[:name] = NAME

    @api.create_playlist(playlist_args)
  rescue Fetcher::Unauthorized
    if @user.update_spotify_tokens(logger: @logger)
      @api = SpotifyApi.new(@user.spotify_access_token, logger: @logger)
      @api.create_playlist(playlist_args)
    end
  end
end
