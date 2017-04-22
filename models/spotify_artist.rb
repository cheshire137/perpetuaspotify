class SpotifyArtist
  attr_reader :name, :url, :id

  def initialize(hash)
    @name = hash['name']
    @url = hash['external_urls']['spotify']
    @id = hash['id']
  end
end
