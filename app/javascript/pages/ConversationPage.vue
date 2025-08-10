<template>
  <div class="conversation-page">
    <header class="conv-header">
      <button @click="back" class="back-btn" aria-label="Back to inbox">←</button>

      <!-- show header when we have partner info -->
      <div class="partner-info" v-if="partner">
        <img
          v-if="partner.primaryPhoto"
          :src="partner.primaryPhoto"
          class="header-avatar"
          alt="Partner avatar"
        />
        <div v-else class="header-avatar placeholder-avatar">
          {{ (partner.firstName?.[0] ?? '') + (partner.lastName?.[0] ?? '') }}
        </div>

        <div class="title">
          {{ partner.firstName }} {{ partner.lastName }}
        </div>
      </div>
    </header>

    <main class="messages" ref="scrollContainer" role="log" aria-live="polite">
      <div
        v-for="m in messages"
        :key="m.id"
        :class="['message-row', { me: isMe(m) }]"
      >
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

        <div v-if="isMe(m)" class="me-spacer" />
      </div>
    </main>

    <footer class="composer-area">
      <MessageComposer :toUserId="partnerIdNumber" @sent="onMessageSent" />
    </footer>
  </div>
</template>

<script setup>
import { ref, computed, watch, nextTick, watchEffect } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { useQuery, useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import MessageComposer from '../components/MessageComposer.vue'

const route = useRoute()
const router = useRouter()

const partnerIdRaw = route.params.userId
const partnerIdNumber = Number(partnerIdRaw) // used for conversation query (your backend expects numeric here)

// --- current user ---
const CURRENT_USER_QUERY = gql` query CurrentUser { currentUser { id } }`
const { result: currentUserResult } = useQuery(CURRENT_USER_QUERY, null, { fetchPolicy: 'network-only' })
const myIdNumber = computed(() => {
  const id = currentUserResult.value?.currentUser?.id
  return id != null ? Number(id) : null
})

// --- conversation messages ---
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
const conversationVars = { userId: partnerIdNumber }
const { result, loading, refetch } = useQuery(CONVERSATION_QUERY, conversationVars, { fetchPolicy: 'network-only', pollInterval: 3000 })
const messages = computed(() => (result.value?.conversation ?? []))

// --- inbox query to refetch after marking read ---
const INBOX_QUERY = gql`
  query Inbox {
    inbox {
      lastMessage {
        id
        content
        createdAt
      }
      user {
        id
        firstName
        lastName
        primaryPhoto
      }
      unreadCount
    }
  }
`
const { refetch: refetchInbox } = useQuery(INBOX_QUERY, null, { fetchPolicy: 'network-only' })

// --- matches query fallback ---
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
const { result: matchesResult } = useQuery(MATCHES_QUERY, null, { fetchPolicy: 'network-only' })
const matches = computed(() => matchesResult.value?.matches ?? [])

// --- mutation to mark messages read ---
const MARK_READ_MUTATION = gql`
  mutation MarkConversationRead($userId: ID!) {
    markConversationRead(userId: $userId) {
      markedCount
    }
  }
`
const { mutate: markConversationRead } = useMutation(MARK_READ_MUTATION)

// compute partner by finding in inbox first (conversations), then fallback to matches
const inboxResult = ref(null)
watchEffect(() => {
  inboxResult.value = refetchInbox ? refetchInbox().then(r => r.data) : null
})

const inbox = computed(() => inboxResult.value?.inbox ?? [])

const partner = computed(() => {
  const pid = String(partnerIdRaw)
  // try inbox first (refetched data)
  if (inboxResult.value && inboxResult.value.inbox) {
    const fromInbox = inboxResult.value.inbox.find(c => String(c.user?.id) === pid)?.user
    if (fromInbox) return fromInbox
  }
  // fallback to matches query
  const fromMatches = matches.value.find(m => String(m.id) === pid)
  if (fromMatches) return fromMatches
  return null
})

// scroll behavior
const scrollContainer = ref(null)
watch(messages, async () => {
  await nextTick()
  if (scrollContainer.value) {
    scrollContainer.value.scrollTop = scrollContainer.value.scrollHeight
  }
})

// mark conversation read on partner load
let hasMarkedRead = false
watch(partner, async (p) => {
  if (!p || hasMarkedRead) return
  try {
    await markConversationRead({ userId: partnerIdNumber })
    await refetchInbox()
    await refetch()
    hasMarkedRead = true
  } catch (err) {
    console.error('markConversationRead error', err)
  }
}, { immediate: true })

function isMe(m) {
  const myId = myIdNumber.value
  if (myId == null) return false
  return Number(m.senderId) === myId
}

function back() {
  router.push({ name: 'Messages' })
}

function onMessageSent() {
  refetch().catch(() => {})
}

function formatDate(iso) {
  try {
    return new Date(iso).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
  } catch {
    return ''
  }
}
</script>

<style scoped>
.conversation-page {
  display: flex;
  flex-direction: column;
  height: 85vh;
  max-width: 720px;
  margin: 0 auto;
  background: #fff;
}

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

.partner-info {
  display: flex;
  align-items: center;
  gap: 12px;
}

.header-avatar {
  width: 40px;
  height: 40px;
  border-radius: 50%;
  object-fit: cover;
}

.messages {
  flex: 1;
  min-height: 0;
  overflow-y: auto;
  padding: 16px;
  display: flex;
  flex-direction: column;
  gap: 12px;
  background: #fafafa;
}

.message-row {
  display: flex;
  align-items: flex-end;
  gap: 8px;
  width: 100%;
}

.message-row:not(.me) {
  justify-content: flex-start;
}

.message-row.me {
  justify-content: flex-end;
}

.small-avatar {
  width: 34px;
  height: 34px;
  border-radius: 50%;
  object-fit: cover;
  flex: 0 0 34px;
  box-shadow: 0 1px 3px rgba(0, 0, 0, 0.08);
}

.message-col {
  display: flex;
  flex-direction: column;
  align-items: flex-start;
  max-width: 70%;
}

.message-row.me .message-col {
  align-items: flex-end;
}

.bubble {
  padding: 10px 14px;
  border-radius: 18px;
  background: #e9ecef;
  color: #111;
  box-shadow: 0 2px 6px rgba(0, 0, 0, 0.06);
  word-break: break-word;
  white-space: pre-wrap;
}

.message-row.me .bubble {
  background: #2d8cff;
  color: #fff;
  border-bottom-right-radius: 6px;
}

.ts {
  font-size: 11px;
  color: #8891a6;
  margin-top: 6px;
}

.me-spacer {
  width: 34px;
  flex: 0 0 34px;
}

.composer-area {
  flex: 0 0 auto;
  border-top: 1px solid #eee;
  background: #fff;
  padding: 8px 12px;
}

.placeholder-avatar {
  display: flex;
  align-items: center;
  justify-content: center;
  background: #cbd5e1;
  color: white;
  font-weight: bold;
  font-size: 16px;
  width: 40px;
  height: 40px;
  border-radius: 50%;
}
</style>
