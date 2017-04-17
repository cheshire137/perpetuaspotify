require_relative 'fetcher'
require_relative 'spotify_audio_features'
require_relative 'spotify_track'

class SpotifyApi < Fetcher
  def initialize(token)
    super('https://api.spotify.com/v1', token)
  end

  # "https://open.spotify.com/user/wizzler" => "wizzler"
  def self.get_user_name(url)
    url.split('/user/').last
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
