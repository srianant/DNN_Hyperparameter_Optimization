class AddMobileToSiteCustomizations < ActiveRecord::Migration
  def change
    add_column :site_customizations, :mobile_stylesheet, :text
    add_column :site_customizations, :mobile_header, :text
    add_column :site_customizations, :mobile_stylesheet_baked, :text
  end
end
