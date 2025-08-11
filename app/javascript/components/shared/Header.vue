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

// detect Super Admin page
const isSuperAdminUsersPage = computed(() => route.name === 'SuperAdminUsers')

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
    // clear local storage and auth state
    try { localStorage.removeItem('auth_token') } catch {}
    try { localStorage.removeItem('currentUser') } catch {}
    try { localStorage.clear() } catch {}
    logout()

    // clear apollo cache
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

// fetch current user so we can display avatar
const CURRENT_USER_QUERY = gql`
  query CurrentUser {
    currentUser {
      id
      firstName
      lastName
      primaryPhoto
    }
  }
`
const { result: currentUserResult } = useQuery(CURRENT_USER_QUERY, null, { fetchPolicy: 'network-only' })
const currentUser = computed(() => currentUserResult.value?.currentUser ?? null)

function goToProfile() {
  router.push({ name: 'Profile' })
}
</script>

<template>
  <header class="header">
    <div class="header-inner">
      <!-- SuperAdminUsers minimal header -->
      <template v-if="isAuthenticated && isSuperAdminUsersPage">
        <nav class="nav-left">
          <ul>
            <!-- special Matches Manager link for superadmin -->
            <li><router-link to="/matches">Matches Manager</router-link></li>
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
            <li v-if="!isAuthenticated"><router-link to="/signin">Sign In</router-link></li>
            <li v-if="!isAuthenticated"><router-link to="/signup">Sign Up</router-link></li>

            <li v-if="showHomeLink"><router-link :to="{ name: 'Swipe' }">Home</router-link></li>
            <li v-if="isAuthenticated"><router-link to="/matches">Matches</router-link></li>
            <li v-if="isAuthenticated"><router-link to="/messages">Inbox</router-link></li>
            <li v-if="isAuthenticated">
              <button @click="handleLogout" class="logout-button">Logout</button>
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
