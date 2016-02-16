class WeatherLocation < ActiveRecord::Base
  belongs_to :weather_grid
  geocoded_by :city, :latitude  => :latitude, :longitude => :longitude   # can also be an IP address
  after_validation :geocode          # auto-fetch coordinates
end
