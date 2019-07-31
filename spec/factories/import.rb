FactoryBot.define do
  factory :import, class: TestApp::Import do
    file { Rack::Test::UploadedFile.new("#{Rails.root}/spec/fixtures/sample.csv", 'text/plain') }
  end
end
