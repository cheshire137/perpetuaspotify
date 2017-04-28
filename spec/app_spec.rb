ENV['RACK_ENV'] = 'test'

require_relative '../app'
require 'rspec'
require 'rack/test'

describe 'Perpetuaspotify App' do
  include Rack::Test::Methods

  def app
    Sinatra::Application
  end

  context 'GET index' do
    it 'loads successfully' do
      get '/'
      expect(last_response).to be_ok
    end

    it 'redirects when user is signed in' do
    end
  end
end
