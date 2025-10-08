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
