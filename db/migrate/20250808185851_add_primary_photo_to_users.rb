class AddPrimaryPhotoToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :primary_photo, :string
  end
end
