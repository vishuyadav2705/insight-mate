import { Router } from 'express';
import OpenAI from 'openai';

const router = Router();
const openaiApiKey = process.env.OPENAI_API_KEY;
const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

router.post('/', async (req, res) => {
  const { messages } = req.body || {};
  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'messages required' });
  }
  if (!openai) {
    return res.json({ reply: `Echo: ${messages[messages.length - 1]?.content ?? ''}` });
  }
  try {
    const completion = await openai.chat.completions.create({
      model: 'gpt-4o-mini',
      messages,
      temperature: 0.7,
    });
    const reply = completion.choices?.[0]?.message?.content ?? '';
    res.json({ reply });
  } catch (err) {
    console.error(err);
    res.status(500).json({ error: 'chat_failed' });
  }
});

export default router;


