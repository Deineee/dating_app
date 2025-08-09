import { createApp, h, provide } from 'vue'
import App from '../src/App.vue'
import { DefaultApolloClient } from '@vue/apollo-composable'
import router from '../src/router'
import '../stylesheets/global.css'
import { apolloClient } from '../src/apollo.js'  

const app = createApp({
  setup() {
    provide(DefaultApolloClient, apolloClient)
  },
  render: () => h(App),
})

app.use(router)

app.mount('#app')
