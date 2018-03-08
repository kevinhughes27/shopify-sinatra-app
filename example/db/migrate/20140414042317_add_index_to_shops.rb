class AddIndexToShops < ActiveRecord::Migration[5.1]
  def self.up
    add_index :shops, :name
  end

  def self.down
    remove_index :shops, :name
  end
end
