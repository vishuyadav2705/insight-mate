import { Router } from 'express';
import mongoose from 'mongoose';

const router = Router();

const HistorySchema = new mongoose.Schema(
  {
    type: { type: String, required: true },
    title: { type: String, required: true },
    detail: { type: String, required: true },
    extra: { type: Object },
  },
  { timestamps: true }
);

const History = mongoose.models.History || mongoose.model('History', HistorySchema);

router.get('/', async (req, res) => {
  if (!mongoose.connection.readyState) return res.json([]);
  const items = await History.find().sort({ createdAt: -1 }).limit(100);
  res.json(items);
});

router.post('/', async (req, res) => {
  if (!mongoose.connection.readyState) return res.status(503).json({ error: 'db_unavailable' });
  const item = await History.create(req.body);
  res.status(201).json(item);
});

export default router;


