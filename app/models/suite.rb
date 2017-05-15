class Suite < ActiveRecord::Base
  has_many :services
  has_many :environments
end
