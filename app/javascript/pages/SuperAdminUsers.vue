<template>
  <div class="super-admin-users">
    <h1>User Manager</h1>

    <div class="table-wrap">
      <table class="user-table">
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
              <img :src="user.primaryPhoto" class="user-photo" />
            </td>
            <td>{{ user.firstName }}</td>
            <td>{{ user.lastName }}</td>
            <td>{{ user.role }}</td>
            <td class="action-buttons">
              <button class="btn view" @click="viewUser(user.id)">View</button>
              <button class="btn edit" @click="openEdit(user.id)">Edit</button>
              <button
                class="btn delete"
                @click="deleteUser(user.id)"
                :disabled="deletingId === user.id"
              >
                {{ deletingId === user.id ? 'Deleting...' : 'Delete' }}
              </button>
            </td>
          </tr>
        </tbody>
      </table>
    </div>

    <UserDetailModal
      v-if="selectedUser"
      :userId="selectedUser"
      @close="selectedUser = null"
    />

    <EditUserModal
      v-if="editingUser"
      :userId="editingUser"
      @close="editingUser = null"
      @saved="onSaved"
    />
  </div>
</template>

<script setup>
import { ref, watch, computed } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { useQuery, useMutation } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import { useAuth } from '../src/composables/useAuth'
import '../stylesheets/header.css'
import { apolloClient } from '../src/apollo'
import UserDetailModal from '../components/UserDetailModal.vue'
import EditUserModal from '../components/EditUserModal.vue'

const router = useRouter()
const route = useRoute()
const { isAuthenticated: authRef, logout } = useAuth()
const isAuthenticated = computed(() => authRef.value)
const authRoutes = ['Swipe', 'Matches', 'Messages', 'Conversation', 'Profile']

const isSuperAdminUsersPage = computed(() => route.name === 'SuperAdminUsers')

const SIGN_OUT_MUTATION = gql`
  mutation SignOut($input: SignOutInput!) {
    signOut(input: $input)
  }
`

const { mutate: signOut } = useMutation(SIGN_OUT_MUTATION)

const handleLogout = async () => {
  try {
    await signOut({ input: {} })
  } catch (error) {
    console.error('Logout failed:', error)
  } finally {
    localStorage.clear()
    logout()
    try {
      await apolloClient.clearStore()
    } catch (err) {
      console.warn('Failed to clear Apollo store', err)
    }
    router.push({ name: 'Landing' })
  }
}

const showHomeLink = computed(() => {
  return isAuthenticated.value && authRoutes.includes(route.name)
})

const CURRENT_USER_QUERY = gql`
  query CurrentUser {
    currentUser {
      id
      firstName
      lastName
      primaryPhoto
    }
  }
`
const { result: currentUserResult } = useQuery(CURRENT_USER_QUERY, null, { fetchPolicy: 'network-only' })
const currentUser = computed(() => currentUserResult.value?.currentUser ?? null)

function goToProfile() {
  router.push({ name: 'Profile' })
}

// === Super Admin User Management ===

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

const users = ref([])
const selectedUser = ref(null)
const editingUser = ref(null)
const deletingId = ref(null)

const { result, refetch } = useQuery(GET_ALL_USERS)

watch(
  result,
  () => {
    // Only show users that are NOT admin or superadmin
    users.value = (result.value?.allUsers ?? []).filter(
      (u) => u.role !== 'admin')
  },
  { immediate: true }
)

function viewUser(id) {
  selectedUser.value = id
}

function openEdit(id) {
  editingUser.value = id
}

function onSaved() {
  editingUser.value = null
  refetch()
}

const DELETE_USER = gql`
  mutation DeleteUser($input: DeleteUserInput!) {
    deleteUser(input: $input) {
      success
      errors
    }
  }
`

const { mutate: deleteUserMutation } = useMutation(DELETE_USER)

async function deleteUser(id) {
  if (confirm('Are you sure you want to delete this user?')) {
    deletingId.value = id
    try {
      const res = await deleteUserMutation({ input: { id } }) // Pass input object
      if (res.data.deleteUser.success) {
        alert('✅ User deleted successfully')
        await refetch()
      } else {
        alert(
          '❌ Failed to delete user: ' +
            (res.data.deleteUser.errors.join(', ') || 'Unknown error')
        )
      }
    } catch (err) {
      console.error(err)
      alert('⚠️ An error occurred while deleting the user.')
    } finally {
      deletingId.value = null
    }
  }
}
</script>

<style scoped>
.super-admin-users {
  padding: 20px;
  background: #f9f9f9;
  min-height: 100vh;
}

h1 {
  font-size: 1.8rem;
  margin-bottom: 20px;
  color: #333;
}

.user-table {
  width: 100%;
  border-collapse: collapse;
  background: white;
  border-radius: 8px;
  overflow: hidden;
  box-shadow: 0px 4px 10px rgba(0,0,0,0.05);
}

.user-table th,
.user-table td {
  padding: 12px 15px;
  text-align: left;
}

.user-table thead {
  background-color: #4a90e2;
  color: white;
}

.user-table tbody tr:nth-child(even) {
  background-color: #f4f6f8;
}

.user-photo {
  width: 50px;
  height: 50px;
  object-fit: cover;
  border-radius: 50%;
  border: 2px solid #ddd;
}

.action-buttons {
  display: flex;
  gap: 8px;
}

.btn {
  padding: 6px 12px;
  font-size: 0.85rem;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  transition: 0.2s ease;
}

.btn.view {
  background-color: #4a90e2;
  color: white;
}

.btn.edit {
  background-color: #f5a623;
  color: white;
}

.btn.delete {
  background-color: #d0021b;
  color: white;
}

.btn:hover {
  opacity: 0.85;
}
</style>
