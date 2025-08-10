<template>
  <form class="composer" @submit.prevent="send">
    <input v-model="text" placeholder="Type a message..." />
    <button type="submit" :disabled="sending || !text.trim()">Send</button>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'

const props = defineProps({ toUserId: { type: Number, required: true } })
const emit = defineEmits(['sent'])

const SEND_MESSAGE = gql`
mutation SendMessage($receiverId: ID!, $content: String!) {
  sendMessage(input: { receiverId: $receiverId, content: $content }) {
    message {
      id
      content
      senderId
      receiverId
      createdAt
    }
    errors
  }
}
`

const { mutate: sendMessage } = useMutation(SEND_MESSAGE)
const text = ref('')
const sending = ref(false)

async function send() {
  if (!text.value.trim()) return
  sending.value = true
  try {
    const { data } = await sendMessage({ receiverId: props.toUserId, content: text.value })
    if (data.sendMessage.errors.length) {
      // handle errors
      console.error(data.sendMessage.errors)
    } else {
      emit('sent', data.sendMessage.message)
      text.value = ''
    }
  } catch (err) {
    console.error(err)
  } finally {
    sending.value = false
  }
}
</script>

<style scoped>
.composer { display:flex; gap:8px; padding:12px; background:#fff; }
.composer input { flex:1; padding:8px 10px; border-radius:8px; border:1px solid #ddd }
.composer button { padding:8px 12px; border-radius:8px; background:#2d8cff; color:#fff; border:none }
</style>
