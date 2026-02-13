function getCsrfToken() {
  const meta = document.querySelector('meta[name="csrf-token"]');
  return meta ? meta.getAttribute('content') : '';
}

function headers(extra = {}) {
  return {
    'Content-Type': 'application/json',
    'X-CSRF-Token': getCsrfToken(),
    ...extra,
  };
}

export async function listChats() {
  const res = await fetch('/api/v1/chats', { headers: headers() });
  if (!res.ok) throw new Error('Failed to list chats');
  return res.json();
}

export async function createChat(title) {
  const res = await fetch('/api/v1/chats', {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ title }),
  });
  if (!res.ok) throw new Error('Failed to create chat');
  return res.json();
}

export async function getChat(chatId) {
  const res = await fetch(`/api/v1/chats/${chatId}`, { headers: headers() });
  if (!res.ok) throw new Error('Failed to get chat');
  return res.json();
}

export async function renameChat(chatId, title) {
  const res = await fetch(`/api/v1/chats/${chatId}`, {
    method: 'PATCH',
    headers: headers(),
    body: JSON.stringify({ title }),
  });
  if (!res.ok) throw new Error('Failed to rename chat');
  return res.json();
}

export async function deleteChat(chatId) {
  const res = await fetch(`/api/v1/chats/${chatId}`, {
    method: 'DELETE',
    headers: headers(),
  });
  if (!res.ok) throw new Error('Failed to delete chat');
}

export async function getChatMessages(chatId) {
  const res = await fetch(`/api/v1/chats/${chatId}/messages`, { headers: headers() });
  if (!res.ok) throw new Error('Failed to get messages');
  return res.json();
}

export async function listModels() {
  const res = await fetch('/api/v1/models', { headers: headers() });
  if (!res.ok) throw new Error('Failed to list models');
  return res.json();
}

export async function updateChatModel(chatId, modelId) {
  const res = await fetch(`/api/v1/chats/${chatId}`, {
    method: 'PATCH',
    headers: headers(),
    body: JSON.stringify({ model_id: modelId }),
  });
  if (!res.ok) throw new Error('Failed to update chat model');
  return res.json();
}

export function streamCompletion(chatId, message, abortSignal) {
  return fetch(`/api/v1/chats/${chatId}/completions`, {
    method: 'POST',
    headers: headers(),
    body: JSON.stringify({ message }),
    signal: abortSignal,
  });
}
