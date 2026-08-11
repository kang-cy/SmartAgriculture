<template>
  <div class="page-container">
    <h1 class="page-title">绑定审批</h1>
    <p class="page-subtitle">管理农户绑定申请、管理者申请，以及撤销管理者身份</p>

    <!-- 绑定码生成 -->
    <div class="bind-code-card">
      <div class="bind-code-header">
        <div class="bind-code-title-area">
          <div class="bind-code-title-icon">
            <el-icon :size="22"><Link /></el-icon>
          </div>
          <div>
            <h3 class="bind-code-title">绑定码生成</h3>
            <p class="bind-code-desc">生成绑定码分享给农户，农户提交申请后在此页面审批</p>
          </div>
        </div>
      </div>
      <div class="bind-code-body">
        <div class="code-display-box">
          <span class="code-display-text">{{ managerBindCode }}</span>
        </div>
        <div class="bind-code-actions">
          <el-button type="primary" :icon="CopyDocument" @click="copyCode">复制</el-button>
          <el-button :icon="Refresh" @click="generateBindCode">重新生成</el-button>
        </div>
      </div>
    </div>

    <!-- Tab 切换 -->
    <el-tabs v-model="activeTab" class="approval-tabs">
      <!-- ===== Tab 1: 绑定审批 ===== -->
      <el-tab-pane label="绑定审批" name="bind">
        <template #label>
          <div class="tab-label">
            <el-icon><Link /></el-icon>
            <span>绑定审批</span>
            <el-badge v-if="bindStats.pending > 0" :value="bindStats.pending" type="warning" />
          </div>
        </template>

        <!-- 统计卡片 -->
        <div class="stats-row">
          <div class="stat-card">
            <div class="stat-icon pending-icon"><el-icon :size="22"><Clock /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ bindStats.pending }}</div><div class="stat-label">待审批</div></div>
          </div>
          <div class="stat-card">
            <div class="stat-icon approved-icon"><el-icon :size="22"><CircleCheckFilled /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ bindStats.approved }}</div><div class="stat-label">已通过</div></div>
          </div>
          <div class="stat-card">
            <div class="stat-icon rejected-icon"><el-icon :size="22"><CircleCloseFilled /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ bindStats.rejected }}</div><div class="stat-label">已驳回</div></div>
          </div>
          <div class="stat-card">
            <div class="stat-icon total-icon"><el-icon :size="22"><Document /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ bindStats.total }}</div><div class="stat-label">申请总数</div></div>
          </div>
        </div>

        <!-- 筛选栏 -->
        <div class="filter-bar">
          <el-radio-group v-model="filterStatus" @change="onFilterChange">
            <el-radio-button value="">全部</el-radio-button>
            <el-radio-button value="pending">待审批</el-radio-button>
            <el-radio-button value="approved">已通过</el-radio-button>
            <el-radio-button value="rejected">已驳回</el-radio-button>
          </el-radio-group>
          <el-button :icon="Refresh" @click="loadRequests">刷新</el-button>
        </div>

        <!-- 申请列表 -->
        <div class="request-list" v-loading="loading">
          <div v-if="filteredRequests.length === 0 && !loading" class="empty-state">
            <el-empty description="暂无绑定申请" />
          </div>
          <div v-for="req in filteredRequests" :key="req.id" class="request-card" :class="`status-${req.status}`">
            <div class="card-status-bar" :class="`bar-${req.status}`"></div>
            <div class="card-content">
              <div class="card-main">
                <div class="card-header-row">
                  <div class="farmer-info">
                    <el-avatar :size="40" class="farmer-avatar">{{ req.farmerName?.charAt(0) || '?' }}</el-avatar>
                    <div class="farmer-detail">
                      <span class="farmer-name">{{ req.farmerName }}</span>
                      <span class="farmer-id">ID: {{ req.farmerUserId }}</span>
                    </div>
                  </div>
                  <el-tag :type="getStatusTag(req.status)" effect="dark" size="small">{{ getStatusLabel(req.status) }}</el-tag>
                </div>
                <div class="card-info-grid">
                  <div class="info-item"><span class="info-label">绑定码</span><span class="info-value code">{{ req.bindCode }}</span></div>
                  <div class="info-item"><span class="info-label">申请时间</span><span class="info-value">{{ req.requestTime }}</span></div>
                  <div class="info-item" v-if="req.resolveTime"><span class="info-label">{{ req.status === 'approved' ? '通过时间' : '驳回时间' }}</span><span class="info-value">{{ req.resolveTime }}</span></div>
                  <div class="info-item" v-if="req.remark && req.status === 'rejected'"><span class="info-label">驳回原因</span><span class="info-value remark">{{ req.remark }}</span></div>
                </div>
              </div>
              <div class="card-actions" v-if="req.status === 'pending'">
                <el-button type="success" :icon="Check" :loading="actionLoading === req.id" @click="handleApprove(req)">同意</el-button>
                <el-button type="danger" plain :icon="Close" :loading="actionLoading === req.id" @click="handleReject(req)">驳回</el-button>
              </div>
              <div class="card-actions" v-else>
                <el-tag :type="getStatusTag(req.status)" effect="plain">{{ req.status === 'approved' ? '已通过审批' : '已驳回' }}</el-tag>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- ===== Tab 2: 管理者审批 ===== -->
      <el-tab-pane label="管理者审批" name="manager">
        <template #label>
          <div class="tab-label">
            <el-icon><UserFilled /></el-icon>
            <span>管理者审批</span>
            <el-badge v-if="managerStats.pending > 0" :value="managerStats.pending" type="warning" />
          </div>
        </template>

        <div class="tab-desc">
          <el-icon><InfoFilled /></el-icon>
          <span>农户申请成为管理者，由您（农场主）审批。通过后该农户可协助管理农田，您可随时撤销其管理者身份。</span>
        </div>

        <!-- 统计卡片 -->
        <div class="stats-row">
          <div class="stat-card">
            <div class="stat-icon pending-icon"><el-icon :size="22"><Clock /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ managerStats.pending }}</div><div class="stat-label">待审批</div></div>
          </div>
          <div class="stat-card">
            <div class="stat-icon approved-icon"><el-icon :size="22"><CircleCheckFilled /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ managerStats.approved }}</div><div class="stat-label">已通过</div></div>
          </div>
          <div class="stat-card">
            <div class="stat-icon rejected-icon"><el-icon :size="22"><CircleCloseFilled /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ managerStats.rejected }}</div><div class="stat-label">已驳回</div></div>
          </div>
          <div class="stat-card">
            <div class="stat-icon total-icon"><el-icon :size="22"><Document /></el-icon></div>
            <div class="stat-body"><div class="stat-value">{{ managerStats.total }}</div><div class="stat-label">申请总数</div></div>
          </div>
        </div>

        <!-- 筛选栏 -->
        <div class="filter-bar">
          <el-radio-group v-model="managerFilterStatus">
            <el-radio-button value="">全部</el-radio-button>
            <el-radio-button value="pending">待审批</el-radio-button>
            <el-radio-button value="approved">已通过</el-radio-button>
            <el-radio-button value="rejected">已驳回</el-radio-button>
          </el-radio-group>
          <el-button :icon="Refresh" @click="loadManagerApps">刷新</el-button>
        </div>

        <!-- 管理者申请列表 -->
        <div class="request-list" v-loading="managerLoading">
          <div v-if="filteredManagerApps.length === 0 && !managerLoading" class="empty-state">
            <el-empty description="暂无管理者申请" />
          </div>
          <div v-for="app in filteredManagerApps" :key="app.id" class="request-card" :class="`status-${app.status}`">
            <div class="card-status-bar" :class="`bar-${app.status}`"></div>
            <div class="card-content">
              <div class="card-main">
                <div class="card-header-row">
                  <div class="farmer-info">
                    <el-avatar :size="40" class="farmer-avatar">{{ app.farmerName?.charAt(0) || '?' }}</el-avatar>
                    <div class="farmer-detail">
                      <span class="farmer-name">{{ app.farmerName }}</span>
                      <span class="farmer-id">ID: {{ app.farmerUserId }}</span>
                    </div>
                  </div>
                  <el-tag :type="getStatusTag(app.status)" effect="dark" size="small">{{ getStatusLabel(app.status) }}</el-tag>
                </div>
                <div class="card-info-grid">
                  <div class="info-item"><span class="info-label">申请时间</span><span class="info-value">{{ app.requestTime }}</span></div>
                  <div class="info-item" v-if="app.resolveTime"><span class="info-label">{{ app.status === 'approved' ? '通过时间' : '驳回时间' }}</span><span class="info-value">{{ app.resolveTime }}</span></div>
                  <div class="info-item full" v-if="app.reason"><span class="info-label">申请理由</span><span class="info-value">{{ app.reason }}</span></div>
                  <div class="info-item full" v-if="app.remark && app.status === 'rejected'"><span class="info-label">驳回原因</span><span class="info-value remark">{{ app.remark }}</span></div>
                </div>
              </div>
              <div class="card-actions" v-if="app.status === 'pending'">
                <el-button type="success" :icon="Check" :loading="managerActionLoading === app.id" @click="handleApproveManager(app)">同意</el-button>
                <el-button type="danger" plain :icon="Close" :loading="managerActionLoading === app.id" @click="handleRejectManager(app)">驳回</el-button>
              </div>
              <div class="card-actions" v-else>
                <el-tag :type="getStatusTag(app.status)" effect="plain">{{ app.status === 'approved' ? '已通过审批' : '已驳回' }}</el-tag>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>

      <!-- ===== Tab 3: 管理者管理（撤销身份） ===== -->
      <el-tab-pane label="管理者管理" name="sub-managers">
        <template #label>
          <div class="tab-label">
            <el-icon><UserFilled /></el-icon>
            <span>管理者管理</span>
            <el-badge v-if="subManagers.length > 0" :value="subManagers.length" type="success" />
          </div>
        </template>

        <div class="tab-desc">
          <el-icon><InfoFilled /></el-icon>
          <span>已通过审批的管理者列表，您可随时撤销其管理者身份。撤销后，其名下田地将归还给您管理。</span>
        </div>

        <!-- 管理者列表 -->
        <div class="request-list" v-loading="subManagerLoading">
          <div v-if="subManagers.length === 0 && !subManagerLoading" class="empty-state">
            <el-empty description="暂无管理者，审批通过的管理者申请将显示在此处" />
          </div>
          <div v-for="mgr in subManagers" :key="mgr.id" class="request-card status-active">
            <div class="card-status-bar bar-active"></div>
            <div class="card-content">
              <div class="card-main">
                <div class="card-header-row">
                  <div class="farmer-info">
                    <el-avatar :size="40" class="farmer-avatar manager-avatar">{{ mgr.managerName?.charAt(0) || '?' }}</el-avatar>
                    <div class="farmer-detail">
                      <span class="farmer-name">{{ mgr.managerName }}</span>
                      <span class="farmer-id">管理者ID: {{ mgr.managerUserId }}</span>
                    </div>
                  </div>
                  <el-tag type="success" effect="dark" size="small">在职</el-tag>
                </div>
                <div class="card-info-grid">
                  <div class="info-item"><span class="info-label">审批通过时间</span><span class="info-value">{{ mgr.approvedTime }}</span></div>
                  <div class="info-item"><span class="info-label">原农户ID</span><span class="info-value">{{ mgr.originalFarmerId }}</span></div>
                </div>
              </div>
              <div class="card-actions">
                <el-button type="danger" plain :icon="CircleClose" :loading="revokeLoading === mgr.id" @click="handleRevokeManager(mgr)">撤销身份</el-button>
              </div>
            </div>
          </div>
        </div>
      </el-tab-pane>
    </el-tabs>

    <!-- 驳回原因弹窗（绑定申请） -->
    <el-dialog v-model="showRejectDialog" title="驳回绑定申请" width="440px">
      <p class="reject-tip">请输入驳回原因（选填），农户将看到此信息</p>
      <el-input v-model="rejectReason" type="textarea" :rows="3" placeholder="如：绑定码已过期，请重新获取" />
      <template #footer>
        <el-button @click="showRejectDialog = false">取消</el-button>
        <el-button type="danger" @click="confirmReject">确认驳回</el-button>
      </template>
    </el-dialog>

    <!-- 驳回原因弹窗（管理者申请） -->
    <el-dialog v-model="showManagerRejectDialog" title="驳回管理者申请" width="440px">
      <p class="reject-tip">请输入驳回原因（选填），申请者将看到此信息</p>
      <el-input v-model="managerRejectReason" type="textarea" :rows="3" placeholder="如：暂不需要 additional 管理者" />
      <template #footer>
        <el-button @click="showManagerRejectDialog = false">取消</el-button>
        <el-button type="danger" @click="confirmRejectManager">确认驳回</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import {
  Clock, CircleCheckFilled, CircleCloseFilled, Document,
  Refresh, Check, Close, CopyDocument, Link, UserFilled, CircleClose, InfoFilled,
} from '@element-plus/icons-vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { api } from '@/api'

