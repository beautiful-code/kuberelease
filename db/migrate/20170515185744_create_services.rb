class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :name
      t.references :suite, index: true
      t.string :docker_repo
      t.string :git_repo
      t.string :k8s_service

      t.timestamps null: false
    end
    add_foreign_key :services, :suites
  end
end
