<template>
  <div class="modal-overlay" @click.self="$emit('close')">
    <div class="modal-content">
      <button class="close" @click="$emit('close')">×</button>

      <div v-if="loading" class="loading">Loading...</div>
      <div v-else-if="error" class="error">{{ error.message }}</div>

      <div v-else-if="user">
        <!-- Primary Photo -->
        <div class="primary-photo">
          <img
            :src="user.primaryPhoto || placeholderImage"
            alt="Primary"
          />
        </div>

        <!-- Gallery excluding primary photo -->
        <div
          class="gallery"
          v-if="user.photos && user.photos.length > 1"
        >
          <img
            v-for="photo in user.photos.filter(p => p !== user.primaryPhoto)"
            :key="photo"
            :src="photo"
            alt="User photo"
          />
        </div>

        <div class="user-info">
          <h2>{{ user.firstName }} {{ user.lastName }}</h2>
          <p class="location">
            📍 {{ user.country }}, {{ user.state }}, {{ user.city }}
          </p>
          <p class="bio">{{ user.bio }}</p>
        </div>

        <div class="matches">
          <h3>Matches</h3>
          <ul>
            <li v-for="match in user.matches" :key="match.id">
              {{ match.firstName }} {{ match.lastName }}
            </li>
            <li v-if="!user.matches.length" class="empty">No matches found.</li>
          </ul>
        </div>
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
  padding: 24px;
  border-radius: 12px;
  max-width: 640px;
  width: 100%;
  position: relative;
  box-shadow: 0 8px 24px rgba(0,0,0,0.25);
  overflow-y: auto;
  max-height: 90vh;
}

.close {
  position: absolute;
  top: 12px; right: 12px;
  font-size: 26px;
  cursor: pointer;
  background: transparent;
  border: none;
  color: #555;
}

.loading, .error {
  text-align: center;
  padding: 20px;
}

.primary-photo {
  display: flex;
  justify-content: center;
  margin-bottom: 16px;
}

.primary-photo img {
  width: 180px;
  height: 180px;
  border-radius: 12px;
  object-fit: cover;
  box-shadow: 0 4px 10px rgba(0,0,0,0.15);
}

.gallery {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(70px, 1fr));
  gap: 8px;
  margin-bottom: 16px;
}

.gallery img {
  width: 100%;
  height: 70px;
  object-fit: cover;
  border-radius: 6px;
  box-shadow: 0 2px 6px rgba(0,0,0,0.1);
}

.user-info {
  text-align: center;
  margin-bottom: 20px;
}

.user-info h2 {
  margin-bottom: 4px;
  font-size: 1.4rem;
}

.location {
  color: #666;
  font-size: 0.9rem;
  margin-bottom: 8px;
}

.bio {
  font-size: 1rem;
  line-height: 1.4;
}

.matches h3 {
  margin-bottom: 8px;
}

.matches ul {
  list-style: none;
  padding: 0;
  margin: 0;
}

.matches li {
  padding: 6px 0;
  border-bottom: 1px solid #eee;
}

.matches li.empty {
  color: #888;
  font-style: italic;
  border: none;
}
</style>