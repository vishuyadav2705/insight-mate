import { Router } from 'express';
import OpenAI from 'openai';
import { GoogleGenerativeAI } from '@google/generative-ai';

const router = Router();
const openaiApiKey = process.env.OPENAI_API_KEY;
const openai = openaiApiKey ? new OpenAI({ apiKey: openaiApiKey }) : null;

const geminiApiKey = process.env.GEMINI_API_KEY;
const genAI = geminiApiKey ? new GoogleGenerativeAI(geminiApiKey) : null;

router.post('/', async (req, res) => {
  const { messages, provider, apiKey } = req.body || {};
  if (!messages || !Array.isArray(messages)) {
    return res.status(400).json({ error: 'messages required' });
  }

  const activeProvider = provider || (geminiApiKey ? 'gemini' : (openaiApiKey ? 'openai' : 'echo'));
  const activeApiKey = apiKey || (activeProvider === 'gemini' ? geminiApiKey : openaiApiKey);

  if (activeProvider === 'gemini') {
    const key = activeApiKey || geminiApiKey;
    if (!key) {
      return res.json({ reply: `Echo (No Gemini API Key): ${messages[messages.length - 1]?.content ?? ''}` });
    }
    try {
      const client = new GoogleGenerativeAI(key);
      const model = client.getGenerativeModel({ model: 'gemini-1.5-flash' });
      
      const history = [];
      const userMessage = messages[messages.length - 1]?.content ?? '';
      
      for (let i = 0; i < messages.length - 1; i++) {
        const m = messages[i];
        const role = m.role === 'assistant' ? 'model' : 'user';
        history.push({
          role,
          parts: [{ text: m.content || '' }]
        });
      }
      
      const chat = model.startChat({ history });
      const result = await chat.sendMessage(userMessage);
      const reply = result.response.text();
      res.json({ reply });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'gemini_chat_failed', detail: err.message });
    }
  } else if (activeProvider === 'openai') {
    const key = activeApiKey || openaiApiKey;
    if (!key) {
      return res.json({ reply: `Echo (No OpenAI API Key): ${messages[messages.length - 1]?.content ?? ''}` });
    }
    try {
      const client = new OpenAI({ apiKey: key });
      const completion = await client.chat.completions.create({
        model: 'gpt-4o-mini',
        messages: messages.map(m => ({ role: m.role, content: m.content })),
        temperature: 0.7,
      });
      const reply = completion.choices?.[0]?.message?.content ?? '';
      res.json({ reply });
    } catch (err) {
      console.error(err);
      res.status(500).json({ error: 'openai_chat_failed', detail: err.message });
    }
  } else {
    res.json({ reply: `Echo: ${messages[messages.length - 1]?.content ?? ''}` });
  }
});

export default router;


