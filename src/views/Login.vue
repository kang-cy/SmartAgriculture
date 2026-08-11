<template>
  <div class="login-page">
    <!-- 左侧品牌区 -->
    <div class="login-brand">
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
        <p class="brand-slogan">实时监测 · 智能灌溉 · 精准管理</p>
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

    <!-- 右侧登录区 -->
    <div class="login-form-area">
      <div class="form-wrapper">
        <div class="form-header">
          <h2 class="form-title">欢迎登录</h2>
          <p class="form-desc">请选择身份并输入账号信息</p>
        </div>

        <!-- 角色切换 -->
        <div class="role-switcher">
          <div
            class="role-tab"
            :class="{ active: currentRole === 'farmer' }"
            @click="switchRole('farmer')"
          >
            <el-icon class="role-icon"><User /></el-icon>
            <span>农户登录</span>
          </div>
          <div
            class="role-tab"
            :class="{ active: currentRole === 'manager' }"
            @click="switchRole('manager')"
          >
            <el-icon class="role-icon"><OfficeBuilding /></el-icon>
            <span>管理者登录</span>
          </div>
        </div>

        <!-- 登录表单 -->
        <el-form
          ref="loginFormRef"
          :model="loginForm"
          :rules="loginRules"
          class="login-form"
          @keyup.enter="handleLogin"
        >
          <el-form-item prop="username">
            <el-input
              v-model="loginForm.username"
              :placeholder="currentRole === 'farmer' ? '请输入农户账号（仅限字母、数字、下划线）' : '请输入管理者账号（仅限字母、数字、下划线）'"
              size="large"
              :prefix-icon="User"
            />
          </el-form-item>
          <el-form-item prop="password">
            <el-input
              v-model="loginForm.password"
              type="password"
              placeholder="请输入密码"
              size="large"
              :prefix-icon="Lock"
              show-password
            />
          </el-form-item>

          <div class="form-options">
            <el-checkbox v-model="loginForm.remember">记住账号</el-checkbox>
            <el-link type="primary" :underline="false">忘记密码？</el-link>
          </div>

          <el-button
            type="primary"
            size="large"
            class="login-btn"
            :loading="loading"
            @click="handleLogin"
          >
            登 录
          </el-button>
        </el-form>

        <!-- 分割线 -->
        <div class="divider">
          <span>其他操作</span>
        </div>

        <!-- 注册入口 -->
        <div class="register-section">
          <span class="register-text">还没有账号？</span>
          <el-link type="primary" :underline="false" @click="goToRegister">立即注册</el-link>
        </div>

        <!-- 演示账号提示 -->
        <div class="demo-hint">
          <el-icon><InfoFilled /></el-icon>
          <span>演示模式：任意账号密码（≥3位）即可登录</span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive } from 'vue'
import { useRouter } from 'vue-router'
import { User, Lock, OfficeBuilding, InfoFilled } from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { useUserStore } from '@/store/user'
import { api } from '@/api'

const router = useRouter()
const userStore = useUserStore()

const currentRole = ref('farmer')
const loginFormRef = ref()
const loading = ref(false)

const loginForm = reactive({
  username: '',
  password: '',
  remember: false,
})

const loginRules = {
  username: [
    { required: true, message: '请输入账号', trigger: 'blur' },
    { pattern: /^[a-zA-Z0-9_]+$/, message: '账号只能包含字母、数字和下划线，不能使用中文', trigger: 'blur' },
  ],
  password: [
    { required: true, message: '请输入密码', trigger: 'blur' },
    { min: 3, message: '密码至少3位', trigger: 'blur' },
  ],
}

const features = [
  { text: '土壤湿度实时监测' },
  { text: '远程灌溉智能控制' },
  { text: '3D农场可视化' },
  { text: 'AI智能灌溉建议' },
]

function switchRole(role) {
  currentRole.value = role
  loginForm.username = ''
  loginForm.password = ''
}

async function handleLogin() {
  if (!loginFormRef.value) return
  try {
    await loginFormRef.value.validate()
  } catch {
    return
  }
  loading.value = true
  try {
    const res = await api.login({
      username: loginForm.username,
      password: loginForm.password,
      role: currentRole.value,
    })
    if (res.code === 200) {
      userStore.setUser(res.data)
      ElMessage.success('登录成功')
      router.push('/dashboard')
    } else {
      ElMessage.error(res.message || '登录失败')
    }
  } catch (err) {
    ElMessage.error('无法连接服务器，请确认后端已启动')
    console.error('登录请求失败:', err)
  } finally {
    loading.value = false
  }
}

function goToRegister() {
  router.push('/register')
}
</script>

<style scoped>
.login-page {
  display: flex;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
}

/* ===== 左侧品牌区 ===== */
.login-brand {
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
.login-form-area {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  background: #ffffff;
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
.login-form {
  margin-bottom: 24px;
}

.form-options {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

.login-btn {
  width: 100%;
  font-size: 16px;
  font-weight: 600;
  letter-spacing: 4px;
}

/* 分割线 */
.divider {
  display: flex;
  align-items: center;
  gap: 12px;
  margin: 24px 0;
  color: #d1d5db;
  font-size: 13px;
}

.divider::before,
.divider::after {
  content: '';
  flex: 1;
  height: 1px;
  background: #e5e7eb;
}

/* 注册入口 */
.register-section {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 4px;
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
  .login-brand {
    display: none;
  }
  .login-form-area {
    flex: 1;
  }
}
</style>
