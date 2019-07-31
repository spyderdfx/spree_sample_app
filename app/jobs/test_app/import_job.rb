module TestApp
  class ImportJob < ActiveJob::Base
    queue_as :import

    def perform(import_id)
      TestApp::ImportService.new(import_id.to_i).call
    end
  end
end
