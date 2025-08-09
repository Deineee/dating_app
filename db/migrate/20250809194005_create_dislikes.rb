class CreateDislikes < ActiveRecord::Migration[8.0]
  def change
    create_table :dislikes do |t|
      t.integer :disliker_id
      t.integer :disliked_id

      t.timestamps
    end
  end
end
