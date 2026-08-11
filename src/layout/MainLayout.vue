<template>
  <div class="main-layout">
    <!-- 侧边栏 -->
    <aside class="sidebar" :class="{ collapsed: isCollapsed }">
      <div class="sidebar-logo">
        <svg viewBox="0 0 32 32" fill="none" class="logo-svg">
          <path d="M16 4 C 9 4, 4 11, 4 19 L 16 28 L 28 19 C 28 11, 23 4, 16 4 Z" fill="#22c55e" opacity="0.3"/>
          <path d="M16 9 L 16 23 M 11 14 L 16 9 L 21 14" stroke="#4ade80" stroke-width="2" fill="none" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
        <span v-show="!isCollapsed" class="logo-text">智慧农业</span>
      </div>

      <nav class="sidebar-nav">
        <router-link
          v-for="item in menuItems"
          :key="item.path"
          :to="item.path"
          class="nav-item"
          active-class="active"
        >
          <el-icon class="nav-icon"><component :is="item.icon" /></el-icon>
          <span v-show="!isCollapsed" class="nav-text">{{ item.title }}</span>
        </router-link>
      </nav>

      <div class="sidebar-footer">
        <div class="collapse-btn" @click="isCollapsed = !isCollapsed">
          <el-icon>
            <Fold v-if="!isCollapsed" />
            <Expand v-else />
          </el-icon>
        </div>
      </div>
    </aside>

    <!-- 主区域 -->
    <div class="main-area">
      <!-- 顶部栏 -->
      <header class="topbar">
        <div class="topbar-left">
          <h3 class="page-name">{{ currentTitle }}</h3>
        </div>
        <div class="topbar-right">
          <!-- 告警铃铛 -->
          <el-badge :value="alertCount" :max="99" class="alert-badge">
            <el-button
              circle
              text
              class="icon-btn"
              @click="$router.push('/alert')"
            >
              <el-icon size="20"><Bell /></el-icon>
            </el-button>
          </el-badge>

          <!-- 3D农场快捷入口 -->
          <el-button
            circle
            text
            class="icon-btn"
            @click="$router.push('/farm3d')"
          >
            <el-icon size="20"><View /></el-icon>
          </el-button>

          <el-divider direction="vertical" />

          <!-- 用户信息 -->
          <el-dropdown trigger="click" @command="handleCommand">
            <div class="user-info">
              <el-avatar :size="34" class="user-avatar">
                {{ userStore.username.charAt(0).toUpperCase() }}
              </el-avatar>
              <div class="user-detail">
                <span class="user-name">{{ userStore.username || '用户' }}</span>
                <span class="user-role">
                  {{ userStore.isFarmer ? '农户' : '管理者' }}
                </span>
              </div>
              <el-icon class="arrow-down"><ArrowDown /></el-icon>
            </div>
            <template #dropdown>
              <el-dropdown-menu>
                <el-dropdown-item v-if="!editingFarmName" disabled>
                  {{ userStore.farmName || '未设置农场名称' }}
                </el-dropdown-item>
                <el-dropdown-item v-if="userStore.isManager && !editingFarmName" command="editFarmName">
                  <el-icon><Edit /></el-icon>
                  修改农场名称
                </el-dropdown-item>
                <el-dropdown-item v-if="editingFarmName" :disabled="true">
                  <div class="farm-name-edit" @click.stop>
                    <el-input
                      v-model="tempFarmName"
                      size="small"
                      placeholder="请输入农场名称"
                      @keyup.enter="saveFarmName"
                    />
                    <el-button type="primary" size="small" :icon="Check" @click="saveFarmName" circle />
                  </div>
                </el-dropdown-item>
                <el-dropdown-item divided command="logout">
                  <el-icon><SwitchButton /></el-icon>
                  退出登录
                </el-dropdown-item>
              </el-dropdown-menu>
            </template>
          </el-dropdown>
        </div>
      </header>

      <!-- 内容区 -->
      <main class="content-area">
        <router-view v-slot="{ Component }">
          <transition name="fade-slide" mode="out-in">
            <component :is="Component" />
          </transition>
        </router-view>
      </main>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ElMessageBox, ElMessage, ElInput } from 'element-plus'
import { Edit, Check } from '@element-plus/icons-vue'
import { useUserStore } from '@/store/user'
import { api } from '@/api'

const route = useRoute()
const router = useRouter()
const userStore = useUserStore()

const isCollapsed = ref(false)
const alertCount = ref(0)
const editingFarmName = ref(false)
const tempFarmName = ref('')

// 根据角色生成菜单
const allMenuItems = [
  { path: '/dashboard', title: '数据总览', icon: 'Odometer', roles: ['farmer', 'manager'] },
  { path: '/monitor', title: '实时监测', icon: 'Monitor', roles: ['farmer', 'manager'] },
  { path: '/farm3d', title: '3D农场', icon: 'View', roles: ['farmer', 'manager'] },
  { path: '/control', title: '设备控制', icon: 'Setting', roles: ['farmer'] },
  { path: '/alert', title: '告警管理', icon: 'Bell', roles: ['farmer', 'manager'] },
  { path: '/ai-chat', title: '智能问答', icon: 'ChatDotRound', roles: ['farmer'] },
  { path: '/bind-manage', title: '绑定管理', icon: 'Link', roles: ['farmer'] },
  { path: '/fields', title: '农田管理', icon: 'Location', roles: ['manager'] },
  { path: '/device-bind', title: '设备绑定', icon: 'Connection', roles: ['manager'] },
  { path: '/bind-approval', title: '绑定审批', icon: 'Check', roles: ['manager'] },
  { path: '/alert-log', title: '告警日志', icon: 'Document', roles: ['manager'] },
]

