require_relative 'fetcher'

class SpotifyApi < Fetcher
  def initialize(token)
    super('https://api.spotify.com/v1', token)
  end

  # "https://open.spotify.com/user/wizzler" => "wizzler"
  def self.get_user_name(url)
    url.split('/user/').last
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
