import { createRouter, createWebHistory } from 'vue-router'
import Home from '../pages/Home.vue'
import SignIn from '../pages/SignIn.vue'
import SignUp from '../pages/SignUp.vue'
import SwipePage from '../pages/SwipePage.vue'
import { useAuth } from './composables/useAuth' 

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

const { isLoggedIn } = useAuth()

router.beforeEach((to, from, next) => {
  const authenticated = isLoggedIn()  // check localStorage token

  if (to.path === '/swipe' && !authenticated) {
    next('/signin')
  } else {
    next()
  }
})

export default router
