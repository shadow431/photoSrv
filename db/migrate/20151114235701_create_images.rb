class CreateImages < ActiveRecord::Migration
  def change
    create_table :images do |t|
      t.string :filename
      t.string :preMd5
      t.string :postMd5
      t.string :dir
      t.string :orientation
      t.text :tags
      t.datetime :dateTaken
      t.boolean :dateIsEstimate

      t.timestamps null: false
    end
  end
end
