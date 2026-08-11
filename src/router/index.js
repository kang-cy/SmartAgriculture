import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/store/user'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('@/views/Login.vue'),
    meta: { title: '登录' },
  },
  {
    path: '/register',
    name: 'Register',
    component: () => import('@/views/Register.vue'),
    meta: { title: '注册' },
  },
  {
    path: '/',
    component: () => import('@/layout/MainLayout.vue'),
    redirect: '/dashboard',
    children: [
      {
        path: 'dashboard',
        name: 'Dashboard',
        component: () => import('@/views/Dashboard.vue'),
        meta: { title: '数据总览', icon: 'Odometer' },
      },
      {
        path: 'monitor',
        name: 'DataMonitor',
        component: () => import('@/views/DataMonitor.vue'),
        meta: { title: '实时监测', icon: 'Monitor' },
      },
      {
        path: 'control',
        name: 'DeviceControl',
        component: () => import('@/views/DeviceControl.vue'),
        meta: { title: '设备控制', icon: 'Setting', roles: ['farmer'] },
      },
      {
        path: 'farm3d',
        name: 'Farm3D',
        component: () => import('@/views/Farm3D.vue'),
        meta: { title: '3D农场', icon: 'View' },
      },
      {
        path: 'alert',
        name: 'AlertManage',
        component: () => import('@/views/AlertManage.vue'),
        meta: { title: '告警管理', icon: 'Bell' },
      },
      {
        path: 'device-bind',
        name: 'DeviceBind',
        component: () => import('@/views/DeviceBind.vue'),
        meta: { title: '设备绑定', icon: 'Connection', roles: ['manager'] },
      },
      {
        path: 'alert-log',
        name: 'AlertLog',
        component: () => import('@/views/AlertLog.vue'),
        meta: { title: '告警日志', icon: 'Document', roles: ['manager'] },
      },
      {
        path: 'ai-chat',
        name: 'AIChat',
        component: () => import('@/views/AIChat.vue'),
        meta: { title: '智能问答', icon: 'ChatDotRound', roles: ['farmer'] },
      },
      {
        path: 'bind-manage',
        name: 'BindManage',
        component: () => import('@/views/BindManage.vue'),
        meta: { title: '绑定管理', icon: 'Link', roles: ['farmer'] },
      },
      {
        path: 'fields',
        name: 'FieldManage',
        component: () => import('@/views/FieldManage.vue'),
        meta: { title: '农田管理', icon: 'Location', roles: ['manager'] },
      },
      {
        path: 'bind-approval',
        name: 'BindApproval',
        component: () => import('@/views/BindApproval.vue'),
        meta: { title: '绑定审批', icon: 'Check', roles: ['manager'] },
      },
    ],
  },
  {
    path: '/:pathMatch(.*)*',
    redirect: '/dashboard',
  },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

router.beforeEach((to, from, next) => {
  document.title = `${to.meta.title || ''} - 智慧农业管理平台`
  const userStore = useUserStore()

  if (to.path === '/login' || to.path === '/register') {
    next()
    return
  }

  if (!userStore.isLoggedIn) {
    next('/login')
    return
  }

  // 角色权限检查
  if (to.meta.roles && !to.meta.roles.includes(userStore.role)) {
    next('/dashboard')
    return
  }

  // 农户无需绑定即可访问所有页面，未绑定时页面显示空数据
  // 绑定管理者后自动显示管理者的农场数据
  next()
})

export default router
