<template>
  <div class="register-page">
    <!-- 左侧品牌区 -->
    <div class="register-brand">
      <div class="brand-content">
        <div class="brand-logo">
          <svg viewBox="0 0 48 48" fill="none" class="logo-icon">
            <circle cx="24" cy="24" r="23" stroke="rgba(255,255,255,0.2)" stroke-width="1"/>
            <path d="M24 8 C 15 8, 8 17, 8 27 L 24 40 L 40 27 C 40 17, 33 8, 24 8 Z" fill="rgba(34,197,94,0.3)"/>
            <path d="M24 14 L 24 34 M 18 20 L 24 14 L 30 20" stroke="#fff" stroke-width="2.5" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
            <circle cx="24" cy="24" r="2.5" fill="#4ade80"/>
          </svg>
        </div>
        <h1 class="brand-title">智慧农业<br/>管理平台</h1>
        <p class="brand-slogan">注册账号 · 开启智慧农业之旅</p>
        <div class="brand-features">
          <div class="feature-item" v-for="f in features" :key="f.text">
            <span class="feature-dot"></span>
            <span>{{ f.text }}</span>
          </div>
        </div>
      </div>
      <div class="brand-decoration">
        <div class="deco-circle deco-1"></div>
        <div class="deco-circle deco-2"></div>
        <div class="deco-circle deco-3"></div>
      </div>
    </div>

    <!-- 右侧注册区 -->
    <div class="register-form-area">
      <div class="form-wrapper">
        <div class="form-header">
          <h2 class="form-title">{{ isFarmOwnerMode ? '成为农场主' : '创建账号' }}</h2>
          <p class="form-desc">{{ isFarmOwnerMode ? '注册独立农场主账号，自主管理您的农田' : '请选择身份并填写注册信息' }}</p>
        </div>

        <!-- 角色切换（农场主模式下隐藏） -->
        <div v-if="!isFarmOwnerMode" class="role-switcher">
          <div
            class="role-tab"
            :class="{ active: currentRole === 'farmer' }"
            @click="switchRole('farmer')"
          >
            <el-icon class="role-icon"><User /></el-icon>
            <span>注册农户账户</span>
          </div>
          <div
            class="role-tab"
            :class="{ active: currentRole === 'manager' }"
            @click="switchRole('manager')"
          >
            <el-icon class="role-icon"><OfficeBuilding /></el-icon>
            <span>注册管理者账户</span>
          </div>
        </div>

        <!-- 农场主模式提示 -->
        <div v-if="isFarmOwnerMode" class="farm-owner-banner">
          <el-icon :size="20"><OfficeBuilding /></el-icon>
          <span>您正在注册为独立农场主，注册后将成为自己农场的管理员</span>
        </div>

        <!-- 注册表单 -->
        <el-form
          ref="registerFormRef"
          :model="registerForm"
          :rules="registerRules"
          class="register-form"
          @keyup.enter="handleRegister"
        >
          <el-form-item prop="username">
            <el-input
              v-model="registerForm.username"
              placeholder="请输入用户名（仅限字母、数字、下划线）"
              size="large"
              :prefix-icon="User"
            />
          </el-form-item>
          <el-form-item prop="password">
            <el-input
              v-model="registerForm.password"
              type="password"
              placeholder="请输入密码（至少6位）"
              size="large"
              :prefix-icon="Lock"
              show-password
            />
          </el-form-item>
          <el-form-item prop="confirmPassword">
            <el-input
              v-model="registerForm.confirmPassword"
              type="password"
              placeholder="请再次输入密码"
              size="large"
              :prefix-icon="Lock"
              show-password
            />
          </el-form-item>
          <el-form-item v-if="currentRole === 'manager'" prop="farmName">
            <el-input
              v-model="registerForm.farmName"
              placeholder="请输入农场名称"
              size="large"
              :prefix-icon="OfficeBuilding"
            />
          </el-form-item>

          <el-button
            type="primary"
            size="large"
            class="register-btn"
            :loading="loading"
            @click="handleRegister"
          >
            注 册
          </el-button>
        </el-form>

        <!-- 返回登录 / 返回上一页 -->
        <div class="back-login">
          <el-icon><ArrowLeft /></el-icon>
          <span>{{ isFarmOwnerMode ? '不想注册？' : '已有账号？' }}</span>
          <el-link type="primary" :underline="false" @click="goBack">{{ isFarmOwnerMode ? '返回' : '返回登录' }}</el-link>
        </div>

        <!-- 演示提示 -->
        <div class="demo-hint">
          <el-icon><InfoFilled /></el-icon>
          <span>演示模式：注册即自动登录</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { User, Lock, OfficeBuilding, ArrowLeft, InfoFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/store/user'
import { api } from '@/api'

const router = useRouter()
const route = useRoute()
const userStore = useUserStore()

// 农场主注册模式：从农户绑定管理页面跳转过来
const isFarmOwnerMode = computed(() => route.query.mode === 'farm_owner')
const currentRole = ref(isFarmOwnerMode.value ? 'manager' : 'farmer')
const registerFormRef = ref()
const loading = ref(false)

const registerForm = reactive({
  username: '',
  password: '',
  confirmPassword: '',
  farmName: '',
})

const validateConfirmPassword = (rule, value, callback) => {
  if (!value) {
    callback(new Error('请再次输入密码'))
  } else if (value !== registerForm.password) {
    callback(new Error('两次输入的密码不一致'))
  } else {
    callback()
  }
}

const registerRules = {
  username: [
    { required: true, message: '请输入用户名', trigger: 'blur' },
    { min: 2, message: '用户名至少2个字符', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_]+$/, message: '用户名只能包含字母、数字和下划线，不能使用中文', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 6, message: '密码至少6位', trigger: 'blur' },
  ],
  confirmPassword: [
    { required: true, message: '请再次输入密码', trigger: 'blur' },
    { validator: validateConfirmPassword, trigger: 'blur' },
  ],
  farmName: [
    {
      required: true,
      message: '请输入农场名称',
      trigger: 'blur',
      validator: (rule, value, callback) => {
        if (currentRole.value === 'manager' && !value) {
          callback(new Error('请输入农场名称'))
        } else {
          callback()
        }
      },
    },
  ],
}

