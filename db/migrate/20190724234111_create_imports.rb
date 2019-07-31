class CreateImports < ActiveRecord::Migration[5.1]
  def up
    create_table :imports, comment: 'Table for product imports' do |t|
      t.timestamps
      t.attachment :file
    end
  end

  def down
    drop_table :imports
  end
end
