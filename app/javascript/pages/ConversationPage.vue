<template>
  <div class="conversation-page">
    <header class="conv-header">
      <button @click="back" class="back-btn">←</button>
      <img :src="partner?.primaryPhoto" class="avatar" v-if="partner" />
      <div class="title">{{ partner?.firstName }} {{ partner?.lastName }}</div>
    </header>

    <div class="messages" ref="scrollContainer">
      <div
        v-for="m in messages"
        :key="m.id"
        :class="['message', { me: m.senderId === myId }]"
      >
        <div class="bubble">{{ m.content }}</div>
        <div class="ts">{{ new Date(m.createdAt).toLocaleString() }}</div>
      </div>
    </div>

    <MessageComposer :toUserId="partnerId" @sent="onMessageSent" />
  </div>
</template>

<script setup>
import { ref, computed, watch, onMounted, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import MessageComposer from '../components/MessageComposer.vue'

const route = useRoute()
const router = useRouter()
const partnerId = Number(route.params.userId)
const myId = Number(localStorage.getItem('currentUserId')) // or get from auth composable

const CONVERSATION_QUERY = gql`
  query Conversation($userId: ID!) {
    conversation(userId: $userId) {
      id
      content
      senderId
      receiverId
      createdAt
    }
  }
`

const { result, loading, refetch } = useQuery(CONVERSATION_QUERY, { userId: partnerId }, { fetchPolicy: 'network-only', pollInterval: 3000 })

const messages = computed(() => (result.value?.conversation ?? []))

const partner = ref(null)
onMounted(async () => {
  const USER_QUERY = gql`
    query User($id: ID!) {
      node(id: $id) {
        ... on User {
          id
          firstName
          lastName
          primaryPhoto
        }
      }
    }
  `
  // You can use your Apollo client or useQuery here to fetch partner info (omitted for brevity)
})

const scrollContainer = ref(null)
watch(messages, async () => {
  await nextTick()
  if (scrollContainer.value) {
    scrollContainer.value.scrollTop = scrollContainer.value.scrollHeight
  }
})

function back() {
  router.push({ name: 'Messages' })
}

function onMessageSent(newMsg) {
  refetch()
}
</script>

<style scoped>
.conversation-page {
  max-width: 720px;
  margin: 1rem auto;
  display: flex;
  flex-direction: column;
  height: calc(100vh - 40px);
}

.conv-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f8fafc;
  border-bottom: 1px solid #ddd;
}

.back-btn {
  font-size: 24px;
  background: transparent;
  border: none;
  cursor: pointer;
  user-select: none;
}

.avatar {
  width: 40px;
  height: 40px;
  border-radius: 8px;
  object-fit: cover;
}

.title {
  font-weight: 700;
  font-size: 1.2rem;
}

.messages {
  flex: 1;
  overflow-y: auto;
  padding: 12px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  background: #fafafa;
}

.message {
  max-width: 70%;
  align-self: flex-start;
  display: flex;
  flex-direction: column;
  align-items: flex-start;
}

.message.me {
  align-self: flex-end;
  align-items: flex-end;
}

.bubble {
  padding: 10px 16px;
  border-radius: 20px;
  background: #e5e5ea;
  color: #000;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
  white-space: pre-wrap;
  word-break: break-word;
}

.message.me .bubble {
  background: #2d8cff;
  color: #fff;
  border-bottom-right-radius: 4px;
  border-bottom-left-radius: 20px;
  border-top-right-radius: 20px;
  border-top-left-radius: 20px;
}

.ts {
  font-size: 10px;
  color: #888;
  margin-top: 4px;
  user-select: none;
}
</style>
