import axios from 'axios'
import { useUserStore } from '@/store/user'

const service = axios.create({
  baseURL: '/api',
  timeout: 10000,
})

// 请求拦截器 - 发送用户身份信息
service.interceptors.request.use(
  (config) => {
    const userStore = useUserStore()
    if (userStore.token) {
      config.headers['Authorization'] = `Bearer ${userStore.token}`
    }
    // 发送用户身份信息到后端
    if (userStore.userId) {
      config.headers['X-User-Id'] = userStore.userId
    }
    if (userStore.role) {
      config.headers['X-User-Role'] = userStore.role
    }
    if (userStore.username) {
      config.headers['X-Username'] = userStore.username
    }
    return config
  },
  (error) => Promise.reject(error)
)

// 响应拦截器 - 静默处理错误，不弹toast
service.interceptors.response.use(
  (response) => {
    const res = response.data
    if (res.code && res.code !== 200) {
      // 业务错误：静默拒绝，不弹toast
      return Promise.reject(new Error(res.message || 'Error'))
    }
    return res
  },
  (error) => {
    // 网络错误：静默拒绝，不弹toast，页面显示空白
    return Promise.reject(error)
  }
)

export default service
