import { createRouter, createWebHistory } from 'vue-router'
import LandingPage from '../pages/LandingPage.vue'
import SignIn from '../pages/SignIn.vue'
import SignUp from '../pages/SignUp.vue'
import SwipePage from '../pages/SwipePage.vue'
import MatchesPage from '../pages/MatchesPage.vue'
import ProfilePage from '../pages/ProfilePage.vue'
import { useAuth } from './composables/useAuth'
import SuperAdminUsers from '../pages/SuperAdminUsers.vue'

const routes = [
  { path: '/', name: 'Landing', component: LandingPage },
  { path: '/signin', name: 'SignIn', component: SignIn },
  { path: '/signup', name: 'SignUp', component: SignUp },
  { path: '/swipe', name: 'Swipe', component: SwipePage },
  { path: '/matches', name: 'Matches', component: MatchesPage },
  { path: '/profile', name: 'Profile', component: ProfilePage },
  { path: '/messages', name: 'Messages', component: () => import('../pages/InboxPage.vue') },
  { path: '/messages/:userId', name: 'Conversation', component: () => import('../pages/ConversationPage.vue') },
  { path: '/superadminusers', name: 'SuperAdminUsers', component: SuperAdminUsers },
]

const router = createRouter({
  history: createWebHistory(),
  routes,
})

const { isLoggedIn } = useAuth()

router.beforeEach((to, from, next) => {
  const authenticated = isLoggedIn()

  // protect swipe, matches, and messages routes
  if (
    ['Swipe', 'Matches', 'Messages', 'Conversation', 'Profile', 'SuperAdminUsers'].includes(to.name) &&
    !authenticated
  ) {
    return next({ name: 'SignIn' })
  }

  next()
})

export default router
