<template>
  <div class="order-edit-form">
    <el-form
      ref="formRef"
      :model="formData"
      :rules="formRules"
      label-width="120px"
      label-position="right"
      size="default"
    >
      <!-- 基本信息 -->
      <el-form-item label="订单类型" prop="serviceType">
        <el-select
          v-model="formData.serviceType"
          placeholder="请选择服务类型"
          style="width: 100%"
        >
          <el-option
            v-for="type in serviceTypeOptions"
            :key="type.value"
            :label="type.label"
            :value="type.value"
          />
        </el-select>
      </el-form-item>

      <el-form-item label="订单金额" prop="amount">
        <el-input-number
          v-model="formData.amount"
          :min="0"
          :max="10000"
          :precision="2"
          :step="50"
          placeholder="请输入订单金额"
          style="width: 100%"
        >
          <template #prefix>¥</template>
        </el-input-number>
      </el-form-item>

      <el-form-item label="服务时长" prop="serviceHours">
        <el-input-number
          v-model="formData.serviceHours"
          :min="1"
          :max="24"
          :step="1"
          placeholder="请输入服务时长"
          style="width: 100%"
        >
          <template #suffix>小时</template>
        </el-input-number>
      </el-form-item>

      <el-form-item label="预约时间" prop="appointmentTime">
        <el-date-picker
          v-model="formData.appointmentTime"
          type="datetime"
          placeholder="请选择预约时间"
          style="width: 100%"
          value-format="YYYY-MM-DD HH:mm:ss"
        />
      </el-form-item>

      <!-- 患者信息 -->
      <el-divider>患者信息</el-divider>
      
      <el-form-item label="患者姓名" prop="patientName">
        <el-input
          v-model="formData.patientName"
          placeholder="请输入患者姓名"
          clearable
        />
      </el-form-item>

      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="手机号码" prop="patientPhone">
            <el-input
              v-model="formData.patientPhone"
              placeholder="请输入手机号码"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="性别" prop="patientGender">
            <el-radio-group v-model="formData.patientGender">
              <el-radio label="male">男</el-radio>
              <el-radio label="female">女</el-radio>
              <el-radio label="unknown">未知</el-radio>
            </el-radio-group>
          </el-form-item>
        </el-col>
      </el-row>

      <el-form-item label="年龄" prop="patientAge">
        <el-input-number
          v-model="formData.patientAge"
          :min="0"
          :max="120"
          :step="1"
          placeholder="请输入年龄"
          style="width: 100%"
        />
      </el-form-item>

      <el-form-item label="身份证号" prop="patientIdCard">
        <el-input
          v-model="formData.patientIdCard"
          placeholder="请输入身份证号"
          clearable
          maxlength="18"
          show-word-limit
        />
      </el-form-item>

      <el-form-item label="健康状况" prop="healthCondition">
        <el-input
          v-model="formData.healthCondition"
          type="textarea"
          :rows="2"
          placeholder="请输入健康状况描述"
          maxlength="500"
          show-word-limit
        />
      </el-form-item>

      <!-- 陪诊师信息 -->
      <el-divider>陪诊师信息</el-divider>
      
      <el-form-item label="陪诊师" prop="companionId">
        <el-select
          v-model="formData.companionId"
          placeholder="请选择陪诊师"
          filterable
          style="width: 100%"
          @change="handleCompanionChange"
        >
          <el-option
            v-for="companion in companionOptions"
            :key="companion.id"
            :label="companion.name"
            :value="companion.id"
          >
            <div class="companion-option">
              <span class="name">{{ companion.name }}</span>
              <span class="info">({{ companion.gender === 'male' ? '男' : '女' }}，{{ companion.age }}岁，评分{{ companion.rating }})</span>
            </div>
          </el-option>
        </el-select>
      </el-form-item>

      <el-form-item label="陪诊师姓名" prop="companionName">
        <el-input
          v-model="formData.companionName"
          placeholder="自动填充"
          disabled
        />
      </el-form-item>

      <el-form-item label="陪诊师电话" prop="companionPhone">
        <el-input
          v-model="formData.companionPhone"
          placeholder="自动填充"
          disabled
        />
      </el-form-item>

      <!-- 医院信息 -->
      <el-divider>医院信息</el-divider>
      
      <el-form-item label="医院" prop="hospitalId">
        <el-select
          v-model="formData.hospitalId"
          placeholder="请选择医院"
          filterable
          style="width: 100%"
          @change="handleHospitalChange"
        >
          <el-option
            v-for="hospital in hospitalOptions"
            :key="hospital.id"
            :label="hospital.name"
            :value="hospital.id"
          >
            <div class="hospital-option">
              <span class="name">{{ hospital.name }}</span>
              <span class="level">{{ hospital.level }}</span>
            </div>
          </el-option>
        </el-select>
      </el-form-item>

      <el-form-item label="医院名称" prop="hospitalName">
        <el-input
          v-model="formData.hospitalName"
          placeholder="自动填充"
          disabled
        />
      </el-form-item>

      <el-form-item label="医院地址" prop="hospitalAddress">
        <el-input
          v-model="formData.hospitalAddress"
          placeholder="自动填充"
          disabled
        />
      </el-form-item>

      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="科室" prop="department">
            <el-input
              v-model="formData.department"
              placeholder="请输入科室"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="医生" prop="doctorName">
            <el-input
              v-model="formData.doctorName"
              placeholder="请输入医生姓名"
              clearable
            />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 服务详情 -->
      <el-divider>服务详情</el-divider>
      
      <el-form-item label="服务项目" prop="serviceItems">
        <el-select
          v-model="formData.serviceItems"
          multiple
          placeholder="请选择服务项目"
          style="width: 100%"
        >
          <el-option
            v-for="item in serviceItemOptions"
            :key="item.value"
            :label="item.label"
            :value="item.value"
          />
        </el-select>
      </el-form-item>

      <el-form-item label="特殊要求" prop="specialRequirements">
        <el-input
          v-model="formData.specialRequirements"
          type="textarea"
          :rows="2"
          placeholder="请输入特殊要求"
          maxlength="200"
          show-word-limit
        />
      </el-form-item>

      <el-form-item label="订单备注" prop="notes">
        <el-input
          v-model="formData.notes"
          type="textarea"
          :rows="3"
          placeholder="请输入订单备注"
          maxlength="1000"
          show-word-limit
        />
      </el-form-item>

      <!-- 紧急联系人 -->
      <el-divider>紧急联系人</el-divider>
      
      <el-row :gutter="20">
        <el-col :span="12">
          <el-form-item label="联系人姓名" prop="emergencyContact">
            <el-input
              v-model="formData.emergencyContact"
              placeholder="请输入紧急联系人姓名"
              clearable
            />
          </el-form-item>
        </el-col>
        <el-col :span="12">
          <el-form-item label="联系电话" prop="emergencyPhone">
            <el-input
              v-model="formData.emergencyPhone"
              placeholder="请输入紧急联系电话"
              clearable
            />
          </el-form-item>
        </el-col>
      </el-row>

      <!-- 表单操作 -->
      <el-form-item>
        <div class="form-actions">
          <el-button @click="handleCancel">取消</el-button>
          <el-button type="primary" @click="handleSubmit" :loading="submitting">
            {{ isEdit ? '更新订单' : '创建订单' }}
          </el-button>
        </div>
      </el-form-item>
    </el-form>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted, computed } from 'vue'
