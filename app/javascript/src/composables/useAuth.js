import { ref } from 'vue'

// reactive ref to track if user is logged in
const isAuthenticated = ref(!!localStorage.getItem('auth_token'))

function login(token) {
  localStorage.setItem('auth_token', token)
  isAuthenticated.value = true
}

function logout() {
  localStorage.removeItem('auth_token')
  isAuthenticated.value = false
}

// helper to check localStorage directly (non-reactive)
function isLoggedIn() {
  return !!localStorage.getItem('auth_token')
}

export function useAuth() {
  return {
    isAuthenticated,
    login,
    logout,
    isLoggedIn,
  }
}
