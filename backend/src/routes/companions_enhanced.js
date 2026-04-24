const express = require('express');
const router = express.Router();

// 模拟陪诊师数据（包含移动端需要的字段）
const companionsData = [
  {
    id: 'comp_001',
    name: '张美丽',
    title: '资深陪诊师',
    experience: '5',
    rating: 4.8,
    completed_orders: 128,
    price_per_hour: '200',
    is_online: true,
    avatar: 'https://images.unsplash.com/photo-1559839734-2b71ea197ec2?w=200&h=200&fit=crop',
    specialties: ['内科陪诊', '老年陪护', '报告解读', '医患沟通'],
    introduction: '拥有5年陪诊经验，擅长内科疾病陪诊和老年患者陪护，耐心细致，服务周到。原三甲医院护士，熟悉医院流程。',
    certification: true,
    languages: ['普通话', '上海话', '英语'],
    service_area: ['上海市区', '浦东新区', '徐汇区', '静安区'],
    available_times: ['周一至周五 08:00-18:00', '周六 09:00-17:00'],
    response_time: '5分钟内',
    success_rate: '98%',
    tags: ['耐心细致', '沟通能力强', '医学背景', '五星好评']
  },
  {
    id: 'comp_002',
    name: '李建国',
    title: '医学专家陪诊',
    experience: '8',
    rating: 4.9,
    completed_orders: 256,
    price_per_hour: '300',
    is_online: true,
    avatar: 'https://images.unsplash.com/photo-1612349317150-e413f6a5b16d?w=200&h=200&fit=crop',
    specialties: ['全科陪诊', '报告解读', '医患沟通', '手术陪护'],
    introduction: '原三甲医院医生，8年临床经验，精通医学术语，能有效协助医患沟通，提供专业的医疗建议和陪诊服务。',
    certification: true,
    languages: ['普通话', '英语', '日语'],
    service_area: ['全上海'],
    available_times: ['周一至周日 07:00-20:00'],
    response_time: '3分钟内',
    success_rate: '99%',
    tags: ['医学专家', '经验丰富', '沟通专家', '高成功率']
  },
  {
    id: 'comp_003',
    name: '王小红',
    title: '妇产专科陪诊师',
    experience: '4',
    rating: 4.7,
    completed_orders: 89,
    price_per_hour: '180',
    is_online: false,
    avatar: 'https://images.unsplash.com/photo-1594824434340-7e7dfc37cabb?w=200&h=200&fit=crop',
    specialties: ['妇产科陪诊', '孕产陪护', '儿童陪诊', '心理疏导'],
    introduction: '专注于妇产科陪诊服务，熟悉各大妇产医院流程，能为孕产妇提供贴心的陪诊和心理支持服务。',
    certification: true,
    languages: ['普通话', '上海话'],
    service_area: ['黄浦区', '徐汇区', '长宁区'],
    available_times: ['周一至周五 09:00-17:00'],
    response_time: '10分钟内',
    success_rate: '96%',
    tags: ['妇产专科', '温柔耐心', '女性专属', '好评如潮']
  },
  {
    id: 'comp_004',
    name: '赵刚',
    title: '老年陪护专家',
    experience: '6',
    rating: 4.8,
    completed_orders: 167,
    price_per_hour: '220',
    is_online: true,
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
    specialties: ['老年陪护', '慢性病管理', '康复陪诊', '用药指导'],
    introduction: '专注于老年患者陪诊服务，熟悉老年常见疾病的诊疗流程，能为老年患者提供安全、周到的陪诊服务。',
    certification: true,
    languages: ['普通话', '上海话'],
    service_area: ['全上海'],
    available_times: ['周一至周六 08:00-19:00'],
    response_time: '8分钟内',
    success_rate: '97%',
    tags: ['老年专家', '安全可靠', '慢性病管理', '家属信赖']
  },
  {
    id: 'comp_005',
    name: '刘婷婷',
    title: '儿科陪诊师',
    experience: '3',
    rating: 4.9,
    completed_orders: 75,
    price_per_hour: '190',
    is_online: true,
    avatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=200&h=200&fit=crop',
    specialties: ['儿科陪诊', '儿童心理', '疫苗接种', '生长发育'],
    introduction: '拥有幼教背景，熟悉儿童心理，能有效安抚儿童情绪，让就医过程更加顺利愉快。',
    certification: true,
    languages: ['普通话', '英语'],
    service_area: ['浦东新区', '闵行区', '徐汇区'],
    available_times: ['周二至周日 08:30-17:30'],
    response_time: '6分钟内',
    success_rate: '99%',
    tags: ['儿科专家', '儿童喜爱', '耐心温柔', '家长推荐']
  },
  {
    id: 'comp_006',
    name: '陈明',
    title: '急诊陪诊专家',
    experience: '7',
    rating: 4.7,
    completed_orders: 142,
    price_per_hour: '280',
    is_online: true,
    avatar: 'https://images.unsplash.com/photo-1507591064344-4c6ce005-128?w=200&h=200&fit=crop',
    specialties: ['急诊陪诊', '外伤处理', '急救知识', '夜间陪诊'],
    introduction: '原急诊科护士，熟悉急诊流程，能在紧急情况下提供专业的陪诊服务和初步医疗处理。',
    certification: true,
    languages: ['普通话', '英语'],
    service_area: ['全上海'],
    available_times: ['24小时服务'],
    response_time: '2分钟内',
    success_rate: '95%',
    tags: ['急诊专家', '快速响应', '急救技能', '全天候']
  },
  {
    id: 'comp_007',
    name: '孙丽华',
    title: '中医陪诊师',
    experience: '5',
    rating: 4.6,
    completed_orders: 98,
    price_per_hour: '210',
    is_online: false,
    avatar: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=200&h=200&fit=crop',
    specialties: ['中医陪诊', '中药调理', '针灸推拿', '养生指导'],
    introduction: '中医世家出身，熟悉中医诊疗流程，能为需要中医治疗的患者提供专业的陪诊和调理建议。',
    certification: true,
    languages: ['普通话', '上海话'],
    service_area: ['静安区', '黄浦区', '虹口区'],
    available_times: ['周一至周五 08:00-18:00'],
    response_time: '15分钟内',
    success_rate: '94%',
    tags: ['中医专家', '传统医学', '调理养生', '经验丰富']
  },
  {
    id: 'comp_008',
    name: '周伟',
    title: '国际医疗陪诊',
    experience: '4',
    rating: 4.8,
    completed_orders: 112,
    price_per_hour: '350',
    is_online: true,
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop',
    specialties: ['国际医疗', '外语陪诊', '高端医疗', '海外就医'],
    introduction: '熟悉国际医疗流程，精通多国语言，能为外籍患者和高端医疗需求者提供专业的陪诊服务。',
    certification: true,
    languages: ['英语', '日语', '韩语', '普通话'],
    service_area: ['全上海'],
    available_times: ['周一至周日 09:00-21:00'],
    response_time: '5分钟内',
    success_rate: '98%',
    tags: ['国际医疗', '多语言', '高端服务', '专业可靠']
  }
];

