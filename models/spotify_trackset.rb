class SpotifyTrackset
  class Error < StandardError; end

  def initialize(user)
    @user = user
    @api = SpotifyApi.new(@user.spotify_access_token)
  end

  def tracks
    return @tracks if defined? @tracks

    tracks = begin
      @api.get_recently_played
    rescue Fetcher::Unauthorized
      if @user.update_spotify_tokens
        @api = SpotifyApi.new(@user.spotify_access_token)
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

  def recommendations(limit: 20)
    @recommendations ||= @api.get_recommendations(
      limit: limit, track_ids: get_seed_track_ids,
      target_features: get_target_features
    )
  end

  def playlist_name
    artists = recommendations.flat_map { |track| track.artists.map(&:name) }
    return if artists.size < 1

    artist_counts = Hash.new(0)
    artists.each do |name|
      artist_counts[name] += 1
    end
    artist_counts = artist_counts.sort_by { |name, count| [-count, name] }.to_h
    artist_counts.keys.uniq[0...3].sort.join(', ')
  end

  private

  def get_seed_track_ids
    tracks.sample(5).map(&:id)
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
