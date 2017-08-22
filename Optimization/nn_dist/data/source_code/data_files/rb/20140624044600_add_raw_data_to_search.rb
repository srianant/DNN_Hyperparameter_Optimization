class AddRawDataToSearch < ActiveRecord::Migration
  def change
    add_column :post_search_data, :raw_data, :text
    add_column :user_search_data, :raw_data, :text
    add_column :category_search_data, :raw_data, :text

    add_column :post_search_data, :locale, :string
    add_column :user_search_data, :locale, :text
    add_column :category_search_data, :locale, :text
  end
end
