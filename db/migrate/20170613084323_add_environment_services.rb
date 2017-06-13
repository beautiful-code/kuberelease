class AddEnvironmentServices < ActiveRecord::Migration
  def change
    create_table :environment_services do |t|
      t.references :environment, index: true
      t.references :service, index: true
      t.text :variables, limit:  4294967295
      t.string :name

      t.timestamps null: false
    end
  end
end
