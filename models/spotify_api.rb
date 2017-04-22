require_relative 'fetcher'
require_relative 'spotify_audio_features'
require_relative 'spotify_playlist'
require_relative 'spotify_track'

class SpotifyApi < Fetcher
  def initialize(token, logger:)
    super('https://api.spotify.com/v1', token, logger: logger)
  end

  # https://developer.spotify.com/web-api/web-api-personalization-endpoints/get-recently-played/
  def get_recently_played(limit: 24)
    json = get("/me/player/recently-played?limit=#{limit}")

    return unless json

    basic_track_data = json['items'].map do |item|
      [item['played_at'], item['track']['id']]
    end.to_h

    track_ids = basic_track_data.values.uniq
    full_track_data = get_track_info_for(track_ids)

    basic_track_data.map do |played_at, id|
      data = full_track_data[id].merge('played_at' => played_at)
      SpotifyTrack.new(data)
    end
  end

  # https://developer.spotify.com/web-api/get-recommendations/
  def get_recommendations(limit: 24, artist_ids: [], track_ids: [], target_features: {})
    # Get more than the specified limit in case duplicates are returned:
    params = { limit: limit + 5 }

    if track_ids.size > 0
      params[:seed_tracks] = track_ids.join(',')
    end
    if artist_ids.size > 0
      params[:seed_artists] = artist_ids.join(',')
    end
    target_features.each do |feature, value|
      params["target_#{feature}"] = value
    end
    param_str = params.map { |key, value| "#{key}=#{value}" }.join('&')

    json = get("/recommendations?#{param_str}")

    return unless json

    tracks_data = json['tracks']

    # Remove duplicate suggestions
    seen_ids = []
    tracks_data = tracks_data.reject do |data|
      have_seen = seen_ids.include?(data['id'])
      seen_ids << data['id']
      have_seen
    end

    tracks = tracks_data.map { |data| SpotifyTrack.new(data) }
    tracks[0...limit]
  end

  def get_audio_features_for(track_ids)
    chunk_size = 100

    feature_data = if track_ids.size <= chunk_size
      audio_features_for_ids(track_ids)
    else
      batches = []
      i = 0
      while i < track_ids.size
        batches.push(track_ids[i, i + chunk_size])
        i += chunk_size
      end

      audio_features_for_batch(batches, 0, [])
    end

    features = feature_data.map { |hash| SpotifyAudioFeatures.new(hash) }
    features.map { |feature| [feature.track_id, feature] }.to_h
  end

  # https://developer.spotify.com/web-api/get-current-users-profile/
  def get_me
    json = get('/me')

    return unless json

    json
  end

  def replace_playlist(user_id:, playlist_id:, track_uris:)
    url = "/users/#{user_id}/playlists/#{playlist_id}/tracks"
    headers = { 'Content-Type' => 'application/json' }

    put(url, headers: headers) do |req|
      req.body = { uris: track_uris }.to_json
    end

    return unless response_code == '201'

    get_playlist(user_id: user_id, playlist_id: playlist_id)
  end

  def get_playlist(user_id:, playlist_id:)
    json = get("/users/#{user_id}/playlists/#{playlist_id}")

    return unless json && json['id']

    SpotifyPlaylist.new(json)
  end

  def create_playlist(user_id:, track_uris:, name:, public_playlist: true, collaborative: false)
    headers = { 'Content-Type' => 'application/json' }
    playlist_url = "/users/#{user_id}/playlists"
    create_json = post(playlist_url, headers: headers) do |req|
      req.body = {
        name: name,
        public: public_playlist,
        collaborative: collaborative
      }.to_json
    end

    return unless create_json && create_json['id']

    playlist_id = create_json['id']
    tracks_url = "/users/#{user_id}/playlists/#{playlist_id}/tracks"
    tracks_json = post(tracks_url, headers: headers) do |req|
      req.body = { uris: track_uris }.to_json
    end

    return unless tracks_json && tracks_json['snapshot_id']

    create_json['snapshot_id'] = tracks_json['snapshot_id']
    SpotifyPlaylist.new(create_json)
  end

  private

  # https://developer.spotify.com/web-api/get-several-tracks/
  def get_track_info_for(track_ids)
    chunk_size = 50

    track_data = if track_ids.size <= chunk_size
      track_info_for_ids(track_ids)
    else
      batches = []
      i = 0
      while i < track_ids.size
        batches.push(track_ids[i, i + chunk_size])
        i += chunk_size
      end

      track_info_for_batch(batches, 0, [])
    end

    track_data.map { |hash| [hash['id'], hash] }.to_h
  end

  def get_headers
    { 'Authorization' => "Bearer #{token}" }
  end

  def track_info_for_batch(batches, index, prev_tracks)
    tracks = track_info_for_ids(batches[index])
    all_tracks = prev_tracks.concat(tracks)

    if index < batches.size - 1
      track_info_for_batch(batches, index + 1, all_tracks)
    else
      all_tracks
    end
  end

  def track_info_for_ids(ids)
    id_str = ids.join(',')
    json = get("/tracks/?ids=#{id_str}")
    json['tracks']
  end

  def audio_features_for_batch(batches, index, prev_features)
    features = audio_features_for_ids(batches[index])
    all_features = prev_features.concat(features)

    if index < batches.size - 1
      audio_features_for_batch(batches, index + 1, all_features)
    else
      all_features
    end
  end

  def audio_features_for_ids(ids)
    id_str = ids.join(',')
    json = get("/audio-features?ids=#{id_str}")
    json['audio_features']
  end
end
