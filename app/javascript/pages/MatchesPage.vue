<template>
  <div class="matches-page">
    <h1 class="title">Your Matches</h1>

    <div v-if="loading" class="loading">Loading matches…</div>

    <div v-else-if="matches.length === 0" class="empty">
      <p>No matches yet — swipe more people to find matches!</p>
    </div>

    <ul v-else class="matches-list">
      <li v-for="m in matches" :key="m.id" class="match-card">
        <img :src="m.primaryPhoto" alt="Primary photo" class="match-photo" />
        <div class="match-info">
            <div class="name">{{ m.firstName }} {{ m.lastName }}</div>
        </div>

        <!-- Message button -->
        <div class="actions">
            <button @click="openConversation(m.id)" class="msg-btn">Message</button>
        </div>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { computed } from 'vue'
import { useRouter } from 'vue-router'
const router = useRouter()

function openConversation(userId) {
  router.push({ name: 'Conversation', params: { userId } })
}

const MATCHES_QUERY = gql`
  query Matches {
    matches {
      id
      firstName
      lastName
      primaryPhoto
    }
  }
`

const { result, loading, error, refetch } = useQuery(MATCHES_QUERY, null, {
  fetchPolicy: 'network-only'
})

// computed array of matches (handles undefined)
const matches = computed(() => (result.value?.matches ?? []))

// optional: handle errors (console/log or show UI)
if (error.value) {
  console.error('Matches query error', error.value)
}
</script>

<style scoped>
.matches-page {
  max-width: 800px;
  margin: 2rem auto;
  padding: 0 1rem;
}

.title {
  font-size: 1.5rem;
  margin-bottom: 1rem;
  text-align: center;
}

.loading,
.empty {
  text-align: center;
  color: #666;
}

.matches-list {
  list-style: none;
  padding: 0;
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(220px, 1fr));
  gap: 1rem;
}

.match-card {
  background: #fff;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0 6px 18px rgba(0,0,0,0.06);
  display: flex;
  align-items: center;
  gap: 0.75rem;
  padding: 0.5rem;
  justify-content: space-between;
  padding-right: 12px;
}

.match-photo {
  width: 72px;
  height: 72px;
  object-fit: cover;
  border-radius: 8px;
  flex-shrink: 0;
}

.match-info .name {
  font-weight: 700;
  font-size: 1rem;
}

.actions { display:flex; align-items:center; gap:8px; }

.msg-btn {
  background: #2d8cff;
  color: white;
  border: none;
  padding: 6px 10px;
  border-radius: 6px;
  cursor: pointer;
}
.msg-btn:hover { background: #1b6fe6; }

</style>
