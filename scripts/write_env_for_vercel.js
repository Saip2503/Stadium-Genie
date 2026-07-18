const fs = require('fs');
const path = require('path');

const rootDir = path.resolve(__dirname, '..');
const envPath = path.join(rootDir, '.env');

const apiKey =
  process.env.AI_API_KEY ||
  process.env.GEMINI_API_KEY ||
  process.env.API_KEY ||
  '';

const lines = [
  `AI_API_KEY=${apiKey}`,
  `GEMINI_API_KEY=${process.env.GEMINI_API_KEY || apiKey}`,
  `API_KEY=${process.env.API_KEY || apiKey}`,
  '',
];

fs.writeFileSync(envPath, lines.join('\n'), { encoding: 'utf8' });

if (apiKey) {
  console.log('Created .env for Flutter web build from Vercel environment.');
} else {
  console.warn(
    'Created .env without an API key. Set AI_API_KEY in Vercel for Gemini responses.',
  );
}
