class SpotifyArtist
  attr_reader :name, :url

  def initialize(hash)
    @name = hash['name']
    @url = hash['external_urls']['spotify']
  end
end
