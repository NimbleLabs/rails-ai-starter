import { streamCompletion } from '../lib/api';

/**
 * ChatModelAdapter for assistant-ui's useLocalRuntime.
 * Streams responses from the Rails SSE endpoint.
 */
export const chatModelAdapter = {
  async *run({ messages, abortSignal }) {
    // Get the last user message to send to our API
    const lastUserMessage = [...messages].reverse().find((m) => m.role === 'user');
    if (!lastUserMessage) return;

    const textContent = lastUserMessage.content
      .filter((part) => part.type === 'text')
      .map((part) => part.text)
      .join('');

    // We need a thread ID — it's passed via the unstable_threadId option
    const threadId = this._currentThreadId;
    if (!threadId) {
      yield { content: [{ type: 'text', text: 'Error: No active chat thread.' }] };
      return;
    }

    const response = await streamCompletion(threadId, textContent, abortSignal);

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

      // Parse SSE lines from buffer
      const lines = buffer.split('\n');
      // Keep the last potentially incomplete line in the buffer
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
          // Skip malformed JSON chunks
        }
      }
    }
  },
};

/**
 * Creates a thread-aware adapter that injects the current thread's remote ID.
 */
export function createThreadAwareAdapter(getThreadId) {
  return {
    async *run(options) {
      const adapter = { ...chatModelAdapter, _currentThreadId: getThreadId() };
      yield* chatModelAdapter.run.call(adapter, options);
    },
  };
}
