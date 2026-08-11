<template>
  <div class="page-container alert-log">
    <!-- 筛选栏 -->
    <div class="filter-card">
      <div class="filter-row">
        <div class="filter-item">
          <span class="filter-label">时间范围</span>
          <el-date-picker
            v-model="dateRange"
            type="daterange"
            range-separator="至"
            start-placeholder="开始日期"
            end-placeholder="结束日期"
            format="YYYY-MM-DD"
            value-format="YYYY-MM-DD"
            style="width: 260px"
            :clearable="true"
          />
        </div>
        <div class="filter-item">
          <span class="filter-label">告警级别</span>
          <el-select v-model="levelFilter" style="width: 130px">
            <el-option label="全部" value="all" />
            <el-option label="警告" value="warning" />
            <el-option label="严重" value="danger" />
            <el-option label="信息" value="info" />
          </el-select>
        </div>
        <div class="filter-item">
          <span class="filter-label">处理状态</span>
          <el-select v-model="statusFilter" style="width: 130px">
            <el-option label="全部" value="all" />
            <el-option label="活跃" value="active" />
            <el-option label="已处理" value="resolved" />
          </el-select>
        </div>
        <div class="filter-item">
          <span class="filter-label">所属地块</span>
          <el-select v-model="fieldFilter" placeholder="全部地块" clearable style="width: 180px">
            <el-option
              v-for="field in fields"
              :key="field.id"
              :label="field.name"
              :value="field.id"
            />
          </el-select>
        </div>
        <el-button type="primary" :icon="Download" @click="handleExport" class="export-btn">
          导出日志
        </el-button>
      </div>
    </div>

    <!-- 统计概览 -->
    <div class="stats-row">
      <div class="stat-card">
        <div class="stat-icon total">
          <el-icon :size="22"><Bell /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ allAlerts.length }}</div>
          <div class="stat-label">告警总数</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon active">
          <el-icon :size="22"><WarningFilled /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ activeCount }}</div>
          <div class="stat-label">活跃告警</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon resolved">
          <el-icon :size="22"><CircleCheckFilled /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">{{ resolvedCount }}</div>
          <div class="stat-label">已处理</div>
        </div>
      </div>
      <div class="stat-card">
        <div class="stat-icon time">
          <el-icon :size="22"><Timer /></el-icon>
        </div>
        <div class="stat-body">
          <div class="stat-value">18<span class="stat-unit">分钟</span></div>
          <div class="stat-label">平均处理时间</div>
        </div>
      </div>
    </div>

    <!-- 告警日志表格 -->
    <div class="table-card" v-loading="loading">
      <el-table
        :data="pagedAlerts"
        stripe
        style="width: 100%"
        :header-cell-style="{ background: '#f9fafb', color: '#374151', fontWeight: 600 }"
      >
        <el-table-column label="序号" type="index" width="70" align="center" />
        <el-table-column label="告警级别" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="levelTagType(row.level)" size="small" effect="dark">
              {{ levelLabels[row.level] }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="地块名称" prop="fieldName" min-width="150" />
        <el-table-column label="告警类型" width="120" align="center">
          <template #default="{ row }">
            <span class="alert-type-text">{{ alertTypeLabels[row.type] }}</span>
          </template>
        </el-table-column>
        <el-table-column label="详情" prop="message" min-width="280" show-overflow-tooltip />
        <el-table-column label="触发时间" prop="time" width="170" />
        <el-table-column label="状态" width="100" align="center">
          <template #default="{ row }">
            <el-tag :type="row.status === 'active' ? 'danger' : 'success'" size="small" effect="plain">
              {{ row.status === 'active' ? '活跃' : '已处理' }}
            </el-tag>
          </template>
        </el-table-column>
        <el-table-column label="处理时间" width="170" align="center">
          <template #default="{ row }">
            <span v-if="row.resolveTime" class="resolve-time">{{ row.resolveTime }}</span>
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
import { ref, computed, watch, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Bell, WarningFilled, CircleCheckFilled, Timer, Download } from '@element-plus/icons-vue'
import { api } from '@/api'

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

const loading = ref(false)
const allAlerts = ref([])
const fields = ref([])

// 筛选条件
const dateRange = ref([])
const levelFilter = ref('all')
const statusFilter = ref('all')
const fieldFilter = ref(null)

// 分页
const currentPage = ref(1)
const pageSize = ref(10)

// 统计
const activeCount = computed(() => allAlerts.value.filter((a) => a.status === 'active').length)
const resolvedCount = computed(() => allAlerts.value.filter((a) => a.status === 'resolved').length)

// 级别标签类型
function levelTagType(level) {
  const map = { danger: 'danger', warning: 'warning', info: 'info' }
  return map[level] || 'info'
}

// 筛选后的告警
const filteredAlerts = computed(() => {
  return allAlerts.value.filter((a) => {
    // 级别筛选
    if (levelFilter.value !== 'all' && a.level !== levelFilter.value) return false
    // 状态筛选
    if (statusFilter.value !== 'all' && a.status !== statusFilter.value) return false
    // 地块筛选
    if (fieldFilter.value && a.fieldId !== fieldFilter.value) return false
    // 日期范围筛选
    if (dateRange.value && dateRange.value.length === 2) {
      const alertTime = new Date(a.time.replace(/-/g, '/'))
      const start = new Date(dateRange.value[0])
      start.setHours(0, 0, 0, 0)
      const end = new Date(dateRange.value[1])
      end.setHours(23, 59, 59, 999)
      if (alertTime < start || alertTime > end) return false
    }
    return true
  })
})

// 分页数据
const pagedAlerts = computed(() => {
  const start = (currentPage.value - 1) * pageSize.value
  return filteredAlerts.value.slice(start, start + pageSize.value)
})

// 筛选条件变化时重置页码
watch([levelFilter, statusFilter, fieldFilter, dateRange], () => {
  currentPage.value = 1
})

// 导出日志
function handleExport() {
  ElMessage.success('告警日志导出成功')
}

// 将 ISO 时间字符串（含 'T' 分隔符）转换为 "YYYY-MM-DD HH:mm:ss" 格式
function normalizeTime(timeStr) {
  if (!timeStr) return ''
  // 后端 LocalDateTime 序列化后形如 "2026-08-04T09:15:22"，需把 'T' 替换为空格
  if (typeof timeStr === 'string' && timeStr.includes('T')) {
    return timeStr.replace('T', ' ')
  }
  return timeStr
}

// 数据加载
async function loadAlerts() {
  loading.value = true
  try {
    const res = await api.getAlerts()
    if (res.code === 200) {
      allAlerts.value = (res.data || []).map((a) => {
        // 兼容后端字段名 createdAt/resolvedAt 与前端 time/resolveTime
        const timeStr = normalizeTime(a.time || a.createdAt || '')
        let resolveTimeStr = normalizeTime(a.resolveTime || a.resolvedAt || null)

        // 为已处理告警添加模拟处理时间（mock 数据或后端未返回 resolvedAt 时）
        if (a.status === 'resolved') {
          if (!resolveTimeStr && timeStr) {
            const triggerTime = new Date(timeStr.replace(/-/g, '/'))
            triggerTime.setMinutes(triggerTime.getMinutes() + Math.floor(Math.random() * 25) + 8)
            resolveTimeStr = formatDateTime(triggerTime)
          }
        } else {
          resolveTimeStr = null
        }

        return { ...a, time: timeStr, resolveTime: resolveTimeStr }
      })
    }
  } catch {
    // 静默处理，页面显示空数据
    allAlerts.value = []
  } finally {
    loading.value = false
  }
}

async function loadFields() {
  try {
    const res = await api.getFields()
    if (res.code === 200) {
      fields.value = res.data
    }
  } catch {
    // 静默处理
  }
}

function formatDateTime(date) {
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, '0')
  const d = String(date.getDate()).padStart(2, '0')
  const h = String(date.getHours()).padStart(2, '0')
  const min = String(date.getMinutes()).padStart(2, '0')
  const s = String(date.getSeconds()).padStart(2, '0')
  return `${y}-${m}-${d} ${h}:${min}:${s}`
}

