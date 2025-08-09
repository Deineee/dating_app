<script setup>
import { computed } from 'vue'
import { useRouter } from 'vue-router'
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useAuth } from '../../src/composables/useAuth' 
import '../../stylesheets/header.css'

const router = useRouter()
const { isAuthenticated: authRef, logout } = useAuth()

// unwrap the ref with a computed
const isAuthenticated = computed(() => authRef.value)

const SIGN_OUT_MUTATION = gql`
  mutation SignOut($input: SignOutInput!) {
    signOut(input: $input)
  }
`

const { mutate: signOut } = useMutation(SIGN_OUT_MUTATION)

const handleLogout = async () => {
  try {
    await signOut({ input: {} }) 
    // Clear all auth-related data from localStorage
    localStorage.removeItem('auth_token')
    localStorage.removeItem('currentUser')

    logout()  // update your reactive auth state as well
    router.push('/')
  } catch (error) {
    console.error('Logout failed:', error)
  }
}
</script>

<template>
  <header class="header">
    <nav>
      <ul>
        <li><router-link to="/">Home</router-link></li>
        <li v-if="!isAuthenticated"><router-link to="/signin">Sign In</router-link></li>
        <li v-if="!isAuthenticated"><router-link to="/signup">Sign Up</router-link></li>
        <li v-if="isAuthenticated">
          <button @click="handleLogout" class="logout-button">Logout</button>
        </li>
      </ul>
    </nav>
  </header>
</template>
