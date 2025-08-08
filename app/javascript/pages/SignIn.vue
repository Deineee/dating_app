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


const SIGN_IN_MUTATION = gql`
  mutation SignIn($input: SignInInput!) {
    signIn(input: $input) {
      user {
        id
        email
      }
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
    } else {
      alert(`Signed in as ${data.signIn.user.email}`)
      // Store user info, maybe redirect, or set auth state here
    }
  } catch (e) {
    errors.value = [e.message]
  }
}
</script>
