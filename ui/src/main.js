import { mount } from 'svelte'
import './app.css'
import App from './App.svelte'

const data = window.__TCA_ANALYSIS__ ?? {}

const app = mount(App, {
  target: document.getElementById('app'),
  props: { data },
})

export default app
