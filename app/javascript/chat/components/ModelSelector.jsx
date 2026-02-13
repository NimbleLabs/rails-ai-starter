import React, { useState, useEffect, useRef } from 'react';
import { listModels, updateChatModel } from '../lib/api';

export function ModelSelector({ chatId, currentModelId, onModelChange }) {
  const [models, setModels] = useState([]);
  const [open, setOpen] = useState(false);
  const ref = useRef(null);

  useEffect(() => {
    listModels().then(setModels).catch(() => {});
  }, []);

  useEffect(() => {
    function handleClickOutside(e) {
      if (ref.current && !ref.current.contains(e.target)) setOpen(false);
    }
    document.addEventListener('mousedown', handleClickOutside);
    return () => document.removeEventListener('mousedown', handleClickOutside);
  }, []);

  const currentModel = models.find((m) => m.model_id === currentModelId);
  const displayName = currentModel?.name || currentModelId || 'Select model';

  async function selectModel(model) {
    setOpen(false);
    if (model.model_id === currentModelId) return;

    if (chatId) {
      await updateChatModel(chatId, model.model_id);
    }
    onModelChange?.(model.model_id);
  }

  if (models.length === 0) return null;

  return (
    <div ref={ref} className="aui-model-selector">
      <button className="aui-model-selector-btn" onClick={() => setOpen(!open)}>
        <span className="aui-model-selector-label">{displayName}</span>
        <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" className="aui-model-chevron" style={{ transform: open ? 'rotate(180deg)' : '' }}>
          <path fillRule="evenodd" d="M4.22 6.22a.75.75 0 011.06 0L8 8.94l2.72-2.72a.75.75 0 111.06 1.06l-3.25 3.25a.75.75 0 01-1.06 0L4.22 7.28a.75.75 0 010-1.06z" clipRule="evenodd" />
        </svg>
      </button>

      {open && (
        <div className="aui-model-dropdown">
          {models.map((model) => (
            <button
              key={model.model_id}
              className={`aui-model-option ${model.model_id === currentModelId ? 'active' : ''}`}
              onClick={() => selectModel(model)}
            >
              <span className="aui-model-option-name">{model.name}</span>
              <span className="aui-model-option-ctx">
                {Math.round(model.context_window / 1000)}k ctx
              </span>
              {model.model_id === currentModelId && (
                <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 16 16" fill="currentColor" className="aui-model-check">
                  <path fillRule="evenodd" d="M12.416 3.376a.75.75 0 01.208 1.04l-5 7.5a.75.75 0 01-1.154.114l-3-3a.75.75 0 011.06-1.06l2.353 2.353 4.493-6.74a.75.75 0 011.04-.207z" clipRule="evenodd" />
                </svg>
              )}
            </button>
          ))}
        </div>
      )}
    </div>
  );
}
