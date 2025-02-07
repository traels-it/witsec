class CreateAddresses < ActiveRecord::Migration[8.0]
  def change
    create_table :addresses do |t|
      t.string :street
      t.string :zip_code
      t.string :city

      t.timestamps
    end
  end
end
