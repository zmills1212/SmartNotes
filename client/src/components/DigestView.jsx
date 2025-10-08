import React from 'react';

export default function DigestView({ digest }) {
  const themes = typeof digest.themes === 'string' ? JSON.parse(digest.themes) : digest.themes;
  
  return (
    <div className="bg-white rounded-lg shadow-md p-6">
      <div className="flex justify-between items-start mb-4">
        <div>
          <h3 className="text-lg font-semibold capitalize">{digest.range} Digest</h3>
          <p className="text-sm text-gray-500">
            {new Date(digest.period_start).toLocaleDateString()} - {new Date(digest.period_end).toLocaleDateString()}
          </p>
        </div>
        <span className="text-xs bg-blue-100 text-blue-800 px-2 py-1 rounded">
          {JSON.parse(digest.source_note_ids).length} notes
        </span>
      </div>
      <div className="mb-4">
        <h4 className="font-medium text-gray-700 mb-2">Summary</h4>
        <div className="text-gray-600 whitespace-pre-line text-sm">{digest.summary}</div>
      </div>
      {themes && themes.length > 0 && (
        <div>
          <h4 className="font-medium text-gray-700 mb-2">Recurring Themes</h4>
          <div className="flex flex-wrap gap-2">
            {themes.map((theme, idx) => (
              <span key={idx} className="bg-gray-100 text-gray-700 px-3 py-1 rounded-full text-xs">
                {theme.keyword} ({theme.count})
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
