exports.up = function(knex) {
  return knex.schema.createTable('webauthn_credentials', table => {
    table.increments('id').primary();
    table.integer('user_id').unsigned().references('id').inTable('users').onDelete('CASCADE');
    table.string('credential_id').unique().notNullable();
    table.text('public_key').notNullable();
    table.integer('counter').defaultTo(0);
    table.jsonb('transports');
    table.timestamp('created_at').defaultTo(knex.fn.now());
    table.timestamp('last_used_at');
    table.index('user_id');
    table.index('credential_id');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('webauthn_credentials');
};
