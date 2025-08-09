import { ref } from 'vue'

// reactive ref to track if user is logged in
const isAuthenticated = ref(!!localStorage.getItem('auth_token'))

// function to log user in
function login(token) {
  localStorage.setItem('auth_token', token)
  isAuthenticated.value = true
}

// function to log user out
function logout() {
  localStorage.removeItem('auth_token')
  isAuthenticated.value = false
}

export function useAuth() {
  return {
    isAuthenticated,
    login,
    logout,
  }
}
