// javascript/router/index.js
import { createRouter, createWebHistory } from 'vue-router'
import Home from '../pages/Home.vue'
import SignIn from '../pages/SignIn.vue'
import SignUp from '../pages/SignUp.vue'
import SwipePage from '../pages/SwipePage.vue'

const routes = [
  { path: '/', component: Home },
  { path: '/signin', component: SignIn },
  { path: '/signup', component: SignUp },
  { path: '/swipe', component: SwipePage },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

// Navigation guard to protect /swipe
router.beforeEach((to, from, next) => {
  const isAuthenticated = !!localStorage.getItem('currentUser')

  if (to.path === '/swipe' && !isAuthenticated) {
    next('/signin')
  } else {
    next()
  }
})

export default router
