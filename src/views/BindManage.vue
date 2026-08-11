<template>
  <div class="page-container">
    <h1 class="page-title">绑定管理</h1>
    <p class="page-subtitle">绑定农场管理者后，即可查看农田数据并进行智能管理</p>

    <!-- 当前绑定状态卡片 -->
    <div class="status-card-wrap" v-loading="pageLoading">
      <!-- 未绑定 -->
      <div v-if="!myRequest" class="status-card empty-card">
        <div class="empty-illustration">
          <el-icon :size="56"><Link /></el-icon>
        </div>
        <h2 class="empty-title">您还未绑定管理者</h2>
        <p class="empty-desc">绑定农场管理者后，即可查看农田数据并进行智能管理</p>
        <el-button type="primary" size="large" :icon="Link" @click="openForm">
          立即绑定
        </el-button>
      </div>

      <!-- 申请审批中 -->
      <div v-else-if="myRequest.status === 'pending'" class="status-card pending-card">
        <div class="status-card-header">
          <div class="status-icon-wrap pending">
            <el-icon :size="34"><Clock /></el-icon>
          </div>
          <div class="status-title-area">
            <h2 class="status-card-title">申请审批中</h2>
            <p class="status-card-desc">您的绑定申请已提交，请耐心等待管理者审批</p>
          </div>
          <el-tag type="warning" effect="dark" size="large">待审批</el-tag>
        </div>
        <div class="status-detail-grid">
          <div class="detail-item">
            <span class="detail-label">绑定码</span>
            <span class="detail-value code">{{ myRequest.bindCode }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">申请时间</span>
            <span class="detail-value">{{ myRequest.requestTime }}</span>
          </div>
        </div>
      </div>

      <!-- 绑定成功 -->
      <div v-else-if="myRequest.status === 'approved'" class="status-card approved-card">
        <div class="status-card-header">
          <div class="status-icon-wrap success">
            <el-icon :size="34"><CircleCheckFilled /></el-icon>
          </div>
          <div class="status-title-area">
            <h2 class="status-card-title">绑定成功</h2>
            <p class="status-card-desc">您已成功绑定农场管理者，现在可以查看农田数据</p>
          </div>
          <el-tag type="success" effect="dark" size="large">已绑定</el-tag>
        </div>
        <div class="status-detail-grid">
          <div class="detail-item">
            <span class="detail-label">绑定码</span>
            <span class="detail-value code">{{ myRequest.bindCode }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">审批时间</span>
            <span class="detail-value">{{ myRequest.resolveTime }}</span>
          </div>
        </div>
      </div>

      <!-- 申请被驳回 -->
      <div v-else-if="myRequest.status === 'rejected'" class="status-card rejected-card">
        <div class="status-card-header">
          <div class="status-icon-wrap danger">
            <el-icon :size="34"><CircleCloseFilled /></el-icon>
          </div>
          <div class="status-title-area">
            <h2 class="status-card-title">申请被驳回</h2>
            <p class="status-card-desc">您的绑定申请未通过审批，请重新获取绑定码后再次申请</p>
          </div>
          <el-tag type="danger" effect="dark" size="large">已驳回</el-tag>
        </div>
        <div class="status-detail-grid">
          <div class="detail-item">
            <span class="detail-label">绑定码</span>
            <span class="detail-value code">{{ myRequest.bindCode }}</span>
          </div>
          <div class="detail-item">
            <span class="detail-label">驳回时间</span>
            <span class="detail-value">{{ myRequest.resolveTime }}</span>
          </div>
          <div class="detail-item full" v-if="myRequest.remark">
            <span class="detail-label">驳回原因</span>
            <span class="detail-value remark">{{ myRequest.remark }}</span>
          </div>
        </div>
        <div class="status-card-footer">
          <el-button type="primary" :icon="RefreshRight" @click="openForm">
            重新申请
          </el-button>
        </div>
      </div>
    </div>

    <!-- 绑定表单 -->
    <transition name="form-slide">
      <div v-if="showForm" class="form-section">
        <div class="form-card">
          <div class="form-card-header">
            <el-icon :size="20"><Link /></el-icon>
            <h3 class="form-card-title">
              {{ myRequest?.status === 'rejected' ? '重新提交绑定申请' : '提交绑定申请' }}
            </h3>
          </div>
          <el-form
            ref="bindFormRef"
            :model="bindForm"
            :rules="bindRules"
            label-width="100px"
            class="bind-form"
          >
            <el-form-item label="绑定码" prop="bindCode">
              <el-input
                v-model="bindForm.bindCode"
                placeholder="请输入管理者提供的绑定码"
                size="large"
                clearable
              />
            </el-form-item>
            <el-form-item label="确认绑定码" prop="confirmCode">
              <el-input
                v-model="bindForm.confirmCode"
                placeholder="请再次输入绑定码"
                size="large"
                clearable
              />
            </el-form-item>
            <el-form-item>
              <el-button
                type="primary"
                size="large"
                :loading="bindLoading"
                @click="handleSubmit"
              >
                提交申请
              </el-button>
              <el-button size="large" @click="closeForm">取消</el-button>
            </el-form-item>
          </el-form>
        </div>
      </div>
    </transition>

    <!-- 绑定流程说明 -->
    <div class="instructions-section">
      <div class="instructions-card">
        <div class="instructions-header">
          <el-icon :size="20"><InfoFilled /></el-icon>
          <h3 class="instructions-title">绑定流程说明</h3>
        </div>
        <div class="instructions-list">
          <div class="instruction-item">
            <div class="step-num">1</div>
            <p class="step-text">联系您的农场管理者获取绑定码</p>
          </div>
          <div class="instruction-item">
            <div class="step-num">2</div>
            <p class="step-text">在上方输入绑定码并提交申请</p>
          </div>
          <div class="instruction-item">
            <div class="step-num">3</div>
            <p class="step-text">等待管理者审批通过</p>
          </div>
          <div class="instruction-item">
            <div class="step-num">4</div>
            <p class="step-text">审批通过后即可查看农田数据</p>
          </div>
        </div>
      </div>
    </div>

    <!-- 更多选项：成为管理者 / 管理自己的农场 -->
    <div class="options-section">
      <div class="options-header">
        <el-icon :size="20"><MoreFilled /></el-icon>
        <h3 class="options-title">更多选项</h3>
      </div>
      <div class="options-grid">
        <!-- 选项1：成为管理者 -->
        <div class="option-card" :class="{ disabled: managerApp && managerApp.type === 'manager' && managerApp.status === 'approved' }">
          <div class="option-icon-wrap manager-icon">
            <el-icon :size="26"><UserFilled /></el-icon>
          </div>
          <div class="option-content">
            <h4 class="option-title">成为管理者</h4>
            <p class="option-desc">拥有多个农田，管理其他农户的数据与设备</p>
          </div>
          <!-- 未申请 -->
          <div v-if="!managerApp || managerApp.type !== 'manager'" class="option-action">
            <el-button
              type="primary"
              :icon="Promotion"
              @click="openManagerForm"
            >
              申请
            </el-button>
          </div>
          <!-- 申请审批中 -->
          <div v-else-if="managerApp.status === 'pending'" class="option-status">
            <el-tag type="warning" effect="dark">审核中</el-tag>
            <el-button text type="info" :icon="RefreshRight" @click="openManagerForm">修改</el-button>
          </div>
          <!-- 申请通过 -->
          <div v-else-if="managerApp.status === 'approved'" class="option-status">
            <el-tag type="success" effect="dark">已通过</el-tag>
          </div>
          <!-- 申请被驳回 -->
          <div v-else-if="managerApp.status === 'rejected'" class="option-status">
            <el-tag type="danger" effect="dark">已驳回</el-tag>
            <el-button text type="primary" :icon="RefreshRight" @click="openManagerForm">重新申请</el-button>
          </div>
        </div>

        <!-- 选项2：管理自己的农场（注册模式，跳转注册页面成为独立农场主） -->
        <div class="option-card" :class="{ disabled: managerApp && managerApp.type === 'manager' && managerApp.status === 'pending' }">
          <div class="option-icon-wrap farm-icon">
            <el-icon :size="26"><House /></el-icon>
          </div>
          <div class="option-content">
            <h4 class="option-title">管理自己的农场</h4>
            <p class="option-desc">注册成为独立农场主，自主管理自己的农田数据与设备</p>
          </div>
          <div class="option-action">
            <el-button
              type="success"
              :icon="Check"
              :disabled="managerApp && managerApp.type === 'manager' && managerApp.status === 'pending'"
              @click="goToFarmOwnerRegister"
            >
              去注册
            </el-button>
          </div>
        </div>
      </div>

      <!-- 管理员申请详情（审批中/驳回时显示） -->
      <div v-if="managerApp && managerApp.type === 'manager' && (managerApp.status === 'pending' || managerApp.status === 'rejected')" class="manager-app-detail">
        <div class="manager-app-row">
          <span class="manager-app-label">申请时间</span>
          <span class="manager-app-value">{{ managerApp.requestTime }}</span>
        </div>
        <div class="manager-app-row" v-if="managerApp.reason">
          <span class="manager-app-label">申请理由</span>
          <span class="manager-app-value">{{ managerApp.reason }}</span>
        </div>
        <div class="manager-app-row" v-if="managerApp.remark">
          <span class="manager-app-label">驳回原因</span>
          <span class="manager-app-value danger">{{ managerApp.remark }}</span>
        </div>
      </div>

      <!-- 自管理模式提示 -->
      <div v-if="managerApp && managerApp.type === 'manager' && managerApp.status === 'approved'" class="self-managed-hint">
        <el-icon><InfoFilled /></el-icon>
        <span>您已成为管理者，可前往管理端查看农场数据</span>
      </div>
    </div>

    <!-- 申请管理员表单 -->
    <transition name="form-slide">
      <div v-if="showManagerForm" class="form-section">
        <div class="form-card">
          <div class="form-card-header">
            <el-icon :size="20"><Promotion /></el-icon>
            <h3 class="form-card-title">
              {{ managerApp?.status === 'rejected' ? '重新提交管理员申请' : '申请成为管理员' }}
            </h3>
          </div>
          <el-form
            ref="managerFormRef"
            :model="managerForm"
            :rules="managerRules"
            label-width="100px"
            class="bind-form"
          >
            <el-form-item label="申请理由" prop="reason">
              <el-input
                v-model="managerForm.reason"
                type="textarea"
                :rows="4"
                placeholder="请简要说明您申请成为管理员的理由，例如：拥有农田规模、管理经验等"
                size="large"
              />
            </el-form-item>
            <el-form-item>
              <el-button
                type="primary"
                size="large"
                :loading="managerAppLoading"
                @click="handleApplyManager"
              >
                提交申请
              </el-button>
              <el-button size="large" @click="closeManagerForm">取消</el-button>
            </el-form-item>
          </el-form>
        </div>
      </div>
    </transition>
  </div>
</template>

<script setup>
import { ref, reactive, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import {
  Clock, CircleCheckFilled, CircleCloseFilled, Link, InfoFilled, RefreshRight,
  Promotion, UserFilled, MoreFilled, House, Check,
} from '@element-plus/icons-vue'
import { ElMessage } from 'element-plus'
import { api } from '@/api'
import { useUserStore } from '@/store/user'

const router = useRouter()
const userStore = useUserStore()

const pageLoading = ref(false)
const myRequest = ref(null)
const showForm = ref(false)
const bindLoading = ref(false)
const bindFormRef = ref()

// ===== 申请成为管理员 / 管理自己的农场 =====
const managerApp = ref(null)
const showManagerForm = ref(false)
const managerAppLoading = ref(false)
const managerFormRef = ref()
const managerForm = reactive({
  reason: '',
})
const managerRules = {
  reason: [
    { required: true, message: '请填写申请理由', trigger: 'blur' },
    { min: 5, message: '申请理由至少5个字符', trigger: 'blur' },
  ],
}

const bindForm = reactive({
  bindCode: '',
  confirmCode: '',
})

const bindRules = {
  bindCode: [
    { required: true, message: '请输入绑定码', trigger: 'blur' },
    { min: 4, message: '绑定码至少4位字符', trigger: 'blur' },
  ],
  confirmCode: [
    { required: true, message: '请再次输入绑定码', trigger: 'blur' },
    {
      validator: (rule, value, callback) => {
        if (value !== bindForm.bindCode) {
          callback(new Error('两次输入的绑定码不一致'))
        } else {
          callback()
        }
      },
      trigger: 'blur',
    },
  ],
}

function openForm() {
  bindForm.bindCode = ''
  bindForm.confirmCode = ''
  showForm.value = true
}

function closeForm() {
  showForm.value = false
  bindFormRef.value?.resetFields()
}

async function handleSubmit() {
  if (!bindFormRef.value) return
  await bindFormRef.value.validate(async (valid) => {
    if (!valid) return
    bindLoading.value = true
    try {
      const res = await api.submitBindRequest(bindForm.bindCode, userStore.username)
      if (res.code === 200) {
        myRequest.value = res.data
        showForm.value = false
        ElMessage.success('申请已提交，请等待管理者审批')
      }
    } catch {
      // 静默处理，不弹toast
    } finally {
      bindLoading.value = false
    }
  })
}

async function loadMyRequest() {
  pageLoading.value = true
  try {
    const res = await api.getMyBindRequest()
    if (res.code === 200) {
      myRequest.value = res.data
    }
  } catch {
    // 静默处理，页面显示空数据
    myRequest.value = null
  } finally {
    pageLoading.value = false
  }
}

// ===== 申请成为管理员 =====
function openManagerForm() {
  managerForm.reason = ''
  showManagerForm.value = true
}

function closeManagerForm() {
  showManagerForm.value = false
  managerFormRef.value?.resetFields()
}

async function handleApplyManager() {
  if (!managerFormRef.value) return
  await managerFormRef.value.validate(async (valid) => {
    if (!valid) return
    managerAppLoading.value = true
    try {
      const res = await api.applyManager({
        farmerName: userStore.username,
        reason: managerForm.reason,
      })
      if (res.code === 200) {
        managerApp.value = res.data
        showManagerForm.value = false
        ElMessage.success('管理员申请已提交，请等待系统审核')
      }
    } catch {
      // 静默处理，不弹toast
    } finally {
      managerAppLoading.value = false
    }
  })
}

async function loadManagerApp() {
  try {
    const res = await api.getMyManagerApplication()
    if (res.code === 200) {
      managerApp.value = res.data
    }
  } catch {
    // 静默处理
  }
}

// 跳转到注册页面，注册成为独立农场主
function goToFarmOwnerRegister() {
  router.push({ path: '/register', query: { mode: 'farm_owner' } })
}

onMounted(() => {
  loadMyRequest()
  loadManagerApp()
})
</script>

<style scoped>
/* ===== 状态卡片区域 ===== */
.status-card-wrap {
  margin-bottom: 24px;
}

.status-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

/* 未绑定空状态 */
.empty-card {
  display: flex;
  flex-direction: column;
  align-items: center;
  text-align: center;
  padding: 56px 32px;
}

.empty-illustration {
  width: 96px;
  height: 96px;
  border-radius: 50%;
  background: var(--primary-bg);
  color: var(--primary);
  display: flex;
  align-items: center;
  justify-content: center;
  margin-bottom: 24px;
}

.empty-title {
  font-size: 20px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 8px;
}

.empty-desc {
  font-size: 14px;
  color: var(--text-secondary);
  margin-bottom: 28px;
  max-width: 380px;
  line-height: 1.6;
}

/* 状态主题卡片 */
.pending-card {
  border-left: 4px solid var(--warning);
}

.approved-card {
  border-left: 4px solid var(--success);
}

.rejected-card {
  border-left: 4px solid var(--danger);
}

.status-card-header {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 24px 28px 16px;
}

.status-icon-wrap {
  width: 60px;
  height: 60px;
  border-radius: 14px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.status-icon-wrap.pending {
  background: #fef3c7;
  color: var(--warning);
  animation: pulse-soft 2s ease-in-out infinite;
}

.status-icon-wrap.success {
  background: #dcfce7;
  color: var(--success);
}

.status-icon-wrap.danger {
  background: #fee2e2;
  color: var(--danger);
}

@keyframes pulse-soft {
  0%, 100% { transform: scale(1); }
  50% { transform: scale(1.06); }
}

.status-title-area {
  flex: 1;
  min-width: 0;
}

.status-card-title {
  font-size: 20px;
  font-weight: 700;
  color: var(--text-primary);
  margin-bottom: 4px;
}

.status-card-desc {
  font-size: 13px;
  color: var(--text-secondary);
  line-height: 1.5;
}

.status-detail-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(200px, 1fr));
  gap: 8px 32px;
  padding: 0 28px 24px;
}

.detail-item {
  display: flex;
  flex-direction: column;
  gap: 4px;
}

.detail-item.full {
  grid-column: 1 / -1;
}

.detail-label {
  font-size: 12px;
  color: var(--text-tertiary);
}

.detail-value {
  font-size: 14px;
  color: var(--text-primary);
  font-weight: 500;
}

.detail-value.code {
  font-family: 'Courier New', monospace;
  font-weight: 700;
  letter-spacing: 1px;
  color: var(--primary-dark);
}

.detail-value.remark {
  color: var(--danger);
}

.status-card-footer {
  padding: 0 28px 24px;
}

/* ===== 绑定表单 ===== */
.form-section {
  margin-bottom: 24px;
}

.form-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

.form-card-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 18px 24px;
  border-bottom: 1px solid var(--border-color);
  color: var(--primary);
}

.form-card-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
}

