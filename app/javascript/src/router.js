import { createRouter, createWebHistory } from 'vue-router'
import LandingPage from '../pages/LandingPage.vue'
import SignIn from '../pages/SignIn.vue'
import SignUp from '../pages/SignUp.vue'
import SwipePage from '../pages/SwipePage.vue'
import MatchesPage from '../pages/MatchesPage.vue'
import { useAuth } from './composables/useAuth'

const routes = [
  { path: '/', name: 'Landing', component: LandingPage },
  { path: '/signin', name: 'SignIn', component: SignIn },
  { path: '/signup', name: 'SignUp', component: SignUp },
  { path: '/swipe', name: 'Swipe', component: SwipePage },
  { path: '/matches', name: 'Matches', component: MatchesPage }
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

const { isLoggedIn } = useAuth()

router.beforeEach((to, from, next) => {
  const authenticated = isLoggedIn()

  // protect swipe and matches
  if ((to.name === 'Swipe' || to.name === 'Matches') && !authenticated) {
    return next({ name: 'SignIn' })
  }

  next()
})

export default router
