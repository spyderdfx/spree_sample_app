require 'spec_helper'

RSpec.describe 'Import products from csv', type: :feature do
  include ActiveJob::TestHelper

  stub_authorization!

  let!(:default_location) { create(:stock_location, name: 'Default', default: true) }

  shared_examples_for 'Successful import' do |fixture_path, imported_products_count|
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
            body: File.read(File.join(Rails.root, fixture_path))
          }
        }
      }
    end

    after do
      Aws.config[:s3] = {}
      Thread.current[:paperclip_s3_instances] = {}

      clear_enqueued_jobs
      clear_performed_jobs
    end

    it "Successfully uploads csv and creates #{imported_products_count} products" do
      expect do
        perform_enqueued_jobs do
          visit spree.admin_imports_path
          attach_file 'import[file]', Rails.root.join(fixture_path)
          submit_form
          expect(page).to have_content('Import started')
        end
      end.to change { Spree::Product.count }.by(imported_products_count)
    end
  end

  it_behaves_like 'Successful import', 'spec/fixtures/sample.csv', 3
  it_behaves_like('Successful import', 'spec/fixtures/sample.csv', 2) do
    let!(:existing_product) { create :product, name: 'Spree Bag' }
  end
  it_behaves_like 'Successful import', 'spec/fixtures/import_without_leading_semicolon.csv', 3
  it_behaves_like 'Successful import', 'spec/fixtures/import_product_without_name.csv', 2
  it_behaves_like 'Successful import', 'spec/fixtures/import_product_without_category.csv', 2
  it_behaves_like 'Successful import', 'spec/fixtures/import_product_without_slug.csv', 3
  it_behaves_like 'Successful import', 'spec/fixtures/import_two_identical_products.csv', 3
end
