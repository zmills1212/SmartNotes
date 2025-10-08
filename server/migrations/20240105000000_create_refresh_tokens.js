exports.up = function(knex) {
  return knex.schema.createTable('refresh_tokens', table => {
    table.increments('id').primary();
    table.integer('user_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.string('token').unique().notNullable();
    table.timestamp('expires_at').notNullable();
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.index('user_id');
    table.index('token');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('refresh_tokens');
};
