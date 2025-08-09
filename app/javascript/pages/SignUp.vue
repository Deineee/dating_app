<template>
  <form class="sign-up-form" @submit.prevent="onSubmit">
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
      <option>Female</option>
    </select>

    <select v-model="sexualOrientation" required>
      <option disabled value="">Sexual Orientation*</option>
      <option>Male</option>
      <option>Female</option>
    </select>

    <select v-model="genderInterest" required>
      <option disabled value="">Gender Interest*</option>
      <option>Male</option>
      <option>Female</option>
    </select>

    <input v-model="country" placeholder="Country" />
    <input v-model="state" placeholder="State/Region" />
    <input v-model="city" placeholder="City" />
    <input v-model="school" placeholder="School (Optional)" />
    
    <textarea v-model="bio" placeholder="Bio*" required maxlength="500"></textarea>

    <input type="file" multiple @change="onFileChange" accept="image/*" required />

    <button type="submit">Sign Up</button>

    <p v-if="errors.length" style="color:red;">
      <span v-for="err in errors" :key="err">{{ err }}</span>
    </p>
  </form>
</template>

<script setup>
import { ref } from 'vue'
import { useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import '../stylesheets/sign_up.css'

const SIGN_UP_MUTATION = gql`
  mutation SignUp($input: SignUpInput!) {
    signUp(input: $input) {
      user { id email }
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

const onFileChange = (e) => {
  const files = Array.from(e.target.files)
  if (files.length > 5) {
    errors.value.push('You can upload a maximum of 5 photos')
  } else {
    photos.value = files
  }
}

const fileToBase64 = (file) => {
  return new Promise((resolve, reject) => {
    const reader = new FileReader()
    reader.readAsDataURL(file)
    reader.onload = () => resolve(reader.result)
    reader.onerror = (error) => reject(error)
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
    // Convert photos to base64 strings
    const base64Photos = await Promise.all(photos.value.map(fileToBase64))

    const { data } = await signUp({
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
        photos: base64Photos, // now array of strings
      }
    })

    if (data.signUp.errors.length) {
      errors.value = data.signUp.errors
    } else {
      alert(`Signed up as ${data.signUp.user.email}`)
    }
  } catch (e) {
    errors.value = [e.message]
  }
}
</script>
