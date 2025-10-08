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
