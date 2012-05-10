class Things < ActiveRecord::Migration
  def change
    create_table :things do |t|
      t.has_upload :friend
      t.has_upload :pet
    end
  end
end
