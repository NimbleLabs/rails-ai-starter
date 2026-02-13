import { listChats, createChat, renameChat, deleteChat, getChatMessages } from '../lib/api';
import { ExportedMessageRepository } from '@assistant-ui/react';

/**
 * RemoteThreadListAdapter for assistant-ui's unstable_useRemoteThreadListRuntime.
 * Maps Rails chat CRUD to the adapter interface.
 */
export class RailsThreadListAdapter {
  constructor(onChatsLoaded) {
    this._onChatsLoaded = onChatsLoaded;
  }

  async list() {
    const chats = await listChats();
    this._onChatsLoaded?.(chats);
    return {
      threads: chats.map((chat) => ({
        remoteId: String(chat.id),
        title: chat.title || 'New Chat',
        status: 'regular',
      })),
    };
  }

  async initialize(_threadId) {
    const chat = await createChat();
    return {
      remoteId: String(chat.id),
      externalId: undefined,
    };
  }

  async rename(remoteId, newTitle) {
    await renameChat(remoteId, newTitle);
  }

  async archive(remoteId) {
    await deleteChat(remoteId);
  }

  async unarchive(_remoteId) {
    // No-op: we don't support unarchiving
  }

  async delete(remoteId) {
    await deleteChat(remoteId);
  }

  generateTitle() {
    // We auto-generate titles on the backend, so return an empty stream
    return Promise.resolve(new ReadableStream());
  }

  async fetch(threadId) {
    // The thread list has all the data we need
    const chats = await listChats();
    const chat = chats.find((c) => String(c.id) === threadId);
    if (!chat) throw new Error('Thread not found');
    return {
      remoteId: String(chat.id),
      title: chat.title || 'New Chat',
      status: 'regular',
    };
  }
}

/**
 * ThreadHistoryAdapter for loading persisted message history.
 */
export function createHistoryAdapter(getThreadId) {
  return {
    async load() {
      const threadId = getThreadId();
      if (!threadId) return { messages: [] };

      try {
        const messages = await getChatMessages(threadId);
        const threadMessages = messages.map((msg) => ({
          role: msg.role,
          content: msg.content
            ? [{ type: 'text', text: msg.content }]
            : [],
          id: String(msg.id),
          createdAt: new Date(msg.created_at),
          ...(msg.role === 'assistant'
            ? { status: { type: 'complete', reason: 'stop' } }
            : {}),
        }));

        return ExportedMessageRepository.fromArray(threadMessages);
      } catch {
        return { messages: [] };
      }
    },

    async append(_item) {
      // Messages are persisted by the Rails backend via ruby_llm
      // No need to persist from the frontend
    },
  };
}
