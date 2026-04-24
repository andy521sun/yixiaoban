const express = require('express');
const router = express.Router();

// 模拟医院数据（包含移动端需要的字段）
const hospitalsData = [
  {
    id: 'hosp_001',
    name: '上海市第一人民医院',
    level: '三甲',
    address: '上海市虹口区武进路85号',
    phone: '021-63240090',
    description: '上海市第一人民医院是上海市属大型综合性三级甲等医院，创建于1864年，是上海最早建立的西医医院之一。',
    image: 'https://images.unsplash.com/photo-1586773860418-dc22f8b874bc?w=400&h=300&fit=crop',
    departments: ['内科', '外科', '妇产科', '儿科', '眼科', '耳鼻喉科', '口腔科', '皮肤科'],
    opening_hours: '08:00-17:00',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.8,
    review_count: 1245,
    distance: '2.5km',
    latitude: 31.2492,
    longitude: 121.4879,
    tags: ['三甲医院', '综合医院', '医保定点', '24小时急诊']
  },
  {
    id: 'hosp_002',
    name: '华山医院',
    level: '三甲',
    address: '上海市静安区乌鲁木齐中路12号',
    phone: '021-62489999',
    description: '复旦大学附属华山医院是卫生部直属医院，是中国最著名的医院之一，以神经外科、皮肤科、感染科闻名。',
    image: 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?w=400&h=300&fit=crop',
    departments: ['神经外科', '皮肤科', '感染科', '内分泌科', '心血管科', '呼吸科'],
    opening_hours: '08:00-17:30',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.9,
    review_count: 1890,
    distance: '3.2km',
    latitude: 31.2205,
    longitude: 121.4493,
    tags: ['三甲医院', '专科强项', '医保定点', '国际医疗']
  },
  {
    id: 'hosp_003',
    name: '瑞金医院',
    level: '三甲',
    address: '上海市黄浦区瑞金二路197号',
    phone: '021-64370045',
    description: '上海交通大学医学院附属瑞金医院是一所集医疗、教学、科研为一体的三级甲等综合性医院，以内分泌科、血液科著称。',
    image: 'https://images.unsplash.com/photo-1582750433449-648ed127bb54?w=400&h=300&fit=crop',
    departments: ['内分泌科', '血液科', '消化内科', '肾内科', '风湿免疫科'],
    opening_hours: '08:00-17:00',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.7,
    review_count: 1567,
    distance: '4.1km',
    latitude: 31.2078,
    longitude: 121.4695,
    tags: ['三甲医院', '教学医院', '医保定点', '科研中心']
  },
  {
    id: 'hosp_004',
    name: '中山医院',
    level: '三甲',
    address: '上海市徐汇区枫林路180号',
    phone: '021-64041990',
    description: '复旦大学附属中山医院是上海市第一批三级甲等医院，以心血管病、肝肿瘤、呼吸病诊治为特色。',
    image: 'https://images.unsplash.com/photo-1516549655669-df6654e435de?w=400&h=300&fit=crop',
    departments: ['心血管科', '肝肿瘤科', '呼吸科', '胸外科', '心外科'],
    opening_hours: '08:00-17:30',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.8,
    review_count: 1789,
    distance: '5.3km',
    latitude: 31.1934,
    longitude: 121.4592,
    tags: ['三甲医院', '心血管专科', '医保定点', '器官移植']
  },
  {
    id: 'hosp_005',
    name: '仁济医院',
    level: '三甲',
    address: '上海市浦东新区浦建路160号',
    phone: '021-58752345',
    description: '上海交通大学医学院附属仁济医院是上海开埠后第一所西医医院，以消化内科、风湿免疫科、泌尿外科闻名。',
    image: 'https://images.unsplash.com/photo-1579684385127-1ef15d508118?w=400&h=300&fit=crop',
    departments: ['消化内科', '风湿免疫科', '泌尿外科', '妇产科', '儿科'],
    opening_hours: '08:00-17:00',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.6,
    review_count: 1345,
    distance: '6.8km',
    latitude: 31.2217,
    longitude: 121.5442,
    tags: ['三甲医院', '历史悠长', '医保定点', '涉外医疗']
  },
  {
    id: 'hosp_006',
    name: '上海市第六人民医院',
    level: '三甲',
    address: '上海市徐汇区宜山路600号',
    phone: '021-64369181',
    description: '上海市第六人民医院以骨科、内分泌代谢科、心血管内科为特色，是上海市重要的医疗中心之一。',
    image: 'https://images.unsplash.com/photo-1584467735871-8db9ac8dcc6d?w=400&h=300&fit=crop',
    departments: ['骨科', '内分泌科', '心血管内科', '康复科', '运动医学科'],
    opening_hours: '08:00-17:00',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.5,
    review_count: 987,
    distance: '7.2km',
    latitude: 31.1789,
    longitude: 121.4321,
    tags: ['三甲医院', '骨科专科', '医保定点', '康复中心']
  },
  {
    id: 'hosp_007',
    name: '上海市儿童医院',
    level: '三甲',
    address: '上海市静安区北京西路1400弄24号',
    phone: '021-62474880',
    description: '上海市儿童医院是上海最早成立的儿童专科医院，专注于儿童疾病的预防、诊断和治疗。',
    image: 'https://images.unsplash.com/photo-1512428813834-c702c7702b78?w=400&h=300&fit=crop',
    departments: ['儿科', '新生儿科', '儿童保健科', '小儿外科', '儿童心理科'],
    opening_hours: '08:00-17:00',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.9,
    review_count: 2345,
    distance: '3.8km',
    latitude: 31.2334,
    longitude: 121.4567,
    tags: ['儿童专科', '三甲医院', '医保定点', '儿科急诊']
  },
  {
    id: 'hosp_008',
    name: '上海市妇产科医院',
    level: '三甲',
    address: '上海市黄浦区方斜路419号',
    phone: '021-63455050',
    description: '复旦大学附属妇产科医院，又称红房子医院，是中国最早的妇产科专科医院之一。',
    image: 'https://images.unsplash.com/photo-1551601651-2a8555f1a136?w=400&h=300&fit=crop',
    departments: ['妇科', '产科', '生殖医学科', '计划生育科', '妇科肿瘤科'],
    opening_hours: '08:00-17:00',
    emergency: true,
    parking: true,
    wifi: true,
    rating: 4.8,
    review_count: 1890,
    distance: '4.5km',
    latitude: 31.2178,
    longitude: 121.4892,
    tags: ['妇产专科', '三甲医院', '医保定点', '生殖医学']
  }
];

