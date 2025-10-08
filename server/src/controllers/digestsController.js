const Digest = require('../models/Digest');
const digestService = require('../services/digestService');

async function getDigests(req, res) {
  try {
    const { range } = req.query;
    const digests = await Digest.findByUserId(req.user.userId, range || null);
    res.json(digests);
  } catch (error) {
    console.error('Get digests error:', error);
    res.status(500).json({ error: 'Failed to fetch digests' });
  }
}

async function generateDigest(req, res) {
  try {
    const { range } = req.query;
    if (!range || !['daily', 'weekly'].includes(range)) {
      return res.status(400).json({ error: 'Range must be "daily" or "weekly"' });
    }
    const digest = await digestService.generateDigest(req.user.userId, range);
    res.status(201).json(digest);
  } catch (error) {
    console.error('Generate digest error:', error);
    res.status(500).json({ error: 'Failed to generate digest' });
  }
}

module.exports = { getDigests, generateDigest };
