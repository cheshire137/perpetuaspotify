class SpotifyAudioFeatures
  include Enumerable

  # See https://developer.spotify.com/web-api/get-several-audio-features/
  attr_reader :acousticness, :danceability, :energy, :instrumentalness,
    :loudness, :mode, :speechiness, :tempo, :valence, :track_id,
    :time_signature, :duration_ms

  def initialize(hash)
    @track_id = hash['id']
    @acousticness = percent(hash['acousticness'])
    @danceability = percent(hash['danceability'])
    @energy = percent(hash['energy'])
    @instrumentalness = percent(hash['instrumentalness'])
    @loudness = hash['loudness'] # between -60 and 0 db
    @mode = hash['mode'] == 1 ? 'major' : 'minor'
    @speechiness = percent(hash['speechiness'])
    @tempo = hash['tempo'] # bpm
    @valence = percent(hash['valence'])
    @time_signature = hash['time_signature']
    @duration_ms = hash['duration_ms']

    @features_hash = {
      'Acousticness' => percent_str(@acousticness),
      'Danceability' => percent_str(@danceability),
      'Energy' => percent_str(@energy),
      'Instrumentalness' => percent_str(@instrumentalness),
      'Loudness' => @loudness,
      'Mode' => @mode,
      'Speechiness' => percent_str(@speechiness),
      'Tempo' => "#{@tempo} bpm",
      'Valence' => percent_str(@valence),
      'Time signature' => @time_signature,
      'Duration' => formatted_duration
    }
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

  def percent_str(value)
    "#{value}%"
  end

  def percent(value)
    (value * 100).round
  end
end
