/**
 * 医小伴APP - 简化陪诊师端API
 * 创建时间：2026年4月19日
 */

const express = require('./backend/node_modules/express');
const app = express();
const PORT = 3004;

app.use(express.json());

// 模拟数据
const companions = [
  { id: 'comp_001', username: 'doctor1', password: '123', name: '张医生', phone: '13800138001' },
  { id: 'comp_002', username: 'nurse1', password: '123', name: '李护士', phone: '13800138002' }
];

const tasks = [
  { id: 'task1', companion_id: 'comp_001', patient: '王先生', hospital: '协和医院', time: '09:00', status: 'pending' },
  { id: 'task2', companion_id: 'comp_001', patient: '李女士', hospital: '华山医院', time: '14:00', status: 'accepted' },
  { id: 'task3', companion_id: 'comp_002', patient: '赵先生', hospital: '瑞金医院', time: '10:30', status: 'pending' }
];

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: 'companion-api' });
});

// 登录
app.post('/api/login', (req, res) => {
  const { username, password } = req.body;
  const companion = companions.find(c => c.username === username && c.password === password);
  
  if (companion) {
    res.json({
      success: true,
      token: `token_${companion.id}`,
      companion: { id: companion.id, name: companion.name }
    });
  } else {
    res.status(401).json({ success: false, message: '登录失败' });
  }
});

// 获取任务列表
app.get('/api/tasks', (req, res) => {
  const token = req.headers.authorization;
  if (!token) return res.status(401).json({ success: false, message: '需要认证' });
  
  const companionId = token.replace('token_', '');
  const companionTasks = tasks.filter(t => t.companion_id === companionId);
  
  res.json({
    success: true,
    tasks: companionTasks,
    count: companionTasks.length
  });
});

// 接单
app.post('/api/tasks/:id/accept', (req, res) => {
  const token = req.headers.authorization;
  if (!token) return res.status(401).json({ success: false, message: '需要认证' });
  
  const taskId = req.params.id;
  const task = tasks.find(t => t.id === taskId);
  
  if (task && task.status === 'pending') {
    task.status = 'accepted';
    res.json({ success: true, message: '接单成功', task });
  } else {
    res.status(400).json({ success: false, message: '无法接单' });
  }
});

// 启动
app.listen(PORT, () => {
  console.log(`陪诊师API运行在 http://localhost:${PORT}`);
  console.log(`测试登录: curl -X POST http://localhost:${PORT}/api/login -d '{"username":"doctor1","password":"123"}'`);
  console.log(`获取任务: curl -H "Authorization: token_comp_001" http://localhost:${PORT}/api/tasks`);
});