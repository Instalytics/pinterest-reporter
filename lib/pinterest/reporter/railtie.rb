require 'pinterest-reporter'
require 'rails'

module PinterestReporter
  class Railtie < Rails::Railtie
    railtie_name :instagram_reporter

    rake_tasks do
      load "tasks/pinterest-reporter.rake"
    end
  end
end
