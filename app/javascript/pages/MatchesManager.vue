<template>
  <div class="matches-manager">
    <h1>Matches Manager</h1>

    <div v-if="loading" class="loading">Loading...</div>
    <div v-else-if="error" class="error">Error: {{ error.message }}</div>

    <table v-else class="matches-table">
      <thead>
        <tr>
          <th>User</th>
          <th>Email</th>
          <th>Matches Count</th>
        </tr>
      </thead>
      <tbody>
        <tr v-for="m in matches" :key="m.user.id">
          <td>{{ m.user.firstName }} {{ m.user.lastName }}</td>
          <td>{{ m.user.email }}</td>
          <td>{{ m.matchesCount }}</td>
        </tr>
      </tbody>
    </table>
  </div>
</template>

<script>
import { ref, watch } from 'vue'
import { useQuery } from '@vue/apollo-composable'
import gql from 'graphql-tag'

const GET_MATCHES_MANAGER = gql`
  query {
    matchesManager {
      user {
        id
        firstName
        lastName
        email
      }
      matchesCount
    }
  }
`

export default {
  name: 'MatchesManager',
  setup() {
    const matches = ref([])

    const { result, loading, error } = useQuery(GET_MATCHES_MANAGER)

    watch(
      result,
      () => {
        matches.value = result.value?.matchesManager ?? []
      },
      { immediate: true }
    )

    return {
      matches,
      loading,
      error
    }
  }
}
</script>

<style scoped>
.matches-manager {
  padding: 20px;
}

.matches-table {
  width: 100%;
  border-collapse: collapse;
}

.matches-table th,
.matches-table td {
  border: 1px solid #ccc;
  padding: 8px;
  text-align: left;
}

.loading {
  color: blue;
}

.error {
  color: red;
}
</style>
