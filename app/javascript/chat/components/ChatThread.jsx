import React from 'react';
import {
  ThreadPrimitive,
  MessagePrimitive,
  ComposerPrimitive,
  ActionBarPrimitive,
  useAuiState,
} from '@assistant-ui/react';
import { MarkdownTextPrimitive } from '@assistant-ui/react-markdown';
import { ModelSelector } from './ModelSelector';
import { useChatMeta } from '../ChatContext';

function ThreadHeader() {
  const { chatMeta, updateChatMeta } = useChatMeta();
  const remoteId = useAuiState((s) => s.threadListItem?.remoteId) || null;
  const meta = remoteId ? chatMeta[remoteId] : null;

  return (
    <div className="aui-thread-header">
      <ModelSelector
        chatId={remoteId}
        currentModelId={meta?.model_id}
        onModelChange={(modelId) => {
          if (remoteId) {
            updateChatMeta(remoteId, { model_id: modelId });
          }
        }}
      />
    </div>
  );
}

function UserMessage() {
  return (
    <MessagePrimitive.Root className="aui-msg aui-msg-user">
      <div className="aui-msg-user-bubble">
        <MessagePrimitive.Content
          components={{
            Text: ({ text }) => <p className="whitespace-pre-wrap">{text}</p>,
          }}
        />
      </div>
    </MessagePrimitive.Root>
  );
}

function AssistantMessage() {
  return (
    <MessagePrimitive.Root className="aui-msg aui-msg-assistant">
      <div className="aui-avatar">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
          <path d="M15.98 1.804a1 1 0 00-1.96 0l-.24 1.192a1 1 0 01-.784.785l-1.192.238a1 1 0 000 1.962l1.192.238a1 1 0 01.785.785l.238 1.192a1 1 0 001.962 0l.238-1.192a1 1 0 01.785-.785l1.192-.238a1 1 0 000-1.962l-1.192-.238a1 1 0 01-.785-.785l-.238-1.192zM6.949 5.684a1 1 0 00-1.898 0l-.683 2.051a1 1 0 01-.633.633l-2.051.683a1 1 0 000 1.898l2.051.684a1 1 0 01.633.632l.683 2.051a1 1 0 001.898 0l.683-2.051a1 1 0 01.633-.633l2.051-.683a1 1 0 000-1.898l-2.051-.683a1 1 0 01-.633-.633L6.95 5.684zM13.949 13.684a1 1 0 00-1.898 0l-.184.551a1 1 0 01-.632.633l-.551.183a1 1 0 000 1.898l.551.183a1 1 0 01.633.633l.183.551a1 1 0 001.898 0l.184-.551a1 1 0 01.632-.633l.551-.183a1 1 0 000-1.898l-.551-.184a1 1 0 01-.633-.632l-.183-.551z" />
        </svg>
      </div>
      <div className="aui-msg-assistant-content">
        <MessagePrimitive.Content
          components={{
            Text: () => (
              <div className="aui-markdown">
                <MarkdownTextPrimitive />
              </div>
            ),
          }}
        />
        <div className="aui-action-bar">
          <ActionBarPrimitive.Copy className="aui-action-btn" />
        </div>
      </div>
    </MessagePrimitive.Root>
  );
}

function EmptyState() {
  return (
    <div className="aui-empty-state">
      <div className="aui-empty-icon">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor" className="w-8 h-8">
          <path d="M15.98 1.804a1 1 0 00-1.96 0l-.24 1.192a1 1 0 01-.784.785l-1.192.238a1 1 0 000 1.962l1.192.238a1 1 0 01.785.785l.238 1.192a1 1 0 001.962 0l.238-1.192a1 1 0 01.785-.785l1.192-.238a1 1 0 000-1.962l-1.192-.238a1 1 0 01-.785-.785l-.238-1.192zM6.949 5.684a1 1 0 00-1.898 0l-.683 2.051a1 1 0 01-.633.633l-2.051.683a1 1 0 000 1.898l2.051.684a1 1 0 01.633.632l.683 2.051a1 1 0 001.898 0l.683-2.051a1 1 0 01.633-.633l2.051-.683a1 1 0 000-1.898l-2.051-.683a1 1 0 01-.633-.633L6.95 5.684zM13.949 13.684a1 1 0 00-1.898 0l-.184.551a1 1 0 01-.632.633l-.551.183a1 1 0 000 1.898l.551.183a1 1 0 01.633.633l.183.551a1 1 0 001.898 0l.184-.551a1 1 0 01.632-.633l.551-.183a1 1 0 000-1.898l-.551-.184a1 1 0 01-.633-.632l-.183-.551z" />
        </svg>
      </div>
      <h2 className="text-lg font-semibold text-gray-800 mb-1">What can I help with?</h2>
      <p className="text-sm text-gray-500">Send a message to start a conversation.</p>
    </div>
  );
}

export function ChatThread() {
  return (
    <ThreadPrimitive.Root className="aui-thread-root">
      <ThreadHeader />

      <ThreadPrimitive.Viewport className="aui-thread-viewport">
        <ThreadPrimitive.Empty>
          <EmptyState />
        </ThreadPrimitive.Empty>

        <div className="aui-messages-container">
          <ThreadPrimitive.Messages
            components={{
              UserMessage,
              AssistantMessage,
            }}
          />
        </div>

        <ThreadPrimitive.ViewportFooter>
          <ThreadPrimitive.ScrollToBottom className="aui-scroll-to-bottom">
            <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
              <path fillRule="evenodd" d="M10 3a.75.75 0 01.75.75v10.638l3.96-4.158a.75.75 0 111.08 1.04l-5.25 5.5a.75.75 0 01-1.08 0l-5.25-5.5a.75.75 0 111.08-1.04l3.96 4.158V3.75A.75.75 0 0110 3z" clipRule="evenodd" />
            </svg>
          </ThreadPrimitive.ScrollToBottom>
        </ThreadPrimitive.ViewportFooter>
      </ThreadPrimitive.Viewport>

      <div className="aui-composer-area">
        <div className="aui-composer-container">
          <ComposerPrimitive.Root className="aui-composer">
            <ComposerPrimitive.Input
              placeholder="Message..."
              className="aui-composer-input"
              submitMode="enter"
            />
            <div className="aui-composer-actions">
              <ComposerPrimitive.Cancel className="aui-stop-btn">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
                  <path fillRule="evenodd" d="M2 10a8 8 0 1116 0 8 8 0 01-16 0zm5-2.25A.75.75 0 017.75 7h4.5a.75.75 0 01.75.75v4.5a.75.75 0 01-.75.75h-4.5a.75.75 0 01-.75-.75v-4.5z" clipRule="evenodd" />
                </svg>
              </ComposerPrimitive.Cancel>
              <ComposerPrimitive.Send className="aui-send-btn">
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
                  <path d="M3.105 2.289a.75.75 0 00-.826.95l1.414 4.925A1.5 1.5 0 005.135 9.25h6.115a.75.75 0 010 1.5H5.135a1.5 1.5 0 00-1.442 1.086l-1.414 4.926a.75.75 0 00.826.95 28.896 28.896 0 0015.293-7.154.75.75 0 000-1.115A28.897 28.897 0 003.105 2.289z" />
                </svg>
              </ComposerPrimitive.Send>
            </div>
          </ComposerPrimitive.Root>
          <p className="text-[11px] text-gray-400 text-center mt-2">AI can make mistakes. Verify important information.</p>
        </div>
      </div>
    </ThreadPrimitive.Root>
  );
}
