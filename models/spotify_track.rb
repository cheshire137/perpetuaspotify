require_relative 'spotify_artist'

class SpotifyTrack
  attr_reader :name, :artists, :url, :played_at, :id, :image_url,
    :image_width, :image_height, :uri
  attr_accessor :audio_features

  def initialize(hash)
    @id = hash['id']
    @name = hash['name']
    @uri = hash['uri']
    @artists = hash['artists'].map { |artist| SpotifyArtist.new(artist) }
    @url = hash['external_urls']['spotify']
    @played_at = if date_str = hash['played_at']
      DateTime.parse(date_str)
    end

    image = hash['album']['images'].detect { |img| img['width'] <= 75 }
    if image
      @image_url = image['url']
      @image_width = image['width']
      @image_height = image['height']
    end
  end

  def artist_count
    @artist_count ||= artists.size
  end

  def artist_names
    artists.map(&:name).join(', ')
  end

  def formatted_played_at
    if played_at
      played_at.strftime('%b %-d, %Y %l:%M %P')
    end
  end
end
