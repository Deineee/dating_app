<script setup>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useMutation, useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useAuth } from '../../src/composables/useAuth'
import '../../stylesheets/header.css'
import { apolloClient } from '../../src/apollo'

const router = useRouter()
const route = useRoute()
const { isAuthenticated: authRef, logout } = useAuth()
const isAuthenticated = computed(() => authRef.value)

// Routes where we show the "Home" link
const authRoutes = ['Swipe', 'Matches', 'Messages', 'Conversation', 'Profile']

// detect admin pages where we want a compact admin header
const isAdminSection = computed(() =>
  ['SuperAdminUsers', 'MatchesManager'].includes(route.name)
)

// Sign out mutation
const SIGN_OUT_MUTATION = gql`
  mutation SignOut($input: SignOutInput!) {
    signOut(input: $input)
  }
`
const { mutate: signOut } = useMutation(SIGN_OUT_MUTATION)

// Logout handler
const handleLogout = async () => {
  try {
    await signOut({ input: {} })
  } catch (error) {
    console.error('Logout failed:', error)
  } finally {
    try { localStorage.removeItem('auth_token') } catch {}
    try { localStorage.removeItem('currentUser') } catch {}
    try { localStorage.clear() } catch {}
    logout()

    try {
      await apolloClient.clearStore()
    } catch (err) {
      console.warn('Failed to clear Apollo store', err)
    }

    router.push({ name: 'Landing' })
  }
}

const showHomeLink = computed(() => {
  return isAuthenticated.value && authRoutes.includes(route.name)
})

const CURRENT_USER_QUERY = gql`
  query CurrentUser {
    currentUser {
      id
      firstName
      lastName
      primaryPhoto
      role
    }
  }
`
const { result: currentUserResult } = useQuery(CURRENT_USER_QUERY, null, { fetchPolicy: 'network-only', pollInterval: 3000 })
const currentUser = computed(() => currentUserResult.value?.currentUser ?? null)

function goToProfile() {
  router.push({ name: 'Profile' })
}
function goToDashboard() {
  router.push({ name: 'SuperAdminUsers' })
}
function goToMatchesManager() {
  router.push({ name: 'MatchesManager' })
}
</script>

<template>
  <header class="header">
    <div class="header-inner">
      <!-- Admin header (Dashboard + Matches Manager + Logout) -->
      <template v-if="isAuthenticated && isAdminSection">
        <nav class="nav-left">
          <ul>
            <li><button class="nav-link" @click="goToDashboard">Dashboard</button></li>
            <li><button class="nav-link" @click="goToMatchesManager">Matches Manager</button></li>
            <li><button class="nav-link" @click="handleLogout">Logout</button></li>
          </ul>
        </nav>

        <div class="nav-right">
          <button class="profile-button" @click="goToProfile"
                  :title="currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : 'Profile'">
            <img
              v-if="currentUser?.primaryPhoto"
              :src="currentUser.primaryPhoto"
              alt="Your avatar"
              class="header-avatar"
            />
            <div v-else class="header-avatar placeholder">
              {{ (currentUser?.firstName?.[0] ?? '') + (currentUser?.lastName?.[0] ?? '') }}
            </div>
          </button>
        </div>
      </template>

      <!-- Normal header -->
      <template v-else>
        <nav class="nav-left">
          <ul>
            <li v-if="!isAuthenticated"><router-link class="nav-link" to="/signin">Sign In</router-link></li>
            <li v-if="!isAuthenticated"><router-link class="nav-link" to="/signup">Sign Up</router-link></li>

            <li v-if="showHomeLink"><router-link class="nav-link" :to="{ name: 'Swipe' }">Home</router-link></li>
            <li v-if="isAuthenticated"><router-link class="nav-link" to="/matches">Matches</router-link></li>
            <li v-if="isAuthenticated"><router-link class="nav-link" to="/messages">Inbox</router-link></li>
            <li v-if="isAuthenticated">
              <button @click="handleLogout" class="nav-link logout-button">Logout</button>
            </li>
          </ul>
        </nav>

        <div class="nav-right" v-if="isAuthenticated">
          <button class="profile-button" @click="goToProfile"
            :title="currentUser ? `${currentUser.firstName} ${currentUser.lastName}` : 'Profile'">
            <img
              v-if="currentUser?.primaryPhoto"
              :src="currentUser.primaryPhoto"
              alt="Your avatar"
              class="header-avatar"
            />
            <div v-else class="header-avatar placeholder">
              {{ (currentUser?.firstName?.[0] ?? '') + (currentUser?.lastName?.[0] ?? '') }}
            </div>
          </button>
        </div>
      </template>
    </div>
  </header>
</template>

<style scoped>
/* Nav container and list styling */
.nav-left ul {
  list-style: none;
  padding: 0;
  margin: 0;
  display: flex;
  gap: 12px;
  align-items: center;
}

/* Unified nav-link button and router-link styles */
.nav-link,
.link-like,
.logout-button {
  background: transparent;
  border: none;
  color: #1f2937;
  cursor: pointer;
  font-size: 1rem;
  font-weight: 500;
  padding: 6px 12px;
  border-radius: 6px;
  transition: background-color 0.2s ease;
  text-decoration: none;
}

.nav-link:hover,
.link-like:hover,
.logout-button:hover,
.nav-link:focus,
.link-like:focus,
.logout-button:focus {
  background-color: rgba(0, 0, 0, 0.05);
  outline: none;
}

/* Remove underline from router-links */
.nav-link.router-link-exact-active {
  font-weight: 600;
  color: #111827;
}

/* Profile avatar */
.header-avatar {
  width: 40px;
  height: 40px;
  border-radius: 9999px;
  object-fit: cover;
  border: 2px solid transparent;
  transition: border-color 0.2s ease;
}

.header-avatar:hover,
.profile-button:hover .header-avatar {
  border-color: #2563eb; /* Tailwind blue-600 */
}

/* Placeholder avatar */
.header-avatar.placeholder {
  display: flex;
  align-items: center;
  justify-content: center;
  background: #e5e7eb;
  color: #374151;
  font-weight: 700;
  font-size: 1rem;
  user-select: none;
}

/* Profile button */
.profile-button {
  background: transparent;
  border: none;
  padding: 0;
  cursor: pointer;
  display: inline-flex;
  align-items: center;
}

/* Responsive tweaks */
@media (max-width: 600px) {
  .nav-left ul {
    flex-wrap: wrap;
    gap: 8px;
  }
  .header-avatar {
    width: 32px;
    height: 32px;
  }
}
</style>
