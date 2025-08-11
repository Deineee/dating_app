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

          <input type="file" accept="image/*" multiple @change="handleFiles" />

          <div class="muted">You can upload up to 5 photos. Click a thumbnail to make it primary. Use × to remove.</div>

          <div class="thumbnails">
            <!-- newly uploaded photos -->
            <div
              v-for="(p, i) in photos"
              :key="'new-'+i"
              class="thumb"
              :class="{ primary: primarySelection.type === 'new' && primarySelection.index === i }"
            >
              <img :src="p.preview" alt="photo" />
              <button class="make-primary" @click.prevent="selectPrimary('new', i)" title="Make primary">★</button>
              <button class="remove" @click.prevent="removePhoto(i)" title="Remove">×</button>
            </div>

            <!-- existing server photos -->
            <div
              v-for="(p, idx) in existingPhotos"
              :key="'existing-'+p.id"
              class="thumb"
              :class="{ primary: primarySelection.type === 'existing' && primarySelection.index === idx }"
            >
              <img :src="p.url" alt="existing photo" />
              <button class="make-primary" @click.prevent="selectPrimary('existing', idx)" title="Make primary">★</button>
              <button class="remove" @click.prevent="removeExistingPhoto(idx)" title="Remove">×</button>
            </div>
          </div>
        </div>
      </div>

      <CropModal
        v-if="croppingImage"
        :imageSrc="croppingImage"
        @confirm="confirmCrop"
        @cancel="cancelCrop"
        @ready="setCropper"
      />

      <form @submit.prevent="save">
        <div class="grid">
          <label>First name <input v-model="form.firstName" required /></label>
          <label>Last name <input v-model="form.lastName" required /></label>
          <label>Mobile number <input v-model="form.mobileNumber" /></label>
          <label>Birthdate <input v-model="form.birthdate" type="date" /></label>
          <label>Gender <input v-model="form.gender" /></label>
          <label>Sexual orientation <input v-model="form.sexual_orientation" /></label>
          <label>Gender interest <input v-model="form.gender_interest" /></label>
          <label>Country <input v-model="form.country" /></label>
          <label>State / Region <input v-model="form.state" /></label>
          <label>City <input v-model="form.city" /></label>
          <label>School <input v-model="form.school" /></label>
          <label class="full">Bio <textarea v-model="form.bio" rows="4" /></label>
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
import CropModal from '../components/CropModal.vue'

const router = useRouter()

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
      __typename
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
        __typename
      }
      errors
    }
  }