// 密码改变时，若已填写确认密码则重新校验一致性
watch(() => registerForm.password, () => {
  if (registerForm.confirmPassword) {
    registerFormRef.value?.validateField('confirmPassword')
  }
})

const features = [
  { text: '土壤湿度实时监测' },
  { text: '远程灌溉智能控制' },
  { text: '3D农场可视化' },
  { text: 'AI智能灌溉建议' },
]

function switchRole(role) {
  if (isFarmOwnerMode.value) return
  currentRole.value = role
}

async function handleRegister() {
  if (!registerFormRef.value) return
  try {
    await registerFormRef.value.validate()
  } catch {
    return
  }
  loading.value = true
  try {
    const res = await api.register({
      username: registerForm.username,
      password: registerForm.password,
      role: currentRole.value,
      farmName: currentRole.value === 'manager' ? registerForm.farmName : '',
    })
    if (res.code === 200) {
      userStore.setUser(res.data)
      ElMessage.success(isFarmOwnerMode.value ? '农场主注册成功，欢迎管理您的农场' : (res.message || '注册成功'))
      router.push('/dashboard')
    } else {
      ElMessage.error(res.message || '注册失败')
    }
  } catch (err) {
    ElMessage.error('无法连接服务器，请确认后端已启动')
    console.error('注册请求失败:', err)
  } finally {
    loading.value = false
  }
}

function goBack() {
  if (isFarmOwnerMode.value) {
    router.back()
  } else {
    router.push('/login')
  }
}
</script>

<style scoped>
.register-page {
  display: flex;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
}