const menuItems = computed(() =>
  allMenuItems.filter((item) => item.roles.includes(userStore.role))
)

const currentTitle = computed(() => route.meta.title || '智慧农业')

function handleCommand(command) {
  if (command === 'logout') {
    ElMessageBox.confirm('确定要退出登录吗？', '提示', {
      confirmButtonText: '确定',
      cancelButtonText: '取消',
      type: 'warning',
    }).then(() => {
      userStore.logout()
      ElMessage.success('已退出登录')
      router.push('/login')
    }).catch(() => {})
  } else if (command === 'editFarmName') {
    tempFarmName.value = userStore.farmName
    editingFarmName.value = true
  }
}

async function saveFarmName() {
  if (!tempFarmName.value.trim()) {
    ElMessage.warning('农场名称不能为空')
    return
  }
  try {
    const res = await api.updateFarmName(tempFarmName.value.trim())
    if (res.code === 200) {
      userStore.farmName = tempFarmName.value.trim()
      localStorage.setItem('sa_farmName', tempFarmName.value.trim())
      ElMessage.success('农场名称已更新')
      editingFarmName.value = false
    }
  } catch {
    // 静默处理，不弹toast
  }
}

onMounted(async () => {
  try {
    const res = await api.getAlerts('active')
    alertCount.value = res.data?.length || 0
  } catch {
    // 静默处理
  }
})
</script>

<style scoped>
.main-layout {
  display: flex;
  height: 100vh;
  width: 100vw;
  overflow: hidden;
}

/* ===== 侧边栏 ===== */
.sidebar {
  width: 220px;
  background: var(--bg-sidebar);
  display: flex;
  flex-direction: column;
  transition: width 0.3s ease;
  flex-shrink: 0;
}

.sidebar.collapsed {
  width: 64px;
}

.sidebar-logo {
  height: 60px;
  display: flex;
  align-items: center;
  gap: 10px;
  padding: 0 20px;
  border-bottom: 1px solid rgba(255, 255, 255, 0.08);
}

.logo-svg {
  width: 28px;
  height: 28px;
  flex-shrink: 0;
}

.logo-text {
  font-size: 18px;
  font-weight: 700;
  color: #f0fdf4;
  white-space: nowrap;
  letter-spacing: 1px;
}

.sidebar-nav {
  flex: 1;
  padding: 12px 10px;
  overflow-y: auto;
  overflow-x: hidden;
}

.sidebar-nav::-webkit-scrollbar {
  width: 0;
}

.nav-item {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 11px 14px;
  margin-bottom: 4px;
  border-radius: 8px;
  color: rgba(240, 253, 244, 0.6);
  text-decoration: none;
  font-size: 14px;
  transition: all 0.2s ease;
  cursor: pointer;
  white-space: nowrap;
}

.nav-item:hover {
  background: rgba(255, 255, 255, 0.06);
  color: rgba(240, 253, 244, 0.9);
}

.nav-item.active {
  background: var(--bg-sidebar-active);
  color: #ffffff;
  font-weight: 500;
}

.nav-icon {
  font-size: 18px;
  flex-shrink: 0;
}

.nav-text {
  overflow: hidden;
  text-overflow: ellipsis;
}

.sidebar-footer {
  padding: 10px;
  border-top: 1px solid rgba(255, 255, 255, 0.08);
}

.collapse-btn {
  display: flex;
  align-items: center;
  justify-content: center;
  height: 36px;
  border-radius: 8px;
  color: rgba(240, 253, 244, 0.5);
  cursor: pointer;
  transition: all 0.2s ease;
}

.collapse-btn:hover {
  background: rgba(255, 255, 255, 0.06);
  color: rgba(240, 253, 244, 0.9);
}

/* ===== 主区域 ===== */
.main-area {
  flex: 1;
  display: flex;
  flex-direction: column;
  overflow: hidden;
  min-width: 0;
}

/* 顶部栏 */
.topbar {
  height: 60px;
  background: #ffffff;
  border-bottom: 1px solid var(--border-color);
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 0 24px;
  flex-shrink: 0;
}

.topbar-left {
  display: flex;
  align-items: center;
}

.page-name {
  font-size: 17px;
  font-weight: 600;
  color: var(--text-primary);
}

.topbar-right {
  display: flex;
  align-items: center;
  gap: 4px;
}

.icon-btn {
  color: var(--text-secondary);
}

.icon-btn:hover {
  color: var(--primary);
}

.alert-badge :deep(.el-badge__content) {
  background: var(--danger);
}

.user-info {
  display: flex;
  align-items: center;
  gap: 10px;
  cursor: pointer;
  padding: 4px 8px;
  border-radius: 8px;
  transition: background 0.2s ease;
}

.user-info:hover {
  background: #f5f5f5;
}

.user-avatar {
  background: var(--primary);
  color: #ffffff;
  font-weight: 600;
  font-size: 14px;
}

.user-detail {
  display: flex;
  flex-direction: column;
  line-height: 1.3;
}

.user-name {
  font-size: 14px;
  font-weight: 600;
  color: var(--text-primary);
}

.user-role {
  font-size: 12px;
  color: var(--text-tertiary);
}

.arrow-down {
  font-size: 12px;
  color: var(--text-tertiary);
}

.farm-name-edit {
  display: flex;
  align-items: center;
  gap: 8px;
  width: 200px;
}

/* 内容区 */
.content-area {
  flex: 1;
  overflow: hidden;
  background: var(--bg-page);
}
</style>
