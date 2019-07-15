require 'spec_helper'

RSpec.describe TestApp::ImportService do
  let(:path) { Rails.root.join('spec/fixtures/sample.csv') }

  let!(:default_location) { create(:stock_location, name: 'Default', default: true) }

  let(:service) { described_class.new(path) }

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
