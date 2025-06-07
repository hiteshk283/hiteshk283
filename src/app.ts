import express from 'express';
import { setRoutes } from './routes/index';
import routes from './routes';

const app = express();
const PORT = process.env.PORT || 3000;

app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use('/', routes);

setRoutes(app);

app.listen(PORT, () => {
    console.log(`Ice Cream Parlour app is running on http://localhost:${PORT}`);
});