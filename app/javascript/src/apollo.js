import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client/core'
import { setContext } from '@apollo/client/link/context'
import { provideApolloClient } from '@vue/apollo-composable'

const httpLink = createHttpLink({
  uri: 'http://localhost:3000/graphql',
})

// Add both CSRF token and JWT token to headers
const authLink = setContext((_, { headers }) => {
  const csrfToken =
    document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') ||
    getCookie('CSRF-TOKEN') || ''

  const token = localStorage.getItem('auth_token') || ''

  return {
    headers: {
      ...headers,
      'X-CSRF-Token': csrfToken,
      // Add Authorization header if token exists
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
    },
  }
})

function getCookie(name) {
  const value = `; ${document.cookie}`
  const parts = value.split(`; ${name}=`)
  if (parts.length === 2) return parts.pop().split(';').shift()
}

const cache = new InMemoryCache()

export const apolloClient = new ApolloClient({
  link: authLink.concat(httpLink),
  cache,
})

export function setupApollo() {
  provideApolloClient(apolloClient)
}