import { ElMessage } from 'element-plus'

const props = defineProps({
  orderData: {
    type: Object,
    default: () => ({})
  },
  isEdit: {
    type: Boolean,
    default: false
  }
})

const emit = defineEmits(['success', 'cancel'])

// 表单引用
const formRef = ref()
const submitting = ref(false)

// 表单数据
const formData = reactive({
  // 基本信息
  serviceType: '',
  amount: 0,
  serviceHours: 2,
  appointmentTime: '',
  
  // 患者信息
  patientName: '',
  patientPhone: '',
  patientGender: 'unknown',
  patientAge: null,
  patientIdCard: '',
  healthCondition: '',
  
  // 陪诊师信息
  companionId: '',
  companionName: '',
  companionPhone: '',
  
  // 医院信息
  hospitalId: '',
  hospitalName: '',
  hospitalAddress: '',
  department: '',
  doctorName: '',
  
  // 服务详情
  serviceItems: [],
  specialRequirements: '',
  notes: '',
  
  // 紧急联系人
  emergencyContact: '',
  emergencyPhone: ''
})

// 表单验证规则
const formRules = {
  serviceType: [
    { required: true, message: '请选择服务类型', trigger: 'change' }
  ],
  amount: [
    { required: true, message: '请输入订单金额', trigger: 'blur' },
    { type: 'number', min: 0, message: '金额不能为负数', trigger: 'blur' }
  ],
  serviceHours: [
    { required: true, message: '请输入服务时长', trigger: 'blur' },
    { type: 'number', min: 1, message: '服务时长至少1小时', trigger: 'blur' }
  ],
  appointmentTime: [
    { required: true, message: '请选择预约时间', trigger: 'change' }
  ],
  patientName: [
    { required: true, message: '请输入患者姓名', trigger: 'blur' }
  ],
  patientPhone: [
    { required: true, message: '请输入手机号码', trigger: 'blur' },
    { pattern: /^1[3-9]\d{9}$/, message: '请输入正确的手机号码', trigger: 'blur' }
  ],
  companionId: [
    { required: true, message: '请选择陪诊师', trigger: 'change' }
  ],
  hospitalId: [
    { required: true, message: '请选择医院', trigger: 'change' }
  ]
}

