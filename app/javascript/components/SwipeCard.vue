<template>
  <div
    class="swipe-card"
    :style="cardStyle"
    @mousedown="startDrag"
    @touchstart="startDrag"
  >
    <!-- Photo area (fills entire card) -->
    <div class="primary-photo">
      <img :src="currentPhoto" alt="Primary Photo" />
      <!-- Left / Right arrows -->
      <button
        class="arrow left"
        @mousedown.stop
        @touchstart.stop
        @click.prevent="prevPhoto"
        aria-label="Previous photo"
        :disabled="photosToShow.length <= 1"
      >
        ‹
      </button>

      <button
        class="arrow right"
        @mousedown.stop
        @touchstart.stop
        @click.prevent="nextPhoto"
        aria-label="Next photo"
        :disabled="photosToShow.length <= 1"
      >
        ›
      </button>

      <!-- Dots indicator -->
      <div class="dots" v-if="photosToShow.length > 1">
        <span
          v-for="(p, i) in photosToShow"
          :key="i"
          :class="['dot', { active: i === photoIndex }]"
        />
      </div>
    </div>

    <!-- Bottom info overlay -->
    <div class="profile-info">
      <div class="meta">
        <h2 class="name">{{ profile.firstName }} {{ profile.lastName }}</h2>
        <p class="location">{{ profile.country }}, {{ profile.state }}, {{ profile.city }}</p>
      </div>
      <p class="bio">{{ profile.bio }}</p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'

const props = defineProps({
  profile: { type: Object, required: true }
})
const emits = defineEmits(['like', 'dislike'])

/* drag/swipe state (keeps your existing swipe behavior) */
const startX = ref(0)
const offsetX = ref(0)
const isDragging = ref(false)

function startDrag(e) {
  isDragging.value = true
  startX.value = e.type.includes('mouse') ? e.clientX : e.touches[0].clientX

  // Add global event listeners
  window.addEventListener('mousemove', onDrag)
  window.addEventListener('touchmove', onDrag, { passive: false })
  window.addEventListener('mouseup', endDrag)
  window.addEventListener('touchend', endDrag)
}

function onDrag(e) {
  if (!isDragging.value) return

  // Prevent scrolling on touch drag
  if (e.type === 'touchmove') e.preventDefault()

  const currentX = e.type.includes('mouse') ? e.clientX : e.touches[0].clientX
  let diff = currentX - startX.value
  offsetX.value = Math.min(Math.max(diff, -300), 300)
}

function endDrag() {
  if (!isDragging.value) return
  isDragging.value = false

  // Remove global event listeners
  window.removeEventListener('mousemove', onDrag)
  window.removeEventListener('touchmove', onDrag)
  window.removeEventListener('mouseup', endDrag)
  window.removeEventListener('touchend', endDrag)

  if (offsetX.value > 100) {
    emits('like', props.profile.id)
  } else if (offsetX.value < -100) {
    emits('dislike', props.profile.id)
  }

  offsetX.value = 0
}

/* card transform + glow effect */
const cardStyle = computed(() => {
  let glowColor = ''
  let glowStrength = Math.min(Math.abs(offsetX.value) / 50, 1) // max 1

  if (offsetX.value > 0) {
    // swipe right → pink glow
    glowColor = `rgba(255, 105, 180, ${glowStrength})` // hot pink
  } else if (offsetX.value < 0) {
    // swipe left → blue glow
    glowColor = `rgba(30, 144, 255, ${glowStrength})` // dodger blue
  }

  return {
    transform: `translateX(${offsetX.value}px) rotate(${offsetX.value / 20}deg)`,
    transition: isDragging.value ? 'none' : 'transform 0.3s ease, box-shadow 0.2s ease',
    boxShadow: glowColor
      ? `0 0 20px ${glowColor}, 0 0 40px ${glowColor}`
      : '0 4px 20px rgba(0,0,0,0.12)',
    background: 'white',
    borderRadius: '20px'
  }
})