.bind-form {
  padding: 24px;
}

.bind-form .el-button + .el-button {
  margin-left: 12px;
}

/* 表单展开/收起动画 */
.form-slide-enter-active,
.form-slide-leave-active {
  transition: all 0.3s ease;
  overflow: hidden;
}

.form-slide-enter-from,
.form-slide-leave-to {
  opacity: 0;
  transform: translateY(-12px);
  max-height: 0;
}

.form-slide-enter-to,
.form-slide-leave-from {
  opacity: 1;
  max-height: 600px;
}

/* ===== 流程说明 ===== */
.instructions-card {
  background: var(--primary-bg);
  border: 1px solid #bbf7d0;
  border-radius: var(--border-radius);
  padding: 20px 24px;
}

.instructions-header {
  display: flex;
  align-items: center;
  gap: 8px;
  margin-bottom: 16px;
  color: var(--primary-dark);
}

.instructions-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--primary-dark);
}

.instructions-list {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
  gap: 12px;
}

.instruction-item {
  display: flex;
  align-items: center;
  gap: 12px;
  background: var(--bg-card);
  border-radius: 8px;
  padding: 12px 16px;
}

.step-num {
  width: 28px;
  height: 28px;
  border-radius: 50%;
  background: var(--primary);
  color: #fff;
  font-size: 14px;
  font-weight: 700;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.step-text {
  font-size: 13px;
  color: var(--text-primary);
  line-height: 1.5;
}

/* ===== 响应式 ===== */
@media (max-width: 768px) {
  .status-card-header {
    flex-wrap: wrap;
    padding: 20px;
  }

  .status-detail-grid {
    padding: 0 20px 20px;
  }

  .status-card-footer {
    padding: 0 20px 20px;
  }

  .bind-form {
    padding: 20px;
  }

  .instructions-list {
    grid-template-columns: 1fr;
  }
}

/* ===== 更多选项 ===== */
.options-section {
  margin-bottom: 24px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  overflow: hidden;
}

.options-header {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 18px 24px;
  border-bottom: 1px solid var(--border-color);
  color: var(--primary);
}

.options-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.options-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(320px, 1fr));
  gap: 16px;
  padding: 20px 24px;
}

