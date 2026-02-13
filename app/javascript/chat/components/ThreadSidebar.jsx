import React from 'react';
import {
  ThreadListPrimitive,
  ThreadListItemPrimitive,
} from '@assistant-ui/react';

function ThreadListItem() {
  return (
    <ThreadListItemPrimitive.Root className="aui-thread-item group">
      <ThreadListItemPrimitive.Trigger className="aui-thread-trigger">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4 shrink-0 text-gray-400">
          <path fillRule="evenodd" d="M10 2c-2.236 0-4.43.18-6.57.524C1.993 2.755 1 4.014 1 5.426v5.148c0 1.413.993 2.67 2.43 2.902 1.168.188 2.352.327 3.55.414.28.02.521.18.642.413l1.713 3.293a.75.75 0 001.33 0l1.713-3.293a.783.783 0 01.642-.413 41.102 41.102 0 003.55-.414c1.437-.232 2.43-1.49 2.43-2.902V5.426c0-1.413-.993-2.67-2.43-2.902A41.289 41.289 0 0010 2zM6.75 6a.75.75 0 000 1.5h6.5a.75.75 0 000-1.5h-6.5zm0 2.5a.75.75 0 000 1.5h3.5a.75.75 0 000-1.5h-3.5z" clipRule="evenodd" />
        </svg>
        <span className="truncate"><ThreadListItemPrimitive.Title /></span>
      </ThreadListItemPrimitive.Trigger>
      <ThreadListItemPrimitive.Delete className="aui-thread-delete">
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" className="w-3.5 h-3.5">
          <path d="M5.28 4.22a.75.75 0 00-1.06 1.06L6.94 8l-2.72 2.72a.75.75 0 101.06 1.06L8 9.06l2.72 2.72a.75.75 0 101.06-1.06L9.06 8l2.72-2.72a.75.75 0 00-1.06-1.06L8 6.94 5.28 4.22z" />
        </svg>
      </ThreadListItemPrimitive.Delete>
    </ThreadListItemPrimitive.Root>
  );
}

export function ThreadSidebar() {
  return (
    <aside className="aui-sidebar">
      <div className="p-3">
        <ThreadListPrimitive.New className="aui-new-chat-btn">
          <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" className="w-4 h-4">
            <path d="M5.433 13.917l1.262-3.155A4 4 0 017.58 9.42l6.92-6.918a2.121 2.121 0 013 3l-6.92 6.918c-.383.383-.84.685-1.343.886l-3.154 1.262a.5.5 0 01-.65-.65z" />
            <path d="M3.5 5.75c0-.69.56-1.25 1.25-1.25h5.5a.75.75 0 000-1.5h-5.5A2.75 2.75 0 002 5.75v8.5A2.75 2.75 0 004.75 17h8.5A2.75 2.75 0 0016 14.25v-5.5a.75.75 0 00-1.5 0v5.5c0 .69-.56 1.25-1.25 1.25h-8.5c-.69 0-1.25-.56-1.25-1.25v-8.5z" />
          </svg>
          New Chat
        </ThreadListPrimitive.New>
      </div>

      <div className="px-3 pb-2">
        <p className="text-[11px] font-semibold text-gray-400 uppercase tracking-wider px-2">Conversations</p>
      </div>

      <div className="flex-1 overflow-y-auto px-2 pb-2">
        <ThreadListPrimitive.Items
          components={{ ThreadListItem }}
        />
      </div>
    </aside>
  );
}
