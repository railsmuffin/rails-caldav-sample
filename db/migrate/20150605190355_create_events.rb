class CreateEvents < ActiveRecord::Migration
  def change
    create_table :events do |t|
      t.string :uid
      t.text :ics
      t.references :calendar, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
