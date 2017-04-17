class SpotifyAudioFeatures
  include Enumerable

  attr_reader :acousticness, :danceability, :energy, :instrumentalness,
    :loudness, :mode, :speechiness, :tempo, :valence, :track_id,
    :time_signature, :duration_ms

  def initialize(hash)
    @track_id = hash['id']
    @acousticness = hash['acousticness']
    @danceability = hash['danceability']
    @energy = hash['energy']
    @instrumentalness = hash['instrumentalness']
    @loudness = hash['loudness']
    @mode = hash['mode']
    @speechiness = hash['speechiness']
    @tempo = hash['tempo']
    @valence = hash['valence']
    @time_signature = hash['time_signature']
    @duration_ms = hash['duration_ms']

    @features_hash = {
      acousticness: @acousticness,
      danceability: @danceability,
      energy: @energy,
      instrumentalness: @instrumentalness,
      loudness: @loudness,
      mode: @mode,
      speechiness: @speechiness,
      tempo: @tempo,
      valence: @valence,
      time_signature: @time_signature,
      duration_ms: @duration_ms
    }
  end

  def each(&block)
    @features_hash.each(&block)
  end
end
