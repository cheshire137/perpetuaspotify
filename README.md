# Perpetuaspotify

View the songs you've listened to most recently on Spotify. From those
songs, a list of recommended songs is generated. You can fiddle with
how those recommendations are generated to tweak the results. Then,
create a playlist of those recommended songs. Listen to that playlist
and do the whole process over again.

![Screenshot of app](https://raw.githubusercontent.com/cheshire137/perpetuaspotify/master/screenshot.png)

## How to Develop

Create [a Spotify application](https://developer.spotify.com/my-applications).
Set `http://localhost:9292/callback/spotify` as a redirect URI.

```bash
bundle install
cp dotenv.sample .env
```

Modify .env to set environment variables, such as your Spotify client
ID and secret. Run `rake generate:secret` to generate `SESSION_SECRET`.

```bash
rake db:create
rake db:migrate
rackup
open http://localhost:9292
```

## How to Test

```bash
RAILS_ENV=test rake db:create db:migrate
bundle exec rspec
```

## How to Deploy to Heroku

Create [an app on Heroku](https://dashboard.heroku.com/apps). Set
`https://your-heroku-app.herokuapp.com/callback/spotify` as a redirect
URI in your Spotify app.

```bash
heroku git:remote -a your-heroku-app
git push heroku master
heroku config:set SPOTIFY_CLIENT_ID=value_here
heroku config:set SPOTIFY_CLIENT_SECRET=value_here
heroku config:set SESSION_SECRET=value_here
heroku run rake db:migrate
heroku restart
```