.option-card {
  display: flex;
  align-items: center;
  gap: 14px;
  padding: 18px;
  border: 1px solid var(--border-color);
  border-radius: 10px;
  background: var(--bg-page, #f9fafb);
  transition: all 0.2s ease;
}

.option-card:hover {
  border-color: var(--primary);
  box-shadow: 0 2px 8px rgba(0, 0, 0, 0.06);
}

.option-card.disabled {
  opacity: 0.5;
  pointer-events: none;
}

.option-icon-wrap {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.manager-icon {
  background: #eff6ff;
  color: #2563eb;
}

.farm-icon {
  background: #f0fdf4;
  color: #16a34a;
}

.option-content {
  flex: 1;
  min-width: 0;
}

.option-title {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 4px;
}

.option-desc {
  font-size: 12px;
  color: var(--text-secondary);
  line-height: 1.4;
}

.option-action {
  flex-shrink: 0;
}

.option-status {
  display: flex;
  flex-direction: column;
  align-items: flex-end;
  gap: 6px;
  flex-shrink: 0;
}

.manager-app-detail {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 16px 24px 20px;
  background: var(--bg-page, #f9fafb);
  border-top: 1px solid var(--border-color);
}

.manager-app-row {
  display: flex;
  gap: 12px;
  font-size: 13px;
}

.manager-app-label {
  color: var(--text-tertiary);
  min-width: 70px;
  flex-shrink: 0;
}

.manager-app-value {
  color: var(--text-primary);
  flex: 1;
}

.manager-app-value.danger {
  color: var(--danger);
}

.self-managed-hint {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 12px 24px;
  background: #f0fdf4;
  border-top: 1px solid #bbf7d0;
  font-size: 13px;
  color: #15803d;
}
</style>
