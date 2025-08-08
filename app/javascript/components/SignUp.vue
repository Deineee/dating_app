<template>
  <form class="sign-up-form" @submit.prevent="onSubmit">
    <input v-model="email" type="email" placeholder="Email" required />
    <input v-model="password" type="password" placeholder="Password" required />
    <input v-model="passwordConfirmation" type="password" placeholder="Confirm Password" required />
    <button type="submit">Sign Up</button>

    <p v-if="errors.length" style="color:red;">
      <span v-for="err in errors" :key="err">{{ err }}</span>
    </p>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'

const SIGN_UP_MUTATION = gql`
  mutation SignUp($input: SignUpInput!) {
    signUp(input: $input) {
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
const passwordConfirmation = ref('')
const errors = ref([])

const { mutate: signUp } = useMutation(SIGN_UP_MUTATION)

const onSubmit = async () => {
  errors.value = []
  try {
    const { data } = await signUp({
      input: {
        email: email.value,
        password: password.value,
        passwordConfirmation: passwordConfirmation.value,
      },
    })

    if (data.signUp.errors.length) {
      errors.value = data.signUp.errors
    } else {
      alert(`Signed up as ${data.signUp.user.email}`)
      // optionally redirect or clear form here
    }
  } catch (e) {
    errors.value = [e.message]
  }
}
</script>
