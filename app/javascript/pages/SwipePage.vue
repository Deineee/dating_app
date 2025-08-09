<template>
  <div class="swipe-page">
    <div v-if="currentProfile" class="profile-card">
      <div class="primary-photo">
        <img :src="currentProfile.primaryPhoto" alt="Primary Photo" />
      </div>
      
      <div class="photo-gallery">
        <img 
          v-for="(photo, index) in currentProfile.photos" 
          :key="index" 
          :src="photo" 
          alt="Gallery Photo"
          class="gallery-photo"
        />
      </div>

      <div class="profile-info">
        <h2>{{ currentProfile.firstName }} {{ currentProfile.lastName }}</h2>
        <p class="location">{{ currentProfile.country }}, {{ currentProfile.state }}, {{ currentProfile.city }}</p>
        <p class="bio">{{ currentProfile.bio }}</p>
      </div>

      <div class="actions">
        <button @click="dislikeProfile">Dislike</button>
        <button @click="likeProfile">Like</button>
      </div>
    </div>

    <div v-else class="no-profiles">
      <p>No more profiles to show.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useQuery, useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'

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

// Now use them
const { result, loading, error } = useQuery(MATCHING_PROFILES_QUERY)
const { mutate: likeUser } = useMutation(LIKE_USER_MUTATION)
const { mutate: dislikeUser } = useMutation(DISLIKE_USER_MUTATION)

const profiles = ref([])
const currentIndex = ref(0)

watch(result, (newResult) => {
  if (newResult && newResult.matchingProfiles) {
    profiles.value = newResult.matchingProfiles
    currentIndex.value = 0
  }
})

const currentProfile = computed(() => profiles.value[currentIndex.value] || null)

async function likeProfile() {
  if (!currentProfile.value) return
  await likeUser({ input: { userId: currentProfile.value.id } })
  nextProfile()
}

async function dislikeProfile() {
  if (!currentProfile.value) return
  await dislikeUser({ input: { userId: currentProfile.value.id } })
  nextProfile()
}

function nextProfile() {
  if (currentIndex.value < profiles.value.length - 1) {
    currentIndex.value++
  } else {
    currentIndex.value = null
  }
}
</script>


<style>
.swipe-page {
  max-width: 400px;
  margin: 1rem auto;
  border: 1px solid #ccc;
  padding: 1rem;
  font-family: Arial, sans-serif;
}

.primary-photo img {
  width: 100%;
  height: auto;
  border-radius: 8px;
}

.photo-gallery {
  display: flex;
  gap: 0.5rem;
  margin-top: 0.5rem;
  overflow-x: auto;
}

.gallery-photo {
  width: 60px;
  height: 60px;
  object-fit: cover;
  border-radius: 4px;
}

.profile-info {
  margin-top: 1rem;
}

.location {
  font-size: 0.9rem;
  color: #666;
  margin-top: -0.5rem;
  margin-bottom: 0.5rem;
}

.bio {
  font-size: 0.95rem;
  line-height: 1.3;
}

.actions {
  margin-top: 1rem;
  display: flex;
  justify-content: space-around;
}

.actions button {
  padding: 0.5rem 1rem;
  font-size: 1rem;
  cursor: pointer;
  border: 1px solid #888;
  background: #f0f0f0;
  border-radius: 4px;
  transition: background-color 0.2s ease;
}

.actions button:hover {
  background: #ddd;
}

.no-profiles {
  text-align: center;
  font-size: 1.2rem;
  color: #999;
  margin-top: 2rem;
}
</style>
