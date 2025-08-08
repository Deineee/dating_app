import { ApolloClient, InMemoryCache, createHttpLink } from '@apollo/client/core'
import { provideApolloClient } from '@vue/apollo-composable'

const httpLink = createHttpLink({
  uri: 'http://localhost:3000/graphql', // your Rails GraphQL endpoint
  credentials: 'include', // important if using cookies for sessions
})

const cache = new InMemoryCache()

export const apolloClient = new ApolloClient({
  link: httpLink,
  cache,
})

export function setupApollo() {
  provideApolloClient(apolloClient)
}
