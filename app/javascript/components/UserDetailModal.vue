<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <button class="close" @click="$emit('close')">×</button>

      <div v-if="loading">Loading...</div>
      <div v-else-if="error">{{ error.message }}</div>

      <div v-else-if="user">
        <img
          :src="user.primaryPhoto || placeholderImage"
          alt="Primary"
          width="150"
          style="border-radius: 8px; object-fit: cover;"
        />

        <div class="gallery" v-if="user.photos && user.photos.length">
          <img
            v-for="photo in user.photos"
            :key="photo"
            :src="photo"
            alt="User photo"
            width="70"
            style="border-radius: 4px; object-fit: cover;"
          />
        </div>

        <h2>{{ user.firstName }} {{ user.lastName }}</h2>

        <p><strong>Location:</strong> {{ user.country }}, {{ user.state }}, {{ user.city }}</p>
        <p><strong>Bio:</strong> {{ user.bio }}</p>

        <h3>Matches</h3>
        <ul>
          <li v-for="match in user.matches" :key="match.id">
            {{ match.firstName }} {{ match.lastName }}
          </li>
          <li v-if="!user.matches.length">No matches found.</li>
        </ul>
      </div>

      <div v-else>
        <p>User not found.</p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, watch, onBeforeUnmount } from 'vue'
import { useQuery, provideApolloClient } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { apolloClient } from '../src/apollo'

provideApolloClient(apolloClient)

const props = defineProps({
  userId: [String, Number],
})

const placeholderImage = 'https://via.placeholder.com/150?text=No+Photo'

const USER_DETAIL_QUERY = gql`
  query UserDetail($id: ID!) {
    user(id: $id) {
      id
      firstName
      lastName
      primaryPhoto
      photos
      country
      state
      city
      bio
      matches {
        id
        firstName
        lastName
      }
    }
  }
`

const user = ref(null)
const variables = ref({ id: null })

// Query runs automatically when variables change
const { result, loading, error, stop } = useQuery(
  USER_DETAIL_QUERY,
  variables,
  { fetchPolicy: 'network-only' }
)

// Update variables when prop changes (this triggers the query)
watch(
  () => props.userId,
  (id) => {
    if (id) {
      variables.value.id = id
      console.log('[UserDetailModal] fetching user id =', id)
    } else {
      user.value = null
    }
  },
  { immediate: true }
)

// IMPORTANT: clone the payload before mutating
watch(
  () => result.value,
  (r) => {
    const payload = r ?? null
    const raw = payload?.user ?? null

    if (raw) {
      // shallow clone + ensure arrays are real arrays (not readonly proxies)
      const cloned = {
        ...raw,
        photos: Array.isArray(raw.photos) ? [...raw.photos] : [],
        matches: Array.isArray(raw.matches) ? [...raw.matches] : []
      }
      user.value = cloned
    } else {
      user.value = null
    }
  },
  { immediate: true }
)

// watch the error ref for query errors
watch(
  () => error.value,
  (e) => {
    if (e) {
      console.error('[UserDetailModal] GraphQL error:', e)
    }
  }
)

onBeforeUnmount(() => {
  if (typeof stop === 'function') stop()
})
</script>


<style scoped>
.modal-overlay {
  position: fixed;
  top: 0; left: 0; right: 0; bottom: 0;
  background: rgba(0,0,0,0.6);
  display: flex; justify-content: center; align-items: center;
  z-index: 1000;
}

.modal-content {
  background: white;
  padding: 20px;
  border-radius: 8px;
  max-width: 600px;
  width: 100%;
  position: relative;
  box-shadow: 0 8px 20px rgba(0,0,0,0.2);
}

.close {
  position: absolute;
  top: 10px; right: 10px;
  font-size: 24px;
  cursor: pointer;
  background: transparent;
  border: none;
}

.gallery {
  margin: 12px 0;
  display: flex;
  gap: 8px;
}
</style>
