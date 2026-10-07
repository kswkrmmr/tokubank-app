class CreateRewards < ActiveRecord::Migration[8.1]
  def change
    create_table :rewards do |t|
      t.string :name, null: false
      t.integer :cost, null: false
      # 叶えた日時。null なら未達成
      t.datetime :redeemed_at
      t.references :user, null: false, foreign_key: true

      t.timestamps
    end

    # 一覧で未達成・達成済みを出し分けるため
    add_index :rewards, [ :user_id, :redeemed_at ]
  end
end
