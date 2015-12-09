class AddIgnoreToImages < ActiveRecord::Migration
  def change
    add_column :images, :ignore, :boolean
  end
end
