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
