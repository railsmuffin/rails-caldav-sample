class CreateCalendars < ActiveRecord::Migration
  def change
    create_table :calendars do |t|
      t.string :name
      t.text :description
      t.references :user, index: true, foreign_key: true

      t.timestamps null: false
    end
  end
end
