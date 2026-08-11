import { defineStore } from 'pinia'
import { ref, computed } from 'vue'

export const useUserStore = defineStore('user', () => {
  const token = ref(localStorage.getItem('sa_token') || '')
  const role = ref(localStorage.getItem('sa_role') || '')
  const username = ref(localStorage.getItem('sa_username') || '')
  const userId = ref(localStorage.getItem('sa_userId') || '')
  const farmName = ref(localStorage.getItem('sa_farmName') || '')

  const isLoggedIn = computed(() => !!token.value)
  const isFarmer = computed(() => role.value === 'farmer')
  const isManager = computed(() => role.value === 'manager')

  function setUser(data) {
    token.value = data.token
    role.value = data.role
    username.value = data.username
    userId.value = data.userId
    farmName.value = data.farmName || ''

    localStorage.setItem('sa_token', data.token)
    localStorage.setItem('sa_role', data.role)
    localStorage.setItem('sa_username', data.username)
    localStorage.setItem('sa_userId', data.userId)
    if (data.farmName) {
      localStorage.setItem('sa_farmName', data.farmName)
    }
  }

  function logout() {
    token.value = ''
    role.value = ''
    username.value = ''
    userId.value = ''
    farmName.value = ''

    localStorage.removeItem('sa_token')
    localStorage.removeItem('sa_role')
    localStorage.removeItem('sa_username')
    localStorage.removeItem('sa_userId')
    localStorage.removeItem('sa_farmName')
  }

  return {
    token,
    role,
    username,
    userId,
    farmName,
    isLoggedIn,
    isFarmer,
    isManager,
    setUser,
    logout,
  }
})
