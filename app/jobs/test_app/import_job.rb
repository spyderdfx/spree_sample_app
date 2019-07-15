module TestApp
  class ImportJob
    @queue = :import

    def self.perform(filename)
      TestApp::ImportService.new(filename).call
    end
  end
end
