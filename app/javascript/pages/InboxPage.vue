<template>
  <div class="inbox-page">
    <h1>Your Messages</h1>

    <div v-if="loading" class="loading">Loading conversations…</div>

    <div v-else-if="conversations.length === 0" class="empty">
      <p>No conversations yet. Matches appear here when you message them.</p>
    </div>

    <ul class="convo-list">
      <li
        v-for="c in conversations"
        :key="c.user.id"
        @click="openConv(c.user.id)"
        class="convo-item"
        tabindex="0"
        role="button"
        @keyup.enter="openConv(c.user.id)"
      >
        <img :src="c.user.primaryPhoto" alt="photo" class="avatar" />
        <div class="meta">
          <div class="name">{{ c.user.firstName }} {{ c.user.lastName }}</div>
          <div class="excerpt">{{ c.lastMessage.content.slice(0, 80) }}</div>
        </div>
        <div class="unread" v-if="c.unreadCount > 0">{{ c.unreadCount }}</div>
      </li>
    </ul>
  </div>
</template>

<script setup>
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useRouter } from 'vue-router'
import { computed } from 'vue'

const router = useRouter()

const INBOX_QUERY = gql`
  query Inbox {
    inbox {
      user {
        id
        firstName
        lastName
        primaryPhoto
      }
      lastMessage {
        id
        content
        createdAt
        senderId
        receiverId
      }
      unreadCount
    }
  }
`

const { result, loading, refetch } = useQuery(INBOX_QUERY, null, {
  fetchPolicy: 'network-only',
  pollInterval: 3000 // 3 seconds
})


const conversations = computed(() => result.value?.inbox ?? [])

function openConv(userId) {
  router.push({ name: 'Conversation', params: { userId } })
}
</script>

<style scoped>
.inbox-page {
  max-width: 600px;
  margin: 40px auto;
  padding: 0 16px;
  text-align: center;
  font-family: "Segoe UI", Tahoma, Geneva, Verdana, sans-serif;
}

h1 {
  margin-bottom: 24px;
  font-weight: 700;
  font-size: 28px;
  color: #222;
}

.loading,
.empty p {
  font-size: 16px;
  color: #555;
  margin-top: 24px;
}

.convo-list {
  list-style: none;
  padding: 0;
  margin: 0 auto;
  display: flex;
  flex-direction: column;
  gap: 16px;
  max-width: 100%;
}

.convo-item {
  display: flex;
  gap: 16px;
  align-items: center;
  padding: 14px 20px;
  cursor: pointer;
  background: #fff;
  border-radius: 12px;
  box-shadow: 0 2px 8px rgb(0 0 0 / 0.1);
  transition: box-shadow 0.2s ease, transform 0.1s ease;
  user-select: none;
}

.convo-item:focus,
.convo-item:hover {
  box-shadow: 0 4px 16px rgb(0 0 0 / 0.15);
  transform: translateY(-2px);
  outline: none;
}

.avatar {
  width: 72px;
  height: 72px;
  object-fit: cover;
  border-radius: 16px;
  flex-shrink: 0;
  box-shadow: 0 2px 6px rgba(0,0,0,0.15);
}

.meta {
  flex-grow: 1;
  text-align: left;
}

.meta .name {
  font-weight: 700;
  font-size: 20px;
  color: #111;
  margin-bottom: 6px;
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}

.excerpt {
  color: #666;
  font-size: 15px;
  line-height: 1.2;
  max-height: 2.4em; /* about 2 lines */
  overflow: hidden;
  text-overflow: ellipsis;
}

.unread {
  background: #e63a4e;
  color: white;
  padding: 6px 12px;
  border-radius: 20px;
  font-weight: 700;
  font-size: 14px;
  min-width: 28px;
  text-align: center;
  user-select: none;
}
</style>
