# frozen_string_literal: true

class AddSearchVectorToProducts < ActiveRecord::Migration[8.0]
  def up
    add_column :products, :search_vector, :tsvector

    execute <<-SQL
      UPDATE products
      SET search_vector = to_tsvector('english',
        coalesce(name, '') || ' ' ||
        coalesce(brand, '') || ' ' ||
        coalesce(categories::text, '')
      )
    SQL

    add_index :products, :search_vector, using: :gin

    execute <<-SQL
      CREATE OR REPLACE FUNCTION products_search_vector_update() RETURNS trigger AS $$
      BEGIN
        NEW.search_vector := to_tsvector('english',
          coalesce(NEW.name, '') || ' ' ||
          coalesce(NEW.brand, '') || ' ' ||
          coalesce(NEW.categories::text, '')
        );
        RETURN NEW;
      END;
      $$ LANGUAGE plpgsql;

      CREATE TRIGGER products_search_vector_trigger
      BEFORE INSERT OR UPDATE ON products
      FOR EACH ROW EXECUTE FUNCTION products_search_vector_update();
    SQL
  end

  def down
    execute "DROP TRIGGER IF EXISTS products_search_vector_trigger ON products;"
    execute "DROP FUNCTION IF EXISTS products_search_vector_update();"
    remove_index :products, :search_vector
    remove_column :products, :search_vector
  end
end
