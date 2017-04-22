class SpotifyPlaylist
  attr_reader :description, :url, :follower_count, :id, :name, :snapshot_id,
    :uri, :owner_url

  def initialize(hash)
    @collaborative = hash['collaborative']
    @description = hash['description']
    @url = hash['external_urls']['spotify']
    @follower_count = hash['followers']['total']
    @id = hash['id']
    @name = hash['name']
    @snapshot_id = hash['snapshot_id']
    @uri = hash['uri']
    @owner_url = hash['owner']['external_urls']['spotify']
    @public = hash['public']
  end

  def public?
    @public
  end

  def collaborative?
    @collaborative
  end
end