// ===== 通用 =====
const activeTab = ref('bind')

// ===== Tab 1: 绑定审批 =====
const loading = ref(false)
const actionLoading = ref(null)
const filterStatus = ref('')
const showRejectDialog = ref(false)
const rejectReason = ref('')
const currentRejectRequest = ref(null)
const requests = ref([])
const managerBindCode = ref('')

function generateBindCode() {
  managerBindCode.value = 'AG' + Math.random().toString(36).substring(2, 8).toUpperCase()
}

function copyCode() {
  navigator.clipboard.writeText(managerBindCode.value)
  ElMessage.success('绑定码已复制')
}

const filteredRequests = computed(() => {
  if (!filterStatus.value) return requests.value
  return requests.value.filter((r) => r.status === filterStatus.value)
})

const bindStats = computed(() => {
  const all = requests.value
  return {
    total: all.length,
    pending: all.filter((r) => r.status === 'pending').length,
    approved: all.filter((r) => r.status === 'approved').length,
    rejected: all.filter((r) => r.status === 'rejected').length,
  }
})

function getStatusTag(status) {
  const map = { pending: 'warning', approved: 'success', rejected: 'danger' }
  return map[status] || 'info'
}

function getStatusLabel(status) {
  const map = { pending: '待审批', approved: '已通过', rejected: '已驳回' }
  return map[status] || status
}

