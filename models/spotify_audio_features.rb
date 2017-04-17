class SpotifyAudioFeatures
  include Enumerable

  # See https://developer.spotify.com/web-api/get-several-audio-features/
  attr_reader :acousticness, :danceability, :energy, :instrumentalness,
    :loudness, :mode, :speechiness, :tempo, :valence, :track_id,
    :time_signature, :duration_ms

  def initialize(hash)
    @track_id = hash['id']
    @acousticness = hash['acousticness']
    @danceability = hash['danceability']
    @energy = hash['energy']
    @instrumentalness = hash['instrumentalness']
    @loudness = hash['loudness'] # between -60 and 0 db
    @mode = hash['mode']
    @speechiness = hash['speechiness']
    @tempo = hash['tempo'] # bpm
    @valence = hash['valence']
    @time_signature = hash['time_signature']
    @duration_ms = hash['duration_ms']

    @features_hash = {}
    if @acousticness > 50
      @features_hash['Acousticness'] = percent_str(@acousticness)
    end
    if @danceability > 50
      @features_hash['Danceability'] = percent_str(@danceability)
    end
    if @energy > 50
      @features_hash['Energy'] = percent_str(@energy)
    end
    if @instrumentalness > 50
      @features_hash['Instrumentalness'] = percent_str(@instrumentalness)
    end
    @features_hash['Loudness'] = @loudness
    @features_hash['Mode'] = @mode == 1 ? 'major' : 'minor'
    if @speechiness > 50
      @features_hash['Speechiness'] = percent_str(@speechiness)
    end
    @features_hash['Tempo'] = "#{@tempo} bpm"
    @features_hash['Valence'] = interpreted_valence
    @features_hash['Time signature'] = @time_signature
    @features_hash['Duration'] = formatted_duration
  end

  def each(&block)
    @features_hash.each(&block)
  end

  def formatted_duration
    hours, milliseconds = duration_ms.divmod(1000 * 60 * 60)
    minutes, milliseconds = milliseconds.divmod(1000 * 60)
    seconds, milliseconds = milliseconds.divmod(1000)

    if hours > 0
      if seconds > 0
        "#{hours}h #{minutes}m #{seconds}s"
      elsif minutes > 0
        "#{hours}h #{minutes}m"
      else
        "#{hours}h"
      end
    elsif minutes > 0
      if seconds > 0
        "#{minutes}m #{seconds}s"
      else
        "#{minutes}m"
      end
    else
      "#{seconds}s"
    end
  end

  private

  def interpreted_valence
    if valence < 20
      'Very negative'
    elsif valence < 40
      'Negative'
    elsif valence < 60
      'Neutral'
    elsif valence < 80
      'Positive'
    else
      'Very positive'
    end
  end

  def percent_str(value)
    "#{percent(value)}%"
  end

  def percent(value)
    (value * 100).round
  end
end
