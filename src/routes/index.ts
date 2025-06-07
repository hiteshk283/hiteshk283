import express, { Router } from 'express';
import { IndexController } from '../controllers/index';

const router = express.Router();
const indexController: IIndexController = new IndexController();

interface App {
    use(path: string, handler: Router): void;
}

interface IIndexController {
    getFlavors(req: express.Request, res: express.Response): void;
    getOrders(req: express.Request, res: express.Response): void;
}

export function setRoutes(app: App): void {
    // Define routes for flavors and orders
    router.get('/flavors', indexController.getFlavors.bind(indexController));
    router.get('/orders', indexController.getOrders.bind(indexController));

    // Attach the router to the app
    app.use('/', router);
}

// Default route
router.get('/', (req, res) => {
    res.send('Welcome to the Ice Cream Parlour!');
});

export default router;