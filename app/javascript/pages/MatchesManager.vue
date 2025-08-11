<template>
  <div class="matches-manager">
    <header class="mm-header">
      <h1>Matches Manager</h1>

      <div class="controls">
        <input
          v-model="q"
          placeholder="Search by name..."
          class="search"
          @input="applyFilter"
        />

        <button class="btn sort" @click="toggleSort">
          Sort: {{ sortDesc ? 'Most matches' : 'Fewest matches' }}
        </button>
      </div>
    </header>

    <div class="card">
      <table class="mm-table">
        <thead>
          <tr>
            <th>Photo</th>
            <th>Name</th>
            <th class="center">Matches</th>
            <th>Actions</th>
          </tr>
        </thead>

        <tbody>
          <tr v-for="u in displayedUsers" :key="u.id">
            <td>
              <img :src="u.primaryPhoto || placeholder" class="avatar" />
            </td>
            <td>
              <div class="name">{{ u.firstName }} {{ u.lastName }}</div>
              <div class="muted">{{ u.role ?? 'user' }}</div>
            </td>
            <td class="center">{{ matchesCount(u) }}</td>
            <td>
              <button class="btn sm" @click="openUser(u.id)">View</button>
            </td>
          </tr>

          <tr v-if="!displayedUsers.length">
            <td colspan="4" class="empty">No users found.</td>
          </tr>
        </tbody>
      </table>
    </div>

    <!-- reuse your existing modal -->
    <UserDetailModal
      v-if="selectedUser"
      :userId="selectedUser"
      @close="selectedUser = null"
    />
  </div>
</template>

<script setup>
import { ref, computed, watch } from 'vue'
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'
import UserDetailModal from '../components/UserDetailModal.vue'

const placeholder = 'https://via.placeholder.com/72?text=No+Photo'

// GraphQL: fetch users + matches (we only request match ids so payload stays small)
const ALL_USERS_WITH_MATCHES = gql`
  query AllUsersWithMatches {
    allUsers {
      id
      firstName
      lastName
      role
      primaryPhoto
      matches {
        id
      }
    }
  }
`

const q = ref('')
const sortDesc = ref(true) // sort by most matches by default
const selectedUser = ref(null)

const { result, loading, error, refetch } = useQuery(ALL_USERS_WITH_MATCHES, null, {
  fetchPolicy: 'network-only'
})

const rawUsers = ref([])

// keep rawUsers in sync with query and filter out admin roles
watch(
  () => result.value,
  (r) => {
    const arr = r?.allUsers ?? []
    // exclude admin / superadmin
    rawUsers.value = arr.filter(u => u.role !== 'admin' && u.role !== 'superadmin')
  },
  { immediate: true }
)

// compute users with matches count (non-mutating)
function matchesCount(u) {
  // If backend later provides matchesCount, use u.matchesCount ?? u.matches?.length ?? 0
  return (u.matches && Array.isArray(u.matches)) ? u.matches.length : 0
}

const displayedUsers = computed(() => {
  let list = rawUsers.value.slice()

  if (q.value && q.value.trim()) {
    const term = q.value.trim().toLowerCase()
    list = list.filter(u => {
      const name = `${u.firstName ?? ''} ${u.lastName ?? ''}`.toLowerCase()
      return name.includes(term)
    })
  }

  list.sort((a, b) => {
    const ma = matchesCount(a)
    const mb = matchesCount(b)
    return sortDesc.value ? mb - ma : ma - mb
  })

  return list
})

// helpers
function applyFilter() {
  // computed displayedUsers will update automatically
}
function toggleSort() {
  sortDesc.value = !sortDesc.value
}
function openUser(id) {
  selectedUser.value = id
}
</script>

<style scoped>
.matches-manager {
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
.mm-header h1 { margin:0; font-size:1.3rem; }
.controls { display:flex; gap:8px; align-items:center; }
.search {
  padding:8px 10px;
  border-radius:8px;
  border:1px solid #e5e7eb;
  width:220px;
}
.btn.sort {
  background:#2563eb;
  color:white;
  border:none;
  padding:8px 10px;
  border-radius:8px;
  cursor:pointer;
}
.card {
  background:white;
  border-radius:10px;
  box-shadow: 0 6px 20px rgba(8,12,24,0.06);
  overflow:hidden;
}
.mm-table {
  width:100%;
  border-collapse:collapse;
}
.mm-table thead { background:#0f172a; color:white; }
.mm-table th, .mm-table td {
  padding:12px 14px;
  text-align:left;
  border-bottom:1px solid #f1f5f9;
}
.avatar { width:48px; height:48px; border-radius:8px; object-fit:cover; border:1px solid #eee; }
.name { font-weight:600; margin-bottom: 4px; }
.muted { color:#6b7280; font-size:0.85rem }
.center { text-align:center; }
.btn.sm {
  padding:6px 10px;
  background:#4a90e2;
  color:white;
  border:none;
  border-radius:6px;
  cursor:pointer;
}
.empty {
  text-align:center;
  padding:20px;
  color:#6b7280;
}
@media (max-width:720px) {
  .mm-header { flex-direction:column; align-items:stretch; gap:8px; }
  .search { width:100%; }
}
</style>
