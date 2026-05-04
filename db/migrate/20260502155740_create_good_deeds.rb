class CreateGoodDeeds < ActiveRecord::Migration[7.2]
  def change
    create_table :good_deeds do |t|
      t.text :content
      t.date :performed_on
      t.integer :points
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end
  end
end
