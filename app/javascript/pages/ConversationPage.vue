<template>
  <div class="conversation-page">
    <header class="conv-header">
      <button @click="back" class="back-btn" aria-label="Back to inbox">←</button>

      <div class="partner-info">
        <img :src="partner?.primaryPhoto" class="header-avatar" v-if="partner" alt="Partner avatar" />
        <div class="title">{{ partner?.firstName }} {{ partner?.lastName }}</div>
      </div>
    </header>

    <!-- messages area: only this scrolls -->
    <main class="messages" ref="scrollContainer" role="log" aria-live="polite">
      <div
        v-for="m in messages"
        :key="m.id"
        :class="['message-row', { me: isMe(m) }]"
      >
        <!-- partner avatar on left messages -->
        <img
          v-if="!isMe(m) && partner"
          :src="partner.primaryPhoto"
          class="small-avatar"
          alt="Partner avatar"
        />

        <div class="message-col">
          <div class="bubble">{{ m.content }}</div>
          <div class="ts">{{ formatDate(m.createdAt) }}</div>
        </div>

        <!-- spacer or your avatar (optional) -->
        <div v-if="isMe(m)" class="me-spacer" />
      </div>
    </main>

    <!-- composer (fixed part of the layout, not overlapping scroll) -->
    <footer class="composer-area">
      <!-- pass a Number to toUserId to avoid prop warnings -->
      <MessageComposer :toUserId="partnerIdNumber" @sent="onMessageSent" />
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import MessageComposer from '../components/MessageComposer.vue'

const route = useRoute()
const router = useRouter()

// route param comes in as string; convert to Number for consistent typing
const partnerIdNumber = Number(route.params.userId)

// Query current user from server (more reliable than localStorage)
const CURRENT_USER_QUERY = gql`
  query CurrentUser {
    currentUser {
      id
    }
  }
`

const { result: currentUserResult } = useQuery(CURRENT_USER_QUERY, null, { fetchPolicy: 'network-only' })

// wait for currentUser; fallback to null if not available
const myIdNumber = computed(() => {
  const id = currentUserResult.value?.currentUser?.id
  return id != null ? Number(id) : null
})

// conversation query
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

const { result, loading, refetch } = useQuery(
  CONVERSATION_QUERY,
  { userId: partnerIdNumber },
  { fetchPolicy: 'network-only', pollInterval: 3000 }
)

const messages = computed(() => (result.value?.conversation ?? []))

// simple partner info query (can reuse your existing user data if you have)
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
const { result: userResult } = useQuery(USER_QUERY, { id: partnerIdNumber }, { fetchPolicy: 'network-only' })
const partner = computed(() => userResult.value?.node ?? null)

// scroll behavior
const scrollContainer = ref(null)
watch(messages, async () => {
  await nextTick()
  if (scrollContainer.value) {
    scrollContainer.value.scrollTop = scrollContainer.value.scrollHeight
  }
})

// compare numeric ids (avoid mixing strings/numbers)
function isMe(m) {
  const myId = myIdNumber.value
  if (myId == null) return false
  return Number(m.senderId) === myId
}

function back() {
  router.push({ name: 'Messages' })
}

function onMessageSent() {
  // refetch conversation after send; parent composer emits 'sent' so we refresh.
  refetch().catch(() => {})
}

// small util
function formatDate(iso) {
  try {
    return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  } catch {
    return ''
  }
}
</script>

<style scoped>
/* root should take full viewport and arrange header / messages / composer */
.conversation-page {
  height: 100vh;
  display: flex;
  flex-direction: column;
  max-width: 720px;
  margin: 0 auto;
  background: #fff;
}

/* header (not scrollable) */
.conv-header {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 12px;
  background: #f8fafc;
  border-bottom: 1px solid #e6e9ee;
  flex: 0 0 auto;
}
.back-btn {
  font-size: 20px;
  background: transparent;
  border: none;
  cursor: pointer;
  padding: 6px;
}
.partner-info { display:flex; align-items:center; gap:12px; }
.header-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
}

/* messages area: only this scrolls */
.messages {
  flex: 1 1 auto;       /* take remaining space */
  overflow-y: auto;     /* only this scrolls */
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  background: #fafafa;
}

/* message row layout */
.message-row {
  display: flex;
  align-items: flex-end;
  gap: 8px;
  width: 100%;
}

/* partner messages align to left */
.message-row:not(.me) {
  justify-content: flex-start;
}

/* my messages align to right */
.message-row.me {
  justify-content: flex-end;
}

/* small avatar for partner left-side messages */
.small-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  object-fit: cover;
  flex: 0 0 34px;
  box-shadow: 0 1px 3px rgba(0,0,0,0.08);
}

/* message column wrapper */
.message-col {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  max-width: 70%;
}

/* align my message bubble to the right */
.message-row.me .message-col {
  align-items: flex-end;
}

/* bubble styling */
.bubble {
  padding: 10px 14px;
  border-radius: 18px;
  background: #e9ecef;
  color: #111;
  box-shadow: 0 2px 6px rgba(0,0,0,0.06);
  word-break: break-word;
  white-space: pre-wrap;
}

/* my bubble color */
.message-row.me .bubble {
  background: #2d8cff;
  color: #fff;
  border-bottom-right-radius: 6px;
}

/* timestamp */
.ts {
  font-size: 11px;
  color: #8891a6;
  margin-top: 6px;
}

/* spacer keeps layout tidy on right side */
.me-spacer {
  width: 34px;
  flex: 0 0 34px;
}

/* composer area (fixed height) */
.composer-area {
  flex: 0 0 auto;
  border-top: 1px solid #eee;
  background: #fff;
  padding: 8px 12px;
}
</style>
