#!/bin/bash

mkdir -p src/services

cat > src/services/keywordDetector.js << 'EOF'
const DEFAULT_KEYWORDS = ['password','passcode','pin','ssn','social security','credit card','debit card','bank account','account number','routing number','medical','diagnosis','hiv','cancer','salary','income','tax','bitcoin','private key','seed phrase','mnemonic','secret key','api key','access token'];

function detectSensitiveContent(text, customKeywords = []) {
  if (!text) return { isSensitive: false, matches: [] };
  const keywords = [...DEFAULT_KEYWORDS, ...customKeywords];
  const lowerText = text.toLowerCase();
  const matches = [];
  for (const keyword of keywords) {
    if (lowerText.includes(keyword.toLowerCase())) matches.push(keyword);
  }
  return { isSensitive: matches.length > 0, matches: [...new Set(matches)] };
}

function validateSensitiveNote(noteData) {
  if (noteData.is_sensitive && !noteData.content_encrypted) {
    return { valid: false, error: 'Sensitive notes must be encrypted client-side before upload' };
  }
  if (!noteData.content_encrypted && noteData.content) {
    const detection = detectSensitiveContent(noteData.content);
    if (detection.isSensitive) {
      return { valid: false, error: 'Content contains sensitive keywords and must be encrypted', matches: detection.matches };
    }
  }
  return { valid: true };
}

module.exports = { detectSensitiveContent, validateSensitiveNote, DEFAULT_KEYWORDS };
EOF

cat > src/services/summarizerService.js << 'EOF'
const natural = require('natural');
const config = require('../config/env');

class SummarizerService {
  constructor() {
    this.tokenizer = new natural.WordTokenizer();
    this.tfidf = new natural.TfIdf();
    if (config.OPENAI_API_KEY) {
      const { OpenAI } = require('openai');
      this.openai = new OpenAI({ apiKey: config.OPENAI_API_KEY });
    }
  }

  async generateSummary(notes, options = {}) {
    const { maxBullets = 5 } = options;
    if (notes.length === 0) return { summary: 'No notes to summarize.', themes: [] };
    if (this.openai) {
      try {
        const notesText = notes.map(n => `Title: ${n.title || 'Untitled'}\nContent: ${n.content}`).join('\n\n---\n\n');
        const prompt = `Summarize these notes in ${maxBullets} bullet points and identify 3-5 themes:\n\n${notesText}`;
        const completion = await this.openai.chat.completions.create({
          model: 'gpt-3.5-turbo',
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.7,
          max_tokens: 500
        });
        return { summary: completion.choices[0].message.content, themes: [] };
      } catch (error) {
        console.error('OpenAI failed, using local summarizer:', error.message);
      }
    }
    return this.generateLocalSummary(notes, maxBullets);
  }

  generateLocalSummary(notes, maxBullets) {
    const allText = notes.map(n => n.content || '').join(' ');
    const tokenizer = new natural.SentenceTokenizer();
    const sentences = tokenizer.tokenize(allText).filter(s => s.length > 20);
    const topSentences = sentences.slice(0, maxBullets);
    const wordFreq = {};
    const stopWords = new Set(natural.stopwords);
    notes.forEach(note => {
      const words = this.tokenizer.tokenize((note.content || '').toLowerCase());
      words.forEach(word => {
        if (!stopWords.has(word) && word.length > 3) wordFreq[word] = (wordFreq[word] || 0) + 1;
      });
    });
    const themes = Object.entries(wordFreq).sort((a, b) => b[1] - a[1]).slice(0, 5).map(([keyword, count]) => ({ keyword, count }));
    return {
      summary: topSentences.map(s => `• ${s}`).join('\n'),
      themes
    };
  }
}

module.exports = new SummarizerService();
EOF

cat > src/services/digestService.js << 'EOF'
const Note = require('../models/Note');
const Digest = require('../models/Digest');
const summarizerService = require('./summarizerService');

class DigestService {
  async generateDigest(userId, range = 'daily') {
    const { startDate, endDate } = this.getDateRange(range);
    const notes = await Note.findForDigest(userId, startDate, endDate);
    if (notes.length === 0) return { message: 'No notes found for this period', noteCount: 0 };
    const { summary, themes } = await summarizerService.generateSummary(notes, { maxBullets: range === 'daily' ? 5 : 10 });
    const digest = await Digest.create({
      user_id: userId,
      range,
      summary,
      themes: JSON.stringify(themes),
      source_note_ids: JSON.stringify(notes.map(n => n.id)),
      period_start: startDate,
      period_end: endDate
    });
    return { ...digest, noteCount: notes.length };
  }

  getDateRange(range) {
    const endDate = new Date();
    const startDate = new Date();
    if (range === 'daily') startDate.setDate(startDate.getDate() - 1);
    else if (range === 'weekly') startDate.setDate(startDate.getDate() - 7);
    return { startDate, endDate };
  }
}

module.exports = new DigestService();
EOF

cat > src/services/schedulerService.js << 'EOF'
const cron = require('node-cron');
const config = require('../config/env');

class SchedulerService {
  constructor() {
    this.jobs = [];
  }
  start() {
    console.log('Scheduler service started (digest jobs would run here)');
  }
  stop() {
    this.jobs.forEach(job => job.stop());
  }
}

module.exports = new SchedulerService();
EOF

echo "Services created!"
