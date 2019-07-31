module TestApp
  class ImportJob
    @queue = :import

    def self.perform(import_id)
      TestApp::ImportService.new(import_id.to_i).call
    end
  end
end