// 获取医院列表（增强版）
router.get('/enhanced', (req, res) => {
  try {
    const { page = 1, limit = 10, level, keyword } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    
    // 过滤数据
    let filteredHospitals = [...hospitalsData];
    
    // 按等级过滤
    if (level) {
      filteredHospitals = filteredHospitals.filter(h => h.level === level);
    }
    
    // 按关键词过滤
    if (keyword) {
      const keywordLower = keyword.toLowerCase();
      filteredHospitals = filteredHospitals.filter(h => 
        h.name.toLowerCase().includes(keywordLower) ||
        h.address.toLowerCase().includes(keywordLower) ||
        h.departments.some(dept => dept.toLowerCase().includes(keywordLower))
      );
    }
    
    // 分页
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = pageNum * limitNum;
    const paginatedHospitals = filteredHospitals.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      data: paginatedHospitals,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: filteredHospitals.length,
        total_pages: Math.ceil(filteredHospitals.length / limitNum)
      },
      filters: {
        levels: ['三甲', '三乙', '二甲', '二乙', '一级'],
        departments: Array.from(new Set(hospitalsData.flatMap(h => h.departments))).slice(0, 20)
      }
    });
  } catch (error) {
    console.error('获取医院列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取医院列表失败',
      error: error.message
    });
  }
});

