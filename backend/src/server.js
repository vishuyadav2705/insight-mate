import express from 'express';
import cors from 'cors';
import mongoose from 'mongoose';
import dotenv from 'dotenv';

import healthRouter from './routes/health.js';
import chatRouter from './routes/chat.js';
import imagesRouter from './routes/images.js';
import historyRouter from './routes/history.js';
import barcodeRouter from './routes/barcode.js';

dotenv.config();

const app = express();
app.use(cors());
app.use(express.json({ limit: '2mb' }));

app.use('/api/health', healthRouter);
app.use('/api/chat', chatRouter);
app.use('/api/images', imagesRouter);
app.use('/api/history', historyRouter);
app.use('/api/barcode', barcodeRouter);

const PORT = process.env.PORT || 8080;
const MONGO_URI = process.env.MONGO_URI || '';

async function start() {
  try {
    if (MONGO_URI) {
      await mongoose.connect(MONGO_URI);
      console.log('Connected to MongoDB');
    } else {
      console.warn('MONGO_URI not set; starting without DB connection');
    }
    app.listen(PORT, () => console.log(`Server listening on http://localhost:${PORT}`));
  } catch (err) {
    console.error('Failed to start server', err);
    process.exit(1);
  }
}

start();


