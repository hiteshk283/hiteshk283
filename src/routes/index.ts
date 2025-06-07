import express from 'express';
import { IndexController } from '../controllers/index';

const router = express.Router();
const indexController: IIndexController = new IndexController();

interface App {
    use(path: string, handler: Router): void;
}

interface IIndexController {
    getFlavors(req: Express.Request, res: Express.Response): void;
    getOrders(req: Express.Request, res: Express.Response): void;
}

export function setRoutes(app: App): void {
    app.use('/flavors', router.get('/', indexController.getFlavors.bind(indexController)));
    app.use('/orders', router.get('/', indexController.getOrders.bind(indexController)));
}

router.get('/', (req, res) => {
    res.send('Welcome to the Ice Cream Parlour!');
});

export default router;