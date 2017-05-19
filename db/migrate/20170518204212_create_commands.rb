class CreateCommands < ActiveRecord::Migration
  def change
    create_table :commands do |t|
      t.references :environment, index: true
      t.references :service, index: true
      t.string :version
      t.string :desc
      t.text :cmd
      t.string :output
      t.string :state
      t.string :pod_name

      t.timestamps null: false
    end
  end
end