function onFilterChange() {}

async function loadRequests() {
  loading.value = true
  try {
    const res = await api.getBindRequests()
    if (res.code === 200) {
      requests.value = res.data || []
    }
  } catch {
    // 静默处理，页面显示空数据
    requests.value = []
  } finally {
    loading.value = false
  }
}

async function handleApprove(req) {
  try {
    await ElMessageBox.confirm(
      `确认同意「${req.farmerName}」的绑定申请？通过后该农户将关联到您的农场。`,
      '审批确认',
      { confirmButtonText: '同意', cancelButtonText: '取消', type: 'success' }
    )
  } catch {
    return
  }
  actionLoading.value = req.id
  try {
    const res = await api.approveBindRequest(req.id)
    if (res.code === 200) {
      ElMessage.success('已同意绑定申请')
      await loadRequests()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    actionLoading.value = null
  }
}

function handleReject(req) {
  currentRejectRequest.value = req
  rejectReason.value = ''
  showRejectDialog.value = true
}

async function confirmReject() {
  const req = currentRejectRequest.value
  if (!req) return
  actionLoading.value = req.id
  showRejectDialog.value = false
  try {
    const res = await api.rejectBindRequest(req.id, rejectReason.value)
    if (res.code === 200) {
      ElMessage.success('已驳回绑定申请')
      await loadRequests()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    actionLoading.value = null
    currentRejectRequest.value = null
  }
}

// ===== Tab 2: 管理者审批 =====
const managerApps = ref([])
const managerLoading = ref(false)
const managerActionLoading = ref(null)
const managerFilterStatus = ref('')
const showManagerRejectDialog = ref(false)
const managerRejectReason = ref('')
const currentRejectManagerApp = ref(null)

const filteredManagerApps = computed(() => {
  if (!managerFilterStatus.value) return managerApps.value
  return managerApps.value.filter((a) => a.status === managerFilterStatus.value)
})

const managerStats = computed(() => {
  const all = managerApps.value
  return {
    total: all.length,
    pending: all.filter((a) => a.status === 'pending').length,
    approved: all.filter((a) => a.status === 'approved').length,
    rejected: all.filter((a) => a.status === 'rejected').length,
  }
})

async function loadManagerApps() {
  managerLoading.value = true
  try {
    const res = await api.getManagerApplications()
    if (res.code === 200) {
      managerApps.value = res.data || []
    }
  } catch {
    // 静默处理，页面显示空数据
    managerApps.value = []
  } finally {
    managerLoading.value = false
  }
}

async function handleApproveManager(app) {
  try {
    await ElMessageBox.confirm(
      `确认同意「${app.farmerName}」的管理者申请？通过后该农户将成为管理者，可协助管理农田。`,
      '审批确认',
      { confirmButtonText: '同意', cancelButtonText: '取消', type: 'success' }
    )
  } catch {
    return
  }
  managerActionLoading.value = app.id
  try {
    const res = await api.approveManagerApplication(app.id)
    if (res.code === 200) {
      ElMessage.success('已同意管理者申请')
      await loadManagerApps()
      await loadSubManagers()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    managerActionLoading.value = null
  }
}

function handleRejectManager(app) {
  currentRejectManagerApp.value = app
  managerRejectReason.value = ''
  showManagerRejectDialog.value = true
}

async function confirmRejectManager() {
  const app = currentRejectManagerApp.value
  if (!app) return
  managerActionLoading.value = app.id
  showManagerRejectDialog.value = false
  try {
    const res = await api.rejectManagerApplication(app.id, managerRejectReason.value)
    if (res.code === 200) {
      ElMessage.success('已驳回管理者申请')
      await loadManagerApps()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    managerActionLoading.value = null
    currentRejectManagerApp.value = null
  }
}

// ===== Tab 3: 管理者管理（撤销身份） =====
const subManagers = ref([])
const subManagerLoading = ref(false)
const revokeLoading = ref(null)

async function loadSubManagers() {
  subManagerLoading.value = true
  try {
    const res = await api.getSubManagers()
    if (res.code === 200) {
      subManagers.value = res.data || []
    }
  } catch {
    // 静默处理，页面显示空数据
    subManagers.value = []
  } finally {
    subManagerLoading.value = false
  }
}

async function handleRevokeManager(mgr) {
  try {
    await ElMessageBox.confirm(
      `确认撤销「${mgr.managerName}」的管理者身份？撤销后其名下田地将归还给您管理。`,
      '撤销确认',
      { confirmButtonText: '确认撤销', cancelButtonText: '取消', type: 'warning' }
    )
  } catch {
    return
  }
  revokeLoading.value = mgr.id
  try {
    const res = await api.revokeManager(mgr.id)
    if (res.code === 200) {
      ElMessage.success(res.message || '已撤销管理者身份')
      await loadSubManagers()
    }
  } catch {
    // 静默处理，不弹toast
  } finally {
    revokeLoading.value = null
  }
}

onMounted(() => {
  generateBindCode()
  loadRequests()
  loadManagerApps()
  loadSubManagers()
})
</script>

<style scoped>
/* 绑定码生成卡片 */
.bind-code-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  margin-bottom: 24px;
  overflow: hidden;
}

.bind-code-header {
  padding: 20px 24px 0;
}

.bind-code-title-area {
  display: flex;
  align-items: center;
  gap: 14px;
}

.bind-code-title-icon {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  background: var(--primary-bg);
  color: var(--primary);
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.bind-code-title {
  font-size: 16px;
  font-weight: 600;
  color: var(--text-primary);
  margin-bottom: 2px;
}

.bind-code-desc {
  font-size: 13px;
  color: var(--text-secondary);
}

.bind-code-body {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px 24px 24px;
  flex-wrap: wrap;
}

.code-display-box {
  flex: 1;
  min-width: 200px;
  padding: 16px 24px;
  background: var(--primary-bg);
  border: 1px dashed #86efac;
  border-radius: 8px;
  text-align: center;
}

.code-display-text {
  font-size: 28px;
  font-weight: 700;
  color: var(--primary);
  letter-spacing: 4px;
  font-family: 'Courier New', monospace;
}

.bind-code-actions {
  display: flex;
  gap: 10px;
  flex-shrink: 0;
}

.stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  margin-bottom: 24px;
}

.stat-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  padding: 18px 20px;
  display: flex;
  align-items: center;
  gap: 14px;
  box-shadow: var(--shadow-sm);
  transition: transform 0.2s ease, box-shadow 0.2s ease;
}

.stat-card:hover {
  transform: translateY(-2px);
  box-shadow: var(--shadow-md);
}

.stat-icon {
  width: 44px;
  height: 44px;
  border-radius: 10px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.pending-icon { background: #fef3c7; color: #f59e0b; }
.approved-icon { background: #dcfce7; color: #22c55e; }
.rejected-icon { background: #fee2e2; color: #ef4444; }
.total-icon { background: #e0e7ff; color: #6366f1; }

.stat-body {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 24px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1;
}

.stat-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 4px;
}

/* 筛选栏 */
.filter-bar {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 20px;
}

/* 申请列表 */
.request-list {
  display: flex;
  flex-direction: column;
  gap: 12px;
}

.empty-state {
  padding: 60px 0;
}

.request-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  overflow: hidden;
  display: flex;
  box-shadow: var(--shadow-sm);
  transition: box-shadow 0.2s ease;
}

.request-card:hover {
  box-shadow: var(--shadow-md);
}

.card-status-bar {
  width: 4px;
  flex-shrink: 0;
}

.bar-pending { background: #f59e0b; }
.bar-approved { background: #22c55e; }
.bar-rejected { background: #ef4444; }
.bar-active { background: #22c55e; }

/* Tab 样式 */
.approval-tabs {
  margin-bottom: 8px;
}

.tab-label {
  display: flex;
  align-items: center;
  gap: 6px;
}

.tab-desc {
  display: flex;
  align-items: flex-start;
  gap: 8px;
  padding: 12px 16px;
  background: var(--primary-bg);
  border: 1px solid #bbf7d0;
  border-radius: 8px;
  margin-bottom: 20px;
  font-size: 13px;
  color: var(--primary-dark);
  line-height: 1.6;
}

.manager-avatar {
  background: #2563eb !important;
}

.info-item.full {
  grid-column: 1 / -1;
}

.card-content {
  flex: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 18px 20px;
  gap: 20px;
}

.card-main {
  flex: 1;
  min-width: 0;
}

.card-header-row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 14px;
}

.farmer-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.farmer-avatar {
  background: var(--primary);
  color: #fff;
  font-weight: 600;
  flex-shrink: 0;
}

.farmer-detail {
  display: flex;
  flex-direction: column;
}

.farmer-name {
  font-size: 15px;
  font-weight: 600;
  color: var(--text-primary);
}

.farmer-id {
  font-size: 12px;
  color: var(--text-tertiary);
}

.card-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(180px, 1fr));
  gap: 8px 24px;
}

.info-item {
  display: flex;
  flex-direction: column;
  gap: 2px;
}

.info-label {
  font-size: 12px;
  color: var(--text-tertiary);
}

.info-value {
  font-size: 13px;
  color: var(--text-primary);
}

.info-value.code {
  font-family: 'Courier New', monospace;
  font-weight: 600;
  letter-spacing: 1px;
  color: var(--primary-dark);
}

.info-value.remark {
  color: var(--danger);
}

.card-actions {
  display: flex;
  flex-direction: column;
  gap: 8px;
  flex-shrink: 0;
}

.card-actions .el-button {
  min-width: 90px;
}

/* 驳回弹窗 */
.reject-tip {
  font-size: 14px;
  color: var(--text-secondary);
  margin-bottom: 12px;
}

/* 响应式 */
@media (max-width: 768px) {
  .stats-row {
    grid-template-columns: repeat(2, 1fr);
  }
  .bind-code-body {
    flex-direction: column;
    align-items: stretch;
  }
  .bind-code-actions {
    width: 100%;
  }
  .bind-code-actions .el-button {
    flex: 1;
  }
  .card-content {
    flex-direction: column;
    align-items: flex-start;
  }
  .card-actions {
    flex-direction: row;
    width: 100%;
  }
  .card-actions .el-button {
    flex: 1;
  }
}
</style>