// 选项数据
const serviceTypeOptions = [
  { value: 'consultation', label: '门诊陪诊' },
  { value: 'hospitalization', label: '住院陪护' },
  { value: 'examination', label: '检查陪同' },
  { value: 'surgery', label: '手术陪同' }
]

const serviceItemOptions = [
  { value: 'registration', label: '门诊挂号协助' },
  { value: 'accompany', label: '就诊陪同' },
  { value: 'medicine', label: '取药协助' },
  { value: 'interpretation', label: '检查结果解读' },
  { value: 'transportation', label: '院内转运' },
  { value: 'nursing', label: '基础护理' },
  { value: 'communication', label: '医患沟通协助' },
  { value: 'document', label: '病历资料整理' }
]

const companionOptions = ref([
  { id: '1', name: '王陪诊师', gender: 'female', age: 32, rating: 4.8, phone: '13900139001' },
  { id: '2', name: '李陪诊师', gender: 'male', age: 28, rating: 4.7, phone: '13900139002' },
  { id: '3', name: '张陪诊师', gender: 'female', age: 35, rating: 4.9, phone: '13900139003' },
  { id: '4', name: '刘陪诊师', gender: 'male', age: 30, rating: 4.6, phone: '13900139004' },
  { id: '5', name: '陈陪诊师', gender: 'female', age: 29, rating: 4.8, phone: '13900139005' }
])

const hospitalOptions = ref([
  { id: '1', name: '北京市第一人民医院', level: '三级甲等', address: '北京市东城区东单大华路1号' },
  { id: '2', name: '北京市协和医院', level: '三级甲等', address: '北京市东城区帅府园1号' },
  { id: '3', name: '北京大学人民医院', level: '三级甲等', address: '北京市西城区西直门南大街11号' },
  { id: '4', name: '北京天坛医院', level: '三级甲等', address: '北京市丰台区南四环西路119号' },
  { id: '5', name: '北京儿童医院', level: '三级甲等', address: '北京市西城区南礼士路56号' }
])

// 计算属性
const companionMap = computed(() => {
  const map = {}
  companionOptions.value.forEach(companion => {
    map[companion.id] = companion
  })
  return map
})

const hospitalMap = computed(() => {
  const map = {}
  hospitalOptions.value.forEach(hospital => {
    map[hospital.id] = hospital
  })
  return map
})

