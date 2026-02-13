import React from 'react'
import ReactDOM from 'react-dom/client'
import ChatApp from '../chat/ChatApp'

document.addEventListener('DOMContentLoaded', () => {
    const root = ReactDOM.createRoot(document.getElementById('react-app'))
    root.render(
        <React.StrictMode>
            <ChatApp />
        </React.StrictMode>
    );
})
