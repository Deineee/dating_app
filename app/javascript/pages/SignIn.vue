<template>
  <form class="sign-in-form" @submit.prevent="onSubmit">
    <input v-model="email" type="email" placeholder="Email" required />
    <input v-model="password" type="password" placeholder="Password" required />
    <button type="submit">Sign In</button>

    <p v-if="errors.length" style="color:red;">
      <span v-for="err in errors" :key="err">{{ err }}</span>
    </p>
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

    // redirect based on role
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

