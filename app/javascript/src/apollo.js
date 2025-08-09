import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client/core'
import { setContext } from '@apollo/client/link/context'
import { provideApolloClient } from '@vue/apollo-composable'

const httpLink = createHttpLink({
  uri: 'http://localhost:3000/graphql',
  credentials: 'include', // important for Devise cookie session
})

const csrfLink = setContext((_, { headers }) => {
  const token =
    document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') ||
    getCookie('CSRF-TOKEN') || '' // fallback if meta missing

  return {
    headers: {
      ...headers,
      'X-CSRF-Token': token,
    },
  }
})

// helper to read CSRF cookie if needed
function getCookie(name) {
  const value = `; ${document.cookie}`
  const parts = value.split(`; ${name}=`)
  if (parts.length === 2) return parts.pop().split(';').shift()
}

const cache = new InMemoryCache()

export const apolloClient = new ApolloClient({
  link: csrfLink.concat(httpLink),
  cache,
})

export function setupApollo() {
  provideApolloClient(apolloClient)
}
