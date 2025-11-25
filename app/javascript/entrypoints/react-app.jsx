import React from 'react'
import ReactDOM from 'react-dom/client'


import Rails from '@rails/ujs';
window.Rails = Rails

document.addEventListener('DOMContentLoaded', () => {
    const root = ReactDOM.createRoot(document.getElementById('react-app'))
    root.render(
        <React.StrictMode>
            <div className={'p-10'}>
                <h1 className={'font-extrabold tracking-tight text-5xl'}>React App</h1>
            </div>
        </React.StrictMode>
    );
})