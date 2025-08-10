<template>
  <div class="profile-page">
    <div class="card">
      <h1>Edit Profile</h1>

      <div class="top-row">
        <div class="avatar-preview">
          <img v-if="previewPrimary" :src="previewPrimary" alt="avatar" />
          <div v-else class="placeholder">{{ initials }}</div>
        </div>

        <div class="photo-controls">
          <label class="label">Add / reorder photos (max 5)</label>

          <!-- file input: allow multiple, each will be cropped in sequence -->
          <input type="file" accept="image/*" multiple @change="handleFiles" />

          <div class="muted">You can upload up to 5 photos. Click a thumbnail to make it primary. Use × to remove.</div>

          <!-- thumbnails for newly uploaded photos -->
          <div class="thumbnails">
            <div
              v-for="(p, i) in photos"
              :key="'new-'+i"
              class="thumb"
              :class="{ primary: i === primaryIndex }"
            >
              <img :src="p.preview" alt="photo" />
              <button class="make-primary" @click.prevent="setPrimary(i)" :title="'Make primary'">★</button>
              <button class="remove" @click.prevent="removePhoto(i)" title="Remove">×</button>
            </div>

            <!-- thumbnails for existing server photos (shown when user hasn't replaced them) -->
            <div
              v-for="(p, idx) in existingPhotos"
              :key="'existing-'+idx"
              class="thumb"
              :class="{ primary: photos.length === 0 && idx === serverPrimaryIndex }"
            >
              <img :src="p" alt="existing photo" />
              <button class="make-primary" @click.prevent="selectExistingPrimary(idx)">★</button>
              <button class="remove" @click.prevent="removeExistingPhoto(idx)" title="Remove">×</button>
            </div>
          </div>
        </div>
      </div>

      <!-- Crop modal — re-uses your component -->
      <CropModal
        v-if="croppingImage"
        :imageSrc="croppingImage"
        @confirm="confirmCrop"
        @cancel="cancelCrop"
        @ready="setCropper"
      />

      <form @submit.prevent="save">
        <div class="grid">
          <label>
            First name
            <input v-model="form.firstName" required />
          </label>

          <label>
            Last name
            <input v-model="form.lastName" required />
          </label>

          <label>
            Mobile number
            <input v-model="form.mobileNumber" />
          </label>

          <label>
            Birthdate
            <input v-model="form.birthdate" type="date" />
          </label>

          <label>
            Gender
            <input v-model="form.gender" />
          </label>

          <label>
            Sexual orientation
            <input v-model="form.sexual_orientation" />
          </label>

          <label>
            Gender interest
            <input v-model="form.gender_interest" />
          </label>

          <label>
            Country
            <input v-model="form.country" />
          </label>

          <label>
            State / Region
            <input v-model="form.state" />
          </label>

          <label>
            City
            <input v-model="form.city" />
          </label>

          <label>
            School
            <input v-model="form.school" />
          </label>

          <label class="full">
            Bio
            <textarea v-model="form.bio" rows="4" />
          </label>
        </div>

        <div class="actions">
          <button type="submit" :disabled="saving">Save</button>
          <button type="button" class="secondary" @click="cancel">Cancel</button>
        </div>

        <div v-if="error" class="error">{{ error }}</div>
        <div v-if="success" class="success">Profile updated ✓</div>
      </form>
    </div>
  </div>
</template>

<script setup>
import { ref, reactive, computed, watch } from 'vue'
import { useQuery, useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useRouter } from 'vue-router'
import { apolloClient } from '../src/apollo'
import CropModal from '../components/CropModal.vue' // your existing crop component

const router = useRouter()

/* ---------- GraphQL ---------- */
const CURRENT_USER_QUERY = gql`
  query CurrentUser {
    currentUser {
      id
      firstName
      lastName
      mobileNumber
      birthdate
      gender
      sexualOrientation
      genderInterest
      country
      state
      city
      school
      bio
      primaryPhoto
      photos
    }
  }
`

const UPDATE_USER_MUTATION = gql`
  mutation UpdateUser($input: UpdateUserInput!) {
    updateUser(input: $input) {
      user {
        id
        firstName
        lastName
        primaryPhoto
        photos
      }
      errors
    }
  }
`

/* ---------- state ---------- */
const { result: currentUserResult } = useQuery(CURRENT_USER_QUERY, null, { fetchPolicy: 'network-only' })
const user = computed(() => currentUserResult.value?.currentUser ?? null)

const form = reactive({
  id: null,
  firstName: '',
  lastName: '',
  mobileNumber: '',
  birthdate: '',
  gender: '',
  sexual_orientation: '',
  gender_interest: '',
  country: '',
  state: '',
  city: '',
  school: '',
  bio: '',
  primaryPhoto: ''
})

// photos: newly uploaded and cropped images (data URLs)
const photos = ref([]) // { preview: dataUrl, base64: dataUrl }
// existingPhotos: strings returned by server (URLs)
const existingPhotos = ref([])
const serverPrimaryIndex = ref(0) // index into existingPhotos representing server primary
const primaryIndex = ref(0) // index into photos (when photos array used)

const croppingImage = ref(null) // dataURL currently in cropper
const cropperInstance = ref(null)
const pendingFiles = ref([]) // files queue to crop

/* populate form and server photos */
watch(user, (u) => {
  if (!u) return
  form.id = u.id
  form.firstName = u.firstName ?? ''
  form.lastName = u.lastName ?? ''
  form.mobileNumber = u.mobileNumber ?? ''
  form.birthdate = u.birthdate ?? ''
  form.gender = u.gender ?? ''
  form.sexual_orientation = u.sexualOrientation ?? ''
  form.gender_interest = u.genderInterest ?? ''
  form.country = u.country ?? ''
  form.state = u.state ?? ''
  form.city = u.city ?? ''
  form.school = u.school ?? ''
  form.bio = u.bio ?? ''
  form.primaryPhoto = u.primaryPhoto ?? ''

  existingPhotos.value = u.photos ?? []
  serverPrimaryIndex.value = 0
}, { immediate: true })

/* computed */
const initials = computed(() => {
  return ((form.firstName?.[0] ?? '') + (form.lastName?.[0] ?? '')).toUpperCase()
})

const previewPrimary = computed(() => {
  // if user uploaded new photos, show photos[primaryIndex]
  if (photos.value.length) return photos.value[primaryIndex.value]?.preview || null
  // else show existing primary or primaryPhoto fallback
  return existingPhotos.value[serverPrimaryIndex.value] ?? form.primaryPhoto ?? null
})

/* ---------- Cropper handlers ---------- */
const setCropper = (instance) => {
  cropperInstance.value = instance
}

// When user selects files -> queue them for cropping and open the first one
const handleFiles = (e) => {
  const files = Array.from(e.target.files || [])
  if (!files.length) return

  // check total limit (existing + queued + new)
  const totalNow = existingPhotos.value.length + photos.value.length + pendingFiles.value.length + files.length
  if (totalNow > 5) {
    alert('You can upload up to 5 photos total. Remove some photos or select fewer images.')
    return
  }

  // push to queue
  pendingFiles.value.push(...files)
  openNextCropper()
}

// open next file in pendingFiles (if any)
const openNextCropper = () => {
  if (pendingFiles.value.length === 0) {
    croppingImage.value = null
    return
  }
  const file = pendingFiles.value.shift()
  const reader = new FileReader()
  reader.onload = (ev) => {
    croppingImage.value = ev.target.result
  }
  reader.readAsDataURL(file)
}

// confirmCrop: cropperInstance provides getCroppedCanvas (same as signup)
const confirmCrop = async () => {
  if (!cropperInstance.value) return
  const canvas = cropperInstance.value.getCroppedCanvas({ width: 400, height: 550 })
  // push to photos array as both preview & base64
  const dataUrl = canvas.toDataURL('image/jpeg', 0.9)
  photos.value.push({ preview: dataUrl, base64: dataUrl })
  // default primary to first uploaded if none chosen
  if (photos.value.length === 1) primaryIndex.value = 0

  // destroy instance and move to next file
  cancelCrop(false)
  // open next if any pending
  if (pendingFiles.value.length) openNextCropper()
}

// cancelCrop: destroy cropper and stop cropping. keep pendingFiles as-is or clear if full cancel
const cancelCrop = (clearQueue = false) => {
  try { cropperInstance.value?.destroy() } catch (e) {}
  cropperInstance.value = null
  croppingImage.value = null
  if (clearQueue) pendingFiles.value = []
}

/* ---------- photo helpers ---------- */
function removePhoto(i) {
  photos.value.splice(i, 1)
  if (primaryIndex.value >= photos.value.length) {
    primaryIndex.value = Math.max(0, photos.value.length - 1)
  }
}

function setPrimary(i) {
  primaryIndex.value = i
}

// remove existing server photo (client requests server to remove on save by sending modified photos array).
function removeExistingPhoto(idx) {
  // remove from existingPhotos list; server will receive photos: existingPhotos (reordered) or [] if replaced
  existingPhotos.value.splice(idx, 1)
  if (serverPrimaryIndex.value >= existingPhotos.value.length) serverPrimaryIndex.value = Math.max(0, existingPhotos.value.length - 1)
}

function selectExistingPrimary(idx) {
  serverPrimaryIndex.value = idx
}

/* ---------- mutation ---------- */
const { mutate: updateUser } = useMutation(UPDATE_USER_MUTATION)
const saving = ref(false)
const error = ref(null)
const success = ref(false)

async function save() {
  error.value = null
  success.value = false
  saving.value = true

  const payload = {
    id: form.id,
    first_name: form.firstName,
    last_name: form.lastName,
    mobile_number: form.mobileNumber,
    birthdate: form.birthdate,
    gender: form.gender,
    sexual_orientation: form.sexual_orientation,
    gender_interest: form.gender_interest,
    country: form.country,
    state: form.state,
    city: form.city,
    school: form.school,
    bio: form.bio
  }

  // Prepare photos + primary index for server
  let photosToSend = null
  let primaryPhotoIndexToSend = null

  if (photos.value.length) {
    photosToSend = photos.value.map((p) => p.base64) // newly uploaded (replaces existing)
    primaryPhotoIndexToSend = primaryIndex.value // index in photos
  } else {
    // no new uploads:
    // if existingPhotos changed (removals or reorder), send the existingPhotos array to preserve order
    photosToSend = existingPhotos.value.length ? existingPhotos.value : []
    primaryPhotoIndexToSend = serverPrimaryIndex.value
  }

  // Build input in shape server expects (snake_case keys)
  const input = {
    input: {
      id: payload.id,
      first_name: payload.first_name,
      last_name: payload.last_name,
      mobile_number: payload.mobile_number,
      birthdate: payload.birthdate,
      gender: payload.gender,
      sexual_orientation: payload.sexual_orientation,
      gender_interest: payload.gender_interest,
      country: payload.country,
      state: payload.state,
      city: payload.city,
      school: payload.school,
      bio: payload.bio,
      photos: photosToSend,
      primary_photo_index: primaryPhotoIndexToSend
    }
  }

  try {
    const res = await updateUser(input)
    const payloadRes = res?.data?.updateUser
    if (payloadRes?.errors && payloadRes.errors.length) {
      error.value = payloadRes.errors.join(', ')
    } else {
      success.value = true
      // refresh CURRENT_USER_QUERY
      try {
        await apolloClient.refetchQueries({ include: [CURRENT_USER_QUERY] })
      } catch (err) {
        try { await apolloClient.resetStore() } catch (_) {}
      }
      // clear local uploads (server now stores them)
      photos.value = []
      // optionally reload server photos from response
      const newPhotos = payloadRes?.user?.photos ?? []
      existingPhotos.value = newPhotos
      serverPrimaryIndex.value = 0
      setTimeout(() => { success.value = false }, 1500)
    }
  } catch (e) {
    error.value = e.message || 'Failed to update profile'
  } finally {
    saving.value = false
  }
}

function cancel() {
  router.back()
}
</script>

<style scoped>
/* keep your previous styling and add photo thumbnails layout */
.profile-page { max-width: 900px; margin: 32px auto; padding: 16px; }
.card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 10px 30px rgba(20, 50, 100, 0.06); }
h1 { margin: 0 0 16px 0; font-size: 1.6rem; }
.top-row { display: flex; gap: 20px; align-items: center; margin-bottom: 18px; }
.avatar-preview img { width: 110px; height: 110px; border-radius: 14px; object-fit: cover; box-shadow: 0 6px 18px rgba(0,0,0,0.08); }
.avatar-preview .placeholder { width: 110px; height: 110px; border-radius: 14px; display:flex; align-items:center; justify-content:center; background:#f1f5f9; color:#475569; font-weight:700; font-size:28px; box-shadow: 0 6px 18px rgba(0,0,0,0.04); }

.photo-controls input { width: 360px; max-width: 100%; padding:8px 10px; border-radius:8px; border:1px solid #e6eef6; margin-top:6px; }
.muted { color:#6b7280; font-size:13px; margin-top:8px; }

/* thumbnails layout */
.thumbnails { display:flex; gap:10px; margin-top:10px; flex-wrap:wrap; }
.thumb { position:relative; width:94px; height:122px; border-radius:8px; overflow:hidden; box-shadow:0 4px 12px rgba(0,0,0,0.06); }
.thumb img { width:100%; height:100%; object-fit:cover; display:block; }
.thumb .make-primary { position:absolute; left:6px; top:6px; background:rgba(255,255,255,0.85); border:none; border-radius:6px; padding:4px; cursor:pointer; font-size:14px; }
.thumb .remove { position:absolute; right:6px; top:6px; background:rgba(0,0,0,0.6); color:white; border:none; border-radius:6px; padding:3px 6px; cursor:pointer; font-weight:600; }
.thumb.primary { outline: 3px solid #2d8cff; transform: translateY(-3px); }

/* rest of your existing form styling */
form .grid { display: grid; grid-template-columns: repeat(2, 1fr); gap: 12px; }
label { display:flex; flex-direction:column; font-size:14px; color:#111; }
label input, label textarea { margin-top:6px; padding:8px 10px; border-radius:8px; border:1px solid #e6eef6; font-size:14px; }
label.full { grid-column: 1 / -1; }
.actions { margin-top: 18px; display:flex; gap:10px; }
.actions button { padding: 10px 14px; border-radius: 8px; border:none; background:#2d8cff; color:white; font-weight:700; cursor:pointer; }
.actions .secondary { background: #f3f4f6; color: #111; font-weight:600; }
.error { color:#b91c1c; margin-top:12px; }
.success { color:#059669; margin-top:12px; }
</style>
