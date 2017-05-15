class CreateEnvironments < ActiveRecord::Migration
  def change
    create_table :environments do |t|
      t.string :name
      t.references :suite, index: true
      t.string :k8s_master
      t.string :k8s_username
      t.string :k8s_password

      t.timestamps null: false
    end
    add_foreign_key :environments, :suites
  end
end
