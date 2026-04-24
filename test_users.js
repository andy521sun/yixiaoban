const http = require('http');
const PORT = 3000;

function req(method, path, data, token) {
  return new Promise((resolve, reject) => {
    const opts = { hostname: 'localhost', port: PORT, path, method, headers: {} };
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
  const testUsers = [
    ['13800138001', '张先生'], ['13800138002', '李女士'], ['13800138003', '王阿姨'],
    ['13800000000', '管理员'], ['13900139001', '张护士'], ['13900139002', '李医生'], ['13900139003', '王阿姨（陪诊师）']
  ];
  console.log('逐个测试用户登录:\n');
  for (const [phone, name] of testUsers) {
    try {
      const r = await req('POST', '/api/auth/login', { phone, password: '123456' });
      console.log(`  ${r.success ? '✅' : '❌'} ${name}(${phone}): ${r.message || '??'}`);
      if (!r.success && r.raw) console.log('     raw:', r.raw);
    } catch(e) {
      console.log(`  ❌ ${name}(${phone}): ERROR ${e.message}`);
    }
  }
})();
