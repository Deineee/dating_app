<template>
  <div class="inbox-page">
    <h1>Your Messages</h1>

    <div v-if="loading">Loading conversations…</div>

    <div v-else-if="conversations.length === 0">
      <p>No conversations yet. Matches appear here when you message them.</p>
    </div>

    <ul class="convo-list">
      <li v-for="c in conversations" :key="c.user.id" @click="openConv(c.user.id)" class="convo-item">
        <img :src="c.user.primaryPhoto" alt="photo" class="avatar" />
        <div class="meta">
          <div class="name">{{ c.user.firstName }} {{ c.user.lastName }}</div>
          <div class="excerpt">{{ c.lastMessage.content.slice(0, 80) }}</div>
        </div>
        <div class="unread" v-if="c.unread_count > 0">{{ c.unread_count }}</div>
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

const { result, loading, refetch } = useQuery(INBOX_QUERY, null, { fetchPolicy: 'network-only' })

const conversations = computed(() => (result.value?.inbox ?? []))

function openConv(userId) {
  router.push({ name: 'Conversation', params: { userId } })
}
</script>

<style scoped>
.convo-list { list-style: none; padding: 0; display: grid; gap: 8px; }
.convo-item { display:flex; gap: 10px; align-items:center; padding:8px; cursor:pointer; background:#fff; border-radius:8px;}
.avatar { width:56px; height:56px; object-fit:cover; border-radius:8px; }
.meta .name { font-weight:700 }
.excerpt { color:#666; font-size:13px; overflow:hidden }
.unread { background:#e63a4e;color:white;padding:4px 8px;border-radius:12px }
</style>
