import { Knex } from 'knex';

export async function up(knex: Knex): Promise<void> {
  // 用户表
  await knex.schema.createTable('users', (table) => {
    table.increments('id').primary();
    table.string('phone', 20).unique().notNullable();
    table.string('password').notNullable();
    table.string('name', 50);
    table.enum('gender', ['male', 'female', 'other']);
    table.date('birthday');
    table.string('avatar');
    table.enum('role', ['patient', 'companion', 'admin']).defaultTo('patient');
    table.string('id_card', 20);
    table.string('id_card_front');
    table.string('id_card_back');
    table.enum('status', ['pending', 'active', 'rejected', 'banned']).defaultTo('pending');
    table.decimal('balance', 10, 2).defaultTo(0);
    table.decimal('rating', 3, 2).defaultTo(5.0);
    table.integer('rating_count').defaultTo(0);
    table.timestamps(true, true);
  });

  // 陪诊师资料表
  await knex.schema.createTable('companions', (table) => {
    table.integer('user_id').primary().references('id').inTable('users');
    table.text('introduction');
    table.json('skills'); // 技能标签
    table.json('certificates'); // 证书图片
    table.json('service_hospitals'); // 服务医院
    table.decimal('hourly_rate', 8, 2);
    table.decimal('daily_rate', 8, 2);
    table.boolean('is_available').defaultTo(true);
    table.integer('completed_orders').defaultTo(0);
    table.timestamps(true, true);
  });

  // 医院表
  await knex.schema.createTable('hospitals', (table) => {
    table.increments('id').primary();
    table.string('name', 200).notNullable();
    table.string('address').notNullable();
    table.decimal('latitude', 10, 8);
    table.decimal('longitude', 11, 8);
    table.string('phone', 20);
    table.text('description');
    table.json('departments'); // 科室列表
    table.json('images');
    table.timestamps(true, true);
  });

  // 订单表
  await knex.schema.createTable('orders', (table) => {
    table.string('order_no', 32).primary();
    table.integer('patient_id').references('id').inTable('users');
    table.integer('companion_id').references('id').inTable('users');
    table.integer('hospital_id').references('id').inTable('hospitals');
    table.string('department', 100);
    table.string('doctor_name', 50);
    table.datetime('appointment_time');
    table.string('address');
    table.text('requirements');
    table.enum('service_type', ['hourly', 'daily', 'custom']).defaultTo('hourly');
    table.decimal('hours', 5, 1);
    table.decimal('amount', 10, 2);
    table.decimal('platform_fee', 10, 2);
    table.decimal('companion_income', 10, 2);
    table.enum('status', ['pending', 'accepted', 'ongoing', 'completed', 'cancelled', 'refunded']).defaultTo('pending');
    table.datetime('start_time');
    table.datetime('end_time');
    table.text('cancellation_reason');
    table.timestamps(true, true);
  });

  // 支付记录表
  await knex.schema.createTable('payments', (table) => {
    table.string('payment_no', 32).primary();
    table.string('order_no', 32).references('order_no').inTable('orders');
    table.enum('type', ['wechat', 'alipay', 'balance']);
    table.decimal('amount', 10, 2);
    table.enum('status', ['pending', 'paid', 'refunded', 'failed']).defaultTo('pending');
    table.string('transaction_id');
    table.json('payment_data');
    table.timestamps(true, true);
  });

  // 聊天消息表
  await knex.schema.createTable('chat_messages', (table) => {
    table.increments('id').primary();
    table.string('room_id', 50).notNullable();
    table.integer('sender_id').references('id').inTable('users');
    table.integer('receiver_id').references('id').inTable('users');
    table.enum('message_type', ['text', 'image', 'voice', 'location', 'system']).defaultTo('text');
    table.text('content');
    table.boolean('is_read').defaultTo(false);
    table.timestamps(true, true);
  });

  // 评价表
  await knex.schema.createTable('reviews', (table) => {
    table.increments('id').primary();
    table.string('order_no', 32).references('order_no').inTable('orders');
    table.integer('patient_id').references('id').inTable('users');
    table.integer('companion_id').references('id').inTable('users');
    table.integer('rating', 1).checkBetween([1, 5]);
    table.text('comment');
    table.json('tags'); // 评价标签
    table.timestamps(true, true);
  });

  // AI问诊记录
  await knex.schema.createTable('ai_consultations', (table) => {
    table.increments('id').primary();
    table.integer('user_id').references('id').inTable('users');
    table.text('symptoms');
    table.text('diagnosis');
    table.text('suggestions');
    table.json('report_analysis'); // 报告解读结果
    table.timestamps(true, true);
  });

  // 创建索引
  await knex.schema.raw('CREATE INDEX idx_users_phone ON users(phone)');
  await knex.schema.raw('CREATE INDEX idx_users_role ON users(role)');
  await knex.schema.raw('CREATE INDEX idx_orders_patient ON orders(patient_id)');
  await knex.schema.raw('CREATE INDEX idx_orders_companion ON orders(companion_id)');
  await knex.schema.raw('CREATE INDEX idx_orders_status ON orders(status)');
  await knex.schema.raw('CREATE INDEX idx_chat_room ON chat_messages(room_id)');
  await knex.schema.raw('CREATE INDEX idx_payments_order ON payments(order_no)');
}

export async function down(knex: Knex): Promise<void> {
  await knex.schema.dropTableIfExists('ai_consultations');
  await knex.schema.dropTableIfExists('reviews');
  await knex.schema.dropTableIfExists('chat_messages');
  await knex.schema.dropTableIfExists('payments');
  await knex.schema.dropTableIfExists('orders');
  await knex.schema.dropTableIfExists('hospitals');
  await knex.schema.dropTableIfExists('companions');
  await knex.schema.dropTableIfExists('users');
}