exports.up = function(knex) {
  return knex.schema.createTable('digests', table => {
    table.increments('id').primary();
    table.integer('user_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.enum('range', ['daily', 'weekly']).notNullable();
    table.text('summary');
    table.jsonb('themes');
    table.jsonb('source_note_ids').defaultTo('[]');
    table.date('period_start');
    table.date('period_end');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('user_id');
    table.index(['user_id', 'range', 'period_start']);
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('digests');
};
