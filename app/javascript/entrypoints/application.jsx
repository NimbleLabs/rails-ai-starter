import React from 'react'
import { createRoot } from 'react-dom/client'
import Rails from '@rails/ujs'

import UserApp from '../app/UserApp'

window.Rails = Rails

const container = document.getElementById('app')
if (container) {
  createRoot(container).render(
    <React.StrictMode>
      <UserApp />
    </React.StrictMode>
  )
}
