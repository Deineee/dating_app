<template>
  <form class="sign-up-form" @submit.prevent="onSubmit">
    <div class="title">Create Account</div>
    <input v-model="firstName" placeholder="First Name*" required />
    <input v-model="lastName" placeholder="Last Name*" required />
    <input v-model="mobileNumber" type="tel" placeholder="Mobile Number*" required />
    <input v-model="email" type="email" placeholder="Email*" required />
    <input v-model="password" type="password" placeholder="Password*" required minlength="6" />
    <input v-model="passwordConfirmation" type="password" placeholder="Confirm Password*" required />
    <input v-model="birthdate" type="date" required />
    
    <select v-model="gender" required>
      <option disabled value="">Select Gender*</option>
      <option>Male</option>
      <option>Other</option>
      <option>Female</option>
    </select>

    <select v-model="sexualOrientation" required>
      <option disabled value="">Sexual Orientation*</option>
      <option>Male</option>
      <option>Other</option>
      <option>Female</option>
    </select>

    <select v-model="genderInterest" required>
      <option disabled value="">Gender Interest*</option>
      <option>Male</option>
      <option>Other</option>
      <option>Female</option>
    </select>

    <input v-model="country" placeholder="Country" />
    <input v-model="state" placeholder="State/Region" />
    <input v-model="city" placeholder="City" />
    <input v-model="school" placeholder="School (Optional)" />
    
    <textarea v-model="bio" placeholder="Bio*" required maxlength="500"></textarea>
      <input type="file" @change="openCropper" accept="image/*" />
        <CropModal
          v-if="croppingImage"
          :imageSrc="croppingImage"
          @confirm="confirmCrop"
          @cancel="cancelCrop"
          @ready="setCropper"
        />
      <div v-if="photos.length" class="photo-preview">
        <img v-for="(photo, index) in photos" :key="index" :src="photo" alt="Preview" />
      </div>

      <button type="submit">Sign Up</button>
      <p v-if="errors.length" class="error" v-for="err in errors" :key="err">{{ err }}</p>
    </form>
</template>

<script setup>
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import '../stylesheets/sign_up.css'
import { useRouter } from 'vue-router'
import { useAuth } from '../src/composables/useAuth'
import { ref, onMounted, nextTick } from 'vue'
import CropModal from '../components/CropModal.vue'

const { login } = useAuth()
const router = useRouter() 

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

const { mutate: signUp } = useMutation(SIGN_UP_MUTATION)
const { mutate: signIn } = useMutation(SIGN_IN_MUTATION)
const croppingImage = ref(null)
const cropperInstance = ref(null)

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

const onFileChange = async (e) => {
  const files = Array.from(e.target.files);
  if (files.length > 5) {
    errors.value.push('You can upload a maximum of 5 photos');
    return;
  }

  const processedFiles = [];
  for (const file of files) {
    const resized = await resizeImage(file, 400, 550); // fixed Tinder-style size
    processedFiles.push(resized);
  }

  photos.value = processedFiles;
};

function resizeImage(file, width, height) {
  return new Promise((resolve) => {
    const img = new Image();
    const reader = new FileReader();
    reader.onload = (e) => {
      img.src = e.target.result;
    };
    img.onload = () => {
      const canvas = document.createElement('canvas');
      canvas.width = width;
      canvas.height = height;
      const ctx = canvas.getContext('2d');
      ctx.drawImage(img, 0, 0, width, height);
      canvas.toBlob((blob) => {
        resolve(new File([blob], file.name, { type: file.type }));
      }, file.type);
    };
    reader.readAsDataURL(file);
  });
}

const fileToBase64 = (fileOrDataUrl) => {
  return new Promise((resolve, reject) => {
    // If it's already a base64 data URL, return as-is
    if (typeof fileOrDataUrl === 'string' && fileOrDataUrl.startsWith('data:')) {
      return resolve(fileOrDataUrl)
    }

    // Otherwise expect a Blob/File
    const reader = new FileReader()
    reader.onload = () => resolve(reader.result)
    reader.onerror = (error) => reject(error)
    reader.readAsDataURL(fileOrDataUrl)
  })
}

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

    // 1. Call signUp mutation first
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

    // 2. Call signIn mutation to get token
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

    // 3. Login and redirect
    login(signInData.signIn.token)
    router.push('/swipe')
  } catch (e) {
    errors.value = [e.message]
  }
}
</script>