/* Photo browsing state */
const photoIndex = ref(0)

const photosToShow = computed(() => {
  // ensure primary photo is the first item and avoid duplicate
  const primary = props.profile.primaryPhoto ? [props.profile.primaryPhoto] : []
  const others = Array.isArray(props.profile.photos) ? props.profile.photos.filter(p => p && p !== props.profile.primaryPhoto) : []
  return primary.concat(others)
})

const currentPhoto = computed(() => photosToShow.value[photoIndex.value] || '')

function prevPhoto() {
  if (photosToShow.value.length <= 1) return
  photoIndex.value = (photoIndex.value - 1 + photosToShow.value.length) % photosToShow.value.length
}

function nextPhoto() {
  if (photosToShow.value.length <= 1) return
  photoIndex.value = (photoIndex.value + 1) % photosToShow.value.length
}

/* reset photo index whenever profile changes (important when new user login) */
watch(() => props.profile, () => {
  photoIndex.value = 0
}, { immediate: true })
</script>

<style scoped>
.swipe-card {
  width: 400px;
  height: 550px;
  margin: auto;
  border-radius: 10px;
  overflow: hidden;
  position: relative;
  background: #fff;
  box-shadow: 0 4px 20px rgba(0,0,0,0.12);
  display: block;
  user-select: none;
}

/* Primary photo fills entire card */
.primary-photo {
  position: relative;
  width: 100%;
  height: 100%;
  background: #eee;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Show the image to fill the full card height, centered horizontally */
.primary-photo img {
  height: 100%;
  width: auto;
  object-fit: cover;
  display: block;
  pointer-events: none;
}

/* Arrow buttons */
.arrow {
  position: absolute;
  top: 50%;
  transform: translateY(-50%);
  width: 44px;
  height: 44px;
  border-radius: 50%;
  border: none;
  background: rgba(0,0,0,0.35);
  color: #fff;
  font-size: 26px;
  line-height: 1;
  display: flex;
  align-items: center;
  justify-content: center;
  cursor: pointer;
  z-index: 20;
  transition: background 0.12s ease;
  -webkit-tap-highlight-color: transparent;
}

.arrow:hover { background: rgba(0,0,0,0.5); }
.arrow:disabled { opacity: 0.45; cursor: default; }

.arrow.left { left: 12px; }
.arrow.right { right: 12px; }

/* Dots indicator (center bottom of image) */
.dots {
  position: absolute;
  left: 50%;
  transform: translateX(-50%);
  bottom: 92px; /* sits above the info overlay */
  display: flex;
  gap: 6px;
  z-index: 20;
}

.dot {
  width: 8px;
  height: 8px;
  border-radius: 50%;
  background: rgba(255,255,255,0.45);
  transition: transform 0.12s ease, background 0.12s ease;
}
.dot.active { background: rgba(255,255,255,0.95); transform: scale(1.2); }

/* profile info overlay at bottom (semi-transparent gradient) */
.profile-info {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  padding: 14px 16px;
  box-sizing: border-box;
  z-index: 30;
  color: #fff;
  background: linear-gradient(to top, rgba(0,0,0,0.65), rgba(0,0,0,0.18) 40%, transparent 100%);
}

.profile-info .meta {
  display: flex;
  align-items: baseline;
  gap: 8px;
  justify-content: space-between;
}

.name {
  font-size: 18px;
  margin: 0;
  font-weight: 700;
}

.location {
  font-size: 13px;
  margin: 0;
  color: rgba(255,255,255,0.9);
}

.bio {
  margin-top: 6px;
  font-size: 13px;
  color: rgba(255,255,255,0.95);
  max-height: 48px;
  overflow: hidden;
  text-overflow: ellipsis;
}

/* small screens tweak */
@media (max-width: 460px) {
  .swipe-card { width: 320px; height: 440px; }
  .arrow { width: 36px; height: 36px; }
  .dots { bottom: 72px; }
}
</style>
