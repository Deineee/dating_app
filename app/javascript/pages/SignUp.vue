<template>
  <form class="sign-up-form" @submit.prevent="onSubmit">
    <!-- Title -->
    <div class="title">Create Account</div>

    <!-- Basic Info -->
    <input v-model="firstName" placeholder="First Name*" required />
    <input v-model="lastName" placeholder="Last Name*" required />
    <input v-model="mobileNumber" type="tel" placeholder="Mobile Number*" required />
    <input v-model="email" type="email" placeholder="Email*" required />
    <input v-model="password" type="password" placeholder="Password*" minlength="6" required />
    <input v-model="passwordConfirmation" type="password" placeholder="Confirm Password*" required />
    <input v-model="birthdate" type="date" required />

    <!-- Selects -->
    <select v-model="gender" required>
      <option disabled value="">Select Gender*</option>
      <option>Male</option>
      <option>Female</option>
      <option>Other</option>
    </select>

    <select v-model="sexualOrientation" required>
      <option disabled value="">Sexual Orientation*</option>
      <option>Male</option>
      <option>Female</option>
      <option>Other</option>
    </select>

    <select v-model="genderInterest" required>
      <option disabled value="">Gender Interest*</option>
      <option>Male</option>
      <option>Female</option>
      <option>Other</option>
    </select>

    <!-- Location -->
    <input v-model="country" placeholder="Country" />
    <input v-model="state" placeholder="State/Region" />
    <input v-model="city" placeholder="City" />

    <!-- Optional -->
    <input v-model="school" placeholder="School (Optional)" />

    <!-- Bio -->
    <textarea v-model="bio" placeholder="Bio*" maxlength="500" required></textarea>

    <!-- Photo Upload -->
    <input type="file" @change="openCropper" accept="image/*" />

    <!-- Cropper Modal -->
    <CropModal
      v-if="croppingImage"
      :imageSrc="croppingImage"
      @confirm="confirmCrop"
      @cancel="cancelCrop"
      @ready="setCropper"
    />

    <!-- Preview -->
    <div v-if="photos.length" class="photo-preview">
      <img
        v-for="(photo, index) in photos"
        :key="index"
        :src="photo"
        alt="Preview"
      />
    </div>

    <!-- Submit -->
    <button type="submit">Sign Up</button>

    <!-- Errors -->
    <p v-for="err in errors" :key="err" class="error">{{ err }}</p>
  </form>
</template>

<script setup>
/* ---------------- Imports ---------------- */
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useAuth } from '../src/composables/useAuth'
import { apolloClient } from '../src/apollo'
import CropModal from '../components/CropModal.vue'
import '../stylesheets/sign_up.css'

/* ---------------- Composables ---------------- */
const { login } = useAuth()
const router = useRouter()

/* ---------------- GraphQL ---------------- */
const SIGN_UP_MUTATION = gql`
  mutation SignUp($input: SignUpInput!) {
    signUp(input: $input) {
      user { id email }
      errors
    }
  }
`
const SIGN_IN_MUTATION = gql`
  mutation SignIn($input: SignInInput!) {
    signIn(input: $input) {
      token
      errors
    }
  }
`
const { mutate: signUp } = useMutation(SIGN_UP_MUTATION)
const { mutate: signIn } = useMutation(SIGN_IN_MUTATION)

/* ---------------- State ---------------- */
const firstName = ref('')
const lastName = ref('')
const mobileNumber = ref('')
const email = ref('')
const password = ref('')
const passwordConfirmation = ref('')
const birthdate = ref('')
const gender = ref('')
const sexualOrientation = ref('')
const genderInterest = ref('')
const country = ref('')
const state = ref('')
const city = ref('')
const school = ref('')
const bio = ref('')
const photos = ref([])
const errors = ref([])

const croppingImage = ref(null)
const cropperInstance = ref(null)

/* ---------------- Cropper ---------------- */
const setCropper = (cropper) => {
  cropperInstance.value = cropper
}

const openCropper = (e) => {
  const file = e.target.files[0]
  if (!file) return
  const reader = new FileReader()
  reader.onload = (event) => {
    croppingImage.value = event.target.result
  }
  reader.readAsDataURL(file)
}

const confirmCrop = () => {
  const canvas = cropperInstance.value.getCroppedCanvas({ width: 400, height: 550 })
  photos.value.push(canvas.toDataURL('image/jpeg', 0.9))
  cancelCrop()
}

const cancelCrop = () => {
  cropperInstance.value?.destroy()
  croppingImage.value = null
  cropperInstance.value = null
}

/* ---------------- Utils ---------------- */
function fileToBase64(fileOrDataUrl) {
  return new Promise((resolve, reject) => {
    if (typeof fileOrDataUrl === 'string' && fileOrDataUrl.startsWith('data:')) {
      return resolve(fileOrDataUrl)
    }
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result)
    reader.onerror = reject
    reader.readAsDataURL(fileOrDataUrl)
  })
}

/* ---------------- Submit ---------------- */
const onSubmit = async () => {
  errors.value = []

  if (password.value !== passwordConfirmation.value) {
    errors.value.push('Passwords do not match')
    return
  }
  if (photos.value.length < 1) {
    errors.value.push('At least one photo is required')
    return
  }

  try {
    const base64Photos = await Promise.all(photos.value.map(fileToBase64))

    // 1. Sign Up
    const { data: signUpData } = await signUp({
      input: {
        firstName: firstName.value,
        lastName: lastName.value,
        mobileNumber: mobileNumber.value,
        email: email.value,
        password: password.value,
        passwordConfirmation: passwordConfirmation.value,
        birthdate: birthdate.value,
        gender: gender.value,
        sexualOrientation: sexualOrientation.value,
        genderInterest: genderInterest.value,
        country: country.value,
        state: state.value,
        city: city.value,
        school: school.value,
        bio: bio.value,
        photos: base64Photos,
      }
    })

    if (signUpData.signUp.errors.length) {
      errors.value = signUpData.signUp.errors
      return
    }

    // 2. Sign In
    const { data: signInData } = await signIn({
      input: {
        email: email.value,
        password: password.value
      }
    })

    if (signInData.signIn.errors.length) {
      errors.value = signInData.signIn.errors
      return
    }

    login(signInData.signIn.token)

    // 3. Refetch current user
    try {
      await apolloClient.refetchQueries({ include: ['CurrentUser'] })
    } catch (err) {
      console.warn('Failed to refetch currentUser after signup/login', err)
    }

    router.push('/swipe')
  } catch (err) {
    console.error('Sign up failed:', err)
    errors.value.push('An error occurred while signing up. Please try again.')
  }
}
</script>
