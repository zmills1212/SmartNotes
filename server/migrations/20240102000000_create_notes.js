exports.up = function(knex) {
  return knex.schema.createTable('notes', table => {
    table.increments('id').primary();
    table.integer('user_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.string('title');
    table.text('content');
    table.boolean('content_encrypted').defaultTo(false);
    table.jsonb('encryption_meta');
    table.jsonb('sensitive_keywords').defaultTo('[]');
    table.boolean('is_sensitive').defaultTo(false);
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('updated_at').defaultTo(knex.fn.now());
    table.index('user_id');
    table.index('is_sensitive');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('notes');
};
