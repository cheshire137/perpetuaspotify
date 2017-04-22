class SpotifyTrackset
  class Error < StandardError; end

  def initialize(user, logger:)
    @user = user
    @logger = logger
    @api = SpotifyApi.new(@user.spotify_access_token, logger: @logger)
  end

  def tracks
    return @tracks if defined? @tracks

    tracks = begin
      @api.get_recently_played
    rescue Fetcher::Unauthorized
      if @user.update_spotify_tokens
        @api = SpotifyApi.new(@user.spotify_access_token, logger: @logger)
        @api.get_recently_played
      else
        raise Error, 'Failed to get recent Spotify tracks.'
      end
    end

    features_by_id = @api.get_audio_features_for(tracks.map(&:id))
    tracks.each do |track|
      track.audio_features = features_by_id[track.id]
    end

    @tracks = tracks
  end

  def recommendations(limit: 24)

    @recommendations ||= begin
      max_seeds = 5
      artist_ids = get_seed_artist_ids

      @api.get_recommendations(
        limit: limit, track_ids: get_seed_track_ids(max_seeds - artist_ids.size),
        target_features: get_target_features,
        artist_ids: artist_ids
      )
    end
  end

  private

  # Returns an array with a couple artist IDs to use as seeds for
  # getting track recommendations, or an empty array. Artist IDs are
  # only returned if those artists appeared multiple times in the
  # tracks list.
  def get_seed_artist_ids
    artist_ids = tracks.flat_map { |track| track.artists.map(&:id) }

    artist_counts = Hash.new(0)
    artist_ids.each do |id|
      artist_counts[id] += 1
    end
    artist_counts = artist_counts.sort_by { |id, count| -count }.to_h

    multi_artists = artist_counts.select { |id, count| count > 1 }.to_h.keys

    if multi_artists.empty?
      []
    else
      multi_artists[0...2]
    end
  end

  def get_seed_track_ids(count)
    tracks.sample(count).map(&:id)
  end

  def get_target_features
    feature_sets = tracks.map(&:audio_features)
    num_tracks = feature_sets.size
    feature_averages = {
      acousticness: 0,
      danceability: 0,
      energy: 0,
      instrumentalness: 0,
      loudness: 0,
      mode: 0,
      speechiness: 0,
      tempo: 0,
      valence: 0,
      time_signature: 0
    }
    feature_names = feature_averages.keys
    feature_sets.each do |feature_set|
      feature_names.each do |feature|
        feature_averages[feature] += feature_set.send(feature)
      end
    end
    feature_names.each do |feature|
      feature_averages[feature] /= num_tracks
    end
    feature_averages
  end
end
