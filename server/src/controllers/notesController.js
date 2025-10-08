const Note = require('../models/Note');
const { validateSensitiveNote } = require('../services/keywordDetector');

async function createNote(req, res) {
  try {
    const { title, content, is_sensitive, content_encrypted, encryption_meta, sensitive_keywords } = req.body;
    const validation = validateSensitiveNote(req.body);
    if (!validation.valid) return res.status(400).json({ error: validation.error, matches: validation.matches });
    const note = await Note.create({
      user_id: req.user.userId,
      title: title || null,
      content: content || null,
      content_encrypted: content_encrypted || false,
      encryption_meta: encryption_meta ? JSON.stringify(encryption_meta) : null,
      sensitive_keywords: sensitive_keywords ? JSON.stringify(sensitive_keywords) : '[]',
      is_sensitive: is_sensitive || false
    });
    res.status(201).json(note);
  } catch (error) {
    console.error('Create note error:', error);
    res.status(500).json({ error: 'Failed to create note' });
  }
}

async function getNotes(req, res) {
  try {
    const notes = await Note.findByUserId(req.user.userId);
    const sanitizedNotes = notes.map(note => {
      if (note.content_encrypted && note.is_sensitive) {
        return { ...note, content: '[LOCKED]', encryption_meta: note.encryption_meta };
      }
      return note;
    });
    res.json(sanitizedNotes);
  } catch (error) {
    console.error('Get notes error:', error);
    res.status(500).json({ error: 'Failed to fetch notes' });
  }
}

async function getNote(req, res) {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    if (note.user_id !== req.user.userId) return res.status(403).json({ error: 'Access denied' });
    res.json(note);
  } catch (error) {
    console.error('Get note error:', error);
    res.status(500).json({ error: 'Failed to fetch note' });
  }
}

async function updateNote(req, res) {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    if (note.user_id !== req.user.userId) return res.status(403).json({ error: 'Access denied' });
    if (req.body.content !== undefined) {
      const validation = validateSensitiveNote(req.body);
      if (!validation.valid) return res.status(400).json({ error: validation.error, matches: validation.matches });
    }
    const updates = {};
    if (req.body.title !== undefined) updates.title = req.body.title;
    if (req.body.content !== undefined) updates.content = req.body.content;
    if (req.body.content_encrypted !== undefined) updates.content_encrypted = req.body.content_encrypted;
    if (req.body.encryption_meta !== undefined) updates.encryption_meta = JSON.stringify(req.body.encryption_meta);
    if (req.body.is_sensitive !== undefined) updates.is_sensitive = req.body.is_sensitive;
    if (req.body.sensitive_keywords !== undefined) updates.sensitive_keywords = JSON.stringify(req.body.sensitive_keywords);
    const updatedNote = await Note.update(req.params.id, updates);
    res.json(updatedNote);
  } catch (error) {
    console.error('Update note error:', error);
    res.status(500).json({ error: 'Failed to update note' });
  }
}

async function deleteNote(req, res) {
  try {
    const note = await Note.findById(req.params.id);
    if (!note) return res.status(404).json({ error: 'Note not found' });
    if (note.user_id !== req.user.userId) return res.status(403).json({ error: 'Access denied' });
    await Note.delete(req.params.id);
    res.status(204).send();
  } catch (error) {
    console.error('Delete note error:', error);
    res.status(500).json({ error: 'Failed to delete note' });
  }
}

module.exports = { createNote, getNotes, getNote, updateNote, deleteNote };
