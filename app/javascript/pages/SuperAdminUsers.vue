<template>
  <div class="super-admin-users">
    <header class="mm-header">
      <h1>User Manager</h1>

      <div class="controls">
        <input
          v-model="q"
          placeholder="Search by name..."
          class="search"
          @input="applyFilter"
        />
      </div>
    </header>

    <div class="card">
      <table class="mm-table">
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
          <tr v-for="user in displayedUsers" :key="user.id">
            <td>
              <img :src="user.primaryPhoto || placeholder" class="avatar" />
            </td>
            <td>{{ user.firstName }}</td>
            <td>{{ user.lastName }}</td>
            <td>{{ user.role }}</td>
            <td class="action-buttons">
              <button class="btn sm view" @click="viewUser(user.id)">View</button>
              <button class="btn sm edit" @click="openEdit(user.id)">Edit</button>
              <button
                class="btn sm delete"
                @click="deleteUser(user.id)"
                :disabled="deletingId === user.id"
              >
                {{ deletingId === user.id ? 'Deleting...' : 'Delete' }}
              </button>
            </td>
          </tr>

          <tr v-if="!displayedUsers.length">
            <td colspan="5" class="empty">No users found.</td>
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
import UserDetailModal from '../components/UserDetailModal.vue'
import EditUserModal from '../components/EditUserModal.vue'

const placeholder = 'https://via.placeholder.com/72?text=No+Photo'

const users = ref([])
const q = ref('')
const displayedUsers = computed(() => {
  if (!q.value.trim()) return users.value
  const term = q.value.toLowerCase()
  return users.value.filter(u => {
    const fullName = `${u.firstName ?? ''} ${u.lastName ?? ''}`.toLowerCase()
    return fullName.includes(term)
  })
})

const selectedUser = ref(null)
const editingUser = ref(null)
const deletingId = ref(null)

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

const { result, refetch } = useQuery(GET_ALL_USERS)

watch(
  result,
  () => {
    users.value = (result.value?.allUsers ?? []).filter(u => u.role !== 'admin')
  },
  { immediate: true }
)

function applyFilter() {
  // displayedUsers is reactive, so no code needed here
}

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
      const res = await deleteUserMutation({ input: { id } })
      if (res.data.deleteUser.success) {
        alert('✅ User deleted successfully')
        await refetch()
      } else {
        alert('❌ Failed to delete user: ' + (res.data.deleteUser.errors.join(', ') || 'Unknown error'))
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
  padding: 18px;
  max-width: 980px;
  margin: 0 auto;
}
.mm-header {
  display:flex;
  align-items:center;
  justify-content:space-between;
  gap: 12px;
  margin-bottom: 12px;
}
.mm-header h1 {
  margin: 0;
  font-size: 1.3rem;
}
.controls {
  display:flex;
  gap:8px;
  align-items:center;
}
.search {
  padding: 8px 10px;
  border-radius: 8px;
  border: 1px solid #e5e7eb;
  width: 220px;
}
.card {
  background: white;
  border-radius: 10px;
  box-shadow: 0 6px 20px rgba(8,12,24,0.06);
  overflow: hidden;
}
.mm-table {
  width: 100%;
  border-collapse: collapse;
}
.mm-table thead {
  background: #0f172a;
  color: white;
}
.mm-table th,
.mm-table td {
  padding: 12px 14px;
  text-align: left;
  border-bottom: 1px solid #f1f5f9;
}
.avatar {
  width: 48px;
  height: 48px;
  border-radius: 8px;
  object-fit: cover;
  border: 1px solid #eee;
}
.action-buttons {
  display: flex;
  gap: 8px;
}
.btn.sm {
  padding: 6px 10px;
  background: #4a90e2;
  color: white;
  border: none;
  border-radius: 6px;
  cursor: pointer;
  font-size: 0.85rem;
}
.btn.sm.view {
  background-color: #4a90e2;
}
.btn.sm.edit {
  background-color: #f5a623;
}
.btn.sm.delete {
  background-color: #d0021b;
}
.btn.sm:hover {
  opacity: 0.85;
}
.empty {
  text-align: center;
  padding: 20px;
  color: #6b7280;
}
@media (max-width: 720px) {
  .mm-header {
    flex-direction: column;
    align-items: stretch;
    gap: 8px;
  }
  .search {
    width: 100%;
  }
}
</style>
