<template>
  <div>
    <LoadingSpinner v-if="loading || !isAuthenticated" />

    <SwipeCard
      v-else-if="currentProfile"
      :profile="currentProfile"
      @like="likeProfile"
      @dislike="dislikeProfile"
    />

    <div v-else class="no-profiles">
      <p>No more profiles to show.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useQuery, useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useAuth } from '../src/composables/useAuth'
import LoadingSpinner from '../components/shared/LoadingSpinner.vue'
import SwipeCard from '../components/SwipeCard.vue'

// Declare queries and mutations first!
const MATCHING_PROFILES_QUERY = gql`
  query {
    matchingProfiles {
      id
      firstName
      lastName
      country
      state
      city
      bio
      photos
      primaryPhoto
    }
  }
`

const LIKE_USER_MUTATION = gql`
  mutation LikeUser($input: LikeUserInput!) {
    likeUser(input: $input) {
      success
    }
  }
`

const DISLIKE_USER_MUTATION = gql`
  mutation DislikeUser($input: DislikeUserInput!) {
    dislikeUser(input: $input) {
      success
    }
  }
`

const { isAuthenticated } = useAuth()
const enabled = ref(false)
const { result, loading } = useQuery(MATCHING_PROFILES_QUERY, null, { enabled })
const { mutate: likeUser } = useMutation(LIKE_USER_MUTATION)
const { mutate: dislikeUser } = useMutation(DISLIKE_USER_MUTATION)

const profiles = ref([])
const currentIndex = ref(0)

watch(result, (newResult) => {
  if (newResult?.matchingProfiles) {
    profiles.value = newResult.matchingProfiles
    currentIndex.value = 0
  }
})

watch(() => isAuthenticated.value, (loggedIn) => {
  if (loggedIn) enabled.value = true
}, { immediate: true })

const currentProfile = computed(() => profiles.value[currentIndex.value] || null)

async function likeProfile(userId) {
  await likeUser({ input: { userId } })
  nextProfile()
}

async function dislikeProfile(userId) {
  await dislikeUser({ input: { userId } })
  nextProfile()
}

function nextProfile() {
  currentIndex.value++
}

</script>

<style scoped>
.no-profiles {
  text-align: center;
  font-size: 1.2rem;
  color: #999;
  margin-top: 2rem;
}
</style>