// 获取陪诊师列表（增强版）
router.get('/enhanced', (req, res) => {
  try {
    const { page = 1, limit = 10, specialty, min_rating, max_price, online_only } = req.query;
    const pageNum = parseInt(page);
    const limitNum = parseInt(limit);
    
    // 过滤数据
    let filteredCompanions = [...companionsData];
    
    // 按专长过滤
    if (specialty) {
      filteredCompanions = filteredCompanions.filter(c => 
        c.specialties.some(s => s.includes(specialty))
      );
    }
    
    // 按最低评分过滤
    if (min_rating) {
      const minRatingNum = parseFloat(min_rating);
      filteredCompanions = filteredCompanions.filter(c => c.rating >= minRatingNum);
    }
    
    // 按最高价格过滤
    if (max_price) {
      const maxPriceNum = parseFloat(max_price);
      filteredCompanions = filteredCompanions.filter(c => 
        parseFloat(c.price_per_hour) <= maxPriceNum
      );
    }
    
    // 只显示在线
    if (online_only === 'true') {
      filteredCompanions = filteredCompanions.filter(c => c.is_online);
    }
    
    // 分页
    const startIndex = (pageNum - 1) * limitNum;
    const endIndex = pageNum * limitNum;
    const paginatedCompanions = filteredCompanions.slice(startIndex, endIndex);
    
    res.json({
      success: true,
      data: paginatedCompanions,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total: filteredCompanions.length,
        total_pages: Math.ceil(filteredCompanions.length / limitNum)
      },
      filters: {
        specialties: Array.from(new Set(companionsData.flatMap(c => c.specialties))),
        price_ranges: [
          { label: '200元以下', min: 0, max: 200 },
          { label: '200-300元', min: 200, max: 300 },
          { label: '300元以上', min: 300, max: 1000 }
        ],
        experience_ranges: [
          { label: '3年以下', min: 0, max: 3 },
          { label: '3-5年', min: 3, max: 5 },
          { label: '5年以上', min: 5, max: 20 }
        ]
      }
    });
  } catch (error) {
    console.error('获取陪诊师列表失败:', error);
    res.status(500).json({
      success: false,
      message: '获取陪诊师列表失败',
      error: error.message
    });
  }
});

