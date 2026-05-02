<template>
  <div class="login-container">
    <div class="login-card">
      <div class="login-header">
        <div class="login-logo">
          <span class="logo-icon">🏥</span>
          <h1>医小伴管理后台</h1>
        </div>
        <p class="login-desc">请使用管理员账号登录</p>
      </div>

      <el-form ref="formRef" :model="form" :rules="rules" @keyup.enter="handleLogin">
        <el-form-item prop="phone">
          <el-input
            v-model="form.phone"
            placeholder="管理员手机号"
            :prefix-icon="Iphone"
            size="large"
          />
        </el-form-item>
        <el-form-item prop="password">
          <el-input
            v-model="form.password"
            type="password"
            placeholder="密码"
            :prefix-icon="ILock"
            size="large"
            show-password
          />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" :loading="loading" @click="handleLogin" class="login-btn" size="large">
            {{ loading ? '登录中...' : '登 录' }}
          </el-button>
        </el-form-item>
      </el-form>

      <div class="login-footer">
        <p v-if="errorMsg" class="error-msg">{{ errorMsg }}</p>
        <el-button text type="primary" size="small" @click="showHint">
          测试账号
        </el-button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { ElMessage } from 'element-plus'
import { Iphone, Lock as ILock } from '@element-plus/icons-vue'
import api from '../api/index.js'

const router = useRouter()
const formRef = ref(null)
const loading = ref(false)
const errorMsg = ref('')

const form = reactive({
  phone: '',
  password: ''
})

const rules = {
  phone: [{ required: true, message: '请输入手机号', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

async function handleLogin() {
  errorMsg.value = ''
  const valid = await formRef.value?.validate().catch(() => false)
  if (!valid) return

  loading.value = true
  const res = await api.login(form.phone, form.password)
  loading.value = false

  if (res.success) {
    const token = res.data?.token
    const user = res.data?.user || {}
    
    if (user.role !== 'admin') {
      errorMsg.value = '此账号非管理员，无权限访问'
      return
    }

    // 存储 token
    localStorage.setItem('admin_token', token)
    
    ElMessage.success('登录成功')
    router.push('/')
  } else {
    errorMsg.value = res.message || '登录失败，请检查账号密码'
  }
}

function showHint() {
  ElMessage.info('管理员账号: 13800000000 / 请咨询开发人员获取密码')
}
</script>

<style scoped>
.login-container {
  display: flex;
  justify-content: center;
  align-items: center;
  min-height: 100vh;
  background: linear-gradient(135deg, #1a73e8 0%, #4285f4 50%, #34a853 100%);
}

.login-card {
  width: 420px;
  padding: 40px;
  background: #fff;
  border-radius: 16px;
  box-shadow: 0 20px 60px rgba(0,0,0,0.15);
}

.login-header {
  text-align: center;
  margin-bottom: 32px;
}

.logo-icon {
  font-size: 48px;
}

.login-logo h1 {
  margin: 12px 0 0;
  font-size: 24px;
  color: #1a73e8;
}

.login-desc {
  color: #999;
  font-size: 14px;
  margin-top: 8px;
}

.login-btn {
  width: 100%;
  margin-top: 8px;
}

.login-footer {
  text-align: center;
  margin-top: 16px;
}

.error-msg {
  color: #f56c6c;
  font-size: 13px;
  margin: 0 0 8px;
}
</style>
