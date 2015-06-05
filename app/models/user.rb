class User < ActiveRecord::Base
  has_many :calendars
end