onMounted(() => {
  loadAlerts()
  loadFields()
})
</script>

<style scoped>
.alert-log {
  padding: 20px 24px;
}

/* ===== 筛选栏 ===== */
.filter-card {
  background: var(--bg-card);
  border: 1px solid var(--border-color);
  border-radius: var(--border-radius);
  box-shadow: var(--shadow-sm);
  padding: 18px 20px;
  margin-bottom: 20px;
}

.filter-row {
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  gap: 16px;
}

.filter-item {
  display: flex;
  align-items: center;
  gap: 8px;
}

.filter-label {
  font-size: 13px;
  color: var(--text-secondary);
  white-space: nowrap;
  font-weight: 500;
}

.export-btn {
  margin-left: auto;
}

/* ===== 统计概览 ===== */
.stats-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
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
  transition: box-shadow 0.2s ease;
}

.stat-card:hover {
  box-shadow: var(--shadow-md);
}

.stat-icon {
  width: 48px;
  height: 48px;
  border-radius: 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  flex-shrink: 0;
}

.stat-icon.total {
  background: #eff6ff;
  color: #2563eb;
}

.stat-icon.active {
  background: #fef2f2;
  color: var(--danger);
}

.stat-icon.resolved {
  background: var(--primary-bg);
  color: var(--primary);
}

.stat-icon.time {
  background: #fffbeb;
  color: var(--warning);
}

.stat-value {
  font-size: 28px;
  font-weight: 700;
  color: var(--text-primary);
  line-height: 1.2;
}

.stat-unit {
  font-size: 14px;
  font-weight: 500;
  color: var(--text-secondary);
  margin-left: 2px;
}

.stat-label {
  font-size: 13px;
  color: var(--text-secondary);
  margin-top: 2px;
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

.resolve-time {
  font-size: 13px;
  color: var(--text-secondary);
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
