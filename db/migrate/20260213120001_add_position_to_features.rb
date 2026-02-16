class AddPositionToFeatures < ActiveRecord::Migration[8.0]
  def change
    add_column :features, :position, :integer

    # Backfill: give planned features positions based on current order
    reversible do |dir|
      dir.up do
        execute <<-SQL
          WITH ranked AS (
            SELECT id, ROW_NUMBER() OVER (ORDER BY priority DESC, created_at ASC) AS pos
            FROM features
            WHERE status = 1
          )
          UPDATE features SET position = ranked.pos
          FROM ranked WHERE features.id = ranked.id
        SQL
      end
    end
  end
end
