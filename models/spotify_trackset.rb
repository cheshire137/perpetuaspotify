class SpotifyTrackset
  class Error < StandardError; end

  def initialize(user)
    @user = user
    @api = SpotifyApi.new(@user.spotify_access_token)
  end

  def fetch
    tracks = begin
      @api.get_recently_played
    rescue Fetcher::Unauthorized
      if @user.update_spotify_tokens
        @api = SpotifyApi.new(@user.spotify_access_token)
        @api.get_recently_played
      else
        raise Error, 'Failed to get recent Spotify tracks.'
      end
    end

    features_by_id = @api.get_audio_features_for(tracks.map(&:id))
    tracks.each do |track|
      track.audio_features = features_by_id[track.id]
    end

    tracks
  end
end