/* ===== 左侧品牌区 ===== */
.register-brand {
  flex: 1.2;
  position: relative;
  background: linear-gradient(135deg, #0a3d2c 0%, #14532d 40%, #166534 100%);
  display: flex;
  align-items: center;
  justify-content: center;
  overflow: hidden;
}

.brand-content {
  position: relative;
  z-index: 2;
  padding: 60px;
  max-width: 500px;
}

.brand-logo {
  margin-bottom: 32px;
}

.logo-icon {
  width: 56px;
  height: 56px;
}

.brand-title {
  font-size: 42px;
  font-weight: 700;
  color: #ffffff;
  line-height: 1.3;
  margin-bottom: 16px;
  letter-spacing: 2px;
}

.brand-slogan {
  font-size: 16px;
  color: rgba(255, 255, 255, 0.7);
  margin-bottom: 48px;
  letter-spacing: 1px;
}

.brand-features {
  display: flex;
  flex-direction: column;
  gap: 18px;
}

.feature-item {
  display: flex;
  align-items: center;
  gap: 12px;
  color: rgba(255, 255, 255, 0.85);
  font-size: 15px;
}

.feature-dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: #4ade80;
  box-shadow: 0 0 12px rgba(74, 222, 128, 0.6);
}

/* 装饰圆 */
.brand-decoration {
  position: absolute;
  inset: 0;
  pointer-events: none;
}

.deco-circle {
  position: absolute;
  border-radius: 50%;
  border: 1px solid rgba(74, 222, 128, 0.1);
}

.deco-1 {
  width: 600px;
  height: 600px;
  top: -200px;
  right: -200px;
}

.deco-2 {
  width: 400px;
  height: 400px;
  bottom: -100px;
  left: -100px;
  border-color: rgba(74, 222, 128, 0.08);
}

.deco-3 {
  width: 200px;
  height: 200px;
  bottom: 20%;
  right: 15%;
  border-color: rgba(74, 222, 128, 0.05);
}

/* ===== 右侧表单区 ===== */
.register-form-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
  overflow-y: auto;
}

.form-wrapper {
  width: 380px;
  padding: 40px 0;
}

.form-header {
  margin-bottom: 32px;
}

.form-title {
  font-size: 26px;
  font-weight: 700;
  color: #1f2937;
  margin-bottom: 8px;
}

.form-desc {
  font-size: 14px;
  color: #9ca3af;
}

/* 角色切换 */
.role-switcher {
  display: flex;
  gap: 8px;
  background: #f3f4f6;
  border-radius: 10px;
  padding: 4px;
  margin-bottom: 28px;
}

/* 农场主模式提示 */
.farm-owner-banner {
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 14px 16px;
  background: #f0fdf4;
  border: 1px solid #bbf7d0;
  border-radius: 10px;
  margin-bottom: 28px;
  font-size: 13px;
  color: #15803d;
  line-height: 1.5;
}

.role-tab {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 8px;
  padding: 10px;
  border-radius: 8px;
  font-size: 14px;
  font-weight: 500;
  color: #6b7280;
  cursor: pointer;
  transition: all 0.25s ease;
}

.role-tab:hover {
  color: #374151;
}

.role-tab.active {
  background: #ffffff;
  color: #16a34a;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.role-icon {
  font-size: 16px;
}

/* 表单 */
.register-form {
  margin-bottom: 20px;
}

.register-btn {
  width: 100%;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 4px;
}

/* 返回登录 */
.back-login {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
  margin-top: 20px;
  font-size: 14px;
  color: #6b7280;
}

/* 演示提示 */
.demo-hint {
  margin-top: 28px;
  display: flex;
  align-items: center;
  gap: 6px;
  padding: 10px 14px;
  background: #f0fdf4;
  border-radius: 8px;
  font-size: 12px;
  color: #15803d;
}

/* 响应式 */
@media (max-width: 900px) {
  .register-brand {
    display: none;
  }
  .register-form-area {
    flex: 1;
  }
}
</style>
