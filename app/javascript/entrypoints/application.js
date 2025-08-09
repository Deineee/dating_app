import { createApp, h, provide } from 'vue'
import App from '../src/App.vue'
import { ApolloClient, InMemoryCache } from '@apollo/client/core'
import { DefaultApolloClient } from '@vue/apollo-composable'
import router from '../src/router'
import '../stylesheets/global.css'

const apolloClient = new ApolloClient({
  uri: '/graphql',
  cache: new InMemoryCache(),
})

const app = createApp({
  setup() {
    provide(DefaultApolloClient, apolloClient)
  },
  render: () => h(App)
})

app.use(router)

app.mount('#app')
