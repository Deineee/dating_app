<template>
  <div
    class="swipe-card"
    :style="cardStyle"
    @mousedown="startDrag"
    @touchstart="startDrag"
    @mousemove="onDrag"
    @touchmove="onDrag"
    @mouseup="endDrag"
    @mouseleave="endDrag"
    @touchend="endDrag"
  >
    <div class="primary-photo">
      <img :src="profile.primaryPhoto" alt="Primary Photo" />
    </div>

    <div class="photo-gallery">
      <img
        v-for="(photo, index) in profile.photos"
        :key="index"
        :src="photo"
        class="gallery-photo"
        alt="Gallery"
      />
    </div>

    <div class="profile-info">
      <h2>{{ profile.firstName }} {{ profile.lastName }}</h2>
      <p class="location">{{ profile.country }}, {{ profile.state }}, {{ profile.city }}</p>
      <p class="bio">{{ profile.bio }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'

const props = defineProps({
  profile: { type: Object, required: true }
})
const emits = defineEmits(['like', 'dislike'])

const startX = ref(0)
const offsetX = ref(0)
const isDragging = ref(false)

function startDrag(e) {
  isDragging.value = true
  startX.value = e.type.includes('mouse') ? e.clientX : e.touches[0].clientX
}

function onDrag(e) {
  if (!isDragging.value) return
  const currentX = e.type.includes('mouse') ? e.clientX : e.touches[0].clientX
  offsetX.value = currentX - startX.value
}

function endDrag() {
  if (!isDragging.value) return
  isDragging.value = false

  if (offsetX.value > 100) {
    emits('like', props.profile.id)
  } else if (offsetX.value < -100) {
    emits('dislike', props.profile.id)
  }

  offsetX.value = 0
}

// Card transform + edge color effect
const cardStyle = computed(() => {
  let backgroundEffect = ''
  if (offsetX.value > 0) {
    // Swipe right → pink glow on right edge
    backgroundEffect = `linear-gradient(to right, transparent, rgba(255, 192, 203, ${Math.min(offsetX.value / 200, 0.5)}))`
  } else if (offsetX.value < 0) {
    // Swipe left → blue glow on left edge
    backgroundEffect = `linear-gradient(to left, transparent, rgba(135, 206, 250, ${Math.min(Math.abs(offsetX.value) / 200, 0.5)}))`
  }

  return {
    transform: `translateX(${offsetX.value}px) rotate(${offsetX.value / 20}deg)`,
    transition: isDragging.value ? 'none' : 'transform 0.3s ease',
    background: backgroundEffect || 'white'
  }
})
</script>

<style scoped>
.swipe-card {
  width: 400px;       /* fixed card width */
  height: 550px;      /* fixed card height */
  margin: auto;
  border-radius: 10px;
  overflow: hidden;   /* ensures image doesn't spill */
  display: flex;
  flex-direction: column;
  background: white;
  box-shadow: 0 4px 15px rgba(0, 0, 0, 0.1);
}

.primary-photo img {
  width: 100%;
  height: 70%;        /* takes up top portion of card */
  object-fit: cover;  /* crops without stretching */
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
}

.bio {
  font-size: 0.95rem;
}
</style>