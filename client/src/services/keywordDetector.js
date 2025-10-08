export const DEFAULT_KEYWORDS = ['password','passcode','pin','ssn','social security','credit card','debit card','bank account','account number','routing number','medical','diagnosis','hiv','cancer','salary','income','tax','bitcoin','private key','seed phrase','mnemonic','secret key','api key','access token'];

export function detectSensitiveContent(text, customKeywords = []) {
  if (!text) return { isSensitive: false, matches: [] };
  const keywords = [...DEFAULT_KEYWORDS, ...customKeywords];
  const lowerText = text.toLowerCase();
  const matches = [];
  for (const keyword of keywords) {
    if (lowerText.includes(keyword.toLowerCase())) {
      matches.push(keyword);
    }
  }
  return {
    isSensitive: matches.length > 0,
    matches: [...new Set(matches)]
  };
}
