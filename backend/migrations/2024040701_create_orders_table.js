/**
 * 医小伴APP - 订单表迁移
 * 创建时间: 2026年4月7日
 * 描述: 创建订单表，支持预约陪诊服务
 */

exports.up = function(knex) {
  return knex.schema.createTable('orders', function(table) {
    // 主键
    table.string('id', 36).primary().comment('订单ID');
    
    // 用户信息
    table.string('user_id', 36).notNullable().comment('用户ID');
    table.string('user_name', 100).comment('用户姓名');
    table.string('user_phone', 20).comment('用户电话');
    
    // 医院信息
    table.string('hospital_id', 36).notNullable().comment('医院ID');
    table.string('hospital_name', 200).comment('医院名称');
    table.string('hospital_level', 50).comment('医院等级');
    table.string('hospital_address', 500).comment('医院地址');
    
    // 陪诊师信息
    table.string('companion_id', 36).notNullable().comment('陪诊师ID');
    table.string('companion_name', 100).comment('陪诊师姓名');
    table.string('companion_level', 50).comment('陪诊师等级');
    table.decimal('companion_price_per_hour', 10, 2).comment('陪诊师时薪');
    
    // 预约信息
    table.string('service_type', 50).notNullable().defaultTo('普通陪诊').comment('服务类型');
    table.timestamp('appointment_time').notNullable().comment('预约时间');
    table.integer('duration_minutes').notNullable().defaultTo(120).comment('服务时长（分钟）');
    
    // 价格信息
    table.decimal('price', 10, 2).notNullable().comment('订单总价');
    table.decimal('base_price', 10, 2).comment('基础价格');
    table.decimal('service_fee', 10, 2).comment('平台服务费');
    table.decimal('discount_amount', 10, 2).defaultTo(0).comment('优惠金额');
    
    // 订单状态
    table.enum('status', [
      'pending',      // 待支付
      'confirmed',    // 已确认
      'in_progress',  // 进行中
      'completed',    // 已完成
      'cancelled',    // 已取消
      'refunded'      // 已退款
    ]).defaultTo('pending').comment('订单状态');
    
    // 支付信息
    table.enum('payment_method', ['wechat', 'alipay', 'bank_card', 'cash']).comment('支付方式');
    table.enum('payment_status', ['unpaid', 'paid', 'refunded', 'failed']).defaultTo('unpaid').comment('支付状态');
    table.timestamp('payment_time').comment('支付时间');
    table.string('payment_transaction_id', 100).comment('支付交易ID');
    
    // 服务信息
    table.text('special_requirements').comment('特殊要求');
    table.text('cancellation_reason').comment('取消原因');
    
    // 时间戳
    table.timestamp('created_at').defaultTo(knex.fn.now()).comment('创建时间');
    table.timestamp('updated_at').defaultTo(knex.fn.now()).comment('更新时间');
    table.timestamp('completed_at').comment('完成时间');
    table.timestamp('cancelled_at').comment('取消时间');
    
    // 索引
    table.index('user_id', 'idx_user_id');
    table.index('status', 'idx_status');
    table.index('payment_status', 'idx_payment_status');
    table.index('created_at', 'idx_created_at');
    table.index(['user_id', 'status'], 'idx_user_status');
    table.index('appointment_time', 'idx_appointment_time');
    
    // 外键约束（实际开发中启用）
    // table.foreign('user_id').references('id').inTable('users');
    // table.foreign('hospital_id').references('id').inTable('hospitals');
    // table.foreign('companion_id').references('id').inTable('companions');
  }).then(() => {
    console.log('✅ 订单表创建成功');
  });
};

exports.down = function(knex) {
  return knex.schema.dropTable('orders').then(() => {
    console.log('🗑️  订单表已删除');
  });
};

/**
 * 表结构说明:
 * 
 * 1. 订单状态流转:
 *    pending → confirmed → in_progress → completed
 *    pending → cancelled
 *    confirmed → cancelled
 *    paid → refunded
 * 
 * 2. 价格计算:
 *    price = base_price + service_fee - discount_amount
 *    base_price = companion_price_per_hour * (duration_minutes / 60) * service_type_multiplier
 * 
 * 3. 服务类型倍数:
 *    - 普通陪诊: 1.0
 *    - 专业陪诊: 1.5
 *    - 急诊陪诊: 2.0
 *    - 长期陪护: 3.0
 * 
 * 4. 陪诊师等级加成:
 *    - 中级: 1.0
 *    - 高级: 1.3
 *    - 专家: 1.5
 * 
 * 5. 索引说明:
 *    - idx_user_id: 快速查询用户订单
 *    - idx_status: 按状态筛选订单
 *    - idx_payment_status: 按支付状态筛选
 *    - idx_created_at: 按创建时间排序
 *    - idx_user_status: 联合查询用户和状态
 *    - idx_appointment_time: 按预约时间查询
 */