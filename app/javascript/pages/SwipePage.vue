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

const { result, loading, refetch } = useQuery(
  MATCHING_PROFILES_QUERY,
  null,
  { enabled, fetchPolicy: 'network-only' }
)

const { mutate: likeUser } = useMutation(LIKE_USER_MUTATION)
const { mutate: dislikeUser } = useMutation(DISLIKE_USER_MUTATION)

const profiles = ref([])
const currentIndex = ref(0)

// When query result changes, replace profiles and reset index
watch(result, (newResult) => {
  if (newResult?.matchingProfiles) {
    profiles.value = newResult.matchingProfiles
    currentIndex.value = 0
  } else {
    // if result is empty, clear
    profiles.value = []
    currentIndex.value = 0
  }
})

// Watch auth changes and ensure fresh fetch on login, clear on logout
watch(
  () => isAuthenticated.value,
  async (loggedIn) => {
    if (loggedIn) {
      // enable query and refetch to make sure we have the latest profiles
      enabled.value = true
      // if refetch is available, request fresh data
      if (typeof refetch === 'function') {
        try {
          await refetch()
        } catch (err) {
          // optional: handle error/log
          console.warn('Refetch matchingProfiles failed', err)
        }
      }
    } else {
      // on logout: disable query and clear local profiles so old card won't show
      enabled.value = false
      profiles.value = []
      currentIndex.value = 0
    }
  },
  { immediate: true }
)

const currentProfile = computed(() => profiles.value[currentIndex.value] || null)

async function likeProfile(userId) {
  try {
    await likeUser({ input: { userId } })
  } catch (err) {
    console.warn('likeUser error', err)
  } finally {
    nextProfile()
  }
}

async function dislikeProfile(userId) {
  try {
    await dislikeUser({ input: { userId } })
  } catch (err) {
    console.warn('dislikeUser error', err)
  } finally {
    nextProfile()
  }
}

function nextProfile() {
  currentIndex.value = currentIndex.value + 1
  // guard to prevent index overflow (optional)
  if (currentIndex.value >= profiles.value.length) {
    // reset/clear so UI shows "No more profiles"
    currentIndex.value = 0
    profiles.value = []
  }
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