// 生命周期钩子
onMounted(() => {
  if (props.isEdit && props.orderData) {
    initFormData()
  } else {
    initDefaultData()
  }
})

// 初始化表单数据（编辑模式）
const initFormData = () => {
  Object.keys(formData).forEach(key => {
    if (props.orderData[key] !== undefined) {
      formData[key] = props.orderData[key]
    }
  })
  
  // 设置陪诊师和医院的ID
  if (props.orderData.companionName) {
    const companion = companionOptions.value.find(c => c.name === props.orderData.companionName)
    if (companion) {
      formData.companionId = companion.id
    }
  }
  
  if (props.orderData.hospitalName) {
    const hospital = hospitalOptions.value.find(h => h.name === props.orderData.hospitalName)
    if (hospital) {
      formData.hospitalId = hospital.id
    }
  }
}

// 初始化默认数据（创建模式）
const initDefaultData = () => {
  // 设置默认预约时间（明天上午9点）
  const tomorrow = new Date()
  tomorrow.setDate(tomorrow.getDate() + 1)
  tomorrow.setHours(9, 0, 0, 0)
  formData.appointmentTime = tomorrow.toISOString().replace('T', ' ').substring(0, 19)
  
  // 设置默认金额
  formData.amount = 199
}

// 事件处理
const handleCompanionChange = (companionId) => {
  const companion = companionMap.value[companionId]
  if (companion) {
    formData.companionName = companion.name
    formData.companionPhone = companion.phone
  }
}

const handleHospitalChange = (hospitalId) => {
  const hospital = hospitalMap.value[hospitalId]
  if (hospital) {
    formData.hospitalName = hospital.name
    formData.hospitalAddress = hospital.address
  }
}

const handleSubmit = async () => {
  if (!formRef.value) return
  
  try {
    // 验证表单
    await formRef.value.validate()
    
    submitting.value = true
    
    // 模拟API调用
    await new Promise(resolve => setTimeout(resolve, 1000))
    
    // 构建提交数据
    const submitData = {
      ...formData,
      // 添加额外的字段
      status: 'waiting_accept',
      createdAt: new Date().toISOString(),
      orderNo: props.isEdit ? props.orderData.orderNo : generateOrderNo()
    }
    
    ElMessage.success(props.isEdit ? '订单更新成功' : '订单创建成功')
    emit('success', submitData)
    
  } catch (error) {
    if (error instanceof Error) {
      ElMessage.error('表单验证失败：' + error.message)
    }
  } finally {
    submitting.value = false
  }
}

const handleCancel = () => {
  emit('cancel')
}

// 工具函数
const generateOrderNo = () => {
  const date = new Date()
  const year = date.getFullYear()
  const month = String(date.getMonth() + 1).padStart(2, '0')
  const day = String(date.getDate()).padStart(2, '0')
  const random = String(Math.floor(Math.random() * 10000)).padStart(4, '0')
  return `ORD${year}${month}${day}${random}`
}
</script>

<style scoped>
.order-edit-form {
  padding: 0;
}

.el-divider {
  margin: 24px 0;
}

.el-divider__text {
  font-size: 14px;
  font-weight: 600;
  color: #303133;
}

.companion-option,
.hospital-option {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.companion-option .name,
.hospital-option .name {
  font-weight: 500;
}

.companion-option .info,
.hospital-option .level {
  font-size: 12px;
  color: #909399;
}

.form-actions {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding-top: 20px;
  border-top: 1px solid #ebeef5;
}

:deep(.el-form-item) {
  margin-bottom: 20px;
}

:deep(.el-form-item__label) {
  font-weight: 500;
  color: #606266;
}

:deep(.el-input-number) {
  width: 100%;
}

:deep(.el-select) {
  width: 100%;
}

:deep(.el-textarea) {
  width: 100%;
}

@media (max-width: 768px) {
  :deep(.el-col) {
    width: 100%;
  }
  
  :deep(.el-form-item__label) {
    text-align: left;
  }
}
</style>