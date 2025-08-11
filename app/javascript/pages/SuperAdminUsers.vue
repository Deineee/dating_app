<template>
  <div class="super-admin-users">
    <h1>User Manager</h1>
    <table>
      <thead>
        <tr>
          <th>Photo</th>
          <th>First Name</th>
          <th>Last Name</th>
          <th>Role</th>
          <th>Actions</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="user in users" :key="user.id">
          <td>
            <img :src="user.primaryPhoto" alt="Primary Photo" width="50" />
          </td>
          <td>{{ user.firstName }}</td>
          <td>{{ user.lastName }}</td>
          <td>{{ user.role }}</td>
          <td>
            <button @click="viewUser(user.id)">View</button>
            <button @click="editUser(user.id)">Edit</button>
            <button @click="deleteUser(user.id)">Delete</button>
          </td>
        </tr>
      </tbody>
    </table>

    <UserDetailModal
      v-if="selectedUser"
      :userId="selectedUser"
      @close="selectedUser = null"
    />
  </div>
</template>

<script setup>
import { ref, watch } from 'vue'
import { useQuery, useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import UserDetailModal from '../components/UserDetailModal.vue'

const GET_ALL_USERS = gql`
  query {
    allUsers {
      id
      firstName
      lastName
      role
      primaryPhoto
    }
  }
`

const DELETE_USER = gql`
  mutation DeleteUser($id: ID!) {
    deleteUser(id: $id) {
      success
      errors
    }
  }
`

const users = ref([])
const selectedUser = ref(null)

const { result, refetch } = useQuery(GET_ALL_USERS)

// Update users list when query result changes
watch(
  result,
  () => {
    users.value = result.value?.allUsers ?? []
  },
  { immediate: true }
)

function viewUser(id) {
  selectedUser.value = id
}

function editUser(id) {
  // TODO: Implement navigation or modal for editing user
  // Example:
  // router.push(`/admin/users/${id}/edit`)
}

const { mutate: deleteUserMutation } = useMutation(DELETE_USER)

async function deleteUser(id) {
  if (confirm('Are you sure you want to delete this user?')) {
    const res = await deleteUserMutation({ id })
    if (res.data.deleteUser.success) {
      alert('User deleted')
      refetch()
    } else {
      alert(
        'Failed to delete user: ' +
          (res.data.deleteUser.errors.join(', ') || 'Unknown error')
      )
    }
  }
}
</script>
