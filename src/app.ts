// filepath: c:\Users\Hitesh\hiteshk283\src\app.ts
import express from 'express';
import path from 'path';
import { setRoutes } from './routes/index';

const app = express();
const PORT = 3000;

app.use(express.json());

// Serve static files
app.use(express.static(path.join(__dirname, 'public')));

setRoutes(app);

app.listen(PORT, () => {
    console.log(`Server is running on http://localhost:${PORT}`);
});