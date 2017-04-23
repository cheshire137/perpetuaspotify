require_relative 'spotify_artist'

class SpotifyTrack
  attr_reader :name, :artists, :url, :played_at, :id, :small_image_url,
    :small_image_width, :small_image_height, :uri, :big_image_url,
    :big_image_width, :big_image_height
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
      @small_image_url = image['url']
      @small_image_width = image['width']
      @small_image_height = image['height']
    end

    image = hash['album']['images'].detect { |img| img['width'] <= 300 }
    if image
      @big_image_url = image['url']
      @big_image_width = image['width']
      @big_image_height = image['height']
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
