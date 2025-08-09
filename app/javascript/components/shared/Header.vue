<template>
  <header class="bg-blue-500 p-4">
    <nav>
      <ul class="flex gap-4 m-0 p-0 list-none">
        <li>
          <router-link
            to="/"
            class="text-white font-semibold no-underline"
            active-class="underline"
          >
            Home
          </router-link>
        </li>
        <li>
          <router-link
            to="/signin"
            class="text-white font-semibold no-underline"
            active-class="underline"
          >
            Sign In
          </router-link>
        </li>
        <li>
          <router-link
            to="/signup"
            class="text-white font-semibold no-underline"
            active-class="underline"
          >
            Sign Up
          </router-link>
        </li>
      </ul>
    </nav>
  </header>
</template>
