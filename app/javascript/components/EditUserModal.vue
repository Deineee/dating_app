<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-card">
      <button class="close" @click="$emit('close')">×</button>

      <h3>Edit user</h3>

      <div v-if="loading">Loading...</div>
      <div v-else-if="queryError" class="error">{{ queryError.message }}</div>

      <form v-else @submit.prevent="onSubmit" class="form">
        <label>
          First name
          <input v-model="form.firstName" />
        </label>

        <label>
          Last name
          <input v-model="form.lastName" />
        </label>

        <label>
          Email
          <input v-model="form.email" type="email" />
        </label>

        <label>
          Country
          <input v-model="form.country" />
        </label>

        <label>
          State / Region
          <input v-model="form.state" />
        </label>

        <label>
          City
          <input v-model="form.city" />
        </label>

        <label>
          Bio
          <textarea v-model="form.bio" rows="3" />
        </label>

        <div class="actions">
          <button type="button" class="btn cancel" @click="$emit('close')">Cancel</button>
          <button type="submit" class="btn save" :disabled="saving">
            {{ saving ? 'Saving...' : 'Save' }}
          </button>
        </div>

        <div v-if="mutateError" class="error small">{{ mutateError }}</div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onBeforeUnmount } from 'vue'
import { useQuery, useMutation, provideApolloClient } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { apolloClient } from '../src/apollo'

provideApolloClient(apolloClient)

const props = defineProps({
  userId: { type: [String, Number], required: true }
})

const GET_USER = gql`
  query UserDetail($id: ID!) {
    user(id: $id) {
      id
      firstName
      lastName
      email
      bio
      country
      state
      city
    }
  }
`

const UPDATE_USER = gql`
  mutation UpdateUser($id: ID, $input: UpdateUserInput!) {
    updateUser(id: $id, input: $input) {
      user {
        id
        firstName
        lastName
        email
        bio
        country
        state
        city
      }
      errors
    }
  }
`

const variables = ref({ id: null })
const { result, loading, error, stop } = useQuery(GET_USER, variables, { fetchPolicy: 'network-only' })

const form = ref({
  firstName: '',
  lastName: '',
  email: '',
  bio: '',
  country: '',
  state: '',
  city: ''
})

watch(
  () => props.userId,
  (id) => {
    if (id) variables.value.id = id
  },
  { immediate: true }
)

watch(
  () => result.value,
  (r) => {
    const u = r?.user ?? null
    if (u) {
      form.value.firstName = u.firstName ?? ''
      form.value.lastName = u.lastName ?? ''
      form.value.email = u.email ?? ''
      form.value.bio = u.bio ?? ''
      form.value.country = u.country ?? ''
      form.value.state = u.state ?? ''
      form.value.city = u.city ?? ''
    }
  },
  { immediate: true }
)

const { mutate: updateUserMut } = useMutation(UPDATE_USER)
const saving = ref(false)
const mutateError = ref(null)
const queryError = error

async function onSubmit() {
  mutateError.value = null
  saving.value = true

  const input = {
    firstName: form.value.firstName,
    lastName: form.value.lastName,
    email: form.value.email,
    bio: form.value.bio,
    country: form.value.country,
    state: form.value.state,
    city: form.value.city
  }

  try {
    const res = await updateUserMut({
      id: props.userId,
      input
    })

    const data = res?.data?.updateUser
    if (data?.errors && data.errors.length) {
      mutateError.value = data.errors.join(', ')
    } else {
      emitSaved()
    }
  } catch (e) {
    mutateError.value = e.message || 'Save failed'
  } finally {
    saving.value = false
  }
}

const emit = defineEmits(['close', 'saved'])
function emitSaved() {
  emit('saved')
  emit('close')
}

onBeforeUnmount(() => {
  if (typeof stop === 'function') stop()
})
</script>

<style scoped>
.modal-overlay {
  position: fixed; inset: 0; display:flex; align-items:center; justify-content:center;
  background: rgba(0,0,0,0.55); z-index: 1000; padding: 12px;
}
.modal-card {
  width: 100%; max-width: 520px; background:white; border-radius:10px; padding:16px;
  box-shadow: 0 10px 30px rgba(2,6,23,0.2);
}
.close { position:absolute; right:16px; top:12px; border:none; background:transparent; font-size:18px; cursor:pointer; }
.form { display:flex; flex-direction:column; gap:10px; margin-top:8px; }
label { font-size:0.85rem; color:#333; display:flex; flex-direction:column; gap:6px; }
input, textarea { padding:8px 10px; border-radius:6px; border:1px solid #e5e7eb; font-size:0.95rem; }
.actions { display:flex; gap:8px; justify-content:flex-end; margin-top:6px; }
.btn { padding:8px 12px; border-radius:8px; border:none; cursor:pointer; }
.btn.save { background:#2563eb; color:white; }
.btn.cancel { background:#f3f4f6; }
.error { color:#b91c1c; margin-top:8px; }
.small { font-size:0.9rem; }
</style>