// 获取陪诊师详情
router.get('/enhanced/:id', (req, res) => {
  try {
    const { id } = req.params;
    const companion = companionsData.find(c => c.id === id);
    
    if (!companion) {
      return res.status(404).json({
        success: false,
        message: '陪诊师不存在'
      });
    }
    
    // 添加更多详情信息
    const companionDetail = {
      ...companion,
      education: [
        { institution: '上海医科大学', degree: '本科', major: '护理学', year: '2010-2014' },
        { institution: '上海市陪诊师培训中心', degree: '高级陪诊师证书', year: '2015' }
      ],
      work_experience: [
        { hospital: '上海市第一人民医院', position: '护士', duration: '4年', description: '在内科病房工作，熟悉医院各项流程' },
        { company: '医小伴陪诊平台', position: '资深陪诊师', duration: `${companion.experience}年`, description: '为数百名患者提供专业陪诊服务' }
      ],
      certificates: [
        { name: '高级陪诊师资格证书', issuer: '上海市卫生健康委员会', date: '2015-06' },
        { name: '急救员证书', issuer: '上海市红十字会', date: '2016-03' },
        { name: '心理咨询师三级', issuer: '国家人力资源和社会保障部', date: '2017-09' }
      ],
      reviews: [
        {
          id: 'rev_001',
          user_name: '张先生',
          user_avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=50&h=50&fit=crop',
          rating: 5,
          date: '2024-03-20',
          content: '李医生非常专业，帮我父亲看病时解释得很清楚，医生说的专业术语他都翻译成我们能听懂的话。',
          order_type: '内科陪诊',
          helpful: 12
        },
        {
          id: 'rev_002',
          user_name: '王女士',
          user_avatar: 'https://images.unsplash.com/photo-1494790108755-2616b612b786?w=50&h=50&fit=crop',
          rating: 5,
          date: '2024-03-15',
          content: '陪诊过程很顺利，李医生提前帮我预约好了专家号，节省了很多排队时间。',
          order_type: '专家门诊陪诊',
          helpful: 8
        },
        {
          id: 'rev_003',
          user_name: '陈先生',
          user_avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=50&h=50&fit=crop',
          rating: 4,
          date: '2024-03-10',
          content: '服务很好，就是价格稍微有点高，不过物有所值。',
          order_type: '全科陪诊',
          helpful: 5
        }
      ],
      statistics: {
        total_orders: companion.completed_orders,
        repeat_customers: Math.floor(companion.completed_orders * 0.3),
        average_response_time: companion.response_time,
        cancellation_rate: '2%',
        customer_satisfaction: companion.success_rate
      },
      availability: {
        today: [
          { time: '09:00-12:00', available: true },
          { time: '14:00-17:00', available: true },
          { time: '18:00-20:00', available: false }
        ],
        tomorrow: [
          { time: '08:00-11:00', available: true },
          { time: '13:00-16:00', available: true },
          { time: '17:00-19:00', available: true }
        ]
      }
    };
    
    res.json({
      success: true,
      data: companionDetail
    });
  } catch (error) {
    console.error('获取陪诊师详情失败:', error);
    res.status(500).json({
      success: false,
      message: '获取陪诊师详情失败',
      error: error.message
    });
  }
});

// 搜索陪诊师
router.get('/enhanced/search', (req, res) => {
  try {
    const { q, specialty, min_experience, max_price } = req.query;
    
    let results = [...companionsData];
    
    // 关键词搜索
    if (q) {
      const queryLower = q.toLowerCase();
      results = results.filter(c => 
        c.name.toLowerCase().includes(queryLower) ||
        c.title.toLowerCase().includes(queryLower) ||
        c.introduction.toLowerCase().includes(queryLower) ||
        c.tags.some(tag => tag.toLowerCase().includes(queryLower))
      );
    }
    
    // 专长搜索
    if (specialty) {
      results = results.filter(c => 
        c.specialties.some(s => s.includes(specialty))
      );
    }
    
    // 最低经验搜索
    if (min_experience) {
      const minExp = parseInt(min_experience);
      results = results.filter(c => parseInt(c.experience) >= minExp);
    }
    
    // 最高价格搜索
    if (max_price) {
      const maxPrice = parseFloat(max_price);
      results = results.filter(c => parseFloat(c.price_per_hour) <= maxPrice);
    }
    
    // 排序：在线优先，然后按评分和订单数
    results.sort((a, b) => {
      if (a.is_online !== b.is_online) return b.is_online - a.is_online;
      if (b.rating !== a.rating) return b.rating - a.rating;
      return b.completed_orders - a.completed_orders;
    });
    
    res.json({
      success: true,
      data: results.slice(0, 20),
      search_info: {
        query: q,
        filters: { specialty, min_experience, max_price },
        result_count: results.length
      }
    });
  } catch (error) {
    console.error('搜索陪诊师失败:', error);
    res.status(500).json({
      success: false,
      message: '搜索陪诊师失败',
      error: error.message
    });
  }
});

module.exports = router;

