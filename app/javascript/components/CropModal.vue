<template>
  <div class="cropper-modal" role="dialog" aria-modal="true">
    <div class="modal-card">
      <!-- fixed area that matches swipe card -->
      <div class="cropper-area">
        <!-- image element used by Cropper -->
        <img ref="cropperImage" :src="imageSrc" alt="Crop preview" />
      </div>

      <!-- zoom slider (connected to cropper.zoomTo) -->
      <input
        ref="zoomSlider"
        type="range"
        min="0.1"
        max="3"
        step="0.01"
        value="1"
        @input="onZoomInput"
        aria-label="Zoom"
      />

      <div class="cropper-actions">
        <button type="button" @click="$emit('confirm')">Crop & Save</button>
        <button type="button" class="cancel" @click="$emit('cancel')">Cancel</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount, watch, nextTick } from 'vue'
import Cropper from 'cropperjs'
import 'cropperjs/dist/cropper.css'

// props from parent (signup.vue passes croppingImage here)
const props = defineProps({
  imageSrc: { type: String, required: true },
  // keep aspectRatio configurable but defaults to your swipe card ratio
  aspectRatio: { type: Number, default: 400 / 550 }
})
const emit = defineEmits(['confirm', 'cancel', 'ready'])

const cropperImage = ref(null)   // template ref for <img>
const zoomSlider = ref(null)     // template ref for slider
const cropper = ref(null)        // store Cropper instance

const CROP_W = 400
const CROP_H = 550

function initCropper() {
  // require the image element and a source
  if (!cropperImage.value || !props.imageSrc) return

  // destroy old instance if present
  if (cropper.value) {
    cropper.value.destroy()
    cropper.value = null
  }

  // Create new Cropper instance
  cropper.value = new Cropper(cropperImage.value, {
    aspectRatio: props.aspectRatio,
    viewMode: 1,
    dragMode: 'move',
    movable: true,
    zoomable: true,
    zoomOnWheel: true,
    cropBoxMovable: false,
    cropBoxResizable: false,
    background: false,
    autoCrop: true,
    responsive: true,
    ready() {
      const cp = cropper.value
      if (!cp) return

      // Auto-zoom so the image at least covers the target crop area
      try {
        const imageData = cp.getImageData()
        // compute minimal ratio so the natural image covers the crop area
        const needRatio = Math.max(
          CROP_W / imageData.naturalWidth,
          CROP_H / imageData.naturalHeight,
          1 // don't zoom out below 1 unless you want to
        )

        // zoom the image to the computed ratio
        cp.zoomTo(needRatio)

        // small delay to let Cropper recalculate after zoom
        setTimeout(() => {
          try {
            // center & set crop box to the fixed size inside the container
            const containerData = cp.getContainerData()
            const left = containerData.left + Math.max(0, (containerData.width - CROP_W) / 2)
            const top = containerData.top + Math.max(0, (containerData.height - CROP_H) / 2)

            cp.setCropBoxData({ left, top, width: CROP_W, height: CROP_H })
          } catch (err) {
            // ignore failures but proceed
          }

          // update slider with current zoom ratio if slider exists
          if (zoomSlider.value) {
            // event.detail.ratio isn't available here; use imageData.width vs naturalWidth
            const currentImageData = cp.getImageData()
            const currentRatio = (currentImageData.width / currentImageData.naturalWidth) || 1
            zoomSlider.value.value = Number(currentRatio).toFixed(2)
          }

          // let parent know cropper is ready and hand over the instance
          emit('ready', cp)
        }, 60)
      } catch (e) {
        emit('ready', cp)
      }
    },

    // update slider when zoom happens (mouse wheel or programmatic)
    zoom(event) {
      if (zoomSlider.value && event && event.detail && typeof event.detail.ratio === 'number') {
        zoomSlider.value.value = Number(event.detail.ratio).toFixed(2)
      }
    }
  })
}

function onZoomInput(e) {
  const val = parseFloat(e.target.value)
  if (cropper.value && !Number.isNaN(val)) {
    cropper.value.zoomTo(val)
  }
}

// watch for the parent passing a new image source
watch(
  () => props.imageSrc,
  async (newSrc) => {
    if (!newSrc) return
    // wait DOM update so <img> has the new src
    await nextTick()

    // If image hasn't fully loaded, wait for its load event
    if (cropperImage.value && !cropperImage.value.complete) {
      const onLoad = () => {
        initCropper()
        cropperImage.value.removeEventListener('load', onLoad)
      }
      cropperImage.value.addEventListener('load', onLoad)
    } else {
      initCropper()
    }
  },
  { immediate: true }
)

onMounted(() => {
  // Make sure slider's input handler uses our ref (template @input already wires this,
  // but we'll ensure a fallback binding if someone interacts before ready)
  if (zoomSlider.value) {
    // initial slider value set to 1 (or will be updated in ready())
    zoomSlider.value.value = zoomSlider.value.value || 1
  }
})

onBeforeUnmount(() => {
  cropper.value?.destroy()
  cropper.value = null
  if (cropperImage.value) cropperImage.value.onload = null
})
</script>

<style scoped>
/* Modal overlay (slight black fade) */
.cropper-modal {
  position: fixed;
  inset: 0;
  background-color: rgba(0, 0, 0, 0.5) !important;
  display: flex;
  align-items: center;
  justify-content: center;
  z-index: 2000;
  opacity: 1 !important; 
}

/* Card wrapper */
.modal-card {
  background: #fff;
  padding: 10px;
  border-radius: 10px;
  box-shadow: 0 6px 20px rgba(0,0,0,0.12);
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 12px;
}

/* Fixed crop area to match swipe-card */
.cropper-area {
  width: 400px;
  height: 550px;
  overflow: hidden;
  background: #fff;
  display: flex;
  align-items: center;
  justify-content: center;
}

/* Do not constrain image with max-width/height — Cropper handles sizes */
.cropper-area img {
  max-width: none;
  max-height: none;
  width: auto;
  height: auto;
  user-select: none;
}

/* actions */
.cropper-actions {
  display: flex;
  gap: 0.75rem;
  justify-content: center;
  width: 100%;
}

/* cursor for draggable image — apply to Cropper's canvas using deep selector */
::v-deep .cropper-canvas {
  cursor: grab !important;
}
::v-deep .cropper-canvas:active {
  cursor: grabbing !important;
}

/* Force Cropper overlays to be opaque (no see-through) */
::v-deep .cropper-bg,
::v-deep .cropper-drag-box {
  background: #fff !important;
  opacity: 1 !important;
}

/* small responsive tweak for small screens */
@media (max-width: 460px) {
  .cropper-area {
    width: 320px;
    height: 440px;
  }
}
</style>
