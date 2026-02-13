import { createContext, useContext } from 'react';

export const ChatContext = createContext({
  chatMeta: {},       // { [remoteId]: { model_id, model_name } }
  setChatMeta: () => {},
});

export function useChatMeta() {
  return useContext(ChatContext);
}
