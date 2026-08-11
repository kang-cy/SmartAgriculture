<template>
  <div class="page-container alert-manage">
    <!-- 告警统计卡片 -->
    <div class="stats-row">
      <div class="stat-card stat-active">
        <div class="stat-icon active-icon">
          <el-icon :size="24"><Bell /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ stats.active }}</div>
          <div class="stat-label">活跃告警</div>
        </div>
      </div>
      <div class="stat-card stat-warning">
        <div class="stat-icon warning-icon">
          <el-icon :size="24"><Warning /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ stats.warning }}</div>
          <div class="stat-label">警告</div>
        </div>
      </div>
      <div class="stat-card stat-danger">
        <div class="stat-icon danger-icon">
          <el-icon :size="24"><WarnTriangleFilled /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ stats.danger }}</div>
          <div class="stat-label">严重</div>
        </div>
      </div>
    </div>

    <!-- 筛选栏 -->
    <div class="filter-card">
      <div class="filter-left">
        <div class="filter-item">
          <span class="filter-label">状态</span>
          <el-radio-group v-model="filterStatus" @change="onFilterChange">
            <el-radio-button value="all">全部</el-radio-button>
            <el-radio-button value="active">活跃</el-radio-button>
            <el-radio-button value="resolved">已处理</el-radio-button>
          </el-radio-group>
        </div>
        <div class="filter-item">
          <span class="filter-label">级别</span>
          <el-select v-model="filterLevel" style="width: 120px" @change="onFilterChange">
            <el-option label="全部" value="all" />
            <el-option label="警告" value="warning" />
            <el-option label="严重" value="danger" />
            <el-option label="信息" value="info" />
          </el-select>
        </div>
      </div>
      <div class="filter-right">
        <div class="auto-refresh">
          <el-switch v-model="autoRefresh" @change="toggleAutoRefresh" />
          <span class="auto-refresh-text">自动刷新（30秒）</span>
        </div>
        <el-button :icon="Refresh" @click="loadAlerts" :loading="loading">刷新</el-button>
      </div>
    </div>

    <!-- 告警表格 -->
    <div class="table-card">
      <el-table
        :data="pagedAlerts"
        v-loading="loading"
        stripe
        style="width: 100%"
        :header-cell-style="{ background: '#f9fafb', color: '#374151', fontWeight: 600 }"
      >
        <el-table-column label="告警级别" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="levelTagType(row.level)" size="small" effect="dark">
              {{ levelLabels[row.level] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="地块名称" prop="fieldName" min-width="160" />
        <el-table-column label="告警类型" width="120" align="center">
          <template #default="{ row }">
            <span class="alert-type-text">{{ alertTypeLabels[row.type] || row.type }}</span>
          </template>
        </el-table-column>
        <el-table-column label="告警详情" prop="message" min-width="280" show-overflow-tooltip />
        <el-table-column label="时间" prop="time" width="170" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag
              :type="row.status === 'active' ? 'danger' : 'success'"
              size="small"
              effect="plain"
            >
              {{ row.status === 'active' ? '活跃' : '已处理' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="操作" width="100" align="center" fixed="right">
          <template #default="{ row }">
            <el-button
              v-if="row.status === 'active'"
              type="primary"
              size="small"
              @click="handleResolve(row)"
            >
              处理
            </el-button>
            <span v-else class="text-muted">—</span>
          </template>
        </el-table-column>
      </el-table>

      <!-- 空状态 -->
      <el-empty v-if="!loading && filteredAlerts.length === 0" description="暂无符合条件的告警记录" />

      <!-- 分页 -->
      <div v-if="filteredAlerts.length > 0" class="pagination-wrap">
        <el-pagination
          v-model:current-page="currentPage"
          v-model:page-size="pageSize"
          :page-sizes="[10, 20, 50]"
          :total="filteredAlerts.length"
          layout="total, sizes, prev, pager, next, jumper"
          background
        />
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, onUnmounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import { Bell, Warning, WarnTriangleFilled, Refresh } from '@element-plus/icons-vue'
import { api } from '@/api'

// ========== 标签映射 ==========
const alertTypeLabels = {
  low_moisture: '湿度不足',
  high_temp: '温度过高',
  device_offline: '设备离线',
  low_battery: '电量低',
}

const levelLabels = {
  warning: '警告',
  danger: '严重',
  info: '信息',
}

// ========== 响应式状态 ==========
const loading = ref(false)
const allAlerts = ref([])
const filterStatus = ref('all')
const filterLevel = ref('all')
const autoRefresh = ref(false)
const currentPage = ref(1)
const pageSize = ref(10)
let refreshTimer = null

// ========== 计算属性 ==========
// 统计数据（基于所有活跃告警）
const stats = computed(() => {
  const active = allAlerts.value.filter((a) => a.status === 'active')
  return {
    active: active.length,
    warning: active.filter((a) => a.level === 'warning').length,
    danger: active.filter((a) => a.level === 'danger').length,
  }
})

// 筛选后的告警列表
const filteredAlerts = computed(() => {
  return allAlerts.value.filter((a) => {
    if (filterStatus.value !== 'all' && a.status !== filterStatus.value) return false
    if (filterLevel.value !== 'all' && a.level !== filterLevel.value) return false
    return true
  })
})

// 当前页数据
const pagedAlerts = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredAlerts.value.slice(start, start + pageSize.value)
})

// ========== 辅助函数 ==========
function levelTagType(level) {
  const map = { danger: 'danger', warning: 'warning', info: 'info' }
  return map[level] || 'info'
}

// 筛选条件变化时重置页码
function onFilterChange() {
  currentPage.value = 1
}

watch([filterStatus, filterLevel], () => {
  currentPage.value = 1
})

// ========== 数据加载 ==========
async function loadAlerts() {
  loading.value = true
  try {
    const res = await api.getAlerts()
    if (res.code === 200 && res.data) {
      allAlerts.value = res.data
    }
  } catch {
    // 静默处理，页面显示空数据
    allAlerts.value = []
  } finally {
    loading.value = false
  }
}

// ========== 处理告警 ==========
async function handleResolve(row) {
  try {
    await ElMessageBox.confirm(
      `确定要处理该告警吗？\n${row.fieldName} - ${alertTypeLabels[row.type] || row.type}`,
      '处理告警',
      {
        confirmButtonText: '确定处理',
        cancelButtonText: '取消',
        type: 'warning',
      },
    )

    const res = await api.resolveAlert(row.id)
    if (res.code === 200) {
      ElMessage.success('告警已处理')
      await loadAlerts()
    }
  } catch (error) {
    // 用户取消操作时不提示错误
    if (error !== 'cancel' && error?.toString() !== 'cancel') {
      // 静默处理，不弹toast
    }
  }
}

// ========== 自动刷新 ==========
function toggleAutoRefresh(val) {
  if (val) {
    refreshTimer = setInterval(() => {
      loadAlerts()
    }, 30000)
    ElMessage.success('已开启自动刷新，每30秒更新一次')
  } else {
    if (refreshTimer) {
      clearInterval(refreshTimer)
      refreshTimer = null
    }
  }
}

// ========== 生命周期 ==========
onMounted(() => {
  loadAlerts()
})

onUnmounted(() => {
  if (refreshTimer) {
    clearInterval(refreshTimer)
    refreshTimer = null
  }
})
</script>

<style scoped>
.alert-manage {
  padding: 20px 24px;
}

/* ===== 统计卡片 ===== */
.stats-row {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 16px;
  margin-bottom: 20px;
}

.stat-card {
  display: flex;
  align-items: center;
  gap: 16px;
  padding: 20px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  transition: box-shadow 0.2s ease, transform 0.2s ease;
}

.stat-card:hover {
  box-shadow: var(--shadow-md);
  transform: translateY(-2px);
}

.stat-icon {
  width: 52px;
  height: 52px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.active-icon {
  background: #fef2f2;
  color: var(--danger);
}

.warning-icon {
  background: #fffbeb;
  color: var(--warning);
}

.danger-icon {
  background: #fef2f2;
  color: var(--danger);
}

.stat-body {
  display: flex;
  flex-direction: column;
}

.stat-value {
  font-size: 30px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.1;
}

.stat-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 4px;
}

/* ===== 筛选栏 ===== */
.filter-card {
  display: flex;
  align-items: center;
  justify-content: space-between;
  flex-wrap: wrap;
  gap: 16px;
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 16px 20px;
  margin-bottom: 20px;
}

.filter-left {
  display: flex;
  align-items: center;
  gap: 24px;
  flex-wrap: wrap;
}

.filter-right {
  display: flex;
  align-items: center;
  gap: 16px;
}

.filter-item {
  display: flex;
  align-items: center;
  gap: 10px;
}

.filter-label {
  font-size: 13px;
  color: var(--text-secondary);
  white-space: nowrap;
  font-weight: 500;
}

.auto-refresh {
  display: flex;
  align-items: center;
  gap: 8px;
}

.auto-refresh-text {
  font-size: 13px;
  color: var(--text-secondary);
  white-space: nowrap;
}

/* ===== 表格卡片 ===== */
.table-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 4px;
  overflow: hidden;
}

.alert-type-text {
  font-size: 13px;
  color: var(--text-primary);
  font-weight: 500;
}

.text-muted {
  color: var(--text-tertiary);
}

/* ===== 分页 ===== */
.pagination-wrap {
  display: flex;
  justify-content: flex-end;
  padding: 16px 20px;
}
</style>
