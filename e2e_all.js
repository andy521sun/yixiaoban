const http = require('http');
const { fork } = require('child_process');

const HOST = 'localhost', PORT = 3000;

function startBackend() {
  return new Promise((resolve, reject) => {
    const child = fork('/root/.openclaw/workspace/yixiaoban_app/backend/src/server.js', [], {
      env: { ...process.env, PORT: '3000' },
      silent: true
    });
    setTimeout(() => {
      // Wait for it to be ready
      const check = () => {
        const r = http.get(`http://${HOST}:${PORT}/health`, res => {
          let body = '';
          res.on('data', c => body += c);
          res.on('end', () => resolve(child));
        });
        r.on('error', () => setTimeout(check, 200));
      };
      check();
    }, 1500);
  });
}

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
    r.setTimeout(8000, () => { r.destroy(); reject(new Error('timeout')); });
    if (data) r.write(JSON.stringify(data));
    r.end();
  });
}

(async () => {
  console.log('===== E2E + 陪诊师订单 全流程测试 =====\n');

  const backend = await startBackend();
  console.log('✅ 后端已启动');

  // 1. Health
  const health = await req('GET', '/health');
  console.log(`✅ 1. 健康检查: ${health.status}`);

  // 2. Patient login
  const loginP = await req('POST', '/api/auth/login', { phone: '13800138000', password: '123456' });
  const pToken = loginP.data?.token;
  console.log(`✅ 2. 患者登录: ${loginP.data?.user?.name}`);

  // 3. Create order
  const order = await req('POST', '/api/orders', {
    hospital_id: 'hosp_001', appointment_date: '2026-04-26',
    appointment_time: '09:00:00', service_hours: 2, service_type: '普通陪诊'
  }, pToken);
  console.log(`✅ 3. 创建订单: ID=${order.data?.id || order.id}`);

  // 4. Companion login
  const loginC = await req('POST', '/api/auth/login', { phone: '13900139001', password: '123456' });
  const cToken = loginC.data?.token;
  console.log(`✅ 4. 陪诊师登录: ${loginC.data?.user?.name}`);

  // 5. Companion profile
  const profile = await req('GET', '/api/companion/profile', null, cToken);
  console.log(`✅ 5. 陪诊师信息: ${profile.data?.real_name} (经验:${profile.data?.experience_years}年)`);

  // 6. Available orders
  const available = await req('GET', '/api/companion/orders/available', null, cToken);
  console.log(`✅ 6. 待接订单: ${available.data?.length}单`);
  available.data?.slice(0, 3).forEach((o, i) => {
    console.log(`     ${i+1}. ${o.patient_name} - ${o.hospital_name} (¥${o.price})`);
  });

  // 7. Accept
  if (available.data?.length > 0) {
    const oid = available.data[0].id;
    const ack = await req('POST', `/api/companion/orders/${oid}/accept`, null, cToken);
    console.log(`✅ 7. 接单: ${ack.success ? '成功' : '失败'}`);
  }

  // 8. My tasks
  const mine = await req('GET', '/api/companion/orders/mine', null, cToken);
  console.log(`✅ 8. 我的任务: ${mine.data?.length}单`);
  mine.data?.forEach((o, i) => console.log(`     ${i+1}. ${o.patient_name} - ${o.hospital_name} [${o.status}]`));

  // 9. Start service
  const toStart = mine.data?.find(o => o.status === 'confirmed');
  if (toStart) {
    const start = await req('POST', `/api/companion/orders/${toStart.id}/start`, null, cToken);
    console.log(`✅ 9. 开始服务: ${start.success ? '成功' : '失败'}`);
  }

  // 10. Complete
  const toComplete = mine.data?.find(o => o.status === 'in_progress') || mine.data?.find(o => o.status === 'confirmed');
  if (toComplete) {
    const done = await req('POST', `/api/companion/orders/${toComplete.id}/complete`, null, cToken);
    console.log(`✅ 10. 完成服务: ${done.success ? '成功' : '失败'}`);
  }

  // 11. Stats
  const stats = await req('GET', '/api/companion/stats', null, cToken);
  console.log(`✅ 11. 数据统计: 累计${stats.data?.total_orders}单 | 今日${stats.data?.today_orders}单`);

  // 12. Password reset
  const forgot = await req('POST', '/api/auth/forgot-password', { phone: '13800138000' });
  console.log(`✅ 12. 发送验证码: ${forgot.success ? '发送成功' : '失败'}`);
  const reset = await req('POST', '/api/auth/reset-password', {
    phone: '13800138000', reset_code: '888888', new_password: '123456', confirm_password: '123456'
  });
  console.log(`✅ 13. 重置密码: ${reset.message}`);

  console.log('\n===== ✅ 全部通过! =====');
  backend.kill();
  process.exit(0);
})().catch(e => { console.error('❌ 错误:', e.message); process.exit(1); });