// 获取医院详情
router.get('/enhanced/:id', (req, res) => {
  try {
    const { id } = req.params;
    const hospital = hospitalsData.find(h => h.id === id);
    
    if (!hospital) {
      return res.status(404).json({
        success: false,
        message: '医院不存在'
      });
    }
    
    // 添加更多详情信息
    const hospitalDetail = {
      ...hospital,
      facilities: {
        parking: hospital.parking,
        wifi: hospital.wifi,
        cafeteria: true,
        pharmacy: true,
        atm: true,
        wheelchair_access: true,
        breastfeeding_room: true
      },
      doctors_count: Math.floor(Math.random() * 500) + 200,
      beds_count: Math.floor(Math.random() * 2000) + 1000,
      annual_patients: Math.floor(Math.random() * 1000000) + 500000,
      appointment_methods: ['微信预约', '电话预约', '现场挂号', '官网预约'],
      payment_methods: ['医保卡', '微信支付', '支付宝', '银行卡', '现金'],
      transportation: [
        { type: '地铁', line: '1号线', station: '人民广场站', distance: '800米' },
        { type: '公交', line: '49路', station: '医院门口', distance: '0米' },
        { type: '公交', line: '123路', station: '医院门口', distance: '0米' }
      ],
      popular_departments: hospital.departments.slice(0, 5).map(dept => ({
        name: dept,
        wait_time: Math.floor(Math.random() * 120) + 30, // 分钟
        doctor_count: Math.floor(Math.random() * 50) + 10
      })),
      reviews: [
        {
          id: 'rev_001',
          user_name: '王先生',
          rating: 5,
          date: '2024-03-15',
          content: '医生专业，护士态度好，环境整洁。陪诊师服务很周到。',
          helpful: 45
        },
        {
          id: 'rev_002',
          user_name: '李女士',
          rating: 4,
          date: '2024-03-10',
          content: '医院很大，第一次来有点找不到方向，好在有陪诊师带领。',
          helpful: 23
        }
      ]
    };
    
    res.json({
      success: true,
      data: hospitalDetail
    });
  } catch (error) {
    console.error('获取医院详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取医院详情失败',
      error: error.message
    });
  }
});

// 搜索医院
router.get('/enhanced/search', (req, res) => {
  try {
    const { q, lat, lng, radius = 10 } = req.query;
    
    if (!q && !lat && !lng) {
      return res.status(400).json({
        success: false,
        message: '请提供搜索关键词或位置信息'
      });
    }
    
    let results = [...hospitalsData];
    
    // 关键词搜索
    if (q) {
      const queryLower = q.toLowerCase();
      results = results.filter(h => 
        h.name.toLowerCase().includes(queryLower) ||
        h.address.toLowerCase().includes(queryLower) ||
        h.departments.some(dept => dept.toLowerCase().includes(queryLower)) ||
        h.tags.some(tag => tag.toLowerCase().includes(queryLower))
      );
    }
    
    // 位置搜索（模拟）
    if (lat && lng) {
      // 这里可以添加真实的位置计算逻辑
      results = results.map(h => ({
        ...h,
        distance_km: parseFloat((Math.random() * 15).toFixed(1))
      })).sort((a, b) => a.distance_km - b.distance_km);
    }
    
    res.json({
      success: true,
      data: results.slice(0, 20),
      search_info: {
        query: q,
        location: lat && lng ? { lat, lng } : null,
        result_count: results.length
      }
    });
  } catch (error) {
    console.error('搜索医院失败:', error);
    res.status(500).json({
      success: false,
      message: '搜索医院失败',
      error: error.message
    });
  }
});

// 获取医院科室列表
router.get('/enhanced/:id/departments', (req, res) => {
  try {
    const { id } = req.params;
    const hospital = hospitalsData.find(h => h.id === id);
    
    if (!hospital) {
      return res.status(404).json({
        success: false,
        message: '医院不存在'
      });
    }
    
    const departments = hospital.departments.map((dept, index) => ({
      id: `dept_${id}_${index + 1}`,
      name: dept,
      description: `${dept}是医院的重点科室之一，拥有先进的医疗设备和专业的医疗团队。`,
      doctor_count: Math.floor(Math.random() * 50) + 10,
      wait_time: Math.floor(Math.random() * 120) + 30,
      is_hot: index < 3,
      services: ['门诊', '住院', '手术', '检查'].slice(0, Math.floor(Math.random() * 4) + 1)
    }));
    
    res.json({
      success: true,
      data: departments,
      hospital_name: hospital.name
    });
  } catch (error) {
    console.error('获取医院科室失败:', error);
    res.status(500).json({
      success: false,
      message: '获取医院科室失败',
      error: error.message
    });
  }
});

module.exports = router;