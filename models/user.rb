class User < ActiveRecord::Base
  validates :email, :spotify_access_token, :spotify_refresh_token,
    :user_name, presence: true
  validates :email, uniqueness: true

  def to_param
    "#{id}-#{user_name}"
  end

  # Updates the Spotify access and refresh tokens for the given User.
  # Returns true on success, false or nil on error.
  def update_spotify_tokens
    spotify_auth_api = SpotifyAuthApi.new(ENV['SPOTIFY_CLIENT_ID'],
                                          ENV['SPOTIFY_CLIENT_SECRET'])
    tokens = spotify_auth_api.refresh_tokens(spotify_refresh_token)

    if tokens
      self.spotify_access_token = tokens['access_token']
      if (refresh_token = tokens['refresh_token']).present?
        self.spotify_refresh_token = refresh_token
      end
      save
    end
  end
end
