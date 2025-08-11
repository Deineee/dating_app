<template>
  <form class="sign-in-form" @submit.prevent="onSubmit" novalidate>
    <div class="title">Login</div>
    <input
      v-model="email"
      type="email"
      placeholder="Email"
      required
      autocomplete="email"
      aria-label="Email"
    />
    <input
      v-model="password"
      type="password"
      placeholder="Password"
      required
      autocomplete="current-password"
      aria-label="Password"
    />
    <button type="submit">Sign In</button>

    <ul v-if="errors.length" class="error-list" role="alert" aria-live="assertive">
      <li v-for="err in errors" :key="err">{{ err }}</li>
    </ul>
  </form>
</template>

<script setup>
import '../stylesheets/sign_in.css'
import { ref } from 'vue'
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useRouter } from 'vue-router'
import { useAuth } from '../src/composables/useAuth'
import { apolloClient } from '../src/apollo'      

const { login } = useAuth()
const router = useRouter() 

const SIGN_IN_MUTATION = gql`
  mutation SignIn($input: SignInInput!) {
    signIn(input: $input) {
      user { id email role }
      token
      errors
    }
  }
`

const email = ref('')
const password = ref('')
const errors = ref([])

const { mutate: signIn } = useMutation(SIGN_IN_MUTATION)

const onSubmit = async () => {
  errors.value = []
  try {
    const { data } = await signIn({
      input: {
        email: email.value,
        password: password.value,
      },
    })

    if (data.signIn.errors.length) {
      errors.value = data.signIn.errors
      return
    }

    login(data.signIn.token)

    try {
      await apolloClient.resetStore()
    } catch (err) {
      console.warn('apollo resetStore failed', err)
      try { await apolloClient.clearStore() } catch (_) {}
    }

    const userRole = data.signIn.user.role

    if (userRole === 'admin') {
      router.push('/superadminusers')
    } else {
      router.push('/swipe')
    }
  } catch (e) {
    errors.value = [e.message]
  }
}
</script>

<style scoped>
.sign-in-form {
  max-width: 360px;
  margin: 3rem auto;
  padding: 2rem 2.5rem;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 6px 18px rgba(0, 0, 0, 0.1);
  display: flex;
  flex-direction: column;
  gap: 1.2rem;
  font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
}

.sign-in-form input {
  padding: 12px 14px;
  border: 1.8px solid #ccc;
  border-radius: 8px;
  font-size: 1rem;
  transition: border-color 0.25s ease;
}

.sign-in-form input:focus {
  border-color: #4a90e2;
  outline: none;
  box-shadow: 0 0 6px rgba(74, 144, 226, 0.5);
}

.sign-in-form button {
  background-color: #4a90e2;
  color: white;
  font-weight: 600;
  padding: 12px 0;
  border: none;
  border-radius: 8px;
  font-size: 1.1rem;
  cursor: pointer;
  transition: background-color 0.3s ease;
}

.sign-in-form button:hover,
.sign-in-form button:focus {
  background-color: #357abd;
  outline: none;
}

.error-list {
  margin-top: 0;
  padding-left: 1.25rem;
  color: #d93025; /* Google red error color */
  font-weight: 600;
  list-style-type: disc;
}

.error-list li + li {
  margin-top: 0.25rem;
}

.title {
  grid-column: 1 / -1;
  text-align: center;
  font-size: 1.5rem;
  margin-bottom: 0.5rem;
  color: #333;
  font-weight: bold;
}
</style>