`

function hashString(s) {
  if (!s) return Date.now().toString(36)
  let h = 0
  for (let i = 0; i < s.length; i++) h = (h << 5) - h + s.charCodeAt(i) | 0
  return Math.abs(h).toString(36)
}

/* Capture refetch from useQuery so we can refresh the current user after mutation */
const { result: currentUserResult, refetch: refetchCurrentUser } = useQuery(CURRENT_USER_QUERY, null, { fetchPolicy: 'network-only' })
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

/* Photo state */
const photos = ref([]) // newly uploaded { preview, base64 }
const existingPhotos = ref([]) // existing server photos { id, url }
const croppingImage = ref(null)
const cropperInstance = ref(null)
const pendingFiles = ref([])

/* Track removals (store original index + stable id) */
const removedExistingIndexes = ref([])

const primarySelection = ref({ type: 'existing', index: 0 })

/* populate form and existing photos — watch will run after refetchCurrentUser() */
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

  existingPhotos.value = (u.photos ?? []).map((url, i) => ({ id: `server-${i}-${hashString(url)}`, url }))
  primarySelection.value = existingPhotos.value.length ? { type: 'existing', index: 0 } : { type: 'new', index: 0 }
  removedExistingIndexes.value = []
}, { immediate: true })

const initials = computed(() => {
  return ((form.firstName?.[0] ?? '') + (form.lastName?.[0] ?? '')).toUpperCase()
})

const previewPrimary = computed(() => {
  if (primarySelection.value.type === 'new') {
    const idx = primarySelection.value.index ?? 0
    return photos.value[idx]?.preview ?? null
  } else {
    const idx = primarySelection.value.index ?? 0
    if (existingPhotos.value[idx]) return existingPhotos.value[idx].url
    return form.primaryPhoto ?? (photos.value[0]?.preview ?? null)
  }
})

const setCropper = (instance) => { cropperInstance.value = instance }

const handleFiles = (e) => {
  const files = Array.from(e.target.files || [])
  if (!files.length) return
  const totalNow = existingPhotos.value.length + photos.value.length + pendingFiles.value.length + files.length
  if (totalNow > 5) {
    alert('You can upload up to 5 photos total. Remove some photos or select fewer images.')
    return
  }
  pendingFiles.value.push(...files)
  openNextCropper()
}

const openNextCropper = () => {
  if (!pendingFiles.value.length) { croppingImage.value = null; return }
  const file = pendingFiles.value.shift()
  const reader = new FileReader()
  reader.onload = (ev) => { croppingImage.value = ev.target.result }
  reader.readAsDataURL(file)
}

const confirmCrop = async () => {
  if (!cropperInstance.value) return
  const canvas = cropperInstance.value.getCroppedCanvas({ width: 400, height: 550 })
  const dataUrl = canvas.toDataURL('image/jpeg', 0.9)
  photos.value.push({ preview: dataUrl, base64: dataUrl })

  if (photos.value.length === 1 && existingPhotos.value.length === 0) {
    primarySelection.value = { type: 'new', index: 0 }
  }

  cancelCrop(false)
  if (pendingFiles.value.length) openNextCropper()
}

const cancelCrop = (clearQueue = false) => {
  try { cropperInstance.value?.destroy() } catch (e) {}
  cropperInstance.value = null
  croppingImage.value = null
  if (clearQueue) pendingFiles.value = []
}

function removePhoto(i) {
  if (photos.value.length + existingPhotos.value.length <= 1) {
    alert('You must have at least one photo.')
    return
  }

  if (primarySelection.value.type === 'new' && primarySelection.value.index === i) {
    if (existingPhotos.value.length) {
      primarySelection.value = { type: 'existing', index: 0 }
    } else {
      primarySelection.value = { type: 'new', index: Math.max(0, i - 1) }
    }
  } else if (primarySelection.value.type === 'new' && primarySelection.value.index > i) {
    primarySelection.value.index = primarySelection.value.index - 1
  }

  photos.value.splice(i, 1)
}

function removeExistingPhoto(idx) {
  if (photos.value.length + existingPhotos.value.length <= 1) {
    alert('You must have at least one photo.')
    return
  }

  const item = existingPhotos.value[idx]
  if (!item) return

  removedExistingIndexes.value.push({ id: item.id, idx })

  if (primarySelection.value.type === 'existing' && primarySelection.value.index === idx) {
    if (photos.value.length) {
      primarySelection.value = { type: 'new', index: 0 }
    } else {
      const next = Math.min(idx, existingPhotos.value.length - 1)
      primarySelection.value = { type: 'existing', index: Math.max(0, next - 1) }
    }
  } else if (primarySelection.value.type === 'existing' && primarySelection.value.index > idx) {
    primarySelection.value.index = primarySelection.value.index - 1
  }

  existingPhotos.value.splice(idx, 1)
}

function selectPrimary(type, index) {
  primarySelection.value = { type, index }
}

const { mutate: updateUser } = useMutation(UPDATE_USER_MUTATION)
const saving = ref(false)
const error = ref(null)
const success = ref(false)

async function save() {
  error.value = null
  success.value = false
  saving.value = true

  const payload = {
    firstName: form.firstName,
    lastName: form.lastName,
    mobileNumber: form.mobileNumber,
    birthdate: form.birthdate,
    gender: form.gender,
    sexualOrientation: form.sexual_orientation,
    genderInterest: form.gender_interest,
    country: form.country,
    state: form.state,
    city: form.city,
    school: form.school,
    bio: form.bio,
  }

  const variablesInput = { ...payload }

  const keptExistingCount = existingPhotos.value.length

  if (photos.value.length > 0) {
    variablesInput.photos = photos.value.map((p) => p.base64)
    if (removedExistingIndexes.value.length > 0) {
      variablesInput.removedPhotoIndexes = removedExistingIndexes.value.map(x => x.idx)
    }
    if (primarySelection.value.type === 'existing') {
      variablesInput.primaryPhotoIndex = primarySelection.value.index
    } else {
      variablesInput.primaryPhotoIndex = keptExistingCount + Number(primarySelection.value.index || 0)
    }
  } else {
    if (removedExistingIndexes.value.length > 0) {
      variablesInput.removedPhotoIndexes = removedExistingIndexes.value.map(x => x.idx)
    }
    if (primarySelection.value.type === 'new') {
      variablesInput.primaryPhotoIndex = 0
    } else {
      variablesInput.primaryPhotoIndex = Number(primarySelection.value.index || 0)
    }
  }

  const variables = { input: variablesInput }

  try {
    const res = await updateUser(variables)
    const payloadRes = res?.data?.updateUser

    if (payloadRes?.errors && payloadRes.errors.length) {
      error.value = payloadRes.errors.join(', ')
    } else {
      success.value = true

      const updatedUser = payloadRes.user || {}

      // Write updated user into Apollo cache for CURRENT_USER_QUERY
      try {
        apolloClient.cache.writeQuery({
          query: CURRENT_USER_QUERY,
          data: {
            currentUser: {
              ...updatedUser,
              __typename: updatedUser.__typename || 'User'
            }
          }
        })
      } catch (cacheErr) {
        console.warn('cache write failed', cacheErr)
      }

      // Update form fields immediately
      form.firstName = updatedUser.firstName ?? form.firstName
      form.lastName = updatedUser.lastName ?? form.lastName
      form.mobileNumber = updatedUser.mobileNumber ?? form.mobileNumber
      form.birthdate = updatedUser.birthdate ?? form.birthdate
      form.gender = updatedUser.gender ?? form.gender
      form.sexual_orientation = updatedUser.sexualOrientation ?? form.sexual_orientation
      form.gender_interest = updatedUser.genderInterest ?? form.gender_interest
      form.country = updatedUser.country ?? form.country
      form.state = updatedUser.state ?? form.state
      form.city = updatedUser.city ?? form.city
      form.school = updatedUser.school ?? form.school
      form.bio = updatedUser.bio ?? form.bio
      form.primaryPhoto = updatedUser.primaryPhoto ?? form.primaryPhoto

      // Append timestamp to bust image cache
      const newPhotos = (updatedUser.photos || [])
      existingPhotos.value = newPhotos.map((url, i) => {
        const sep = url.includes('?') ? '&' : '?'
        return { id: `server-${i}-${hashString(url)}`, url: `${url}${sep}v=${Date.now()}` }
      })

      photos.value = []
      removedExistingIndexes.value = []

      primarySelection.value = existingPhotos.value.length ? { type: 'existing', index: 0 } : { type: 'new', index: 0 }

      try {
        if (typeof refetchCurrentUser === 'function') {
          await refetchCurrentUser()
        } else {
          await apolloClient.query({ query: CURRENT_USER_QUERY, fetchPolicy: 'network-only' })
        }
      } catch (e) {
        console.warn('refetch failed', e)
      }

      setTimeout(() => { success.value = false }, 1800)
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
/* same styles as before (trimmed for brevity) */
.profile-page { max-width: 900px; margin: 32px auto; padding: 16px; }
.card { background: white; border-radius: 12px; padding: 20px; box-shadow: 0 10px 30px rgba(20,50,100,0.06); }
.top-row { display:flex; gap:20px; align-items:center; margin-bottom:18px; }
.avatar-preview img { width:110px;height:110px;border-radius:14px;object-fit:cover;box-shadow:0 6px 18px rgba(0,0,0,0.08); }
.avatar-preview .placeholder { width:110px;height:110px;border-radius:14px;display:flex;align-items:center;justify-content:center;background:#f1f5f9;color:#475569;font-weight:700;font-size:28px;box-shadow:0 6px 18px rgba(0,0,0,0.04); }
.photo-controls input { width:360px;max-width:100%;padding:8px 10px;border-radius:8px;border:1px solid #e6eef6;margin-top:6px; }
.muted { color:#6b7280;font-size:13px;margin-top:8px; }
.thumbnails { display:flex; gap:10px; margin-top:10px; flex-wrap:wrap; }
.thumb { position:relative; width:94px; height:122px; border-radius:8px; overflow:hidden; box-shadow:0 4px 12px rgba(0,0,0,0.06); }
.thumb img { width:100%; height:100%; object-fit:cover; display:block; }
.thumb .make-primary { position:absolute; left:6px; top:6px; background:rgba(255,255,255,0.85); border:none; border-radius:6px; padding:4px; cursor:pointer; font-size:14px; }
.thumb .remove { position:absolute; right:6px; top:6px; background:rgba(0,0,0,0.6); color:white; border:none; border-radius:6px; padding:3px 6px; cursor:pointer; font-weight:600; }
.thumb.primary { outline: 3px solid #2d8cff; transform: translateY(-3px); }
form .grid { display:grid; grid-template-columns: repeat(2,1fr); gap:12px; }
label { display:flex; flex-direction:column; font-size:14px; color:#111; }
label input, label textarea { margin-top:6px; padding:8px 12px; font-size:15px; border-radius:6px; border:1px solid #cbd5e1; }
label.full { grid-column: span 2; }
.actions { margin-top:20px; display:flex; gap:12px; }
button { background:#2d8cff; border:none; border-radius:8px; color:white; font-weight:700; font-size:16px; padding:10px 18px; cursor:pointer; }
button.secondary { background:#9ca3af; }
.error { margin-top:14px; color:#d14343; font-weight:600; }
.success { margin-top:14px; color:#2ea443; font-weight:600; }
</style>
