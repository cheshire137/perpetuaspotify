require_relative 'spotify_artist'

class SpotifyTrack
  attr_reader :name, :artists, :url, :played_at

  def initialize(hash)
    @name = hash['name']
    @artists = hash['artists'].map do |artist|
      SpotifyArtist.new(artist)
    end
    @url = hash['external_urls']['spotify']
    @played_at = DateTime.parse(hash['played_at'])
  end

  def artist_names
    artists.map(&:name).join(', ')
  end
end
