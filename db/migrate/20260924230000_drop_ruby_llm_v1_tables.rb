# RubyLLM 2.0 replaces its 1.x tables with a new schema (the migrations that
# follow). The starter has no conversations worth carrying over, so it starts
# fresh instead of running the 1.16 → 2.0 data upgrade.
#
# An app forked from an older starter that DOES have real chats in production
# must not use this: run `bin/rails generate ruby_llm:upgrade` instead, which
# preserves them (https://rubyllm.com/next/upgrading/).
class DropRubyLlmV1Tables < ActiveRecord::Migration[8.1]
  def up
    # These tables reference each other; cascade drops the foreign keys too.
    %i[tool_calls messages chats models].each do |table|
      drop_table table, force: :cascade, if_exists: true
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
