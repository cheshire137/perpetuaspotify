require_relative 'fetcher'
require_relative 'spotify_audio_features'
require_relative 'spotify_playlist'
require_relative 'spotify_track'

class SpotifyApi < Fetcher
  def initialize(token)
    super('https://api.spotify.com/v1', token)
  end

  # https://developer.spotify.com/web-api/web-api-personalization-endpoints/get-recently-played/
  def get_recently_played
    json = get('/me/player/recently-played')

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
  def get_recommendations(limit: 20, track_ids: [], target_features: {})
    params = { limit: limit }
    if track_ids.size > 0
      params[:seed_tracks] = track_ids.join(',')
    end
    target_features.each do |feature, value|
      params["target_#{feature}"] = value
    end
    param_str = params.map { |key, value| "#{key}=#{value}" }.join('&')

    json = get("/recommendations?#{param_str}")

    return unless json

    json['tracks'].map { |data| SpotifyTrack.new(data) }
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
