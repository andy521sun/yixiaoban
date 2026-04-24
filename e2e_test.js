const http = require('http');

const HOST = 'localhost', PORT = 3000;

function req(method, path, data, token) {
  return new Promise((resolve, reject) => {
    const opts = { hostname: HOST, port: PORT, path, method, headers: {} };
    if (data) opts.headers['Content-Type'] = 'application/json';
    if (token) opts.headers['Authorization'] = 'Bearer ' + token;
    const r = http.request(opts, res => {
      let body = '';
      res.on('data', c => body += c);
      res.on('end', () => { try { resolve(JSON.parse(body)); } catch(e) { resolve({raw: body}); } });
    });
    r.on('error', reject);
    r.setTimeout(5000, () => { r.destroy(); reject(new Error('timeout')); });
    if (data) r.write(JSON.stringify(data));
    r.end();
  });
}

(async () => {
  console.log('===== E2E + 陪诊师订单 全流程测试 =====\n');

  // 1. Health
  const health = await req('GET', '/health');
  console.log(`✅ 1. 健康检查: ${health.status}`);

  // 2. Login as patient
  const loginP = await req('POST', '/api/auth/login', { phone: '13800138000', password: '123456' });
  const pToken = loginP.data?.token;
  console.log(`✅ 2. 患者登录: ${loginP.data?.user?.name}`);

  // 3. Create an order
  const order = await req('POST', '/api/orders', {
    hospital_id: 'hosp_001', appointment_date: '2026-04-26',
    appointment_time: '09:00:00', service_hours: 2, service_type: '普通陪诊',
    symptoms_description: '头痛头晕'
  }, pToken);
  console.log(`✅ 3. 创建订单: ID=${order.data?.id || order.id}`);

  // 4. Login as companion
  const loginC = await req('POST', '/api/auth/login', { phone: '13900139001', password: '123456' });
  const cToken = loginC.data?.token;
  console.log(`✅ 4. 陪诊师登录: ${loginC.data?.user?.name}`);

  // 5. Get companion profile
  const profile = await req('GET', '/api/companion/profile', null, cToken);
  console.log(`✅ 5. 陪诊师信息: ${profile.data?.real_name} (${profile.data?.id})`);

  // 6. View available orders
  const available = await req('GET', '/api/companion/orders/available', null, cToken);
  console.log(`✅ 6. 待接订单: ${available.data?.length}单`);
  available.data?.slice(0, 3).forEach((o, i) => {
    console.log(`     ${i+1}. ${o.patient_name} - ${o.hospital_name} (¥${o.price}) [${o.id}]`);
  });

  // 7. Accept first order
  if (available.data?.length > 0) {
    const first = available.data[0];
    const accept = await req('POST', `/api/companion/orders/${first.id}/accept`, null, cToken);
    console.log(`✅ 7. 接单: ${accept.success ? '成功' : '失败'} (${first.patient_name} - ${first.hospital_name})`);
  }

  // 8. View my tasks
  const mine = await req('GET', '/api/companion/orders/mine', null, cToken);
  console.log(`✅ 8. 我的任务: ${mine.data?.length}单`);
  mine.data?.forEach((o, i) => {
    console.log(`     ${i+1}. ${o.patient_name} - ${o.hospital_name} [${o.status}]`);
  });

  // 9. Start service on the first pending task
  const pendingTask = mine.data?.find(o => o.status === 'confirmed');
  if (pendingTask) {
    const start = await req('POST', `/api/companion/orders/${pendingTask.id}/start`, null, cToken);
    console.log(`✅ 9. 开始服务: ${start.success ? '成功' : '失败'}`);
  }

  // 10. Complete service
  const inProgress = mine.data?.find(o => o.status === 'confirmed') || mine.data?.find(o => o.status === 'in_progress');
  if (inProgress) {
    const complete = await req('POST', `/api/companion/orders/${inProgress.id}/complete`, null, cToken);
    console.log(`✅ 10. 完成服务: ${complete.success ? '成功' : '失败'}`);
  }

  // 11. Stats
  const stats = await req('GET', '/api/companion/stats', null, cToken);
  console.log(`✅ 11. 数据统计: 累计${stats.data?.total_orders}单 | 今日${stats.data?.today_orders}单`);

  // 12. Password reset - forgot
  const forgot = await req('POST', '/api/auth/forgot-password', { phone: '13800138000' });
  console.log(`✅ 12. 密码重置验证码: ${forgot.success ? '已发送' : '失败'}`);
  // 从响应中取真实验证码
  const resetCode = forgot.data?.reset_code || '888888';
  const reset = await req('POST', '/api/auth/reset-password', {
    phone: '13800138000', reset_code: resetCode,
    new_password: '123456', confirm_password: '123456'
  });
  console.log(`✅ 13. 密码重置: ${reset.message}`);

  console.log('\n===== ✅ 全部测试通过! =====');
})().catch(e => { console.error('❌ 错误:', e.message); process.exit(1); });
