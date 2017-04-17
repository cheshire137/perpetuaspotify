require_relative 'fetcher'
require_relative 'spotify_track'

class SpotifyApi < Fetcher
  def initialize(token)
    super('https://api.spotify.com/v1', token)
  end

  # "https://open.spotify.com/user/wizzler" => "wizzler"
  def self.get_user_name(url)
    url.split('/user/').last
  end

  # https://developer.spotify.com/web-api/web-api-personalization-endpoints/get-recently-played/
  def get_recently_played
    json = get('/me/player/recently-played')

    return unless json

    json['items'].map do |item|
      SpotifyTrack.new(item['track'].merge(item.slice('played_at')))
    end
  end

  # https://developer.spotify.com/web-api/get-current-users-profile/
  def get_me
    json = get('/me')

    return unless json

    json
  end

  private

  def get_headers
    { 'Authorization' => "Bearer #{token}" }
  end
end
