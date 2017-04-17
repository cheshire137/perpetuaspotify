require_relative 'spotify_artist'

class SpotifyTrack
  attr_reader :name, :artists, :url, :played_at, :id
  attr_accessor :audio_features

  def initialize(hash)
    @id = hash['id']
    @name = hash['name']
    @artists = hash['artists'].map do |artist|
      SpotifyArtist.new(artist)
    end
    @url = hash['external_urls']['spotify']
    @played_at = DateTime.parse(hash['played_at'])
  end

  def artist_count
    @artist_count ||= artists.size
  end

  def formatted_played_at
    played_at.strftime('%b %-d, %Y %l:%M %P')
  end
end
