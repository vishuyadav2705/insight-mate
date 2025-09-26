import { Router } from 'express';
import OpenAI from 'openai';

const router = Router();
const openaiApiKey = process.env.OPENAI_API_KEY;
const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

router.post('/generate', async (req, res) => {
  const { prompt } = req.body || {};
  if (!prompt) return res.status(400).json({ error: 'prompt required' });
  if (!openai) return res.json({ url: `https://picsum.photos/seed/${encodeURIComponent(prompt)}/512/512` });
  try {
    const result = await openai.images.generate({
      model: 'gpt-image-1',
      prompt,
      size: '512x512',
    });
    const url = result.data?.[0]?.url;
    res.json({ url });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'image_generation_failed' });
  }
});

export default router;


