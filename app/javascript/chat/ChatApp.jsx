import React, { useRef, useMemo, useState, useCallback } from 'react';
import {
  useLocalRuntime,
  useAuiState,
  unstable_useRemoteThreadListRuntime,
  AssistantRuntimeProvider,
} from '@assistant-ui/react';
import { RailsThreadListAdapter, createHistoryAdapter } from './adapters/threadListAdapter';
import { ChatContext } from './ChatContext';
import { ChatLayout } from './components/ChatLayout';
import './styles/chat.css';

function getCsrfToken() {
  return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '';
}

const chatModelAdapter = {
  async *run({ messages, abortSignal, unstable_threadId }) {
    const lastUserMessage = [...messages].reverse().find((m) => m.role === 'user');
    if (!lastUserMessage) return;

    const textContent = lastUserMessage.content
      .filter((part) => part.type === 'text')
      .map((part) => part.text)
      .join('');

    const threadId = unstable_threadId;
    if (!threadId) {
      yield { content: [{ type: 'text', text: 'Error: No active chat thread.' }] };
      return;
    }

    const response = await fetch(`/api/v1/chats/${threadId}/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'X-CSRF-Token': getCsrfToken(),
      },
      body: JSON.stringify({ message: textContent }),
      signal: abortSignal,
    });

    if (!response.ok) {
      const errorText = await response.text();
      yield { content: [{ type: 'text', text: `Error: ${errorText}` }] };
      return;
    }

    const reader = response.body.getReader();
    const decoder = new TextDecoder();
    let fullText = '';
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (!line.startsWith('data: ')) continue;
        const jsonStr = line.slice(6).trim();
        if (!jsonStr) continue;

        try {
          const data = JSON.parse(jsonStr);
          if (data.done) break;
          if (data.error) {
            yield { content: [{ type: 'text', text: `Error: ${data.error}` }] };
            return;
          }
          if (data.content) {
            fullText += data.content;
            yield { content: [{ type: 'text', text: fullText }] };
          }
        } catch {
          // Skip malformed chunks
        }
      }
    }
  },
};

function useInnerRuntime() {
  const remoteId = useAuiState((s) => s.threadListItem?.remoteId);
  const remoteIdRef = useRef(null);
  remoteIdRef.current = remoteId;

  const historyAdapter = useMemo(
    () => createHistoryAdapter(() => remoteIdRef.current),
    [],
  );

  return useLocalRuntime(chatModelAdapter, {
    adapters: { history: historyAdapter },
  });
}

function useRailsChatRuntime(onChatsLoaded) {
  const threadListAdapter = useMemo(
    () => new RailsThreadListAdapter(onChatsLoaded),
    [onChatsLoaded],
  );

  return unstable_useRemoteThreadListRuntime({
    runtimeHook: useInnerRuntime,
    adapter: threadListAdapter,
  });
}

export default function ChatApp() {
  const [chatMeta, setChatMeta] = useState({});

  const onChatsLoaded = useCallback((chats) => {
    const meta = {};
    for (const chat of chats) {
      meta[String(chat.id)] = {
        model_id: chat.model_id,
        model_name: chat.model_name,
      };
    }
    setChatMeta(meta);
  }, []);

  const updateChatMeta = useCallback((remoteId, updates) => {
    setChatMeta((prev) => ({
      ...prev,
      [remoteId]: { ...prev[remoteId], ...updates },
    }));
  }, []);

  const runtime = useRailsChatRuntime(onChatsLoaded);

  const contextValue = useMemo(
    () => ({ chatMeta, updateChatMeta }),
    [chatMeta, updateChatMeta],
  );

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <ChatContext.Provider value={contextValue}>
        <ChatLayout />
      </ChatContext.Provider>
    </AssistantRuntimeProvider>
  );
}
