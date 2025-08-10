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

const { result, loading, error } = useQuery(MATCHES_QUERY, null, {
  fetchPolicy: 'network-only',
})

const matches = computed(() => result.value?.matches ?? [])

if (error.value) {
  console.error('Matches query error', error.value)
}
</script>

<style scoped>
.matches-page {
  max-width: 900px;
  margin: 3rem auto;
  padding: 0 1.5rem;
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Oxygen,
    Ubuntu, Cantarell, "Open Sans", "Helvetica Neue", sans-serif;
  background: #f9fafb;
  border-radius: 12px;
  box-shadow: 0 8px 20px rgba(0, 0, 0, 0.05);
  padding-bottom: 2rem;
}

.title {
  font-size: 2rem;
  margin-bottom: 1.5rem;
  text-align: center;
  color: #222;
  font-weight: 700;
  letter-spacing: 0.03em;
}

.loading,
.empty {
  text-align: center;
  color: #777;
  font-size: 1.2rem;
  margin-top: 2rem;
}

.matches-list {
  list-style: none;
  padding: 0;
  margin: 0 auto;
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(280px, 1fr));
  gap: 1.25rem;
}

.match-card {
  background: white;
  border-radius: 14px;
  overflow: hidden;
  box-shadow: 0 10px 25px rgba(0, 0, 0, 0.08);
  display: flex;
  align-items: center;
  gap: 1.25rem;
  padding: 1rem 1.25rem;
  justify-content: space-between;
  transition: transform 0.15s ease, box-shadow 0.15s ease;
  cursor: pointer;
}

.match-card:hover {
  box-shadow: 0 14px 40px rgba(0, 0, 0, 0.15);
  transform: translateY(-3px);
}

.match-photo {
  width: 100px;
  height: 100px;
  object-fit: cover;
  border-radius: 16px;
  flex-shrink: 0;
  box-shadow: 0 4px 12px rgba(0, 0, 0, 0.1);
}

.match-info {
  flex-grow: 1;
  text-align: left;
}

.match-info .name {
  font-weight: 800;
  font-size: 1.3rem;
  color: #1a1a1a;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.actions {
  display: flex;
  align-items: center;
}

.msg-btn {
  background-color: #2d8cff;
  color: white;
  border: none;
  padding: 10px 18px;
  border-radius: 8px;
  font-weight: 700;
  font-size: 1rem;
  transition: background-color 0.3s ease;
  user-select: none;
}

.msg-btn:hover {
  background-color: #1b6fe6;
}

@media (max-width: 480px) {
  .matches-list {
    grid-template-columns: 1fr;
  }
  .match-card {
    padding: 1rem;
    gap: 1rem;
  }
  .match-photo {
    width: 80px;
    height: 80px;
  }
  .match-info .name {
    font-size: 1.1rem;
  }
  .msg-btn {
    padding: 8px 14px;
    font-size: 0.9rem;
  }
}
</style>
