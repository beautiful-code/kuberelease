class EnvironmentService < ActiveRecord::Base
  belongs_to :service
  belongs_to :environment

  serialize :variables, JSON

  validates_uniqueness_of :service_id, scope: :environment_id

  after_initialize do
    self.variables = '[]' if self.variables.blank?
  end
end
