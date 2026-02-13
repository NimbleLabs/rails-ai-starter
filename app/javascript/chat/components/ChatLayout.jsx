import React from 'react';
import { ThreadSidebar } from './ThreadSidebar';
import { ChatThread } from './ChatThread';

export function ChatLayout() {
  return (
    <div style={{ display: 'flex', height: '100%' }}>
      <ThreadSidebar />
      <div style={{ flex: 1, display: 'flex', flexDirection: 'column', minWidth: 0 }}>
        <ChatThread />
      </div>
    </div>
  );
}
