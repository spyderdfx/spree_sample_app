require 'spec_helper'

RSpec.describe TestApp::ImportService do
  let(:import) { create :import }

  let!(:default_location) { create(:stock_location, name: 'Default', default: true) }

  let(:service) { described_class.new(import.id) }

  before do
    Aws.config[:s3] = {
      stub_responses: {
        list_buckets: {
          buckets: [name: 'test']
        },
        list_objects: {
          contents: [{key: 'test'}]
        },
        get_object: {
          body: File.read(File.join(Rails.root, 'spec', 'fixtures', 'sample.csv'))
        }
      }
    }
  end

  after do
    Aws.config[:s3] = {}
  end

  describe '#call' do
    it 'parses file and creates products' do
      expect { service.call }.to change { Spree::Product.count }.from(0).to(3)
    end

    context 'when some categories already exist' do
      let!(:category) { create :taxon, name: 'Bags' }

      it 'does not create category' do
        service.call

        expect(Spree::Product.all.map(&:taxons).flatten).to include(category)
      end
    end
  end
end
