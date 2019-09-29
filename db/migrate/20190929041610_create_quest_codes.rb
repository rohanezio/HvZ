class CreateQuestCodes < ActiveRecord::Migration
  def change
    create_table :quest_codes do |t|
      t.string :code
      t.integer :points
      t.integer :game_id
      t.integer :registration_id
      t.datetime :created_at
      t.datetime :updated_at

      t.timestamps null: false
    end
  end
end
