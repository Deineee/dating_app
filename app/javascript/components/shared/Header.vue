<script setup>
import { computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useAuth } from '../../src/composables/useAuth'
import '../../stylesheets/header.css'
import { apolloClient } from '../../src/apollo' //


const router = useRouter()
const route = useRoute()
const { isAuthenticated: authRef, logout } = useAuth()
const isAuthenticated = computed(() => authRef.value)
const authRoutes = ['Swipe', 'Matches']

const SIGN_OUT_MUTATION = gql`
  mutation SignOut($input: SignOutInput!) {
    signOut(input: $input)
  }
`

const { mutate: signOut } = useMutation(SIGN_OUT_MUTATION)

const handleLogout = async () => {
  try {
    await signOut({ input: {} })
  } catch (error) {
    console.error('Logout failed:', error)
  } finally {
    // clear token + local data
    localStorage.removeItem('auth_token')
    localStorage.removeItem('currentUser')
    logout()

    // clear Apollo cache (do NOT resetStore here)
    try {
      await apolloClient.clearStore()
    } catch (err) {
      console.warn('Failed to clear Apollo store', err)
    }

    // redirect to landing
    router.push({ name: 'Landing' })
  }
}

const showHomeLink = computed(() => {
  return isAuthenticated.value && authRoutes.includes(route.name)
})
</script>

<template>
  <header class="header">
    <nav>
      <ul>
        <li v-if="!isAuthenticated"><router-link to="/signin">Sign In</router-link></li>
        <li v-if="!isAuthenticated"><router-link to="/signup">Sign Up</router-link></li>

        <!-- Home link visible only when on the Swipe route AND authenticated -->
        <li v-if="showHomeLink"><router-link :to="{ name: 'Swipe' }">Home</router-link></li>

        <!-- Matches link for authenticated users -->
        <li v-if="isAuthenticated"><router-link to="/matches">Matches</router-link></li>

        <!-- Logout button -->
        <li v-if="isAuthenticated">
          <button @click="handleLogout" class="logout-button">Logout</button>
        </li>
      </ul>
    </nav>
  </header>
</template>
